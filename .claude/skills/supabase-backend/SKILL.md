---
name: supabase-backend
description: Regole per il backend Supabase del Pokédex TCG — migration SQL, Row Level Security, indici, trigger, test pgTAP, Edge Functions e generazione dei tipi. Usare per qualsiasi modifica a supabase/ o allo schema dati.
---

# Supabase backend

## Principi
- **Lo schema esiste solo nelle migration** (`supabase/migrations/`). Mai modificare lo schema da Studio senza poi generare la migration.
- **RLS attiva su ogni tabella in `public`**, senza eccezioni. Una tabella senza policy non è leggibile dai client, ed è il comportamento voluto.
- I client usano solo la chiave pubblica (anon/publishable). La chiave segreta/service role si usa solo dentro Edge Functions o server route.
- Supabase contiene i dati utente; il catalogo carte resta su TCGdex (vedi `tcgdex-data`).

## Comandi
```bash
supabase migration new <slug>          # crea supabase/migrations/<ts>_<slug>.sql
supabase db reset                      # ricrea il DB locale: migration + seed
supabase test db                       # esegue i test pgTAP in supabase/tests
supabase db diff -f <slug>             # genera una migration dalle modifiche fatte in Studio
supabase gen types typescript --local > web/shared/types/database.types.ts
supabase functions serve <name>        # Edge Function in locale
supabase db push                       # applica le migration al progetto remoto (solo dopo il merge)
```

## Template di migration
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

-- Una policy per operazione: più leggibile e più facile da testare
create policy "collection_select_own" on public.collection
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "collection_insert_own" on public.collection
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "collection_update_own" on public.collection
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "collection_delete_own" on public.collection
  for delete to authenticated using ((select auth.uid()) = user_id);

-- updated_at automatico
create or replace function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

create trigger collection_set_updated_at before update on public.collection
  for each row execute function public.set_updated_at();
```

## Best practice
- `(select auth.uid())` va scritto tra parentesi nelle policy: Postgres lo valuta una volta per query e non una per riga.
- Indicizza le colonne usate nelle policy e nei filtri (`user_id`, `set_id`).
- Le funzioni hanno `set search_path = ''` e usano nomi qualificati (`public.x`). `security definer` solo se serve davvero, motivato nell'intent.
- Usa i vincoli (`check`, `unique`, `not null`) per l'integrità dei dati, non la validazione client.
- Le operazioni del tipo "aggiungi o incrementa" si fanno con `upsert` sulla unique key (`onConflict: 'user_id,card_id,lang,variant'`).
- Una migration già mergiata non si modifica più: si crea una nuova migration.
- Migration distruttive (drop, rename, cambi di tipo) vanno dichiarate nella sezione "Rischi" dell'intent.

## Test pgTAP (obbligatori per ogni tabella o policy nuova)
```sql
-- supabase/tests/collection_rls.test.sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

-- utenti fittizi
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'a@test.dev'),
  ('00000000-0000-0000-0000-00000000000b', 'b@test.dev');

insert into public.collection (user_id, card_id, set_id)
values ('00000000-0000-0000-0000-00000000000a', 'swsh3-136', 'swsh3');

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000b"}';

select is((select count(*) from public.collection)::int, 0, 'B non vede le carte di A');
select throws_ok(
  $$ insert into public.collection (user_id, card_id, set_id)
     values ('00000000-0000-0000-0000-00000000000a', 'x-1', 'x') $$,
  '42501', null, 'B non può inserire per conto di A');

set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a"}';
select is((select count(*) from public.collection)::int, 1, 'A vede la propria carta');

select * from finish();
rollback;
```

## Edge Functions (Deno/TypeScript)
- Una funzione per cartella: `supabase/functions/<name>/index.ts`; il codice condiviso va in `supabase/functions/_shared/`.
- Valida l'input (per esempio con zod) e rispondi sempre in JSON con status corretti.
- Se agisce per conto dell'utente, crea il client con l'header `Authorization` della richiesta, così la RLS resta attiva. Il service role si usa solo per job di sistema (per esempio un cron di cache prezzi).
- Segreti con `supabase secrets set`, mai nel codice.

## Checklist
- [ ] Migration creata con la CLI, `db reset` pulito
- [ ] RLS attiva e una policy per ogni operazione necessaria
- [ ] Test pgTAP per accesso consentito e negato
- [ ] Tipi TS rigenerati e committati
- [ ] Modello Dart aggiornato su mobile (se cambia lo schema)
