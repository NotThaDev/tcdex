begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'a@test.dev'),
  ('00000000-0000-0000-0000-00000000000b', 'b@test.dev');

insert into public.collection (user_id, card_id, set_id)
values ('00000000-0000-0000-0000-00000000000a', 'swsh3-136', 'swsh3');

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b"}';

select is((select count(*) from public.collection)::int, 0, 'B cannot see A''s cards');
select throws_ok(
  $$ insert into public.collection (user_id, card_id, set_id)
     values ('00000000-0000-0000-0000-00000000000a', 'x-1', 'x') $$,
  '42501', null, 'B cannot insert on behalf of A');

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a"}';
select is((select count(*) from public.collection)::int, 1, 'A sees own card');

select * from finish();
rollback;
