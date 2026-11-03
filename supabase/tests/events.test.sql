-- M2: series expansion (DST), update_series, cancel_event, integrity guards, calendar feed, cron.
-- Users: oA owner A, tA trainer A, mJ member A in Juniors, mO member A without group, oB owner B.
begin;
create extension if not exists pgtap with schema extensions;
select plan(49);

insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0002-0000000000a1', 'oa@m2.test', '{"full_name":"Owner A"}'),
 ('00000000-0000-0000-0002-0000000000a2', 'ta@m2.test', '{"full_name":"Trainer A"}'),
 ('00000000-0000-0000-0002-0000000000a3', 'mj@m2.test', '{"full_name":"Junior"}'),
 ('00000000-0000-0000-0002-0000000000a4', 'mo@m2.test', '{"full_name":"Other"}'),
 ('00000000-0000-0000-0002-0000000000b1', 'ob@m2.test', '{"full_name":"Owner B"}');
insert into workspaces (id, slug, name, timezone) values
 ('aaaaaaaa-0000-0000-0002-000000000001', 'm2-a', 'Studio A', 'Europe/Zurich'),
 ('bbbbbbbb-0000-0000-0002-000000000001', 'm2-b', 'Studio B', 'Europe/Ljubljana');
insert into memberships (workspace_id, user_id, role, status) values
 ('aaaaaaaa-0000-0000-0002-000000000001', '00000000-0000-0000-0002-0000000000a1', 'owner',   'active'),
 ('aaaaaaaa-0000-0000-0002-000000000001', '00000000-0000-0000-0002-0000000000a2', 'trainer', 'active'),
 ('aaaaaaaa-0000-0000-0002-000000000001', '00000000-0000-0000-0002-0000000000a3', 'member',  'active'),
 ('aaaaaaaa-0000-0000-0002-000000000001', '00000000-0000-0000-0002-0000000000a4', 'member',  'active'),
 ('bbbbbbbb-0000-0000-0002-000000000001', '00000000-0000-0000-0002-0000000000b1', 'owner',   'active');
insert into groups (id, workspace_id, name) values
 ('99999999-0000-0000-0002-000000000001', 'aaaaaaaa-0000-0000-0002-000000000001', 'Juniors'),
 ('99999999-0000-0000-0002-0000000000b1', 'bbbbbbbb-0000-0000-0002-000000000001', 'B group');
insert into group_members (group_id, user_id, workspace_id) values
 ('99999999-0000-0000-0002-000000000001', '00000000-0000-0000-0002-0000000000a3', 'aaaaaaaa-0000-0000-0002-000000000001');

-- Tuesday 18:30 class in Zurich starting 2 Mar 2027, across the DST switch on Sunday 28 Mar 2027
insert into event_series (id, workspace_id, title, weekdays, start_time, duration_min, starts_on, rsvp_deadline_minutes) values
 ('5e000000-0000-0000-0002-000000000001', 'aaaaaaaa-0000-0000-0002-000000000001', 'Hip Hop', '{2}', '18:30', 90, '2027-03-02', 120),
 ('5e000000-0000-0000-0002-000000000002', 'aaaaaaaa-0000-0000-0002-000000000001', 'Biweekly', '{1,4}', '17:00', 60, '2027-03-01', null);
-- a weekly series starting today, for the "12 weeks ahead" rule
insert into event_series (id, workspace_id, title, weekdays, start_time, duration_min, starts_on, group_ids) values
 ('5e000000-0000-0000-0002-000000000003', 'aaaaaaaa-0000-0000-0002-000000000001', 'Juniors weekly',
  array[extract(isodow from current_date + 1)::smallint], '23:00', 60, current_date, '{99999999-0000-0000-0002-000000000001}');
update event_series set interval_weeks = 2 where id = '5e000000-0000-0000-0002-000000000002';

