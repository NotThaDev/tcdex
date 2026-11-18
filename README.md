# Pokédex TCG

App "Pokédex" for the Pokémon Trading Card Game cards: full catalog, advanced filters, market prices and a personal Collection synced between mobile and web.

| Part | Stack | Folder |
|---|---|---|
| Mobile | Flutter (Dart 3) · Riverpod 3 · go_router · supabase_flutter | `mobile/` |
| Web | Nuxt 4 (Vue 3, TypeScript) · Pinia · @nuxtjs/supabase v2 · @nuxtjs/i18n | `web/` |
| Backend | Supabase: Postgres + RLS, Auth, Edge Functions (Deno/TS) | `supabase/` |
| Card data | [TCGdex](https://tcgdex.dev) REST API v2 (public, no key, IT + EN, prices included) | — |

---

## Architecture

```
┌──────────────┐        ┌──────────────┐
│ mobile/      │        │ web/         │
│ Flutter      │        │ Nuxt 4       │
└──┬────────┬──┘        └──┬────────┬──┘
   │        │              │        │
   │  catalog, sets, prices (read-only)
   │        └──────┬───────┘        │
   │               ▼                │
   │        api.tcgdex.net/v2/{it|en}
   │                                │
   │  auth + Collection (read/write, RLS)
   └──────────────┬─────────────────┘
                  ▼
           Supabase (Postgres)
```

Architecture rules:

1. **TCGdex is the source of truth for the catalog.** We do not copy the catalog into Supabase. If a cache is needed (for example prices to compute the Estimated value of the Collection), an Edge Function will handle it, never the clients.
2. **Supabase holds only user data**: the Collection and, in the future, preferences and wishlist.
3. **TCGdex's `card_id` (e.g. `swsh3-136`) is the key that links the two worlds.** It is the same in all languages.
4. **No security logic in clients.** Every access to user data is protected by RLS on the Postgres side.
5. **Mobile and web have the same features and the same data model.** A feature is not finished until it exists on both, or until the INTENT explicitly says otherwise.

---

## Repository structure

```
pokedex-tcg/
├── README.md                     # this file
├── docs/
│   ├── intents/
│   │   ├── _TEMPLATE.md          # INTENT template, copy before every PR
│   │   └── 0001-<slug>.md        # one file per PR
│   └── decisions/                # short ADRs for architectural choices
├── .claude/
│   └── skills/
│       ├── pr-intent/            # PR workflow: intent → plan → implementation → verification
│       ├── clear-description/    # PR descriptions: fixed sections, Mermaid diagrams, live checklist
│       ├── supabase-backend/     # migrations, RLS, Edge Functions, types
│       ├── tcgdex-data/          # how to use TCGdex (endpoints, languages, prices, images)
│       ├── nuxt-web/             # web structure and best practices
│       └── flutter-mobile/       # mobile structure and best practices
├── .github/
│   └── pull_request_template.md
├── supabase/
│   ├── config.toml
│   ├── migrations/               # versioned SQL: single source of truth for the schema
│   ├── seed.sql                  # local development data
│   ├── functions/                # Edge Functions (Deno)
│   └── tests/                    # pgTAP tests (RLS and constraints)
├── web/                          # Nuxt 4 (see nuxt-web skill)
│   ├── app/
│   ├── server/
│   ├── i18n/locales/{it,en}.json
│   ├── shared/types/             # TCGdex types + generated database.types.ts
│   └── tests/
└── mobile/                       # Flutter (see flutter-mobile skill)
    ├── lib/
    │   ├── app/
    │   ├── core/
    │   ├── features/<feature>/{data,domain,presentation}/
    │   └── l10n/                 # ARB files it/en
    ├── env/dev.example.json
    └── test/
```

---

## Features (MVP)

| # | Feature | Web | Mobile |
|---|---|---|---|
| F1 | Catalog: set list, cards per set, card details | ☐ | ☐ |
| F2 | Search and filters: name, type, rarity, illustrator, set | ☐ | ☐ |
| F3 | Data language IT/EN, with EN fallback if the card is not available in IT | ☐ | ☐ |
| F4 | Cardmarket (EUR) and TCGplayer (USD) prices in the details | ☐ | ☐ |
| F5 | Supabase Auth (email + magic link) | ☐ | ☐ |
| F6 | Collection: add/remove, quantity, variant, language of the physical card | ☐ | ☐ |
| F7 | Progress per set (owned / total) | ☐ | ☐ |
| F8 | Estimated value of the Collection (requires price cache) | ☐ | ☐ |

---

## Data model (Supabase)

```sql
-- supabase/migrations/<timestamp>_collection.sql
create table public.collection (
  id         bigint generated always as identity primary key,
  user_id    uuid not null default auth.uid() references auth.users on delete cascade,
  card_id    text not null,                 -- TCGdex id, e.g. "swsh3-136"
  set_id     text not null,                 -- e.g. "swsh3", for progress per set
  lang       text not null default 'en' check (lang in ('it','en')),
  variant    text not null default 'normal'
             check (variant in ('normal','reverse','holo','firstEdition')),
  quantity   int  not null default 1 check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, card_id, lang, variant)
);
```

The full schema, with RLS, indexes and triggers, is defined **only** through migrations (see `supabase-backend` skill).

---

## Local setup

Prerequisites: Node 22 LTS or higher, Bun, Flutter stable, Docker and Supabase CLI.

```bash
# 1. Local backend
supabase start                 # starts Postgres, Auth and Studio in Docker
supabase db reset              # applies migrations and seed.sql
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
cp env/dev.example.json env/dev.json  # then insert the key
flutter run --dart-define-from-file=env/dev.json
```

### Environment variables

| Where | Variable | Notes |
|---|---|---|
| web/.env | `SUPABASE_URL`, `SUPABASE_KEY` | public key only (anon/publishable) |
| web/.env | `SUPABASE_SECRET_KEY` | only if a server route must bypass RLS; never exposed to the client |
| mobile/env/*.json | `SUPABASE_URL`, `SUPABASE_KEY` | passed with `--dart-define-from-file`; file in `.gitignore` |

No secrets should be committed. The only env files in the repo are `web/.env.example` and `mobile/env/dev.example.json`: copy them to `web/.env` and `mobile/env/dev.json` and insert the publishable key from `supabase status`.

On an Android emulator `127.0.0.1` points to the emulator itself: in `mobile/env/dev.json` use `SUPABASE_URL=http://10.0.2.2:54321`. On an iOS simulator `http://127.0.0.1:54321` works.

---

## Quality commands

A PR is opened only if **all** of these commands pass.

| Area | Command |
|---|---|
| Supabase | `supabase db reset && supabase test db` |
| Web | `bun run lint && bun run typecheck && bun run test && bun run build` |
| Mobile | `dart format --set-exit-if-changed . && flutter analyze && flutter test` |

If the change touches the frontend, even indirectly through an endpoint or RLS, test it in the browser for web and on an emulator or device for mobile.

---

## Development workflow

1. **Intent**: copy `docs/intents/_TEMPLATE.md` to `docs/intents/NNNN-slug.md` and fill it in. No code before the intent is approved.
2. **Branch**: `feat/NNNN-slug`, `fix/NNNN-slug`, `chore/NNNN-slug`.
3. **Plan** (Opus) → **plan validation** (Sonnet) → **implementation** (Haiku, also with subagents). Details in the `pr-intent` skill.
4. **Verification**: quality commands plus manual testing, with results reported in the intent.
5. **PR**: title in Conventional Commits; the description refers to the intent.

### Conventions

- **Commit**: Conventional Commits (`feat(web): filters by rarity`, `fix(mobile): …`, `chore(db): …`). Possible scopes: `web`, `mobile`, `db`, `fn`, `docs`, `repo`.
- **Language**: code, names and comments in English; documentation and intents in English; UI in IT and EN via i18n.
- **One PR does one thing.** Migrations go in separate PRs or at the start of the feature PR, never in the middle.
