-- M2: events (SPEC §5.2)
--   * weekly series materialised into events: expand_series(), DST-safe (local time → workspace timezone)
--   * update_series(… 'future'): upcoming occurrences without RSVPs follow the series; answered ones are kept
--   * cancel_event(): this / future, optional in-app notice (push + e-mail delivery arrive with M5)
--   * nightly cron keeps 12 weeks of occurrences ahead
--   * personal iCal feed: secret token per user, read by the `calendar` Edge Function via calendar_feed()

-- ───────────────────────── series and event columns ─────────────────────────
alter table public.event_series
  add column location_url          text,
  add column image_url             text,
  add column rsvp_deadline_minutes integer check (rsvp_deadline_minutes between 0 and 20160),  -- before start; null = at start
  add constraint event_series_title_length check (length(title) between 1 and 140),
  add constraint event_series_until_after_start check (until is null or until >= starts_on);

alter table public.events
  add column occurrence_date date,                          -- series occurrences: the local date it was generated for
  add column is_exception    boolean not null default false, -- edited on its own: series updates leave it alone
  add column cancelled_at    timestamptz,
  add constraint events_occurrence_needs_series check (occurrence_date is null or series_id is not null),
  add constraint events_deadline_before_end check (rsvp_deadline is null or rsvp_deadline <= ends_at);

create unique index events_series_occurrence on public.events (series_id, occurrence_date) where series_id is not null;
create index on public.events (workspace_id, status, starts_at);

-- ───────────────────────── integrity triggers ─────────────────────────
-- group_ids must be groups of the same workspace
create or replace function private.check_group_ids() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if cardinality(new.group_ids) > 0 and exists (
       select 1 from unnest(new.group_ids) g(id)
       where not exists (select 1 from groups where groups.id = g.id and groups.workspace_id = new.workspace_id)) then
    perform private.fail('group_invalid');
  end if;
  return new;
end $$;
create trigger events_check_groups before insert or update of group_ids, workspace_id on public.events
  for each row execute function private.check_group_ids();
create trigger series_check_groups before insert or update of group_ids, workspace_id on public.event_series
  for each row execute function private.check_group_ids();

-- events never move between workspaces or series; editing a series occurrence by hand makes it an exception
create or replace function private.guard_event_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.workspace_id <> old.workspace_id or new.series_id is distinct from old.series_id
     or new.occurrence_date is distinct from old.occurrence_date then
    perform private.fail('forbidden');
  end if;
  if new.status = 'cancelled' and old.status <> 'cancelled' then new.cancelled_at := now(); end if;
  if new.status = 'scheduled' then new.cancelled_at := null; end if;
  if old.series_id is not null and coalesce(current_setting('bw.series_sync', true), '') <> 'on'
     and (new.title, new.description, new.starts_at, new.ends_at, new.location, new.location_url, new.category,
          new.image_url, new.capacity, new.rsvp_deadline, new.visibility, new.group_ids)
         is distinct from
         (old.title, old.description, old.starts_at, old.ends_at, old.location, old.location_url, old.category,
          old.image_url, old.capacity, old.rsvp_deadline, old.visibility, old.group_ids) then
    new.is_exception := true;
  end if;
  return new;
end $$;
create trigger events_guard_update before update on public.events
  for each row execute function private.guard_event_update();

create or replace function private.guard_series_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.workspace_id <> old.workspace_id then perform private.fail('forbidden'); end if;
  return new;
end $$;
create trigger series_guard_update before update on public.event_series
  for each row execute function private.guard_series_update();

-- ───────────────────────── series expansion ─────────────────────────
-- Local dates of a series between two dates. Weeks are counted from the Monday of starts_on.
create or replace function private.series_dates(s public.event_series, p_from date, p_to date) returns setof date
language sql stable as $$
  select d::date
  from generate_series(greatest(s.starts_on, p_from), least(coalesce(s.until, p_to), p_to), interval '1 day') d
  where extract(isodow from d)::smallint = any (s.weekdays)
    and ((d::date - (s.starts_on - (extract(isodow from s.starts_on)::int - 1))) / 7) % s.interval_weeks = 0;
$$;

-- Start of an occurrence: local wall-clock time in the workspace timezone (DST-safe).
create or replace function private.occurrence_start(s public.event_series, d date, tz text) returns timestamptz
language sql stable as $$ select (d + s.start_time) at time zone tz $$;

