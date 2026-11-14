# Pokédex TCG

App "Pokédex" per le carte del Pokémon Trading Card Game: catalogo completo, filtri avanzati, prezzi di mercato e collezione personale sincronizzata tra mobile e web.

| Parte | Stack | Cartella |
|---|---|---|
| Mobile | Flutter (Dart 3) · Riverpod 3 · go_router · supabase_flutter | `mobile/` |
| Web | Nuxt 4 (Vue 3, TypeScript) · Pinia · @nuxtjs/supabase v2 · @nuxtjs/i18n | `web/` |
| Backend | Supabase: Postgres + RLS, Auth, Edge Functions (Deno/TS) | `supabase/` |
| Dati carte | [TCGdex](https://tcgdex.dev) REST API v2 (pubblica, senza chiave, IT + EN, prezzi inclusi) | — |

---

## Architettura

```
┌──────────────┐        ┌──────────────┐
│ mobile/      │        │ web/         │
│ Flutter      │        │ Nuxt 4       │
└──┬────────┬──┘        └──┬────────┬──┘
   │        │              │        │
   │  catalogo, set, prezzi (sola lettura)
   │        └──────┬───────┘        │
   │               ▼                │
   │        api.tcgdex.net/v2/{it|en}
   │                                │
   │  auth + collezione (lettura/scrittura, RLS)
   └──────────────┬─────────────────┘
                  ▼
           Supabase (Postgres)
```

Regole architetturali:

1. **TCGdex è la fonte di verità del catalogo.** Non copiamo il catalogo in Supabase. Se servirà una cache (per esempio i prezzi per calcolare il valore della collezione), la gestirà una Edge Function, mai i client.
2. **Supabase contiene solo i dati dell'utente**: collezione e, in futuro, preferenze e wishlist.
3. **Il `card_id` di TCGdex (es. `swsh3-136`) è la chiave che lega i due mondi.** È uguale in tutte le lingue.
4. **Nessuna logica di sicurezza nei client.** Ogni accesso ai dati utente è protetto da RLS lato Postgres.
5. **Mobile e web hanno le stesse funzioni e lo stesso modello di dati.** Una feature non è finita finché non esiste su entrambi, oppure finché l'INTENT non dice esplicitamente il contrario.

---

## Struttura del repository

```
pokedex-tcg/
├── README.md                     # questo file
├── docs/
│   ├── intents/
│   │   ├── _TEMPLATE.md          # template INTENT, da copiare prima di ogni PR
│   │   └── 0001-<slug>.md        # un file per PR
│   └── decisions/                # ADR brevi per le scelte architetturali
├── .claude/
│   └── skills/
│       ├── pr-intent/            # workflow PR: intent → piano → implementazione → verifica
│       ├── supabase-backend/     # migration, RLS, Edge Functions, tipi
│       ├── tcgdex-data/          # come si usa TCGdex (endpoint, lingue, prezzi, immagini)
│       ├── nuxt-web/             # struttura e best practice web
│       └── flutter-mobile/       # struttura e best practice mobile
├── .github/
│   └── pull_request_template.md
├── supabase/
│   ├── config.toml
│   ├── migrations/               # SQL versionato: unica fonte dello schema
│   ├── seed.sql                  # dati di sviluppo locale
│   ├── functions/                # Edge Functions (Deno)
│   └── tests/                    # test pgTAP (RLS e vincoli)
├── web/                          # Nuxt 4 (vedi skill nuxt-web)
│   ├── app/
│   ├── server/
│   ├── i18n/locales/{it,en}.json
│   ├── shared/types/             # tipi TCGdex + database.types.ts generato
│   └── tests/
└── mobile/                       # Flutter (vedi skill flutter-mobile)
    ├── lib/
    │   ├── app/
    │   ├── core/
    │   ├── features/<feature>/{data,domain,presentation}/
    │   └── l10n/                 # file ARB it/en
    ├── env/dev.example.json
    └── test/
```

---

## Funzionalità (MVP)

| # | Feature | Web | Mobile |
|---|---|---|---|
| F1 | Catalogo: lista set, carte per set, dettaglio carta | ☐ | ☐ |
| F2 | Ricerca e filtri: nome, tipo, rarità, illustratore, set | ☐ | ☐ |
| F3 | Lingua dati IT/EN, con fallback EN se la carta non c'è in IT | ☐ | ☐ |
| F4 | Prezzi Cardmarket (EUR) e TCGplayer (USD) nel dettaglio | ☐ | ☐ |
| F5 | Auth Supabase (email + magic link) | ☐ | ☐ |
| F6 | Collezione: aggiungi/rimuovi, quantità, variante, lingua della carta fisica | ☐ | ☐ |
| F7 | Avanzamento per set (possedute / totali) | ☐ | ☐ |
| F8 | Valore stimato della collezione (richiede cache prezzi) | ☐ | ☐ |

---

## Modello dati (Supabase)

```sql
-- supabase/migrations/<timestamp>_collection.sql
create table public.collection (
  id         bigint generated always as identity primary key,
  user_id    uuid not null default auth.uid() references auth.users on delete cascade,
  card_id    text not null,                 -- id TCGdex, es. "swsh3-136"
  set_id     text not null,                 -- es. "swsh3", per l'avanzamento per set
  lang       text not null default 'en' check (lang in ('it','en')),
  variant    text not null default 'normal'
             check (variant in ('normal','reverse','holo','firstEdition')),
  quantity   int  not null default 1 check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, card_id, lang, variant)
);
```

Lo schema completo, con RLS, indici e trigger, si definisce **solo** tramite migration (vedi skill `supabase-backend`).

---

## Setup locale

Prerequisiti: Node 22 LTS o superiore, Bun, Flutter stable, Docker e Supabase CLI.

```bash
# 1. Backend locale
supabase start                 # avvia Postgres, Auth e Studio in Docker
supabase db reset              # applica le migration e seed.sql
supabase gen types typescript --local > web/shared/types/database.types.ts

# 2. Web
cd web
cp .env.example .env           # SUPABASE_URL, SUPABASE_KEY (publishable/anon)
bun install
bun run dev                       # http://localhost:3000

# 3. Mobile
cd mobile
flutter pub get
dart run build_runner build -d
cp env/dev.example.json env/dev.json  # poi inserisci la chiave
flutter run --dart-define-from-file=env/dev.json
```

### Variabili d'ambiente

| Dove | Variabile | Note |
|---|---|---|
| web/.env | `SUPABASE_URL`, `SUPABASE_KEY` | solo la chiave pubblica (anon/publishable) |
| web/.env | `SUPABASE_SECRET_KEY` | solo se una server route deve bypassare RLS; mai esposta al client |
| mobile/env/*.json | `SUPABASE_URL`, `SUPABASE_KEY` | passate con `--dart-define-from-file`; file in `.gitignore` |

Nessun segreto va committato. Gli unici file env nel repo sono `web/.env.example` e `mobile/env/dev.example.json`: copiali in `web/.env` e `mobile/env/dev.json` e inserisci la chiave publishable da `supabase status`.

Su emulatore Android `127.0.0.1` punta all'emulatore stesso: in `mobile/env/dev.json` usa `SUPABASE_URL=http://10.0.2.2:54321`. Su simulatore iOS va bene `http://127.0.0.1:54321`.

---

## Comandi di qualità

Una PR si apre solo se **tutti** questi comandi passano.

| Area | Comando |
|---|---|
| Supabase | `supabase db reset && supabase test db` |
| Web | `bun run lint && bun run typecheck && bun run test && bun run build` |
| Mobile | `dart format --set-exit-if-changed . && flutter analyze && flutter test` |

Se la modifica tocca il frontend, anche indirettamente tramite un endpoint o la RLS, va provata nel browser per il web e su emulatore o dispositivo per il mobile.

---

## Workflow di sviluppo

1. **Intent**: copia `docs/intents/_TEMPLATE.md` in `docs/intents/NNNN-slug.md` e compilalo. Nessun codice prima che l'intent sia approvato.
2. **Branch**: `feat/NNNN-slug`, `fix/NNNN-slug`, `chore/NNNN-slug`.
3. **Piano** (Opus) → **validazione del piano** (Sonnet) → **implementazione** (Haiku, anche con subagenti). Dettagli nella skill `pr-intent`.
4. **Verifica**: comandi di qualità più prova manuale, con i risultati riportati nell'intent.
5. **PR**: titolo in Conventional Commits; la descrizione rimanda all'intent.

### Convenzioni

- **Commit**: Conventional Commits (`feat(web): filtri per rarità`, `fix(mobile): …`, `chore(db): …`). Scope possibili: `web`, `mobile`, `db`, `fn`, `docs`, `repo`.
- **Lingua**: codice, nomi e commenti in inglese; documentazione e intent in italiano; UI in IT e EN tramite i18n.
- **Una PR fa una sola cosa.** Le migration vanno in PR separate o all'inizio della PR della feature, mai a metà.
