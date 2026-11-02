-- M1: workspace and membership RPCs (SPEC §5.1), schema guards, logo storage, account deletion.
-- Users: oA owner A, tA trainer A, mA member A (in group G), nu new user, oB owner B, del member A who deletes the account.
begin;
create extension if not exists pgtap with schema extensions;
select plan(68);

-- ───────────────────────── fixtures (as postgres) ─────────────────────────
insert into auth.users (id, email, raw_user_meta_data) values
 ('00000000-0000-0000-0001-0000000000a1', 'oa@m1.test', '{"full_name":"Owner A"}'),
 ('00000000-0000-0000-0001-0000000000a2', 'ta@m1.test', '{"full_name":"Trainer A"}'),
 ('00000000-0000-0000-0001-0000000000a3', 'ma@m1.test', '{"full_name":"Member A"}'),
 ('00000000-0000-0000-0001-0000000000a4', 'nu@m1.test', '{"full_name":"New User"}'),
 ('00000000-0000-0000-0001-0000000000a5', 'del@m1.test', '{"full_name":"Leaving Member"}'),
 ('00000000-0000-0000-0001-0000000000b1', 'ob@m1.test', '{"full_name":"Owner B"}');

insert into workspaces (id, slug, name, join_code, require_approval) values
 ('aaaaaaaa-0000-0000-0001-000000000001', 'm1-a', 'Studio A', 'CODEAAAA', true),
 ('bbbbbbbb-0000-0000-0001-000000000001', 'm1-b', 'Studio B', 'CODEBBBB', false);
insert into memberships (workspace_id, user_id, role, status) values
 ('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a1', 'owner',   'active'),
 ('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a2', 'trainer', 'active'),
 ('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a3', 'member',  'active'),
 ('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a5', 'member',  'active'),
 ('bbbbbbbb-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000b1', 'owner',   'active');
insert into groups (id, workspace_id, name) values
 ('99999999-0000-0000-0001-000000000001', 'aaaaaaaa-0000-0000-0001-000000000001', 'G'),
 ('99999999-0000-0000-0001-000000000002', 'aaaaaaaa-0000-0000-0001-000000000001', 'Unused'),
 ('99999999-0000-0000-0001-0000000000b1', 'bbbbbbbb-0000-0000-0001-000000000001', 'B group');
insert into group_members (group_id, user_id, workspace_id) values
 ('99999999-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a3', 'aaaaaaaa-0000-0000-0001-000000000001');
insert into events (workspace_id, title, starts_at, ends_at, group_ids) values
 ('aaaaaaaa-0000-0000-0001-000000000001', 'Open class', now() + interval '1 day', now() + interval '1 day 1 hour', '{}'),
 ('aaaaaaaa-0000-0000-0001-000000000001', 'G class',    now() + interval '2 day', now() + interval '2 day 1 hour',
  '{99999999-0000-0000-0001-000000000001}');
insert into attendance_log (event_id, user_id, workspace_id, new_present, changed_by)
select id, '00000000-0000-0000-0001-0000000000a3', workspace_id, true, '00000000-0000-0000-0001-0000000000a5'
from events where title = 'Open class';

