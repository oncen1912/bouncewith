-- M1: workspaces and members (SPEC §5.1)
-- RPCs for creating/joining workspaces and managing members, plus tightening of the init schema:
--   * group membership must stay inside its workspace and disappears when the membership is removed
--   * owners edit settings columns only (slug and join_code are not writable through the API)
--   * workspace timezone must be a real IANA zone
--   * logo storage bucket, writable by the workspace owner only
-- Errors use stable codes (errcode P0001, message = code) that the UI translates.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- ───────────────────────── helpers ─────────────────────────
create or replace function private.fail(code text) returns void
language plpgsql as $$ begin raise exception using errcode = 'P0001', message = code; end $$;

create or replace function public.try_uuid(value text) returns uuid
language plpgsql immutable as $$
begin
  return value::uuid;
exception when invalid_text_representation then
  return null;
end $$;

create or replace function private.is_valid_timezone(tz text) returns boolean
language sql stable as $$ select exists (select 1 from pg_timezone_names where name = tz) $$;

create or replace function private.require_uid() returns uuid
language plpgsql stable as $$
declare v uuid := auth.uid();
begin
  if v is null then perform private.fail('not_authenticated'); end if;
  return v;
end $$;

create or replace function private.active_owner_count(p_ws uuid) returns int
language sql stable as $$
  select count(*)::int from public.memberships
  where workspace_id = p_ws and role = 'owner' and status = 'active';
$$;

-- Target of a trainer action: must exist, must not be the caller, owners only by owners.
create or replace function private.member_target(p_ws uuid, p_user uuid) returns public.memberships
language plpgsql stable set search_path = public as $$
declare t memberships;
begin
  perform private.require_uid();
  if not is_trainer(p_ws) then perform private.fail('forbidden'); end if;
  if p_user = auth.uid() then perform private.fail('cannot_target_self'); end if;
  select * into t from memberships where workspace_id = p_ws and user_id = p_user;
  if not found then perform private.fail('not_found'); end if;
  if t.role = 'owner' and not is_owner(p_ws) then perform private.fail('forbidden'); end if;
  return t;
end $$;

create or replace function private.new_join_code() returns text
language plpgsql volatile as $$
declare v text;
begin
  loop
    -- 8 chars from an alphabet without look-alikes (0/O, 1/I/L)
    select string_agg(substr('ABCDEFGHJKMNPQRSTUVWXYZ23456789', 1 + (get_byte(b, i) % 31), 1), '')
      into v
      from (select extensions.gen_random_bytes(8) as b) r, generate_series(0, 7) as i;
    exit when not exists (select 1 from public.workspaces where join_code = v);
  end loop;
  return v;
end $$;

-- ───────────────────────── schema tightening ─────────────────────────
-- group_members must reference a group and a membership of the same workspace
alter table public.groups add constraint groups_name_length check (length(trim(name)) between 1 and 60);
alter table public.groups add constraint groups_id_workspace_key unique (id, workspace_id);
alter table public.group_members
  add constraint group_members_group_same_ws foreign key (group_id, workspace_id)
    references public.groups (id, workspace_id) on delete cascade,
  add constraint group_members_membership_fk foreign key (workspace_id, user_id)
    references public.memberships (workspace_id, user_id) on delete cascade;

-- a group used by upcoming events can't be deleted (those events would vanish for its members)
create or replace function private.guard_group_delete() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from events e
             where e.workspace_id = old.workspace_id and old.id = any (e.group_ids)
               and e.status = 'scheduled' and e.ends_at > now()) then
    perform private.fail('group_in_use');
  end if;
  return old;
end $$;
create trigger groups_guard_delete before delete on public.groups
  for each row execute function private.guard_group_delete();

-- timezone must exist
create or replace function private.check_workspace_timezone() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not private.is_valid_timezone(new.timezone) then perform private.fail('timezone_invalid'); end if;
  return new;
end $$;
create trigger workspaces_check_timezone before insert or update of timezone on public.workspaces
  for each row execute function private.check_workspace_timezone();

-- new codes use the look-alike-free alphabet too
alter table public.workspaces alter column join_code set default private.new_join_code();

-- owners update settings only; slug, join_code, created_by are changed through RPCs (or not at all)
revoke update on public.workspaces from authenticated, anon;
grant update (name, type, timezone, logo_url, accent_color, faq_text, require_approval, allow_self_absence, allowed_origins)
  on public.workspaces to authenticated;

-- profiles: users edit their own preferences, never id/created_at
revoke update on public.profiles from authenticated, anon;
grant update (full_name, avatar_url, locale, notify_email, notify_push) on public.profiles to authenticated;