create or replace function private.expand_series(p_series uuid, p_until date) returns int
language plpgsql security definer set search_path = public as $$
declare
  s  event_series;
  tz text;
  n  int;
begin
  select * into s from event_series where id = p_series;
  if not found then perform private.fail('not_found'); end if;
  select timezone into tz from workspaces where id = s.workspace_id;

  perform set_config('bw.series_sync', 'on', true);
  insert into events (workspace_id, series_id, occurrence_date, title, description, starts_at, ends_at,
                      location, location_url, category, image_url, capacity, rsvp_deadline,
                      visibility, group_ids, created_by)
  select s.workspace_id, s.id, o.d, s.title, s.description, o.starts_at, o.starts_at + make_interval(mins => s.duration_min),
         s.location, s.location_url, s.category, s.image_url, s.capacity,
         o.starts_at - make_interval(mins => s.rsvp_deadline_minutes),
         s.visibility, s.group_ids, s.created_by
  from (select d, private.occurrence_start(s, d, tz) as starts_at
        from private.series_dates(s, (now() at time zone tz)::date, p_until) d) o
  where o.starts_at > now()                      -- never create occurrences in the past
  on conflict (series_id, occurrence_date) where series_id is not null do nothing;  -- existing/edited/cancelled stay
  get diagnostics n = row_count;
  perform set_config('bw.series_sync', 'off', true);
  return n;
end $$;

create or replace function public.expand_series(p_series uuid, p_until date default current_date + 84) returns int
language plpgsql security definer set search_path = public as $$
declare v_ws uuid;
begin
  perform private.require_uid();
  select workspace_id into v_ws from event_series where id = p_series;
  if v_ws is null or not is_trainer(v_ws) then perform private.fail('forbidden'); end if;
  return private.expand_series(p_series, least(p_until, current_date + 366));
end $$;

-- Nightly: keep 12 weeks of occurrences ahead for every running series.
create or replace function private.extend_all_series() returns int
language plpgsql security definer set search_path = public as $$
declare
  r record;
  total int := 0;
begin
  for r in select id from event_series where until is null or until >= current_date loop
    total := total + private.expand_series(r.id, current_date + 84);
  end loop;
  return total;
end $$;

