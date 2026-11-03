-- M3: rsvp, counts, check-in, QR, reset, history.
-- Workspace A: oA owner, tA trainer, m1 (Juniors), m2, m3 members, n non-member. Workspace B: oB owner, mB member.
begin;
create extension if not exists pgtap with schema extensions;
select plan(62);

insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0003-0000000000a1', 'oa@m3.test', '{"full_name":"Owner A"}'),
 ('00000000-0000-0000-0003-0000000000a2', 'ta@m3.test', '{"full_name":"Trainer A"}'),
 ('00000000-0000-0000-0003-0000000000a3', 'm1@m3.test', '{"full_name":"Ana"}'),
 ('00000000-0000-0000-0003-0000000000a4', 'm2@m3.test', '{"full_name":"Bor"}'),
 ('00000000-0000-0000-0003-0000000000a5', 'm3@m3.test', '{"full_name":"Cene"}'),
 ('00000000-0000-0000-0003-0000000000a6', 'n@m3.test',  '{"full_name":"Nobody"}'),
 ('00000000-0000-0000-0003-0000000000b1', 'ob@m3.test', '{"full_name":"Owner B"}'),
 ('00000000-0000-0000-0003-0000000000b2', 'mb@m3.test', '{"full_name":"Member B"}');
insert into workspaces (id, slug, name) values
 ('aaaaaaaa-0000-0000-0003-000000000001', 'm3-a', 'Studio A'),
 ('bbbbbbbb-0000-0000-0003-000000000001', 'm3-b', 'Studio B');
insert into memberships (workspace_id, user_id, role, status) values
 ('aaaaaaaa-0000-0000-0003-000000000001', '00000000-0000-0000-0003-0000000000a1', 'owner',   'active'),
 ('aaaaaaaa-0000-0000-0003-000000000001', '00000000-0000-0000-0003-0000000000a2', 'trainer', 'active'),
 ('aaaaaaaa-0000-0000-0003-000000000001', '00000000-0000-0000-0003-0000000000a3', 'member',  'active'),
 ('aaaaaaaa-0000-0000-0003-000000000001', '00000000-0000-0000-0003-0000000000a4', 'member',  'active'),
 ('aaaaaaaa-0000-0000-0003-000000000001', '00000000-0000-0000-0003-0000000000a5', 'member',  'active'),
 ('bbbbbbbb-0000-0000-0003-000000000001', '00000000-0000-0000-0003-0000000000b1', 'owner',   'active'),
 ('bbbbbbbb-0000-0000-0003-000000000001', '00000000-0000-0000-0003-0000000000b2', 'member',  'active');
insert into groups (id, workspace_id, name) values
 ('99999999-0000-0000-0003-000000000001', 'aaaaaaaa-0000-0000-0003-000000000001', 'Juniors');
insert into group_members (group_id, user_id, workspace_id) values
 ('99999999-0000-0000-0003-000000000001', '00000000-0000-0000-0003-0000000000a3', 'aaaaaaaa-0000-0000-0003-000000000001');

insert into events (id, workspace_id, title, starts_at, ends_at, capacity, rsvp_deadline, status, group_ids) values
 -- E1: open, capacity 2
 ('e3000000-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0003-000000000001', 'Hip Hop', now() + interval '1 day', now() + interval '1 day 90 min', 2, null, 'scheduled', '{}'),
 -- E2: deadline passed
 ('e3000000-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0003-000000000001', 'Closed', now() + interval '1 day', now() + interval '1 day 1 hour', null, now() - interval '1 hour', 'scheduled', '{}'),
 -- E3: cancelled
 ('e3000000-0000-0000-0000-000000000003', 'aaaaaaaa-0000-0000-0003-000000000001', 'Off', now() + interval '2 day', now() + interval '2 day 1 hour', null, null, 'cancelled', '{}'),
 -- E4: Juniors only
 ('e3000000-0000-0000-0000-000000000004', 'aaaaaaaa-0000-0000-0003-000000000001', 'Juniors', now() + interval '3 day', now() + interval '3 day 1 hour', null, null, 'scheduled', '{99999999-0000-0000-0003-000000000001}'),
 -- E5: last week, already recorded
 ('e3000000-0000-0000-0000-000000000005', 'aaaaaaaa-0000-0000-0003-000000000001', 'Last week', now() - interval '7 day', now() - interval '7 day' + interval '1 hour', null, null, 'scheduled', '{}');
