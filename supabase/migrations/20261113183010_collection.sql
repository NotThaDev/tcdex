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

create policy "collection_select_own" on public.collection
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "collection_insert_own" on public.collection
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "collection_update_own" on public.collection
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "collection_delete_own" on public.collection
  for delete to authenticated using ((select auth.uid()) = user_id);

create or replace function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

create trigger collection_set_updated_at before update on public.collection
  for each row execute function public.set_updated_at();
