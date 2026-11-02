-- Local demo data. Applied by `npx supabase db reset`. Never run against production.
-- Every seeded user signs in with password "bouncewith" (e.g. owner@niko-dance.example).
--
-- niko-dance: 1 owner, 1 trainer, 6 members (3 in Juniors), 4 upcoming events
-- yoga-zug:   1 owner, 1 member, 1 event (second workspace for cross-tenant checks)

-- ───────────────────────── users ─────────────────────────
with u (id, email, full_name) as (values
  ('11111111-0000-0000-0000-000000000001'::uuid, 'owner@niko-dance.example',   'Niko Owner'),
  ('11111111-0000-0000-0000-000000000002'::uuid, 'trainer@niko-dance.example', 'Tara Trainer'),
  ('11111111-0000-0000-0000-000000000011'::uuid, 'ana@niko-dance.example',     'Ana Kovač'),
  ('11111111-0000-0000-0000-000000000012'::uuid, 'luka@niko-dance.example',    'Luka Novak'),
  ('11111111-0000-0000-0000-000000000013'::uuid, 'mia@niko-dance.example',     'Mia Horvat'),
  ('11111111-0000-0000-0000-000000000014'::uuid, 'jan@niko-dance.example',     'Jan Meier'),
  ('11111111-0000-0000-0000-000000000015'::uuid, 'lea@niko-dance.example',     'Lea Müller'),
  ('11111111-0000-0000-0000-000000000016'::uuid, 'tim@niko-dance.example',     'Tim Keller'),
  ('22222222-0000-0000-0000-000000000001'::uuid, 'owner@yoga-zug.example',     'Yara Yoga'),
  ('22222222-0000-0000-0000-000000000011'::uuid, 'member@yoga-zug.example',    'Max Zug')
), ins as (
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                          confirmation_token, recovery_token, email_change, email_change_token_new)
  select '00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated', email,
         extensions.crypt('bouncewith', extensions.gen_salt('bf')), now(),
         '{"provider":"email","providers":["email"]}', jsonb_build_object('full_name', full_name), now(), now(),
         '', '', '', ''
  from u
  returning id, email
)
insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), id, id::text, 'email',
       jsonb_build_object('sub', id::text, 'email', email, 'email_verified', true), now(), now(), now()
from ins;

-- profiles are created by the on_auth_user_created trigger; give a couple of users other languages
update public.profiles set locale = 'sl' where id in ('11111111-0000-0000-0000-000000000011', '11111111-0000-0000-0000-000000000012');
update public.profiles set locale = 'de' where id in ('11111111-0000-0000-0000-000000000014', '22222222-0000-0000-0000-000000000001');

-- ───────────────────────── workspaces ─────────────────────────
insert into public.workspaces (id, slug, name, type, accent_color, join_code, require_approval, allowed_origins, created_by, faq_text) values
  ('a0000000-0000-0000-0000-000000000001', 'niko-dance', 'Niko Dance School', 'dance', '#1BBDBF', 'NIKO2026', true,
   '{https://bouncewith.me}', '11111111-0000-0000-0000-000000000001',
   'Classes take place at Studio Bounce, Baarerstrasse 10, Zug. Bring indoor shoes and water.'),
  ('b0000000-0000-0000-0000-000000000001', 'yoga-zug', 'Yoga Zug', 'yoga', '#F8B830', 'YOGAZUG1', false,
   '{}', '22222222-0000-0000-0000-000000000001', '');

insert into public.memberships (workspace_id, user_id, role, status) values
  ('a0000000-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000001', 'owner',   'active'),
  ('a0000000-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000002', 'trainer', 'active'),
  ('a0000000-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000011', 'member',  'active'),
  ('a0000000-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000012', 'member',  'active'),
  ('a0000000-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000013', 'member',  'active'),
  ('a0000000-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000014', 'member',  'active'),
  ('a0000000-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000015', 'member',  'active'),
  ('a0000000-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000016', 'member',  'pending'),
  ('b0000000-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', 'owner',   'active'),
  ('b0000000-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000011', 'member',  'active');

insert into public.groups (id, workspace_id, name) values
  ('a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Juniors');
insert into public.group_members (group_id, user_id, workspace_id) values
  ('a1000000-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000011', 'a0000000-0000-0000-0000-000000000001'),
  ('a1000000-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000012', 'a0000000-0000-0000-0000-000000000001'),
  ('a1000000-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000013', 'a0000000-0000-0000-0000-000000000001');

-- ───────────────────────── events ─────────────────────────
-- Local times in the workspace timezone, converted to timestamptz (CLAUDE.md rule 7).
insert into public.events (id, workspace_id, title, description, starts_at, ends_at, location, category, capacity, visibility, group_ids, created_by)
select id, ws, title, description,
       ((current_date + day_offset) + start_local) at time zone 'Europe/Zurich',
       ((current_date + day_offset) + start_local + duration) at time zone 'Europe/Zurich',
       location, category, capacity, visibility::public.event_visibility, group_ids::uuid[], created_by
from (values
  ('a2000000-0000-0000-0000-000000000001'::uuid, 'a0000000-0000-0000-0000-000000000001'::uuid,
   'Hip Hop Basics', '<p>Grooves, bounce and the first combo.</p>', 1, time '18:30', interval '90 min',
   'Studio Bounce', 'class', null::int, 'members', '{}', '11111111-0000-0000-0000-000000000002'::uuid),
  ('a2000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001',
   'Juniors Freestyle', '<p>Freestyle practice for the Juniors group.</p>', 2, time '17:00', interval '60 min',
   'Studio Bounce', 'class', null, 'members', '{a1000000-0000-0000-0000-000000000001}', '11111111-0000-0000-0000-000000000002'),
  ('a2000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001',
   'Open Workshop: Popping', '<p>Guest teacher, open to everyone.</p>', 5, time '14:00', interval '120 min',
   'Studio Bounce', 'workshop', 20, 'public', '{}', '11111111-0000-0000-0000-000000000001'),
  ('a2000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001',
   'Crew Battle Night', '<p>Friendly battles, all levels.</p>', 9, time '19:00', interval '180 min',
   'Galvanik Zug', 'battle', 60, 'public', '{}', '11111111-0000-0000-0000-000000000001'),
  ('b2000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001',
   'Morning Flow', '<p>Gentle vinyasa.</p>', 1, time '07:00', interval '60 min',
   'Seeufer', 'class', 12, 'members', '{}', '22222222-0000-0000-0000-000000000001')
) as e (id, ws, title, description, day_offset, start_local, duration, location, category, capacity, visibility, group_ids, created_by);