create function pg_temp.login(u uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
$$;
grant execute on function pg_temp.login(uuid) to authenticated, anon;

-- ───────────────────────── anon ─────────────────────────
set local role anon;
select throws_ok($$ select create_workspace('X', 'x-studio') $$, '42501', null, 'anon cannot call create_workspace');
select throws_ok($$ select join_workspace('CODEAAAA') $$, '42501', null, 'anon cannot call join_workspace');
select throws_ok($$ select private.fail('x') $$, '42501', null, 'private schema is not reachable');
reset role;
set local role authenticated;

-- ───────────────────────── create_workspace ─────────────────────────
select pg_temp.login('00000000-0000-0000-0001-0000000000a4');
select isnt(create_workspace('New Studio', 'New-Studio', 'yoga'), null, 'a signed-in user creates a workspace');
select results_eq($$ select slug, role::text, status::text from my_memberships() $$,
  $$ values ('new-studio', 'owner', 'active') $$, 'creator is the active owner; slug is lower-cased');
select is((select count(*)::int from workspaces where slug = 'new-studio'), 1, 'creator can read the new workspace');
select ok((select join_code ~ '^[A-HJ-KM-NP-Z2-9]{8}$' from workspaces where slug = 'new-studio'),
  'new join codes use 8 look-alike-free characters');
select throws_ok($$ select create_workspace('Dup', 'm1-a') $$, 'P0001', 'slug_taken', 'slug must be unique');
select throws_ok($$ select create_workspace('Bad', 'a!') $$, 'P0001', 'slug_invalid', 'slug must match the pattern');
select throws_ok($$ select create_workspace('Bad', 'join') $$, 'P0001', 'slug_reserved', 'route names are reserved');
select throws_ok($$ select create_workspace('X', 'xyz-studio') $$, 'P0001', 'name_invalid', 'name needs 2+ characters');
select throws_ok($$ select create_workspace('Tz', 'tz-studio', 'other', 'Mars/Olympus') $$, 'P0001', 'timezone_invalid',
  'timezone must be an IANA zone');

-- ───────────────────────── preview + join ─────────────────────────
select results_eq($$ select name, require_approval, my_status::text from workspace_preview(' codeaaaa ') $$,
  $$ values ('Studio A', true, null::text) $$, 'preview shows the workspace for a valid code (trimmed, any case)');
select is_empty($$ select * from workspace_preview('NOPE1234') $$, 'preview is empty for an unknown code');
select throws_ok($$ select join_workspace('NOPE1234') $$, 'P0001', 'invalid_code', 'unknown code is rejected');
select is(join_workspace('codeaaaa')::text, 'pending', 'joining a workspace that requires approval → pending');
select is(join_workspace('CODEAAAA')::text, 'pending', 'joining again is idempotent');
select is((select status::text from my_memberships() where slug = 'm1-a'), 'pending', 'pending user sees the request in my_memberships');
select is((select count(*)::int from workspaces where slug = 'm1-a'), 0, 'pending user cannot read the workspace row');
select is((select count(*)::int from events where workspace_id = 'aaaaaaaa-0000-0000-0001-000000000001'), 0,
  'pending user sees no events');
select is(join_workspace('CODEBBBB')::text, 'active', 'joining a workspace without approval → active');

-- ───────────────────────── approve / block / remove ─────────────────────────
select pg_temp.login('00000000-0000-0000-0001-0000000000a3');
select throws_ok($$ select approve_member('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a4') $$,
  'P0001', 'forbidden', 'a member cannot approve');
select throws_ok($$ select workspace_members('aaaaaaaa-0000-0000-0001-000000000001') $$,
  'P0001', 'forbidden', 'a member cannot list members with e-mails');

select pg_temp.login('00000000-0000-0000-0001-0000000000b1');
select throws_ok($$ select approve_member('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a4') $$,
  'P0001', 'forbidden', 'owner of B cannot approve in A');
select throws_ok($$ select workspace_members('aaaaaaaa-0000-0000-0001-000000000001') $$,
  'P0001', 'forbidden', 'owner of B cannot list A members');
select throws_ok($$ select regenerate_join_code('aaaaaaaa-0000-0000-0001-000000000001') $$,
  'P0001', 'forbidden', 'owner of B cannot regenerate A''s code');

select pg_temp.login('00000000-0000-0000-0001-0000000000a2');
select lives_ok($$ select approve_member('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a4') $$,
  'trainer approves a pending member');
select results_eq($$ select email, status::text from workspace_members('aaaaaaaa-0000-0000-0001-000000000001') where email = 'nu@m1.test' $$,
  $$ values ('nu@m1.test', 'active') $$, 'trainer sees the member with e-mail, now active');
select is((select group_ids from workspace_members('aaaaaaaa-0000-0000-0001-000000000001') where email = 'ma@m1.test'),
  '{99999999-0000-0000-0001-000000000001}'::uuid[], 'member list includes group ids');
select throws_ok($$ select block_member('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a1') $$,
  'P0001', 'forbidden', 'a trainer cannot act on an owner');
select throws_ok($$ select remove_member('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a2') $$,
  'P0001', 'cannot_target_self', 'a trainer cannot remove themselves this way');
select throws_ok($$ select set_member_role('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a3', 'trainer') $$,
  'P0001', 'forbidden', 'a trainer cannot change roles');
select throws_ok($$ select regenerate_join_code('aaaaaaaa-0000-0000-0001-000000000001') $$,
  'P0001', 'forbidden', 'a trainer cannot regenerate the join code');
select lives_ok($$ select block_member('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a3') $$,
  'trainer blocks a member');
select is((select count(*)::int from group_members where user_id = '00000000-0000-0000-0001-0000000000a3'), 0,
  'blocking removes group memberships');

select pg_temp.login('00000000-0000-0000-0001-0000000000a3');
select is((select count(*)::int from workspaces), 0, 'a blocked member cannot read the workspace');
select is((select count(*)::int from events), 0, 'a blocked member sees no events');
select is_empty($$ select * from my_memberships() $$, 'blocked memberships are hidden from my_memberships');
select throws_ok($$ select join_workspace('CODEAAAA') $$, 'P0001', 'blocked', 'a blocked member cannot re-join');

select pg_temp.login('00000000-0000-0000-0001-0000000000a2');
select lives_ok($$ select approve_member('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a3') $$,
  'approving a blocked member unblocks them');
select lives_ok($$ select remove_member('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a4') $$,
  'trainer removes a member');

select pg_temp.login('00000000-0000-0000-0001-0000000000a4');
select is((select count(*)::int from my_memberships() where slug = 'm1-a'), 0, 'removed member no longer has the membership');

-- ───────────────────────── roles and ownership ─────────────────────────
select pg_temp.login('00000000-0000-0000-0001-0000000000a1');
select throws_ok($$ select set_member_role('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a1', 'member') $$,
  'P0001', 'last_owner', 'the last owner cannot demote themselves');
select throws_ok($$ select leave_workspace('aaaaaaaa-0000-0000-0001-000000000001') $$,
  'P0001', 'last_owner', 'the last owner cannot leave');
select is((select is_last_owner from my_memberships() where slug = 'm1-a'), true, 'my_memberships flags the last owner');
select lives_ok($$ select set_member_role('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a2', 'owner') $$,
  'owner promotes the trainer to owner');
select lives_ok($$ select set_member_role('aaaaaaaa-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000a1', 'trainer') $$,
  'with a second owner, the first owner can step down (ownership transfer)');

select pg_temp.login('00000000-0000-0000-0001-0000000000a2');
select ok((select join_code from workspaces where slug = 'm1-a') = 'CODEAAAA', 'code before regeneration');
select isnt(regenerate_join_code('aaaaaaaa-0000-0000-0001-000000000001'), 'CODEAAAA', 'the new owner regenerates the join code');
select throws_ok($$ select join_workspace('CODEAAAA') $$, 'P0001', 'invalid_code', 'the old code stops working');

-- ───────────────────────── settings columns ─────────────────────────
select throws_ok($$ update workspaces set slug = 'hijack' where slug = 'm1-a' $$, '42501', null, 'slug is not writable');
select throws_ok($$ update workspaces set join_code = 'AAAAAAAA' where slug = 'm1-a' $$, '42501', null, 'join_code is not writable');
select throws_ok($$ update workspaces set timezone = 'Mars/Olympus' where slug = 'm1-a' $$, 'P0001', 'timezone_invalid',
  'settings reject an invalid timezone');
with u as (update workspaces set name = 'Studio A+', timezone = 'Europe/Ljubljana' where slug = 'm1-a' returning 1)
select is(count(*)::int, 1, 'owner updates name and timezone') from u;

-- ───────────────────────── groups ─────────────────────────
select throws_ok($$ insert into group_members (group_id, user_id, workspace_id) values
  ('99999999-0000-0000-0001-000000000001', '00000000-0000-0000-0001-0000000000b1', 'aaaaaaaa-0000-0000-0001-000000000001') $$,
  '23503', null, 'only members of the workspace can be added to a group');
select throws_ok($$ insert into group_members (group_id, user_id, workspace_id) values
  ('99999999-0000-0000-0001-0000000000b1', '00000000-0000-0000-0001-0000000000a3', 'aaaaaaaa-0000-0000-0001-000000000001') $$,
  '23503', null, 'a group of another workspace cannot be used');
select throws_ok($$ delete from groups where id = '99999999-0000-0000-0001-000000000001' $$, 'P0001', 'group_in_use',
  'a group used by upcoming events cannot be deleted');
with d as (delete from groups where id = '99999999-0000-0000-0001-000000000002' returning 1)
select is(count(*)::int, 1, 'an unused group can be deleted') from d;

-- ───────────────────────── logo storage ─────────────────────────
select lives_ok($$ insert into storage.objects (bucket_id, name) values
  ('workspace-logos', 'aaaaaaaa-0000-0000-0001-000000000001/logo-1.png') $$, 'owner uploads a logo into their folder');
select pg_temp.login('00000000-0000-0000-0001-0000000000a1');  -- now a trainer
select throws_ok($$ insert into storage.objects (bucket_id, name) values
  ('workspace-logos', 'aaaaaaaa-0000-0000-0001-000000000001/logo-2.png') $$, '42501', null, 'a trainer cannot upload logos');
select pg_temp.login('00000000-0000-0000-0001-0000000000b1');
select throws_ok($$ insert into storage.objects (bucket_id, name) values
  ('workspace-logos', 'aaaaaaaa-0000-0000-0001-000000000001/logo-3.png') $$, '42501', null, 'owner of B cannot upload into A''s folder');
select throws_ok($$ insert into storage.objects (bucket_id, name) values
  ('workspace-logos', 'not-a-uuid/logo.png') $$, '42501', null, 'malformed folders are rejected');

-- ───────────────────────── delete account ─────────────────────────
select throws_ok($$ select delete_my_account('wrong@m1.test') $$, 'P0001', 'confirm_mismatch', 'deletion needs the own e-mail');
select throws_ok($$ select delete_my_account('OB@m1.test') $$, 'P0001', 'last_owner', 'the last owner of a workspace cannot delete the account');
select pg_temp.login('00000000-0000-0000-0001-0000000000a5');
select lives_ok($$ select delete_my_account(' DEL@m1.test ') $$, 'a member deletes their account');

reset role;
select is((select count(*)::int from auth.users where id = '00000000-0000-0000-0001-0000000000a5'), 0, 'auth user is gone');
select is((select count(*)::int from profiles where id = '00000000-0000-0000-0001-0000000000a5'), 0, 'profile cascades');
select is((select count(*)::int from attendance_log where changed_by is null and user_id = '00000000-0000-0000-0001-0000000000a3'), 1,
  'attendance_log.changed_by is anonymised, the history stays');

select * from finish();
rollback;