insert into attendance (event_id, user_id, workspace_id, present) values
 ('e3000000-0000-0000-0000-000000000005', '00000000-0000-0000-0003-0000000000a3', 'aaaaaaaa-0000-0000-0003-000000000001', true),
 ('e3000000-0000-0000-0000-000000000005', '00000000-0000-0000-0003-0000000000a4', 'aaaaaaaa-0000-0000-0003-000000000001', false);
insert into attendance_log (event_id, user_id, workspace_id, old_present, new_present) values
 ('e3000000-0000-0000-0000-000000000005', '00000000-0000-0000-0003-0000000000a3', 'aaaaaaaa-0000-0000-0003-000000000001', null, true);

create function pg_temp.login(u uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
$$;
grant execute on function pg_temp.login(uuid) to authenticated, anon;

set local role anon;
select throws_ok($$ select rsvp('e3000000-0000-0000-0000-000000000001', 'going') $$, '42501', null, 'anon cannot rsvp');
reset role;
set local role authenticated;

-- ───────────────────────── rsvp ─────────────────────────
select pg_temp.login('00000000-0000-0000-0003-0000000000a3');
select is(rsvp('e3000000-0000-0000-0000-000000000001', 'going')::text, 'going', 'a member answers "going"');
select pg_temp.login('00000000-0000-0000-0003-0000000000a4');
select is(rsvp('e3000000-0000-0000-0000-000000000001', 'going')::text, 'going', 'second "going" fills the capacity of 2');
select pg_temp.login('00000000-0000-0000-0003-0000000000a5');
select throws_ok($$ select rsvp('e3000000-0000-0000-0000-000000000001', 'going') $$, 'P0001', 'event_full', 'a third "going" is refused');
select pg_temp.login('00000000-0000-0000-0003-0000000000a3');
select is(rsvp('e3000000-0000-0000-0000-000000000001', 'not_going', '  Sick  ')::text, 'not_going', 'changing the answer is an upsert');
select is((select reason from rsvps where event_id = 'e3000000-0000-0000-0000-000000000001' and user_id = auth.uid()), 'Sick',
  'the reason is stored, trimmed');
select is(rsvp('e3000000-0000-0000-0000-000000000001', 'going')::text, 'going', 'switching back to going while there is room');
select is((select reason from rsvps where event_id = 'e3000000-0000-0000-0000-000000000001' and user_id = auth.uid()), null,
  '"going" clears the reason');
select is(rsvp('e3000000-0000-0000-0000-000000000001', 'not_going')::text, 'not_going', 'and back to not going (frees the place)');
select pg_temp.login('00000000-0000-0000-0003-0000000000a5');
select is(rsvp('e3000000-0000-0000-0000-000000000001', 'going')::text, 'going', 'a freed place can be taken');
select throws_ok($$ select rsvp('e3000000-0000-0000-0000-000000000004', 'not_going', repeat('x', 301)) $$, 'P0001', 'not_found',
  'a group-only event is invisible to non-group members');
select pg_temp.login('00000000-0000-0000-0003-0000000000a3');
select throws_ok($$ select rsvp('e3000000-0000-0000-0000-000000000004', 'not_going', repeat('x', 301)) $$, 'P0001', 'reason_too_long',
  'reasons are limited to 300 characters');
select throws_ok($$ select rsvp('e3000000-0000-0000-0000-000000000002', 'going') $$, 'P0001', 'rsvp_closed', 'after the deadline answers are closed');
select throws_ok($$ select rsvp('e3000000-0000-0000-0000-000000000003', 'going') $$, 'P0001', 'event_cancelled', 'cancelled events take no answers');
select pg_temp.login('00000000-0000-0000-0003-0000000000b2');
select throws_ok($$ select rsvp('e3000000-0000-0000-0000-000000000001', 'going') $$, 'P0001', 'not_found', 'a member of B cannot answer an A event');

reset role;
update workspaces set allow_self_absence = false where id = 'aaaaaaaa-0000-0000-0003-000000000001';
set local role authenticated;
select pg_temp.login('00000000-0000-0000-0003-0000000000a4');
select throws_ok($$ select rsvp('e3000000-0000-0000-0000-000000000001', 'not_going') $$, 'P0001', 'self_absence_disabled',
  '"can''t make it" respects allow_self_absence');
reset role;
update workspaces set allow_self_absence = true where id = 'aaaaaaaa-0000-0000-0003-000000000001';
set local role authenticated;

-- ───────────────────────── counts and lists ─────────────────────────
select pg_temp.login('00000000-0000-0000-0003-0000000000a4');
select results_eq($$ select invited, going, not_going, no_answer, present, absent from event_counts('e3000000-0000-0000-0000-000000000001') $$,
  $$ values (3, 2, 1, 0, 0, 0) $$, 'members see counts: 3 invited, 2 going, 1 not going');
select throws_ok($$ select * from event_attendees('e3000000-0000-0000-0000-000000000001') $$, 'P0001', 'forbidden', 'members cannot list names');
select is((select count(*)::int from rsvps where event_id = 'e3000000-0000-0000-0000-000000000001'), 1, 'members only see their own answer');
select pg_temp.login('00000000-0000-0000-0003-0000000000b1');
select throws_ok($$ select * from event_counts('e3000000-0000-0000-0000-000000000001') $$, 'P0001', 'not_found', 'owner of B gets no counts for A');
select throws_ok($$ select * from event_attendees('e3000000-0000-0000-0000-000000000001') $$, 'P0001', 'forbidden', 'owner of B gets no names for A');
select is_empty($$ select * from event_counts_many(array['e3000000-0000-0000-0000-000000000001'::uuid]) $$, 'batch counts skip invisible events');

select pg_temp.login('00000000-0000-0000-0003-0000000000a2');
select results_eq($$ select full_name, answer::text, in_audience from event_attendees('e3000000-0000-0000-0000-000000000001') $$,
  $$ values ('Ana', 'not_going', true), ('Bor', 'going', true), ('Cene', 'going', true) $$, 'the trainer sees who answered what');
select is((select count(*)::int from checkin_candidates('e3000000-0000-0000-0000-000000000001')), 5,
  'walk-in candidates are all active members of the workspace');
select is((select count(*)::int from event_counts_many(array['e3000000-0000-0000-0000-000000000001'::uuid, 'e3000000-0000-0000-0000-000000000004'])), 2,
  'trainers get batch counts for every event');

-- ───────────────────────── check-in ─────────────────────────
select pg_temp.login('00000000-0000-0000-0003-0000000000a3');
select throws_ok($$ select start_checkin('e3000000-0000-0000-0000-000000000001') $$, 'P0001', 'forbidden', 'members cannot start check-in');
select throws_ok($$ select mark_attendance('e3000000-0000-0000-0000-000000000001', '00000000-0000-0000-0003-0000000000a3', true) $$,
  'P0001', 'forbidden', 'members cannot mark themselves');
select pg_temp.login('00000000-0000-0000-0003-0000000000b1');
select throws_ok($$ select mark_attendance('e3000000-0000-0000-0000-000000000001', '00000000-0000-0000-0003-0000000000a3', true) $$,
  'P0001', 'forbidden', 'owner of B cannot mark A attendance');

select pg_temp.login('00000000-0000-0000-0003-0000000000a2');
select is(start_checkin('e3000000-0000-0000-0000-000000000001'), 2, 'start: both confirmed members are present by default');
select is(start_checkin('e3000000-0000-0000-0000-000000000001'), 0, 'starting again changes nothing');
select is((select count(*)::int from attendance_log where event_id = 'e3000000-0000-0000-0000-000000000001' and note = 'default' and new_present), 2,
  'defaults are logged');
select lives_ok($$ select mark_attendance('e3000000-0000-0000-0000-000000000001', '00000000-0000-0000-0003-0000000000a5', false) $$,
  'trainer marks a confirmed member absent');
select results_eq($$ select old_present, new_present, changed_by from attendance_log
                     where event_id = 'e3000000-0000-0000-0000-000000000001' and user_id = '00000000-0000-0000-0003-0000000000a5' and note = 'trainer' $$,
  $$ values (true, false, '00000000-0000-0000-0003-0000000000a2'::uuid) $$, 'the change is logged with old and new value');
select lives_ok($$ select mark_attendance('e3000000-0000-0000-0000-000000000001', '00000000-0000-0000-0003-0000000000a5', false) $$,
  'marking the same value again is fine');
select is((select count(*)::int from attendance_log where user_id = '00000000-0000-0000-0003-0000000000a5' and note = 'trainer'), 1,
  'an unchanged value is not logged twice');
select lives_ok($$ select mark_attendance('e3000000-0000-0000-0000-000000000001', '00000000-0000-0000-0003-0000000000a3', true) $$,
  'a member who said "can''t make it" can still be marked present (walk-in)');
select throws_ok($$ select mark_attendance('e3000000-0000-0000-0000-000000000001', '00000000-0000-0000-0003-0000000000a6', true) $$,
  'P0001', 'not_member', 'people outside the workspace cannot be marked');
select throws_ok($$ select mark_attendance('e3000000-0000-0000-0000-000000000003', '00000000-0000-0000-0003-0000000000a3', true) $$,
  'P0001', 'event_cancelled', 'no attendance on cancelled events');
select results_eq($$ select present, absent from event_counts('e3000000-0000-0000-0000-000000000001') $$,
  $$ values (2, 1) $$, 'counts include present and absent');

-- ───────────────────────── QR ─────────────────────────
select throws_ok($$ select create_checkin_token('e3000000-0000-0000-0000-000000000001', 0) $$, 'P0001', 'invalid_minutes', 'token lifetime is checked');
reset role;
create temp table tokens (name text, token text);
grant all on tokens to authenticated;
set local role authenticated;
insert into tokens values ('e1', create_checkin_token('e3000000-0000-0000-0000-000000000001')),
                          ('e4', create_checkin_token('e3000000-0000-0000-0000-000000000004'));
select is((select length(token) from tokens where name = 'e1'), 32, 'trainer gets a 32-character token');
select isnt((select token_hash from checkin_tokens where event_id = 'e3000000-0000-0000-0000-000000000001'),
  (select token from tokens where name = 'e1'), 'only the hash is stored');
select pg_temp.login('00000000-0000-0000-0003-0000000000a3');
select throws_ok($$ select create_checkin_token('e3000000-0000-0000-0000-000000000001') $$, 'P0001', 'forbidden', 'members cannot create tokens');

select pg_temp.login('00000000-0000-0000-0003-0000000000a5');
select is(qr_checkin((select token from tokens where name = 'e1')), 'e3000000-0000-0000-0000-000000000001'::uuid, 'scanning checks the member in');
select results_eq($$ select present, method::text from attendance where event_id = 'e3000000-0000-0000-0000-000000000001' and user_id = auth.uid() $$,
  $$ values (true, 'qr') $$, 'present by QR (overrides the earlier "absent")');
select is((select count(*)::int from attendance_log), 0, 'members cannot read the attendance log');
reset role;
select is((select count(*)::int from attendance_log where user_id = '00000000-0000-0000-0003-0000000000a5' and note = 'qr'
             and old_present = false and new_present), 1, 'the QR check-in is logged');
set local role authenticated;
select throws_ok($$ select qr_checkin('nope') $$, 'P0001', 'invalid_token', 'unknown tokens are rejected');
select pg_temp.login('00000000-0000-0000-0003-0000000000a4');
select throws_ok($$ select qr_checkin((select token from tokens where name = 'e4')) $$, 'P0001', 'not_invited',
  'a member outside the group cannot check in to a group event');
select pg_temp.login('00000000-0000-0000-0003-0000000000b2');
select throws_ok($$ select qr_checkin((select token from tokens where name = 'e1')) $$, 'P0001', 'not_invited',
  'a member of B cannot use an A token');
reset role;
update checkin_tokens set expires_at = now() - interval '1 minute' where event_id = 'e3000000-0000-0000-0000-000000000004';
set local role authenticated;
select pg_temp.login('00000000-0000-0000-0003-0000000000a3');
select throws_ok($$ select qr_checkin((select token from tokens where name = 'e4')) $$, 'P0001', 'token_expired', 'expired tokens are rejected');

-- ───────────────────────── reset ─────────────────────────
select throws_ok($$ select reset_attendance('e3000000-0000-0000-0000-000000000001', 'Hip Hop') $$, 'P0001', 'forbidden', 'members cannot reset');
select pg_temp.login('00000000-0000-0000-0003-0000000000a2');
select throws_ok($$ select reset_attendance('e3000000-0000-0000-0000-000000000001', 'hip hop!') $$, 'P0001', 'confirm_mismatch',
  'the typed title must match');
select is(reset_attendance('e3000000-0000-0000-0000-000000000001', ' Hip Hop '), 3, 'reset removes the attendance of this event');
select is((select count(*)::int from attendance where event_id = 'e3000000-0000-0000-0000-000000000001'), 0, 'nothing left for this event');
select is((select count(*)::int from attendance_log where event_id = 'e3000000-0000-0000-0000-000000000001' and note = 'reset' and new_present is null), 3,
  'every removed row is logged (new_present = null)');
select is((select count(*)::int from attendance where event_id = 'e3000000-0000-0000-0000-000000000005'), 2,
  'other events keep their attendance');
select is((select count(*)::int from attendance_log where event_id = 'e3000000-0000-0000-0000-000000000005'), 1,
  'other events keep their history');

-- ───────────────────────── history ─────────────────────────
select results_eq($$ select user_id, events, present, absent from attendance_summary('aaaaaaaa-0000-0000-0003-000000000001')
                     where user_id in ('00000000-0000-0000-0003-0000000000a3', '00000000-0000-0000-0003-0000000000a4') order by 1 $$,
  $$ values ('00000000-0000-0000-0003-0000000000a3'::uuid, 1, 1, 0), ('00000000-0000-0000-0003-0000000000a4'::uuid, 1, 0, 1) $$,
  'summary: past events, present, absent per member');
select pg_temp.login('00000000-0000-0000-0003-0000000000a3');
select results_eq($$ select title, present from member_attendance('aaaaaaaa-0000-0000-0003-000000000001', auth.uid()) $$,
  $$ values ('Last week', true) $$, 'a member sees their own history');
select throws_ok($$ select * from member_attendance('aaaaaaaa-0000-0000-0003-000000000001', '00000000-0000-0000-0003-0000000000a4') $$,
  'P0001', 'forbidden', 'but not someone else''s');
select throws_ok($$ select * from attendance_summary('aaaaaaaa-0000-0000-0003-000000000001') $$, 'P0001', 'forbidden', 'members get no summary');

select * from finish();
rollback;
