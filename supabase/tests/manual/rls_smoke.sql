\set ON_ERROR_STOP on
-- users: o = owner of ws A, t = trainer A, m1 = member A (group juniors), m2 = member A (no group), x = owner of ws B
insert into auth.users (id, raw_user_meta_data) values
 ('00000000-0000-0000-0000-00000000000a', '{"full_name":"Owner A"}'),
 ('00000000-0000-0000-0000-00000000000b', '{"full_name":"Trainer A"}'),
 ('00000000-0000-0000-0000-00000000000c', '{"full_name":"Member 1"}'),
 ('00000000-0000-0000-0000-00000000000d', '{"full_name":"Member 2"}'),
 ('00000000-0000-0000-0000-00000000000e', '{"full_name":"Owner B"}');

insert into workspaces (id, slug, name, type) values
 ('aaaaaaaa-0000-0000-0000-000000000001', 'niko-dance', 'Niko Dance School', 'dance'),
 ('bbbbbbbb-0000-0000-0000-000000000001', 'yoga-zug', 'Yoga Zug', 'yoga');
insert into memberships values
 ('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000a','owner','active'),
 ('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000b','trainer','active'),
 ('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000c','member','active'),
 ('aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000d','member','active'),
 ('bbbbbbbb-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000e','owner','active');
insert into groups (id, workspace_id, name) values ('99999999-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','Juniors');
insert into group_members values ('99999999-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000c','aaaaaaaa-0000-0000-0000-000000000001');
insert into events (id, workspace_id, title, starts_at, ends_at, group_ids) values
 ('eeeeeeee-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','All crew', now()+interval '1 day', now()+interval '1 day 1 hour', '{}'),
 ('eeeeeeee-0000-0000-0000-000000000002','aaaaaaaa-0000-0000-0000-000000000001','Juniors only', now()+interval '2 day', now()+interval '2 day 1 hour', '{99999999-0000-0000-0000-000000000001}'),
 ('eeeeeeee-0000-0000-0000-000000000003','bbbbbbbb-0000-0000-0000-000000000001','Yoga flow', now()+interval '1 day', now()+interval '1 day 1 hour', '{}');
insert into conversations (id, workspace_id, kind, member_id) values
 ('cccccccc-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','direct','00000000-0000-0000-0000-00000000000c');
insert into messages (conversation_id, workspace_id, sender_id, body) values
 ('cccccccc-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000c','Can I come late?');
insert into webhooks (workspace_id, url, event_types) values ('aaaaaaaa-0000-0000-0000-000000000001','https://bouncewith.me/hook','{event.created}');

create function pg_temp.as_user(u text) returns void language plpgsql as $$
begin perform set_config('request.jwt.claim.sub', u, false); end $$;
create function pg_temp.check(label text, got bigint, want bigint) returns void language plpgsql as $$
begin
  if got <> want then raise exception 'FAIL % : got %, want %', label, got, want; end if;
  raise notice 'ok  %', label;
end $$;

-- profile trigger fired
select pg_temp.check('profiles created by trigger', (select count(*) from profiles), 5);

set role authenticated;

-- member 1 (in Juniors)
select pg_temp.as_user('00000000-0000-0000-0000-00000000000c');
select pg_temp.check('m1 sees both A events', (select count(*) from events), 2);
select pg_temp.check('m1 sees no B workspace', (select count(*) from workspaces where slug='yoga-zug'), 0);
select pg_temp.check('m1 sees own direct conversation', (select count(*) from conversations), 1);
select pg_temp.check('m1 sees own message', (select count(*) from messages), 1);

-- member 2 (no group)
select pg_temp.as_user('00000000-0000-0000-0000-00000000000d');
select pg_temp.check('m2 sees only all-crew event', (select count(*) from events), 1);
select pg_temp.check('m2 cannot see m1 direct chat', (select count(*) from conversations), 0);
select pg_temp.check('m2 cannot see m1 messages', (select count(*) from messages), 0);
select pg_temp.check('m2 sees co-member profiles of A only', (select count(*) from profiles), 4);

do $$ begin
  insert into events (workspace_id, title, starts_at, ends_at)
  values ('aaaaaaaa-0000-0000-0000-000000000001','Hack', now(), now()+interval '1 hour');
  raise exception 'FAIL member could create event';
exception when insufficient_privilege then raise notice 'ok  member cannot create event';
end $$;

do $$ begin
  insert into messages (conversation_id, workspace_id, sender_id, body)
  values ('cccccccc-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','00000000-0000-0000-0000-00000000000d','spy');
  raise exception 'FAIL member posted into another member''s direct chat';
exception when insufficient_privilege then raise notice 'ok  member cannot post into another direct chat';
end $$;

do $$ begin
  update memberships set role = 'owner' where user_id = '00000000-0000-0000-0000-00000000000d';
  if found then raise exception 'FAIL member escalated own role'; end if;
  raise notice 'ok  member cannot change own role';
end $$;

-- trainer
select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select pg_temp.check('trainer sees all A events', (select count(*) from events), 2);
select pg_temp.check('trainer sees all A conversations', (select count(*) from conversations), 1);
insert into events (workspace_id, title, starts_at, ends_at)
  values ('aaaaaaaa-0000-0000-0000-000000000001','New class', now()+interval '3 day', now()+interval '3 day 1 hour');
select pg_temp.check('trainer created event', (select count(*) from events), 3);
do $$ begin
  insert into events (workspace_id, title, starts_at, ends_at)
  values ('bbbbbbbb-0000-0000-0000-000000000001','Cross-tenant', now(), now()+interval '1 hour');
  raise exception 'FAIL trainer wrote into another workspace';
exception when insufficient_privilege then raise notice 'ok  trainer cannot write into another workspace';
end $$;
select pg_temp.check('trainer cannot list webhooks (owner only)', (select count(*) from webhooks), 0);

-- owner
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select pg_temp.check('owner lists webhooks', (select count(*) from webhooks), 1);
do $$ begin
  perform secret from webhooks;
  raise exception 'FAIL owner could read webhook secret via API';
exception when insufficient_privilege then raise notice 'ok  webhook secret not readable via API';
end $$;

-- owner of B
select pg_temp.as_user('00000000-0000-0000-0000-00000000000e');
select pg_temp.check('B owner sees only B event', (select count(*) from events), 1);

-- anonymous
reset role; set role anon;
select pg_temp.as_user('');
select pg_temp.check('anon sees no events (public reads go through the API)', (select count(*) from events), 0);
reset role;
\echo ALL RLS TESTS PASSED
