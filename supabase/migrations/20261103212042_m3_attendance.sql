-- M3: attendance (SPEC §5.3)
-- Members answer (rsvp), trainers record what happened (start_checkin / mark_attendance / qr_checkin) and can reset
-- one event. Every attendance change is written to attendance_log (CLAUDE.md rule 9). Members never write the
-- rsvps or attendance tables directly.
--
-- Who counts for an event ("participants"): active members (role 'member') it is addressed to (whole workspace or
-- its groups), plus anyone who answered or was marked (trainers who RSVP'd, walk-ins from other groups).

-- ───────────────────────── helpers ─────────────────────────
create or replace function private.event_audience(p_event uuid) returns setof uuid
language sql stable security definer set search_path = public as $$
  select m.user_id
  from events e join memberships m on m.workspace_id = e.workspace_id and m.status = 'active' and m.role = 'member'
  where e.id = p_event
    and (cardinality(e.group_ids) = 0
         or exists (select 1 from group_members gm where gm.user_id = m.user_id and gm.group_id = any (e.group_ids)));
$$;

create or replace function private.event_participants(p_event uuid) returns setof uuid
language sql stable security definer set search_path = public as $$
  select * from private.event_audience(p_event)
  union select user_id from rsvps where event_id = p_event
  union select user_id from attendance where event_id = p_event;
$$;

create or replace function private.trainer_event(p_event uuid) returns public.events
language plpgsql stable security definer set search_path = public as $$
declare ev events;
begin
  perform private.require_uid();
  select * into ev from events where id = p_event;
  if not found then perform private.fail('not_found'); end if;
  if not is_trainer(ev.workspace_id) then perform private.fail('forbidden'); end if;
  return ev;
end $$;

create or replace function private.log_attendance(ev public.events, p_user uuid, p_old boolean, p_new boolean, p_note text)
returns void language sql security definer set search_path = public as $$
  insert into attendance_log (event_id, user_id, workspace_id, old_present, new_present, changed_by, note)
  values (ev.id, p_user, ev.workspace_id, p_old, p_new, auth.uid(), p_note);
$$;

-- ───────────────────────── rsvp ─────────────────────────
create or replace function public.rsvp(p_event uuid, p_answer public.rsvp_answer, p_reason text default null)
returns public.rsvp_answer
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := private.require_uid();
  ev events;
  v_reason text := nullif(trim(coalesce(p_reason, '')), '');
begin
  -- the row lock serialises concurrent "going" answers so capacity can't be overbooked
  select * into ev from events where id = p_event for update;
  if not found or not can_see_event(p_event) then perform private.fail('not_found'); end if;
  if ev.status <> 'scheduled' then perform private.fail('event_cancelled'); end if;
  if now() >= coalesce(ev.rsvp_deadline, ev.starts_at) then perform private.fail('rsvp_closed'); end if;
  if length(v_reason) > 300 then perform private.fail('reason_too_long'); end if;
  if p_answer = 'not_going' and not (select allow_self_absence from workspaces where id = ev.workspace_id) then
    perform private.fail('self_absence_disabled');
  end if;
  if p_answer = 'going' and ev.capacity is not null
     and (select count(*) from rsvps where event_id = ev.id and answer = 'going' and user_id <> v_uid) >= ev.capacity then
    perform private.fail('event_full');
  end if;

  insert into rsvps (event_id, user_id, workspace_id, answer, reason)
  values (ev.id, v_uid, ev.workspace_id, p_answer, case when p_answer = 'not_going' then v_reason end)
  on conflict (event_id, user_id) do update
    set answer = excluded.answer, reason = excluded.reason, answered_at = now();
  return p_answer;
end $$;

-- ───────────────────────── counts (no names) ─────────────────────────
create or replace function public.event_counts_many(p_events uuid[])
returns table (event_id uuid, invited int, going int, not_going int, no_answer int, present int, absent int)
language sql stable security definer set search_path = public as $$
  select e.id,
         (select count(*) from private.event_participants(e.id))::int,
         (select count(*) from rsvps r where r.event_id = e.id and r.answer = 'going')::int,
         (select count(*) from rsvps r where r.event_id = e.id and r.answer = 'not_going')::int,
         (select count(*) from private.event_participants(e.id) p(u)
           where not exists (select 1 from rsvps r where r.event_id = e.id and r.user_id = p.u))::int,
         (select count(*) from attendance a where a.event_id = e.id and a.present)::int,
         (select count(*) from attendance a where a.event_id = e.id and not a.present)::int
  from events e
  where e.id = any (p_events[1:200]) and can_see_event(e.id);
$$;

create or replace function public.event_counts(p_event uuid)
returns table (invited int, going int, not_going int, no_answer int, present int, absent int)
language plpgsql stable security definer set search_path = public as $$
begin
  perform private.require_uid();
  if not can_see_event(p_event) then perform private.fail('not_found'); end if;
  return query select c.invited, c.going, c.not_going, c.no_answer, c.present, c.absent
               from public.event_counts_many(array[p_event]) c;
end $$;

-- ───────────────────────── trainer lists ─────────────────────────
create or replace function public.event_attendees(p_event uuid)
returns table (user_id uuid, full_name text, role public.member_role, in_audience boolean, answer public.rsvp_answer,
               reason text, answered_at timestamptz, present boolean, method public.attendance_method,
               marked_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
declare ev events := private.trainer_event(p_event);
begin
  return query
    select p.u, pr.full_name, m.role, p.u in (select * from private.event_audience(ev.id)),
           r.answer, r.reason, r.answered_at, a.present, a.method, a.marked_at
    from private.event_participants(ev.id) p(u)
    join profiles pr on pr.id = p.u
    left join memberships m on m.workspace_id = ev.workspace_id and m.user_id = p.u
    left join rsvps r on r.event_id = ev.id and r.user_id = p.u
    left join attendance a on a.event_id = ev.id and a.user_id = p.u
    order by lower(pr.full_name);
end $$;

-- Walk-in candidates: every active member of the workspace (not only the event's audience).
create or replace function public.checkin_candidates(p_event uuid)
returns table (user_id uuid, full_name text)
language plpgsql stable security definer set search_path = public as $$
declare ev events := private.trainer_event(p_event);
begin
  return query
    select m.user_id, pr.full_name from memberships m join profiles pr on pr.id = m.user_id
    where m.workspace_id = ev.workspace_id and m.status = 'active'
    order by lower(pr.full_name);
end $$;

-- ───────────────────────── check-in ─────────────────────────
-- Confirmed members are present by default; the trainer only marks the exceptions.
create or replace function public.start_checkin(p_event uuid) returns int
language plpgsql security definer set search_path = public as $$
declare
  ev events := private.trainer_event(p_event);
  n int;
begin
  if ev.status <> 'scheduled' then perform private.fail('event_cancelled'); end if;
  with ins as (
    insert into attendance (event_id, user_id, workspace_id, present, method, marked_by)
    select ev.id, r.user_id, ev.workspace_id, true, 'default', auth.uid()
    from rsvps r
    where r.event_id = ev.id and r.answer = 'going'
      and not exists (select 1 from attendance a where a.event_id = ev.id and a.user_id = r.user_id)
    on conflict do nothing
    returning user_id)
  insert into attendance_log (event_id, user_id, workspace_id, old_present, new_present, changed_by, note)
  select ev.id, ins.user_id, ev.workspace_id, null, true, auth.uid(), 'default' from ins;
  get diagnostics n = row_count;
  return n;
end $$;

create or replace function public.mark_attendance(p_event uuid, p_user uuid, p_present boolean) returns void
language plpgsql security definer set search_path = public as $$
declare
  ev events := private.trainer_event(p_event);
  v_old boolean;
begin
  if ev.status <> 'scheduled' then perform private.fail('event_cancelled'); end if;
  if not exists (select 1 from memberships where workspace_id = ev.workspace_id and user_id = p_user and status = 'active')
     and not exists (select 1 from rsvps where event_id = ev.id and user_id = p_user) then
    perform private.fail('not_member');
  end if;
  select present into v_old from attendance where event_id = ev.id and user_id = p_user;
  insert into attendance (event_id, user_id, workspace_id, present, method, marked_by)
  values (ev.id, p_user, ev.workspace_id, p_present, 'trainer', auth.uid())
  on conflict (event_id, user_id) do update
    set present = excluded.present, method = 'trainer', marked_by = auth.uid(), marked_at = now();
  if v_old is distinct from p_present then perform private.log_attendance(ev, p_user, v_old, p_present, 'trainer'); end if;
end $$;

create or replace function public.create_checkin_token(p_event uuid, p_minutes int default 30) returns text
language plpgsql security definer set search_path = public as $$
declare
  ev events := private.trainer_event(p_event);
  v_token text := encode(extensions.gen_random_bytes(16), 'hex');
begin
  if ev.status <> 'scheduled' then perform private.fail('event_cancelled'); end if;
  if p_minutes not between 1 and 240 then perform private.fail('invalid_minutes'); end if;
  insert into checkin_tokens (event_id, workspace_id, token_hash, expires_at, created_by)
  values (ev.id, ev.workspace_id, encode(extensions.digest(v_token, 'sha256'), 'hex'),
          now() + make_interval(mins => p_minutes), auth.uid());
  return v_token;
end $$;

-- A member scans the QR code: present, method 'qr'. Returns the event id for the confirmation screen.
create or replace function public.qr_checkin(p_token text) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := private.require_uid();
  t checkin_tokens;
  ev events;
  v_old boolean;
begin
  select * into t from checkin_tokens
  where token_hash = encode(extensions.digest(trim(coalesce(p_token, '')), 'sha256'), 'hex');
  if not found then perform private.fail('invalid_token'); end if;
  if t.expires_at < now() then perform private.fail('token_expired'); end if;
  select * into ev from events where id = t.event_id;
  if not can_see_event(ev.id) then perform private.fail('not_invited'); end if;
  if ev.status <> 'scheduled' then perform private.fail('event_cancelled'); end if;

  select present into v_old from attendance where event_id = ev.id and user_id = v_uid;
  insert into attendance (event_id, user_id, workspace_id, present, method, marked_by)
  values (ev.id, v_uid, ev.workspace_id, true, 'qr', v_uid)
  on conflict (event_id, user_id) do update set present = true, method = 'qr', marked_by = v_uid, marked_at = now();
  if v_old is distinct from true then perform private.log_attendance(ev, v_uid, v_old, true, 'qr'); end if;
  return ev.id;
end $$;

-- Removes the attendance of ONE event (the UI asks to type its title). Each removed row is logged first.
create or replace function public.reset_attendance(p_event uuid, p_confirm_title text) returns int
language plpgsql security definer set search_path = public as $$
declare
  ev events := private.trainer_event(p_event);
  n int;
begin
  if trim(coalesce(p_confirm_title, '')) <> trim(ev.title) then perform private.fail('confirm_mismatch'); end if;
  insert into attendance_log (event_id, user_id, workspace_id, old_present, new_present, changed_by, note)
  select ev.id, a.user_id, ev.workspace_id, a.present, null, auth.uid(), 'reset'
  from attendance a where a.event_id = ev.id;
  delete from attendance where event_id = ev.id;
  get diagnostics n = row_count;
  return n;
end $$;

-- ───────────────────────── history and stats ─────────────────────────
-- Past events of one member (self or trainer), newest first.
create or replace function public.member_attendance(p_ws uuid, p_user uuid, p_days int default 365)
returns table (event_id uuid, title text, starts_at timestamptz, answer public.rsvp_answer, reason text,
               present boolean, method public.attendance_method)
language plpgsql stable security definer set search_path = public as $$
begin
  perform private.require_uid();
  if not (is_trainer(p_ws) or (p_user = auth.uid() and is_member(p_ws))) then perform private.fail('forbidden'); end if;
  return query
    select e.id, e.title, e.starts_at, r.answer, r.reason, a.present, a.method
    from events e
    left join rsvps r on r.event_id = e.id and r.user_id = p_user
    left join attendance a on a.event_id = e.id and a.user_id = p_user
    where e.workspace_id = p_ws and e.status = 'scheduled'
      and e.starts_at < now() and e.starts_at >= now() - make_interval(days => least(p_days, 3660))
      and p_user in (select * from private.event_participants(e.id))
    order by e.starts_at desc;
end $$;

-- Per member over a period: events they were part of, present, absent (marked), unrecorded.
create or replace function public.attendance_summary(p_ws uuid, p_days int default 90)
returns table (user_id uuid, events int, present int, absent int, unrecorded int)
language plpgsql stable security definer set search_path = public as $$
begin
  perform private.require_uid();
  if not is_trainer(p_ws) then perform private.fail('forbidden'); end if;
  return query
    with ev as (
      select e.id from events e
      where e.workspace_id = p_ws and e.status = 'scheduled'
        and e.starts_at < now() and e.starts_at >= now() - make_interval(days => least(p_days, 3660))),
    pairs as (select ev.id as event_id, p.u from ev, private.event_participants(ev.id) p(u))
    select m.user_id,
           count(pairs.event_id)::int,
           count(*) filter (where a.present)::int,
           count(*) filter (where a.present = false)::int,
           count(*) filter (where pairs.event_id is not null and a.present is null)::int
    from memberships m
    left join pairs on pairs.u = m.user_id
    left join attendance a on a.event_id = pairs.event_id and a.user_id = m.user_id
    where m.workspace_id = p_ws and m.status = 'active'
    group by m.user_id;
end $$;

-- ───────────────────────── privileges ─────────────────────────
revoke execute on all functions in schema private from public, anon, authenticated;
do $$
declare f text;
begin
  foreach f in array array[
    'rsvp(uuid, public.rsvp_answer, text)', 'event_counts_many(uuid[])', 'event_counts(uuid)',
    'event_attendees(uuid)', 'checkin_candidates(uuid)', 'start_checkin(uuid)',
    'mark_attendance(uuid, uuid, boolean)', 'create_checkin_token(uuid, integer)', 'qr_checkin(text)',
    'reset_attendance(uuid, text)', 'member_attendance(uuid, uuid, integer)', 'attendance_summary(uuid, integer)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
