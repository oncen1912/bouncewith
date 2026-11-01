-- BounceWith — initial schema (draft migration)
-- Target: Supabase Postgres (auth.users, auth.uid() and the realtime schema are provided by Supabase).
-- Copy to supabase/migrations/<timestamp>_init.sql in the new repo.
-- Conventions:
--   * every table except profiles carries workspace_id
--   * RLS is enabled on every table; writes that enforce business rules go through RPC functions (see SPEC.md §5)
--   * timestamps are timestamptz; display uses workspaces.timezone

create extension if not exists pgcrypto;

-- ───────────────────────── enums ─────────────────────────
create type public.workspace_type    as enum ('dance', 'fitness', 'yoga', 'other');
create type public.member_role       as enum ('owner', 'trainer', 'member');
create type public.membership_status as enum ('pending', 'active', 'blocked');
create type public.event_status      as enum ('scheduled', 'cancelled');
create type public.event_visibility  as enum ('members', 'public');
create type public.event_source      as enum ('app', 'api', 'import');
create type public.rsvp_answer       as enum ('going', 'not_going');
create type public.attendance_method as enum ('trainer', 'qr', 'default');
create type public.conversation_kind as enum ('broadcast', 'event', 'group', 'direct');

-- ───────────────────────── core ─────────────────────────
create table public.workspaces (
  id                 uuid primary key default gen_random_uuid(),
  slug               text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{2,39}$'),
  name               text not null check (length(name) between 2 and 80),
  type               public.workspace_type not null default 'other',
  timezone           text not null default 'Europe/Zurich',
  logo_url           text,
  accent_color       text check (accent_color ~ '^#[0-9A-Fa-f]{6}$'),
  faq_text           text not null default '',
  join_code          text not null unique default upper(substr(md5(gen_random_uuid()::text), 1, 8)),
  require_approval   boolean not null default true,
  allow_self_absence boolean not null default true,
  allowed_origins    text[] not null default '{}',   -- widget embedding, e.g. {'https://bouncewith.me'}
  created_by         uuid references auth.users (id) on delete set null,
  created_at         timestamptz not null default now()
);

create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  full_name    text not null default '',
  avatar_url   text,
  locale       text not null default 'en' check (locale in ('en', 'sl', 'de', 'fr')),
  notify_email boolean not null default true,
  notify_push  boolean not null default true,
  created_at   timestamptz not null default now()
);

create table public.memberships (
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  role         public.member_role not null default 'member',
  status       public.membership_status not null default 'pending',
  joined_at    timestamptz not null default now(),
  primary key (workspace_id, user_id)
);
create index on public.memberships (user_id);

create table public.groups (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  name         text not null,
  created_at   timestamptz not null default now(),
  unique (workspace_id, name)
);