-- ───────────────────────── update series (scope 'future') ─────────────────────────
-- Scope 'this' is a plain update of one event row (the trigger marks it as an exception).
-- Scope 'future' changes the series from this occurrence on (starts_on moves there, so earlier dates are never
-- generated under the new rule): upcoming occurrences without RSVPs and not edited
-- individually are updated (or cancelled if their date no longer fits); answered ones are kept as they are.
create or replace function public.update_series(p_event uuid, p_changes jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  ev  events;
  s   event_series;
  tz  text;
  r   record;
  v_start timestamptz;
  n_updated int := 0;
  n_cancelled int := 0;
  n_kept int := 0;
  n_created int;
  v_horizon date;
  c jsonb := coalesce(p_changes, '{}');
begin
  perform private.require_uid();
  select * into ev from events where id = p_event;
  if not found then perform private.fail('not_found'); end if;
  if not is_trainer(ev.workspace_id) then perform private.fail('forbidden'); end if;
  if ev.series_id is null then perform private.fail('not_series'); end if;

  -- keep the horizon the series already has (it may reach further than the default 12 weeks)
  select greatest(current_date + 84, max(occurrence_date)) into v_horizon from events where series_id = ev.series_id;

  update event_series set
    title          = case when c ? 'title'          then c->>'title'                  else title end,
    description    = case when c ? 'description'    then coalesce(c->>'description', '') else description end,
    location       = case when c ? 'location'       then c->>'location'               else location end,
    location_url   = case when c ? 'location_url'   then c->>'location_url'           else location_url end,
    category       = case when c ? 'category'       then c->>'category'               else category end,
    image_url      = case when c ? 'image_url'      then c->>'image_url'              else image_url end,
    capacity       = case when c ? 'capacity'       then (c->>'capacity')::int        else capacity end,
    visibility     = case when c ? 'visibility'     then (c->>'visibility')::event_visibility else visibility end,
    group_ids      = case when c ? 'group_ids'      then array(select jsonb_array_elements_text(c->'group_ids')::uuid) else group_ids end,
    start_time     = case when c ? 'start_time'     then (c->>'start_time')::time     else start_time end,
    duration_min   = case when c ? 'duration_min'   then (c->>'duration_min')::int    else duration_min end,
    weekdays       = case when c ? 'weekdays'       then array(select jsonb_array_elements_text(c->'weekdays')::smallint) else weekdays end,
    interval_weeks = case when c ? 'interval_weeks' then (c->>'interval_weeks')::smallint else interval_weeks end,
    until          = case when c ? 'until'          then (c->>'until')::date          else until end,
    rsvp_deadline_minutes = case when c ? 'rsvp_deadline_minutes' then (c->>'rsvp_deadline_minutes')::int else rsvp_deadline_minutes end,
    -- the new rule applies from this occurrence on (also the week anchor for "every N weeks")
    starts_on      = greatest(starts_on, ev.occurrence_date)
  where id = ev.series_id
  returning * into s;
  select timezone into tz from workspaces where id = s.workspace_id;

  perform set_config('bw.series_sync', 'on', true);
  for r in
    select e.id, e.occurrence_date,
           e.is_exception or exists (select 1 from rsvps where rsvps.event_id = e.id) as keep
    from events e
    where e.series_id = s.id and e.occurrence_date >= ev.occurrence_date
      and e.status = 'scheduled' and e.ends_at > now()
  loop
    if r.keep then
      n_kept := n_kept + 1;
    elsif r.occurrence_date in (select private.series_dates(s, r.occurrence_date, r.occurrence_date)) then
      v_start := private.occurrence_start(s, r.occurrence_date, tz);
      update events set title = s.title, description = s.description, location = s.location,
                        location_url = s.location_url, category = s.category, image_url = s.image_url,
                        capacity = s.capacity, visibility = s.visibility, group_ids = s.group_ids,
                        starts_at = v_start, ends_at = v_start + make_interval(mins => s.duration_min),
                        rsvp_deadline = v_start - make_interval(mins => s.rsvp_deadline_minutes)
      where id = r.id;
      n_updated := n_updated + 1;
    else
      update events set status = 'cancelled' where id = r.id;
      n_cancelled := n_cancelled + 1;
    end if;
  end loop;
  perform set_config('bw.series_sync', 'off', true);

  n_created := private.expand_series(s.id, v_horizon);
  return jsonb_build_object('updated', n_updated, 'cancelled', n_cancelled, 'kept', n_kept, 'created', n_created);
end $$;

-- ───────────────────────── cancel ─────────────────────────
create or replace function private.broadcast_conversation(p_ws uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  select id into v from conversations where workspace_id = p_ws and kind = 'broadcast';
  if v is null then
    insert into conversations (workspace_id, kind) values (p_ws, 'broadcast')
    on conflict do nothing returning id into v;
    if v is null then select id into v from conversations where workspace_id = p_ws and kind = 'broadcast'; end if;
  end if;
  return v;
end $$;

-- Active members an event is addressed to (whole workspace, or its groups + all trainers/owners).
create or replace function private.event_invitees(p_event uuid) returns setof uuid
language sql stable security definer set search_path = public as $$
  select m.user_id
  from events e join memberships m on m.workspace_id = e.workspace_id and m.status = 'active'
  where e.id = p_event
    and (cardinality(e.group_ids) = 0 or m.role in ('owner', 'trainer')
         or exists (select 1 from group_members gm where gm.user_id = m.user_id and gm.group_id = any (e.group_ids)));
$$;

-- p_scope 'this' cancels one event; 'future' (series only) ends the series before this occurrence and cancels the
-- upcoming ones. With p_notify, the message goes to everyone invited (in-app now; push/e-mail with M5).
create or replace function public.cancel_event(p_event uuid, p_notify boolean default false,
                                               p_scope text default 'this', p_message text default null) returns int
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := private.require_uid();
  ev events;
  n int;
  v_msg uuid;
begin
  select * into ev from events where id = p_event;
  if not found then perform private.fail('not_found'); end if;
  if not is_trainer(ev.workspace_id) then perform private.fail('forbidden'); end if;
  if p_scope not in ('this', 'future') then perform private.fail('invalid_scope'); end if;
  if p_scope = 'future' and ev.series_id is null then perform private.fail('not_series'); end if;
  if p_notify and length(trim(coalesce(p_message, ''))) = 0 then perform private.fail('message_required'); end if;

  if p_scope = 'future' then
    update event_series set until = ev.occurrence_date - 1 where id = ev.series_id and (until is null or until >= ev.occurrence_date);
    update events set status = 'cancelled'
    where series_id = ev.series_id and occurrence_date >= ev.occurrence_date and status = 'scheduled' and ends_at > now();
  else
    update events set status = 'cancelled' where id = ev.id and status = 'scheduled';
  end if;
  get diagnostics n = row_count;

  if p_notify then
    insert into messages (conversation_id, workspace_id, sender_id, body, audience)
    values (private.broadcast_conversation(ev.workspace_id), ev.workspace_id, v_uid, trim(p_message),
            jsonb_build_object('scope', 'event', 'event_id', ev.id, 'filter', 'all', 'reason', 'cancelled'))
    returning id into v_msg;
    insert into message_recipients (message_id, user_id, workspace_id)
    select v_msg, u, ev.workspace_id from private.event_invitees(ev.id) u where u <> v_uid;
  end if;
  return n;
end $$;

-- ───────────────────────── personal iCal feed ─────────────────────────
alter table public.profiles
  add column calendar_token text unique default encode(extensions.gen_random_bytes(24), 'hex');

-- co-members may read profiles: hide the token column from the API
revoke select on public.profiles from authenticated, anon;
grant select (id, full_name, avatar_url, locale, notify_email, notify_push, created_at) on public.profiles to authenticated;

create or replace function public.my_calendar_token() returns text
language sql stable security definer set search_path = public as $$
  select calendar_token from profiles where id = auth.uid();
$$;

create or replace function public.reset_calendar_token() returns text
language plpgsql security definer set search_path = public as $$
declare v text := encode(extensions.gen_random_bytes(24), 'hex');
begin
  perform private.require_uid();
  update profiles set calendar_token = v where id = auth.uid();
  return v;
end $$;

-- Read by the `calendar` Edge Function (publishable key, no user session): the token is the credential.
-- Same visibility as RLS: active memberships; group events only for their groups (trainers see all).
create or replace function public.calendar_feed(p_token text)
returns table (id uuid, title text, description text, starts_at timestamptz, ends_at timestamptz, location text,
               location_url text, status public.event_status, updated_at timestamptz, workspace_name text,
               workspace_slug text)
language sql stable security definer set search_path = public as $$
  select e.id, e.title, e.description, e.starts_at, e.ends_at, e.location, e.location_url, e.status, e.updated_at,
         w.name, w.slug
  from profiles p
  join memberships m on m.user_id = p.id and m.status = 'active'
  join workspaces w on w.id = m.workspace_id
  join events e on e.workspace_id = m.workspace_id
  where length(p_token) >= 32 and p.calendar_token = p_token
    and e.starts_at between now() - interval '30 days' and now() + interval '180 days'
    and (cardinality(e.group_ids) = 0 or m.role in ('owner', 'trainer')
         or exists (select 1 from group_members gm where gm.user_id = p.id and gm.group_id = any (e.group_ids)))
  order by e.starts_at
  limit 2000;
$$;

-- lets the Edge Function tell an unknown token (404) from an empty calendar
create or replace function public.calendar_feed_exists(p_token text) returns boolean
language sql stable security definer set search_path = public as $$
  select length(p_token) >= 32 and exists (select 1 from profiles where calendar_token = p_token);
$$;

-- ───────────────────────── privileges ─────────────────────────
revoke execute on all functions in schema private from public, anon, authenticated;
do $$
declare f text;
begin
  foreach f in array array[
    'expand_series(uuid, date)', 'update_series(uuid, jsonb)', 'cancel_event(uuid, boolean, text, text)',
    'my_calendar_token()', 'reset_calendar_token()']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke execute on function public.calendar_feed(text), public.calendar_feed_exists(text) from public;
grant execute on function public.calendar_feed(text), public.calendar_feed_exists(text) to anon, authenticated;

-- ───────────────────────── cron ─────────────────────────
create extension if not exists pg_cron;
select cron.schedule('bw-extend-series', '17 2 * * *', $$select private.extend_all_series()$$);
