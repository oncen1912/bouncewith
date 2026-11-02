-- RLS tests for the init schema (ported from the manual smoke test, plus cross-workspace denial for every table).
-- Users: oA = owner A, tA = trainer A, m1 = member A in Juniors, m2 = member A without group, oB = owner B.
begin;
create extension if not exists pgtap with schema extensions;
select plan(66);

-- ───────────────────────── fixtures (as postgres) ─────────────────────────
insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0000-00000000000a', 'oa@test.local', '{"full_name":"Owner A"}'),
 ('00000000-0000-0000-0000-00000000000b', 'ta@test.local', '{"full_name":"Trainer A"}'),
 ('00000000-0000-0000-0000-00000000000c', 'm1@test.local', '{"full_name":"Member 1"}'),
 ('00000000-0000-0000-0000-00000000000d', 'm2@test.local', '{"full_name":"Member 2"}'),
 ('00000000-0000-0000-0000-00000000000e', 'ob@test.local', '{"full_name":"Owner B"}');

insert into workspaces (id, slug, name, type) values
 ('aaaaaaaa-0000-0000-0000-000000000001', 'test-a', 'Workspace A', 'dance'),
 ('bbbbbbbb-0000-0000-0000-000000000001', 'test-b', 'Workspace B', 'yoga');
insert into memberships (workspace_id, user_id, role, status) values
 ('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','owner','active'),
 ('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000b','trainer','active'),
 ('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000c','member','active'),
 ('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000d','member','active'),
 ('bbbbbbbb-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000e','owner','active');
insert into groups (id, workspace_id, name) values
 ('99999999-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','Juniors');
insert into group_members (group_id, user_id, workspace_id) values
 ('99999999-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000c','aaaaaaaa-0000-0000-0000-000000000001');
insert into event_series (workspace_id, title, weekdays, start_time, duration_min, starts_on) values
 ('aaaaaaaa-0000-0000-0000-000000000001', 'Weekly hip hop', '{2}', '18:30', 90, current_date);
insert into events (id, workspace_id, title, starts_at, ends_at, group_ids) values
 ('eeeeeeee-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','All crew', now()+interval '1 day', now()+interval '1 day 1 hour', '{}'),
 ('eeeeeeee-0000-0000-0000-000000000002','aaaaaaaa-0000-0000-0000-000000000001','Juniors only', now()+interval '2 day', now()+interval '2 day 1 hour', '{99999999-0000-0000-0000-000000000001}'),
 ('eeeeeeee-0000-0000-0000-000000000003','bbbbbbbb-0000-0000-0000-000000000001','Yoga flow', now()+interval '1 day', now()+interval '1 day 1 hour', '{}');
insert into rsvps (event_id, user_id, workspace_id, answer) values
 ('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000c','aaaaaaaa-0000-0000-0000-000000000001','going');
insert into attendance (event_id, user_id, workspace_id, present) values
 ('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000c','aaaaaaaa-0000-0000-0000-000000000001', true);
insert into attendance_log (event_id, user_id, workspace_id, old_present, new_present) values
 ('eeeeeeee-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000c','aaaaaaaa-0000-0000-0000-000000000001', null, true);
insert into checkin_tokens (event_id, workspace_id, token_hash, expires_at) values
 ('eeeeeeee-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','hash-1', now()+interval '30 min');
insert into conversations (id, workspace_id, kind, member_id) values
 ('cccccccc-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','direct','00000000-0000-0000-0000-00000000000c');
insert into messages (id, conversation_id, workspace_id, sender_id, body) values
 ('dddddddd-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000c','Can I come late?');
insert into message_recipients (message_id, user_id, workspace_id) values
 ('dddddddd-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000b','aaaaaaaa-0000-0000-0000-000000000001');
insert into ai_logs (workspace_id, user_id, question) values
 ('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000c','When is class?');
insert into api_keys (workspace_id, name, prefix, key_hash, scopes) values
 ('aaaaaaaa-0000-0000-0000-000000000001','Website','bw_live_ab12cd34','key-hash-1','{events:write}');
insert into webhooks (id, workspace_id, url, event_types) values
 ('77777777-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','https://bouncewith.me/hook','{event.created}');
insert into webhook_deliveries (webhook_id, workspace_id, event_type, payload) values
 ('77777777-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','event.created','{}');