create table public.group_members (
  group_id     uuid not null references public.groups (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  primary key (group_id, user_id)
);
create index on public.group_members (user_id);

-- ───────────────────────── events ─────────────────────────
-- MVP recurrence: weekly only (weekdays + interval). Occurrences are materialised into events.
create table public.event_series (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  title        text not null,
  description  text not null default '',
  weekdays     smallint[] not null check (weekdays <@ array[1,2,3,4,5,6,7]::smallint[] and cardinality(weekdays) > 0), -- ISO: 1 = Monday
  interval_weeks smallint not null default 1 check (interval_weeks between 1 and 4),
  start_time   time not null,
  duration_min integer not null check (duration_min between 5 and 1440),
  starts_on    date not null,
  until        date,
  location     text,
  category     text,
  capacity     integer check (capacity > 0),
  visibility   public.event_visibility not null default 'members',
  group_ids    uuid[] not null default '{}',
  created_by   uuid references public.profiles (id) on delete set null,
  created_at   timestamptz not null default now()
);

create table public.events (
  id            uuid primary key default gen_random_uuid(),
  workspace_id  uuid not null references public.workspaces (id) on delete cascade,
  series_id     uuid references public.event_series (id) on delete set null,
  title         text not null check (length(title) between 1 and 140),
  description   text not null default '',           -- sanitised HTML
  starts_at     timestamptz not null,
  ends_at       timestamptz not null,
  location      text,
  location_url  text,
  category      text,
  image_url     text,
  capacity      integer check (capacity > 0),
  rsvp_deadline timestamptz,                        -- null = starts_at
  status        public.event_status not null default 'scheduled',
  visibility    public.event_visibility not null default 'members',
  group_ids     uuid[] not null default '{}',       -- empty = whole workspace
  source        public.event_source not null default 'app',
  external_id   text,
  external_url  text,
  created_by    uuid references public.profiles (id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  check (ends_at > starts_at),
  unique (workspace_id, external_id)
);
create index on public.events (workspace_id, starts_at);
create index on public.events (series_id);

-- ───────────────────────── attendance ─────────────────────────
create table public.rsvps (
  event_id     uuid not null references public.events (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  answer       public.rsvp_answer not null,
  reason       text,
  answered_at  timestamptz not null default now(),
  primary key (event_id, user_id)
);
create index on public.rsvps (user_id);

create table public.attendance (
  event_id     uuid not null references public.events (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  present      boolean not null,
  method       public.attendance_method not null default 'trainer',
  marked_by    uuid references public.profiles (id) on delete set null,
  marked_at    timestamptz not null default now(),
  primary key (event_id, user_id)
);

create table public.attendance_log (
  id           bigint generated always as identity primary key,
  event_id     uuid not null references public.events (id) on delete cascade,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  old_present  boolean,
  new_present  boolean,                              -- null = row removed by reset
  changed_by   uuid references public.profiles (id) on delete set null,
  changed_at   timestamptz not null default now(),
  note         text
);
create index on public.attendance_log (event_id);

create table public.checkin_tokens (
  id           uuid primary key default gen_random_uuid(),
  event_id     uuid not null references public.events (id) on delete cascade,
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  token_hash   text not null unique,
  expires_at   timestamptz not null,
  created_by   uuid references public.profiles (id) on delete set null
);

-- ───────────────────────── messaging ─────────────────────────
create table public.conversations (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  kind         public.conversation_kind not null,
  event_id     uuid references public.events (id) on delete cascade,
  group_id     uuid references public.groups (id) on delete cascade,
  member_id    uuid references public.profiles (id) on delete cascade,  -- direct: the member side
  created_at   timestamptz not null default now(),
  check ((kind = 'event')  = (event_id  is not null)),
  check ((kind = 'group')  = (group_id  is not null)),
  check ((kind = 'direct') = (member_id is not null))
);
create unique index conversations_one_broadcast on public.conversations (workspace_id) where kind = 'broadcast';
create unique index conversations_one_direct    on public.conversations (workspace_id, member_id) where kind = 'direct';
create unique index conversations_one_event     on public.conversations (event_id) where kind = 'event';
create unique index conversations_one_group     on public.conversations (group_id) where kind = 'group';

create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  workspace_id    uuid not null references public.workspaces (id) on delete cascade,
  sender_id       uuid references public.profiles (id) on delete set null,  -- null = system / AI hand-off
  body            text not null check (length(body) between 1 and 4000),
  audience        jsonb,          -- broadcasts only, e.g. {"event_id": "...", "filter": "not_confirmed"} or {"group_id": "..."}
  reply_to        uuid references public.messages (id) on delete set null,
  created_at      timestamptz not null default now(),
  deleted_at      timestamptz
);
create index on public.messages (conversation_id, created_at);

-- broadcast recipients + read receipts + delivery status
create table public.message_recipients (
  message_id     uuid not null references public.messages (id) on delete cascade,
  user_id        uuid not null references public.profiles (id) on delete cascade,
  workspace_id   uuid not null references public.workspaces (id) on delete cascade,
  read_at        timestamptz,
  pushed_at      timestamptz,
  emailed_at     timestamptz,
  primary key (message_id, user_id)
);
create index on public.message_recipients (user_id, read_at);

create table public.push_subscriptions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  endpoint   text not null unique,
  p256dh     text not null,
  auth       text not null,
  user_agent text,
  created_at timestamptz not null default now()
);

-- ───────────────────────── AI + integration ─────────────────────────
create table public.ai_logs (
  id           bigint generated always as identity primary key,
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  user_id      uuid references public.profiles (id) on delete set null,
  question     text not null,
  answer       text,
  handed_off   boolean not null default false,
  created_at   timestamptz not null default now()
);

create table public.api_keys (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  name         text not null,
  prefix       text not null,                 -- first 8 chars shown in UI, e.g. 'bw_live_ab12cd34'
  key_hash     text not null unique,          -- sha256 of the full key; the key itself is shown once
  scopes       text[] not null check (scopes <@ array['events:read','events:write','attendance:read']),
  created_by   uuid references public.profiles (id) on delete set null,
  created_at   timestamptz not null default now(),
  last_used_at timestamptz,
  revoked_at   timestamptz
);

create table public.webhooks (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  url          text not null check (url ~ '^https://'),
  secret       text not null default encode(gen_random_bytes(32), 'hex'),
  event_types  text[] not null,
  active       boolean not null default true,
  created_at   timestamptz not null default now()
);

create table public.webhook_deliveries (
  id              bigint generated always as identity primary key,
  webhook_id      uuid not null references public.webhooks (id) on delete cascade,
  workspace_id    uuid not null references public.workspaces (id) on delete cascade,
  event_type      text not null,
  payload         jsonb not null,
  status          text not null default 'pending' check (status in ('pending', 'delivered', 'failed')),
  attempts        integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  last_error      text,
  created_at      timestamptz not null default now()
);
create index on public.webhook_deliveries (status, next_attempt_at);

-- widget sign-ups waiting for e-mail confirmation (service role only)
create table public.pending_signups (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  event_id     uuid references public.events (id) on delete cascade,
  email        text not null check (email = lower(email)),
  full_name    text not null,
  token_hash   text not null unique,
  origin       text,
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null default now() + interval '48 hours',
  confirmed_at timestamptz
);

-- ───────────────────────── helper functions ─────────────────────────
-- security definer so policies can call them without recursing into memberships' own RLS
create or replace function public.is_member(ws uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from memberships m
                 where m.workspace_id = ws and m.user_id = auth.uid() and m.status = 'active');
$$;

create or replace function public.is_trainer(ws uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from memberships m
                 where m.workspace_id = ws and m.user_id = auth.uid() and m.status = 'active'
                   and m.role in ('owner', 'trainer'));
$$;

create or replace function public.is_owner(ws uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from memberships m
                 where m.workspace_id = ws and m.user_id = auth.uid() and m.status = 'active'
                   and m.role = 'owner');
$$;

create or replace function public.in_any_group(groups uuid[]) returns boolean
language sql stable security definer set search_path = public as $$
  select cardinality(groups) = 0
      or exists (select 1 from group_members gm where gm.user_id = auth.uid() and gm.group_id = any (groups));
$$;

-- can the current user see this event?
create or replace function public.can_see_event(ev uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from events e
                 where e.id = ev
                   and (is_trainer(e.workspace_id)
                        or (is_member(e.workspace_id) and in_any_group(e.group_ids))));
$$;

create or replace function public.can_see_conversation(conv uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from conversations c
    where c.id = conv
      and (is_trainer(c.workspace_id)
           or (is_member(c.workspace_id) and (
                  (c.kind = 'direct' and c.member_id = auth.uid())
               or (c.kind = 'group'  and exists (select 1 from group_members gm
                                                 where gm.group_id = c.group_id and gm.user_id = auth.uid()))
               or (c.kind = 'event'  and can_see_event(c.event_id))
               or  c.kind = 'broadcast'))));
$$;

-- keep events.updated_at fresh
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$ begin new.updated_at := now(); return new; end; $$;
create trigger events_touch before update on public.events
  for each row execute function public.touch_updated_at();

-- create a profile row for every new auth user
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ───────────────────────── row level security ─────────────────────────
alter table public.workspaces         enable row level security;
alter table public.profiles           enable row level security;
alter table public.memberships        enable row level security;
alter table public.groups             enable row level security;
alter table public.group_members      enable row level security;
alter table public.event_series       enable row level security;
alter table public.events             enable row level security;
alter table public.rsvps              enable row level security;
alter table public.attendance         enable row level security;
alter table public.attendance_log     enable row level security;
alter table public.checkin_tokens     enable row level security;
alter table public.conversations      enable row level security;
alter table public.messages           enable row level security;
alter table public.message_recipients enable row level security;
alter table public.push_subscriptions enable row level security;
alter table public.ai_logs            enable row level security;
alter table public.api_keys           enable row level security;
alter table public.webhooks           enable row level security;
alter table public.webhook_deliveries enable row level security;
alter table public.pending_signups    enable row level security;  -- no policies: service role only

-- workspaces: members read; owner updates; creation via create_workspace() RPC
create policy ws_select on public.workspaces for select to authenticated using (is_member(id));
create policy ws_update on public.workspaces for update to authenticated using (is_owner(id)) with check (is_owner(id));

-- profiles: self, or anyone sharing an active workspace
create policy profiles_select on public.profiles for select to authenticated using (
  id = auth.uid()
  or exists (select 1 from memberships mine join memberships theirs using (workspace_id)
             where mine.user_id = auth.uid() and mine.status = 'active' and theirs.user_id = profiles.id));
create policy profiles_update on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- memberships: read own + co-members; all writes via RPC (join_workspace, approve_member, set_member_role, remove_member)
create policy memberships_select on public.memberships for select to authenticated
  using (user_id = auth.uid() or is_member(workspace_id));

-- groups
create policy groups_select on public.groups for select to authenticated using (is_member(workspace_id));
create policy groups_write  on public.groups for all    to authenticated
  using (is_trainer(workspace_id)) with check (is_trainer(workspace_id));
create policy group_members_select on public.group_members for select to authenticated using (is_member(workspace_id));
create policy group_members_write  on public.group_members for all    to authenticated
  using (is_trainer(workspace_id)) with check (is_trainer(workspace_id));

-- events & series: trainers write; members read what is addressed to them; no deletes (cancel instead)
create policy series_select on public.event_series for select to authenticated using (is_member(workspace_id));
create policy series_write  on public.event_series for all    to authenticated
  using (is_trainer(workspace_id)) with check (is_trainer(workspace_id));
create policy events_select on public.events for select to authenticated using (
  is_trainer(workspace_id) or (is_member(workspace_id) and in_any_group(group_ids)));
create policy events_insert on public.events for insert to authenticated with check (is_trainer(workspace_id));
create policy events_update on public.events for update to authenticated
  using (is_trainer(workspace_id)) with check (is_trainer(workspace_id));

-- rsvps / attendance: read own or as trainer; writes via rsvp(), mark_attendance(), qr_checkin(), reset_attendance()
create policy rsvps_select on public.rsvps for select to authenticated
  using (user_id = auth.uid() or is_trainer(workspace_id));
create policy attendance_select on public.attendance for select to authenticated
  using (user_id = auth.uid() or is_trainer(workspace_id));
create policy attendance_log_select on public.attendance_log for select to authenticated
  using (is_trainer(workspace_id));
create policy checkin_tokens_select on public.checkin_tokens for select to authenticated
  using (is_trainer(workspace_id));

-- messaging
create policy conversations_select on public.conversations for select to authenticated
  using (can_see_conversation(id));
create policy messages_select on public.messages for select to authenticated using (
  is_trainer(workspace_id)
  or (can_see_conversation(conversation_id)
      and (audience is null
           or exists (select 1 from message_recipients r where r.message_id = messages.id and r.user_id = auth.uid()))));
-- posting in direct/group/event conversations; broadcasts only via send_broadcast()
create policy messages_insert on public.messages for insert to authenticated with check (
  sender_id = auth.uid()
  and audience is null
  and can_see_conversation(conversation_id)
  and exists (select 1 from conversations c where c.id = conversation_id
              and c.workspace_id = messages.workspace_id and c.kind <> 'broadcast'));
create policy messages_soft_delete on public.messages for update to authenticated
  using (sender_id = auth.uid() or is_owner(workspace_id))
  with check (sender_id = auth.uid() or is_owner(workspace_id));
create policy recipients_select on public.message_recipients for select to authenticated
  using (user_id = auth.uid() or is_trainer(workspace_id));

-- push subscriptions: own only
create policy push_own on public.push_subscriptions for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- AI logs and integration settings: trainers / owners read; writes via Edge Functions (service role)
create policy ai_logs_select   on public.ai_logs            for select to authenticated using (is_trainer(workspace_id));
create policy api_keys_select  on public.api_keys           for select to authenticated using (is_owner(workspace_id));
create policy webhooks_select  on public.webhooks           for select to authenticated using (is_owner(workspace_id));
create policy deliveries_select on public.webhook_deliveries for select to authenticated using (is_owner(workspace_id));

-- column-level protection: owners may list keys and webhooks, but never read secrets or key hashes through the API.
-- (A column-level revoke is not enough while a table-level grant exists, so replace the table grant with a column list.)
revoke select on public.webhooks from authenticated, anon;
grant  select (id, workspace_id, url, event_types, active, created_at) on public.webhooks to authenticated;
revoke select on public.api_keys from authenticated, anon;
grant  select (id, workspace_id, name, prefix, scopes, created_by, created_at, last_used_at, revoked_at)
  on public.api_keys to authenticated;
-- pending_signups is service-role only
revoke all on public.pending_signups from authenticated, anon;
