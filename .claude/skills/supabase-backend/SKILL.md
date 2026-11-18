---
name: supabase-backend
description: Rules for the Pokédex TCG Supabase backend — SQL migrations, Row Level Security, indexes, triggers, pgTAP tests, Edge Functions and type generation. Use for any change to supabase/ or to the data schema.
---

# Supabase backend

## Principles
- **The schema exists only in migrations** (`supabase/migrations/`). Never modify the schema from Studio without then generating the migration.
- **RLS enabled on every table in `public`**, no exceptions. A table without policies is not readable by clients, and that is the intended behavior.
- Clients use only the public key (anon/publishable). The secret/service role key is used only inside Edge Functions or server routes.
- Supabase holds the user data; the card catalog stays on TCGdex (see `tcgdex-data`).

## Commands
```bash
supabase migration new <slug>          # creates supabase/migrations/<ts>_<slug>.sql
supabase db reset                      # recreates the local DB: migrations + seed
supabase test db                       # runs the pgTAP tests in supabase/tests
supabase db diff -f <slug>             # generates a migration from changes made in Studio
supabase gen types typescript --local > web/shared/types/database.types.ts
supabase functions serve <name>        # Edge Function locally
supabase db push                       # applies migrations to the remote project (only after merge)
```

## Migration template
```sql
-- <ts>_collection.sql
create table public.collection (
  id         bigint generated always as identity primary key,
  user_id    uuid not null default auth.uid() references auth.users on delete cascade,
  card_id    text not null,
  set_id     text not null,
  lang       text not null default 'en' check (lang in ('it','en')),
  variant    text not null default 'normal'
             check (variant in ('normal','reverse','holo','firstEdition')),
  quantity   int  not null default 1 check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, card_id, lang, variant)
);

create index collection_user_set_idx on public.collection (user_id, set_id);

alter table public.collection enable row level security;

-- One policy per operation: more readable and easier to test
create policy "collection_select_own" on public.collection
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "collection_insert_own" on public.collection
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "collection_update_own" on public.collection
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "collection_delete_own" on public.collection
  for delete to authenticated using ((select auth.uid()) = user_id);

-- automatic updated_at
create or replace function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

create trigger collection_set_updated_at before update on public.collection
  for each row execute function public.set_updated_at();
```

## Best practices
- `(select auth.uid())` must be wrapped in parentheses in policies: Postgres evaluates it once per query and not once per row.
- Index the columns used in policies and filters (`user_id`, `set_id`).
- Functions have `set search_path = ''` and use qualified names (`public.x`). `security definer` only when really needed, justified in the intent.
- Use constraints (`check`, `unique`, `not null`) for data integrity, not client-side validation.
- "Add or increment" operations are done with `upsert` on the unique key (`onConflict: 'user_id,card_id,lang,variant'`).
- An already merged migration is never modified again: create a new migration.
- Destructive migrations (drop, rename, type changes) must be declared in the "Risks" section of the intent.

## pgTAP tests (mandatory for every new table or policy)
```sql
-- supabase/tests/collection_rls.test.sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

-- fake users
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
select is((select count(*) from public.collection)::int, 1, 'A sees their own card');

select * from finish();
rollback;
```

## Edge Functions (Deno/TypeScript)
- One function per folder: `supabase/functions/<name>/index.ts`; shared code goes in `supabase/functions/_shared/`.
- Validate the input (for example with zod) and always respond in JSON with correct statuses.
- If acting on behalf of the user, create the client with the request's `Authorization` header, so RLS stays active. The service role is used only for system jobs (for example a price cache cron).
- Secrets via `supabase secrets set`, never in code.

## Checklist
- [ ] Migration created with the CLI, clean `db reset`
- [ ] RLS enabled and one policy for each required operation
- [ ] pgTAP tests for allowed and denied access
- [ ] TS types regenerated and committed
- [ ] Dart model updated on mobile (if the schema changes)