create function pg_temp.login(u uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
$$;
grant execute on function pg_temp.login(uuid) to authenticated, anon;
create function pg_temp.local(e uuid) returns text language sql as $$
  select to_char(starts_at at time zone 'Europe/Zurich', 'YYYY-MM-DD HH24:MI') from events where id = e;
$$;
grant execute on function pg_temp.local(uuid) to authenticated;

set local role authenticated;

-- ───────────────────────── expand_series ─────────────────────────
select pg_temp.login('00000000-0000-0000-0002-0000000000a3');
select throws_ok($$ select expand_series('5e000000-0000-0000-0002-000000000001') $$, 'P0001', 'forbidden', 'a member cannot expand a series');
select pg_temp.login('00000000-0000-0000-0002-0000000000b1');
select throws_ok($$ select expand_series('5e000000-0000-0000-0002-000000000001') $$, 'P0001', 'forbidden', 'owner of B cannot expand A''s series');

select pg_temp.login('00000000-0000-0000-0002-0000000000a2');
select is(expand_series('5e000000-0000-0000-0002-000000000001', '2027-05-25'), 13, 'weekly Tuesday class: 13 occurrences 2 Mar – 25 May 2027');
select is(expand_series('5e000000-0000-0000-0002-000000000001', '2027-05-25'), 0, 'expanding again creates nothing (idempotent)');
select results_eq(
  $$ select to_char(starts_at at time zone 'UTC', 'MM-DD HH24:MI'), to_char(starts_at at time zone 'Europe/Zurich', 'HH24:MI')
     from events where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date in ('2027-03-23', '2027-03-30') order by starts_at $$,
  $$ values ('03-23 17:30', '18:30'), ('03-30 16:30', '18:30') $$,
  'DST: 18:30 local stays 18:30 — 17:30 UTC before 28 Mar, 16:30 UTC after');
select is((select count(*)::int from events where series_id = '5e000000-0000-0000-0002-000000000001'
             and to_char(starts_at at time zone 'Europe/Zurich', 'ID HH24:MI') <> '2 18:30'), 0,
  'every occurrence is a Tuesday at 18:30 local time');
select is((select to_char(rsvp_deadline at time zone 'Europe/Zurich', 'HH24:MI') from events
            where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date = '2027-03-02'), '16:30',
  'RSVP deadline = start minus rsvp_deadline_minutes');
select is((select ends_at - starts_at from events where series_id = '5e000000-0000-0000-0002-000000000001' limit 1),
  interval '90 minutes', 'duration is applied');
select is(expand_series('5e000000-0000-0000-0002-000000000002', '2027-03-31'), 5,
  'every 2 weeks on Mon + Thu, March 2027: 1, 4, 15, 18, 29');
select results_eq($$ select occurrence_date from events where series_id = '5e000000-0000-0000-0002-000000000002' order by 1 $$,
  $$ values ('2027-03-01'::date), ('2027-03-04'), ('2027-03-15'), ('2027-03-18'), ('2027-03-29') $$, 'alternate weeks are skipped');
select cmp_ok(expand_series('5e000000-0000-0000-0002-000000000003'), '>=', 12, 'default horizon gives 12 weeks of a weekly class');
select ok((select max(starts_at) <= now() + interval '85 days' and min(starts_at) > now()
           from events where series_id = '5e000000-0000-0000-0002-000000000003'),
  'occurrences lie in the future and within 12 weeks');

-- ───────────────────────── visibility of generated events ─────────────────────────
select pg_temp.login('00000000-0000-0000-0002-0000000000a4');
select is((select count(*)::int from events where series_id = '5e000000-0000-0000-0002-000000000003'), 0,
  'group-only occurrences are hidden from members outside the group');
select pg_temp.login('00000000-0000-0000-0002-0000000000a3');
select cmp_ok((select count(*)::int from events where series_id = '5e000000-0000-0000-0002-000000000003'), '>=', 12,
  'group members see the occurrences');
select pg_temp.login('00000000-0000-0000-0002-0000000000b1');
select is((select count(*)::int from events where workspace_id = 'aaaaaaaa-0000-0000-0002-000000000001'), 0,
  'owner of B sees no A events');
select is((select count(*)::int from event_series where workspace_id = 'aaaaaaaa-0000-0000-0002-000000000001'), 0,
  'owner of B sees no A series');

-- ───────────────────────── edits: this vs future ─────────────────────────
select pg_temp.login('00000000-0000-0000-0002-0000000000a2');
with u as (update events set title = 'Hip Hop — guest teacher'
           where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date = '2027-03-16' returning is_exception)
select is((select bool_and(is_exception) from u), true, 'editing one occurrence marks it as an exception');
reset role;
insert into rsvps (event_id, user_id, workspace_id, answer)
select id, '00000000-0000-0000-0002-0000000000a3', workspace_id, 'going'
from events where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date = '2027-03-23';
set local role authenticated;

select pg_temp.login('00000000-0000-0000-0002-0000000000a3');
select throws_ok($$ select update_series((select id from events where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date = '2027-03-09'),
  '{"title":"x"}') $$, 'P0001', 'forbidden', 'a member cannot update a series');

select pg_temp.login('00000000-0000-0000-0002-0000000000a2');
select is(
  update_series((select id from events where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date = '2027-03-09'),
                '{"start_time":"19:00","title":"Hip Hop Advanced"}'),
  '{"updated": 10, "cancelled": 0, "kept": 2, "created": 0}'::jsonb,
  'future (9 Mar – 25 May): 10 updated, the edited and the answered occurrence are kept');
select is(pg_temp.local((select id from events where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date = '2027-03-30')),
  '2027-03-30 19:00', 'new start time applies after DST too');
select is(pg_temp.local((select id from events where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date = '2027-03-23')),
  '2027-03-23 18:30', 'an occurrence with RSVPs is not changed silently');
select is((select title from events where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date = '2027-03-16'),
  'Hip Hop — guest teacher', 'an individually edited occurrence keeps its edits');
select is(pg_temp.local((select id from events where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date = '2027-03-02')),
  '2027-03-02 18:30', 'earlier occurrences are untouched');
select is(
  update_series((select id from events where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date = '2027-05-04'),
                '{"weekdays":[3]}'),
  '{"updated": 0, "cancelled": 4, "kept": 0, "created": 3}'::jsonb,
  'moving to Wednesday from 4 May: Tuesdays 4–25 May cancelled, Wednesdays 5–19 May created (horizon 25 May)');
select is((select count(*)::int from events where series_id = '5e000000-0000-0000-0002-000000000001'
             and status = 'scheduled' and extract(isodow from occurrence_date) = 3), 3,
  'Wednesday occurrences exist only from the edited occurrence on');
select is((select count(*)::int from events where series_id is null and title = 'x'), 0, 'no stray events');

-- ───────────────────────── cancel_event ─────────────────────────
select pg_temp.login('00000000-0000-0000-0002-0000000000a4');
select throws_ok($$ select cancel_event((select id from events where series_id = '5e000000-0000-0000-0002-000000000003' limit 1)) $$,
  'P0001', 'not_found', 'a member cannot even see (and so not cancel) a group-only event');
select pg_temp.login('00000000-0000-0000-0002-0000000000a3');
select throws_ok($$ select cancel_event((select id from events where series_id = '5e000000-0000-0000-0002-000000000003' order by starts_at limit 1)) $$,
  'P0001', 'forbidden', 'a member cannot cancel');

select pg_temp.login('00000000-0000-0000-0002-0000000000a2');
select throws_ok($$ select cancel_event((select id from events where series_id = '5e000000-0000-0000-0002-000000000003' order by starts_at limit 1), true) $$,
  'P0001', 'message_required', 'notifying needs a message');
select is(cancel_event((select id from events where series_id = '5e000000-0000-0000-0002-000000000003' order by starts_at limit 1),
                       true, 'this', 'Sorry, no class today'), 1, 'trainer cancels one occurrence with a notice');
select ok((select status = 'cancelled' and cancelled_at is not null from events
           where series_id = '5e000000-0000-0000-0002-000000000003' order by starts_at limit 1), 'status and cancelled_at are set');
select results_eq($$ select r.user_id from message_recipients r join messages m on m.id = r.message_id
                     where m.body = 'Sorry, no class today' order by 1 $$,
  $$ values ('00000000-0000-0000-0002-0000000000a1'::uuid), ('00000000-0000-0000-0002-0000000000a3'::uuid) $$,
  'the notice reaches the group member and the owner, not the sender or members outside the group');
select is(cancel_event((select id from events where series_id = '5e000000-0000-0000-0002-000000000002' and occurrence_date = '2027-03-15'),
                       false, 'future'), 3, 'cancelling "this and following" cancels the rest of the series');
select is((select until from event_series where id = '5e000000-0000-0000-0002-000000000002'), '2027-03-14'::date,
  'the series ends the day before');
select is(expand_series('5e000000-0000-0000-0002-000000000002', '2027-06-30'), 0, 'an ended series creates nothing more');
with d as (delete from events where series_id = '5e000000-0000-0000-0002-000000000002' returning 1)
select is(count(*)::int, 0, 'events are still never hard-deleted') from d;

-- ───────────────────────── guards ─────────────────────────
select throws_ok($$ insert into events (workspace_id, title, starts_at, ends_at, group_ids) values
  ('aaaaaaaa-0000-0000-0002-000000000001', 'Bad', now() + interval '1 day', now() + interval '1 day 1 hour',
   '{99999999-0000-0000-0002-0000000000b1}') $$, 'P0001', 'group_invalid', 'groups of another workspace are rejected');
reset role;
insert into memberships (workspace_id, user_id, role, status)
  values ('bbbbbbbb-0000-0000-0002-000000000001', '00000000-0000-0000-0002-0000000000a2', 'trainer', 'active');
set local role authenticated;
select pg_temp.login('00000000-0000-0000-0002-0000000000a2');
select throws_ok($$ update events set workspace_id = 'bbbbbbbb-0000-0000-0002-000000000001'
                    where series_id = '5e000000-0000-0000-0002-000000000001' and occurrence_date = '2027-03-02' $$,
  'P0001', 'forbidden', 'a trainer of two workspaces cannot move an event between them');

-- ───────────────────────── calendar feed ─────────────────────────
select pg_temp.login('00000000-0000-0000-0002-0000000000a3');
select ok(length(my_calendar_token()) = 48, 'a user reads their own calendar token');
select throws_ok($$ select calendar_token from profiles $$, '42501', null, 'tokens are not readable through the profiles table');

reset role;
create temp table tok as select id, calendar_token from profiles where id::text like '00000000-0000-0000-0002-%';
select is((select count(distinct calendar_token)::int from tok), 5, 'every user has a different token');
grant select on tok to anon;
set local role anon;
select set_config('request.jwt.claims', '', true);
select cmp_ok((select count(*)::int from calendar_feed((select calendar_token from tok where id = '00000000-0000-0000-0002-0000000000a3'))
               where title = 'Juniors weekly'), '>=', 11, 'the feed of a Junior includes the Juniors class');
select is((select count(*)::int from calendar_feed((select calendar_token from tok where id = '00000000-0000-0000-0002-0000000000a4'))
           where title = 'Juniors weekly'), 0, 'the feed of a member outside the group does not');
select is((select count(*)::int from calendar_feed((select calendar_token from tok where id = '00000000-0000-0000-0002-0000000000b1'))), 0,
  'the feed of owner B has no A events');
select is_empty($$ select * from calendar_feed('not-a-real-token-but-long-enough-000000000000') $$, 'an unknown token gives nothing');
select is(calendar_feed_exists('not-a-real-token-but-long-enough-000000000000'), false, 'unknown tokens are reported as unknown');
select is(calendar_feed_exists((select calendar_token from tok where id = '00000000-0000-0000-0002-0000000000a4')), true, 'known tokens exist');
select throws_ok($$ select expand_series('5e000000-0000-0000-0002-000000000001') $$, '42501', null, 'anon cannot call trainer RPCs');

reset role;
select is((select count(*)::int from cron.job where jobname = 'bw-extend-series'), 1, 'the nightly series job is scheduled');

select * from finish();
rollback;