-- ───────────────────────── workspaces ─────────────────────────
create or replace function public.create_workspace(
  p_name text, p_slug text, p_type public.workspace_type default 'other', p_timezone text default 'Europe/Zurich'
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid  uuid := private.require_uid();
  v_slug text := lower(trim(p_slug));
  v_id   uuid;
begin
  if length(trim(coalesce(p_name, ''))) not between 2 and 80 then perform private.fail('name_invalid'); end if;
  if v_slug is null or v_slug !~ '^[a-z0-9][a-z0-9-]{2,39}$' then perform private.fail('slug_invalid'); end if;
  if v_slug = any (array['new', 'join', 'admin', 'api', 'app', 'auth', 'login', 'me', 'settings', 'www', 'widget', 'help', 'support'])
    then perform private.fail('slug_reserved'); end if;
  if not private.is_valid_timezone(p_timezone) then perform private.fail('timezone_invalid'); end if;
  if (select count(*) from workspaces where created_by = v_uid) >= 20 then perform private.fail('workspace_limit'); end if;
  if exists (select 1 from workspaces where slug = v_slug) then perform private.fail('slug_taken'); end if;

  insert into workspaces (name, slug, type, timezone, created_by)
  values (trim(p_name), v_slug, p_type, p_timezone, v_uid)
  returning id into v_id;
  insert into memberships (workspace_id, user_id, role, status) values (v_id, v_uid, 'owner', 'active');
  return v_id;
exception when unique_violation then
  perform private.fail('slug_taken');
end $$;

create or replace function public.regenerate_join_code(p_ws uuid) returns text
language plpgsql security definer set search_path = public as $$
declare v text;
begin
  perform private.require_uid();
  if not is_owner(p_ws) then perform private.fail('forbidden'); end if;
  v := private.new_join_code();
  update workspaces set join_code = v where id = p_ws;
  return v;
end $$;

-- What the join page shows before joining. Nothing for an unknown code.
create or replace function public.workspace_preview(p_code text)
returns table (slug text, name text, type public.workspace_type, logo_url text, accent_color text,
               require_approval boolean, my_status public.membership_status)
language sql stable security definer set search_path = public as $$
  select w.slug, w.name, w.type, w.logo_url, w.accent_color, w.require_approval, m.status
  from workspaces w
  left join memberships m on m.workspace_id = w.id and m.user_id = auth.uid()
  where auth.uid() is not null and w.join_code = upper(trim(p_code));
$$;

-- All my memberships, including pending ones (the workspaces table only shows active memberships).
create or replace function public.my_memberships()
returns table (workspace_id uuid, slug text, name text, type public.workspace_type, timezone text,
               accent_color text, logo_url text, role public.member_role, status public.membership_status,
               is_last_owner boolean)
language sql stable security definer set search_path = public as $$
  select w.id, w.slug, w.name, w.type, w.timezone, w.accent_color, w.logo_url, m.role, m.status,
         m.role = 'owner' and m.status = 'active' and private.active_owner_count(w.id) = 1
  from memberships m join workspaces w on w.id = m.workspace_id
  where m.user_id = auth.uid() and m.status <> 'blocked'
  order by w.name;
$$;

-- ───────────────────────── membership ─────────────────────────
create or replace function public.join_workspace(p_code text) returns public.membership_status
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := private.require_uid();
  v_ws     workspaces;
  v_status membership_status;
begin
  select * into v_ws from workspaces where join_code = upper(trim(p_code));
  if not found then perform private.fail('invalid_code'); end if;

  select status into v_status from memberships where workspace_id = v_ws.id and user_id = v_uid;
  if found then
    if v_status = 'blocked' then perform private.fail('blocked'); end if;
    return v_status;   -- idempotent
  end if;

  v_status := case when v_ws.require_approval then 'pending' else 'active' end;
  insert into memberships (workspace_id, user_id, role, status) values (v_ws.id, v_uid, 'member', v_status);
  return v_status;
end $$;

create or replace function public.approve_member(p_ws uuid, p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform private.member_target(p_ws, p_user);
  update memberships set status = 'active' where workspace_id = p_ws and user_id = p_user and status <> 'active';
end $$;

create or replace function public.block_member(p_ws uuid, p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
declare t memberships := private.member_target(p_ws, p_user);
begin
  if t.role = 'owner' and t.status = 'active' and private.active_owner_count(p_ws) = 1 then
    perform private.fail('last_owner');
  end if;
  update memberships set status = 'blocked' where workspace_id = p_ws and user_id = p_user;
  delete from group_members where workspace_id = p_ws and user_id = p_user;
end $$;

create or replace function public.remove_member(p_ws uuid, p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
declare t memberships := private.member_target(p_ws, p_user);
begin
  if t.role = 'owner' and t.status = 'active' and private.active_owner_count(p_ws) = 1 then
    perform private.fail('last_owner');
  end if;
  delete from memberships where workspace_id = p_ws and user_id = p_user;  -- group_members cascade
end $$;

create or replace function public.set_member_role(p_ws uuid, p_user uuid, p_role public.member_role) returns void
language plpgsql security definer set search_path = public as $$
declare t memberships;
begin
  perform private.require_uid();
  if not is_owner(p_ws) then perform private.fail('forbidden'); end if;
  select * into t from memberships where workspace_id = p_ws and user_id = p_user;
  if not found then perform private.fail('not_found'); end if;
  if t.status <> 'active' then perform private.fail('not_active'); end if;
  if t.role = 'owner' and p_role <> 'owner' and private.active_owner_count(p_ws) = 1 then
    perform private.fail('last_owner');
  end if;
  update memberships set role = p_role where workspace_id = p_ws and user_id = p_user;
end $$;

create or replace function public.leave_workspace(p_ws uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := private.require_uid();
  t memberships;
begin
  select * into t from memberships where workspace_id = p_ws and user_id = v_uid;
  if not found then perform private.fail('not_found'); end if;
  if t.status = 'blocked' then perform private.fail('blocked'); end if;
  if t.role = 'owner' and t.status = 'active' and private.active_owner_count(p_ws) = 1 then
    perform private.fail('last_owner');
  end if;
  delete from memberships where workspace_id = p_ws and user_id = v_uid;
end $$;

-- Trainer view of the member list, with e-mail (needed to recognise who asked to join).
create or replace function public.workspace_members(p_ws uuid)
returns table (user_id uuid, full_name text, avatar_url text, email text, role public.member_role,
               status public.membership_status, joined_at timestamptz, group_ids uuid[])
language plpgsql stable security definer set search_path = public as $$
begin
  perform private.require_uid();
  if not is_trainer(p_ws) then perform private.fail('forbidden'); end if;
  return query
    select m.user_id, p.full_name, p.avatar_url, u.email::text, m.role, m.status, m.joined_at,
           coalesce(array_agg(gm.group_id) filter (where gm.group_id is not null), '{}')
    from memberships m
    join profiles p on p.id = m.user_id
    join auth.users u on u.id = m.user_id
    left join group_members gm on gm.workspace_id = m.workspace_id and gm.user_id = m.user_id
    where m.workspace_id = p_ws
    group by m.user_id, p.full_name, p.avatar_url, u.email, m.role, m.status, m.joined_at
    order by m.status, lower(p.full_name);
end $$;

-- ───────────────────────── account ─────────────────────────
-- Deletes the caller's account. Profile and memberships cascade; attendance_log.changed_by,
-- messages.sender_id and ai_logs.user_id are set null (SPEC §11).
create or replace function public.delete_my_account(p_confirm_email text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := private.require_uid();
  v_email text;
begin
  select email into v_email from auth.users where id = v_uid;
  if lower(trim(coalesce(p_confirm_email, ''))) <> lower(v_email) then perform private.fail('confirm_mismatch'); end if;
  if exists (select 1 from memberships m
             where m.user_id = v_uid and m.role = 'owner' and m.status = 'active'
               and private.active_owner_count(m.workspace_id) = 1) then
    perform private.fail('last_owner');
  end if;
  delete from auth.users where id = v_uid;
end $$;

-- ───────────────────────── function privileges ─────────────────────────
revoke execute on all functions in schema private from public, anon, authenticated;
do $$
declare f text;
begin
  foreach f in array array[
    'create_workspace(text, text, public.workspace_type, text)', 'regenerate_join_code(uuid)',
    'workspace_preview(text)', 'my_memberships()', 'join_workspace(text)', 'approve_member(uuid, uuid)',
    'block_member(uuid, uuid)', 'remove_member(uuid, uuid)', 'set_member_role(uuid, uuid, public.member_role)',
    'leave_workspace(uuid)', 'workspace_members(uuid)', 'delete_my_account(text)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

-- ───────────────────────── storage: workspace logos ─────────────────────────
-- Path: {workspace_id}/logo-{timestamp}.{ext}. Public read (logos appear in the widget); owner-only write.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('workspace-logos', 'workspace-logos', true, 1048576, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do nothing;

create policy logos_owner_select on storage.objects for select to authenticated
  using (bucket_id = 'workspace-logos' and public.is_owner(public.try_uuid((storage.foldername(name))[1])));
create policy logos_owner_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'workspace-logos' and public.is_owner(public.try_uuid((storage.foldername(name))[1])));
create policy logos_owner_update on storage.objects for update to authenticated
  using (bucket_id = 'workspace-logos' and public.is_owner(public.try_uuid((storage.foldername(name))[1])))
  with check (bucket_id = 'workspace-logos' and public.is_owner(public.try_uuid((storage.foldername(name))[1])));
create policy logos_owner_delete on storage.objects for delete to authenticated
  using (bucket_id = 'workspace-logos' and public.is_owner(public.try_uuid((storage.foldername(name))[1])));