insert into pending_signups (workspace_id, email, full_name, token_hash) values
 ('aaaaaaaa-0000-0000-0000-000000000001','visitor@test.local','Visitor','signup-hash-1');
insert into push_subscriptions (user_id, endpoint, p256dh, auth) values
 ('00000000-0000-0000-0000-00000000000c','https://push.test/1','p','a');

select is((select count(*)::int from profiles where id::text like '00000000-0000-0000-0000-00000000000%'), 5,
  'profiles are created by the auth.users trigger');
select is((select full_name from profiles where id = '00000000-0000-0000-0000-00000000000a'), 'Owner A',
  'profile takes full_name from user metadata');

create function pg_temp.login(u uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
$$;
grant execute on function pg_temp.login(uuid) to authenticated, anon;

set local role authenticated;

-- ───────────────────────── member 1 (in Juniors) ─────────────────────────
select pg_temp.login('00000000-0000-0000-0000-00000000000c');
select is((select count(*)::int from events), 2, 'm1 sees both A events');
select is((select count(*)::int from workspaces), 1, 'm1 sees only workspace A');
select is((select count(*)::int from conversations), 1, 'm1 sees own direct conversation');
select is((select count(*)::int from messages), 1, 'm1 sees own message');
select is((select count(*)::int from rsvps), 1, 'm1 sees own RSVP');
select is((select count(*)::int from push_subscriptions), 1, 'm1 sees own push subscription');
select is((select count(*)::int from attendance_log), 0, 'm1 cannot read the attendance log');
select is((select count(*)::int from checkin_tokens), 0, 'm1 cannot read check-in tokens');
select is((select count(*)::int from ai_logs), 0, 'm1 cannot read AI logs');

-- members have no direct write rights on rsvps, attendance, memberships (CLAUDE.md rule 3)
select throws_ok($$ insert into rsvps (event_id, user_id, workspace_id, answer) values
  ('eeeeeeee-0000-0000-0000-000000000002','00000000-0000-0000-0000-00000000000c','aaaaaaaa-0000-0000-0000-000000000001','going') $$,
  '42501', null, 'm1 cannot insert an RSVP directly');
with u as (update rsvps set answer = 'not_going' returning 1)
  select is(count(*)::int, 0, 'm1 cannot update an RSVP directly') from u;
select throws_ok($$ insert into attendance (event_id, user_id, workspace_id, present) values
  ('eeeeeeee-0000-0000-0000-000000000002','00000000-0000-0000-0000-00000000000c','aaaaaaaa-0000-0000-0000-000000000001', true) $$,
  '42501', null, 'm1 cannot mark own attendance');
select throws_ok($$ insert into memberships (workspace_id, user_id, role, status) values
  ('bbbbbbbb-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000c','owner','active') $$,
  '42501', null, 'm1 cannot insert a membership');
select throws_ok($$ insert into workspaces (slug, name) values ('sneaky', 'Sneaky') $$,
  '42501', null, 'workspaces are created only via RPC');

-- ───────────────────────── member 2 (no group) ─────────────────────────
select pg_temp.login('00000000-0000-0000-0000-00000000000d');
select is((select count(*)::int from events), 1, 'm2 sees only the whole-workspace event');
select is((select count(*)::int from conversations), 0, 'm2 cannot see m1 direct chat');
select is((select count(*)::int from messages), 0, 'm2 cannot see m1 messages');
select is((select count(*)::int from rsvps), 0, 'm2 cannot see m1 RSVP');
select is((select count(*)::int from attendance), 0, 'm2 cannot see m1 attendance');
select is((select count(*)::int from push_subscriptions), 0, 'm2 cannot see m1 push subscription');
select is((select count(*)::int from profiles), 4, 'm2 sees co-member profiles of A only');
select throws_ok($$ insert into events (workspace_id, title, starts_at, ends_at)
  values ('aaaaaaaa-0000-0000-0000-000000000001','Hack', now(), now()+interval '1 hour') $$,
  '42501', null, 'member cannot create an event');
select throws_ok($$ insert into messages (conversation_id, workspace_id, sender_id, body)
  values ('cccccccc-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000d','spy') $$,
  '42501', null, 'member cannot post into another member''s direct chat');
with u as (update memberships set role = 'owner' where user_id = '00000000-0000-0000-0000-00000000000d' returning 1)
  select is(count(*)::int, 0, 'member cannot change own role') from u;
with u as (update profiles set full_name = 'Hacked' where id = '00000000-0000-0000-0000-00000000000c' returning 1)
  select is(count(*)::int, 0, 'member cannot edit another profile') from u;
with u as (update workspaces set name = 'Hacked' returning 1)
  select is(count(*)::int, 0, 'member cannot edit workspace settings') from u;

-- ───────────────────────── trainer A ─────────────────────────
select pg_temp.login('00000000-0000-0000-0000-00000000000b');
select is((select count(*)::int from events), 2, 'trainer sees all A events, including group-only');
select is((select count(*)::int from conversations), 1, 'trainer sees all A direct chats');
select is((select count(*)::int from messages), 1, 'trainer reads messages in direct chats');
select is((select count(*)::int from attendance_log), 1, 'trainer reads the attendance log');
select lives_ok($$ insert into events (workspace_id, title, starts_at, ends_at)
  values ('aaaaaaaa-0000-0000-0000-000000000001','New class', now()+interval '3 day', now()+interval '3 day 1 hour') $$,
  'trainer creates an event');
select is((select count(*)::int from events), 3, 'trainer sees the new event');
select throws_ok($$ insert into events (workspace_id, title, starts_at, ends_at)
  values ('bbbbbbbb-0000-0000-0000-000000000001','Cross-tenant', now(), now()+interval '1 hour') $$,
  '42501', null, 'trainer cannot write into another workspace');
with d as (delete from events returning 1)
  select is(count(*)::int, 0, 'events are never hard-deleted (no delete policy)') from d;
select is((select count(*)::int from webhooks), 0, 'trainer cannot list webhooks (owner only)');
select is((select count(*)::int from api_keys), 0, 'trainer cannot list API keys (owner only)');

-- ───────────────────────── owner A (positive controls) ─────────────────────────
select pg_temp.login('00000000-0000-0000-0000-00000000000a');
select is((select count(*)::int from webhooks), 1, 'owner lists webhooks');
select is((select count(*)::int from api_keys), 1, 'owner lists API keys');
select is((select count(*)::int from webhook_deliveries), 1, 'owner lists webhook deliveries');
select throws_ok($$ select secret from webhooks $$, '42501', null, 'webhook secret is not readable via the API');
select throws_ok($$ select key_hash from api_keys $$, '42501', null, 'API key hash is not readable via the API');
select throws_ok($$ select count(*) from pending_signups $$, '42501', null, 'pending sign-ups are service-role only');
with u as (update workspaces set name = 'Workspace A+' returning 1)
  select is(count(*)::int, 1, 'owner edits workspace settings') from u;

-- ───────────────────────── owner B: cross-workspace denial on every table ─────────────────────────
select pg_temp.login('00000000-0000-0000-0000-00000000000e');
select is((select count(*)::int from events), 1, 'B owner sees only the B event');
select is((select count(*)::int from workspaces where id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: workspaces');
select is((select count(*)::int from memberships where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: memberships');
select is((select count(*)::int from groups where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: groups');
select is((select count(*)::int from group_members where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: group_members');
select is((select count(*)::int from event_series where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: event_series');
select is((select count(*)::int from events where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: events');
select is((select count(*)::int from rsvps where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: rsvps');
select is((select count(*)::int from attendance where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: attendance');
select is((select count(*)::int from attendance_log where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: attendance_log');
select is((select count(*)::int from checkin_tokens where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: checkin_tokens');
select is((select count(*)::int from conversations where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: conversations');
select is((select count(*)::int from messages where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: messages');
select is((select count(*)::int from message_recipients where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: message_recipients');
select is((select count(*)::int from ai_logs where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: ai_logs');
select is((select count(*)::int from api_keys where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: api_keys');
select is((select count(*)::int from webhooks where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: webhooks');
select is((select count(*)::int from webhook_deliveries where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001'), 0, 'B owner cannot read A: webhook_deliveries');
select is((select count(*)::int from profiles where id = '00000000-0000-0000-0000-00000000000c'), 0, 'B owner cannot read A: member profiles');
with u as (update events set title = 'Pwned' where workspace_id = 'aaaaaaaa-0000-0000-0000-000000000001' returning 1)
  select is(count(*)::int, 0, 'B owner cannot update A events') from u;

-- ───────────────────────── anonymous ─────────────────────────
reset role;
set local role anon;
select set_config('request.jwt.claims', '', true);
select is((select count(*)::int from events), 0, 'anon sees no events (public reads go through the API)');

select * from finish();
rollback;
