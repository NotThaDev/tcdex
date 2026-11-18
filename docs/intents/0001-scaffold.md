# INTENT 0001 — Scaffold of web, mobile and Supabase

| Field | Value |
|---|---|
| Status | `in review` |
| Type | `chore` |
| Areas | `web` · `mobile` · `db` |
| Feature README | — (prerequisite of F1–F8) |
| Branch | `chore/0001-scaffold` |
| PR | #… |

---

## 1. Why
The repo contains only documentation and skills. Before developing any feature, working projects are needed for web, mobile and backend, with the quality commands from the README passing. Without this base, every feature PR would also have to do setup, and it would become impossible to review.

## 2. What (scope)
Nothing changes for the end user: empty apps are started with the structure described in the skills.

**Included**
- `supabase/`: `supabase init`, `collection` migration (table, index, RLS, `updated_at` trigger) as per the `supabase-backend` skill, empty `seed.sql`, pgTAP RLS tests.
- `web/`: Nuxt 4 project with **bun**, modules `@nuxtjs/supabase`, `@nuxtjs/i18n` (it/en), `@nuxt/eslint`, `@nuxt/test-utils` (`@pinia/nuxt` and `@nuxt/image` arrive with F1, when they are needed); TypeScript strict; a placeholder `index.vue` page, translated; `.env.example`; a sample Vitest unit test; generated `database.types.ts`.
- `mobile/`: Flutter project (`com.notthadev.tcdex`, Android + iOS) with only the dependencies used by the scaffold (flutter_riverpod, riverpod_annotation/generator, build_runner, go_router, supabase_flutter, flutter_localizations, intl, very_good_analysis; dio/freezed/cached_network_image/mocktail arrive with F1), `main.dart` + `app/app.dart` + `app/router.dart` + `core/env.dart`, l10n it/en with a localized placeholder screen, `env/dev.example.json`, one widget test.
- GitHub Actions CI: one workflow with three jobs (db, web, mobile) that run the quality commands from the README.

**Excluded**
- Any TCGdex call, catalog pages, auth UI, collection (F1–F8).
- Playwright and e2e tests (they arrive with F1, when there is a page to test).
- Remote Supabase project, deploy, `supabase db push`.
- Edge Functions.
- Flutter platforms other than Android and iOS (web, desktop).

## 3. Acceptance criteria
- [ ] AC1 — Given a clean clone, when I run `supabase start && supabase db reset && supabase test db`, then the migration applies and the RLS tests pass (a user neither sees nor inserts rows of another user).
- [ ] AC2 — Given `web/.env` filled in from the example, when I run `bun run lint && bun run typecheck && bun run test && bun run build` in `web/`, then all commands pass.
- [ ] AC3 — When I open `http://localhost:3000` and `/en` with `bun run dev`, then I see the placeholder text in Italian and in English respectively, with no console errors.
- [ ] AC4 — When I run `dart format --set-exit-if-changed . && flutter analyze && flutter test` in `mobile/`, then all commands pass.
- [ ] AC5 — When I start the app on an emulator with `flutter run --dart-define-from-file=env/dev.json`, then I see the localized placeholder screen and Supabase initializes without errors. (Manual check; on an Android emulator the local URL is `http://10.0.2.2:54321`.)
- [ ] AC6 — When I open a PR, then the CI runs the three jobs and they are green.

## 4. Technical design
- **Data / schema**: `supabase/migrations/<ts>_collection.sql` = template of the `supabase-backend` skill (table `collection`, index `(user_id, set_id)`, 4 policies, trigger). Tests: `supabase/tests/collection_rls.test.sql`.
- **APIs used**: no TCGdex call. Supabase only as client initialization.
- **Web**: `nuxt.config.ts` as per the `nuxt-web` skill (section "Base config"); `app/app.vue`, `app/pages/index.vue`, `i18n/locales/{it,en}.json`, `shared/types/database.types.ts`, `tests/unit/`. Package manager: bun (`bun install`, scripts in `package.json`: `dev`, `build`, `lint`, `typecheck`, `test` → vitest).
- **Mobile**: `lib/{app,core,features}` structure of the `flutter-mobile` skill; for now no feature, only a `HomeScreen` placeholder in `app/`. Riverpod codegen configured (`build_runner`), even though there is not yet a generated provider beyond the router's one.
- **Web/mobile parity**: yes, both scaffolded in this PR.
- **Discarded alternatives**:
  - pnpm → replaced by bun at the user's request.
  - `collection` migration in a separate PR → the README allows putting it at the start of the first PR; without at least one table, `supabase test db` and type generation make no sense.
  - Monorepo tool (Turborepo/Nx) → not needed with two apps on different stacks.

## 5. Risks and impacts
- Security / RLS: RLS active from the first migration; only the anon key in the clients; `.env` and `mobile/env/*.json` in `.gitignore`.
- Performance: n/a.
- Breaking change / data migration: none (new repo).
- New dependencies: all those listed in the `nuxt-web` and `flutter-mobile` skills, at the latest stable versions. Local toolchain: bun 1.3.8, Supabase CLI 3.1.0, Flutter stable (Homebrew).
- CI: `supabase start` in GitHub Actions requires Docker (available on `ubuntu-latest`); the db job will be the slowest (~2–3 min).

## 6. Plan
| # | Step | Area | Model | Done |
|---|---|---|---|---|
| 1 | Complete `.gitignore` (env, `.nuxt`, `.output`, `.dart_tool`, `build/`, `supabase/.temp`); `supabase init`, `collection` migration, empty `seed.sql`, pgTAP tests from the skill; `db reset` + `test db` green; Supabase stays running | db | Haiku | ☑ |
| 2 | Nuxt 4 with bun. Scripts: `postinstall`/`lint`/`typecheck` preceded by `nuxt prepare`, `test: vitest run`; `typeCheck: false` in config (typecheck only from the script); `supabase.redirect: false` until F5; `.env.example` with local values; `vitest.config.ts` with `defineVitestConfig`; test on a pure util; generated and committed `database.types.ts`. No Playwright, stores, or pages beyond `index.vue` | web | Haiku | ☑ |
| 3 | `flutter create --org com.notthadev --project-name tcdex --platforms android,ios mobile`; minimal deps; `analysis_options` with very_good_analysis (generated files excluded, `public_member_api_docs: false`); l10n in `lib/l10n`; `router.dart` with a `@riverpod` provider; widget test on `App` without `Supabase.initialize`; `env/dev.example.json` | mobile | Haiku | ☑ |
| 4 | `.github/workflows/ci.yml`: db (`supabase/setup-cli`, start, reset, test), web (`setup-bun` 1.3.8, dummy `.env`, 4 commands), mobile (`flutter-action` stable, pub get, build_runner, 3 commands); `permissions: contents: read`, `concurrency` | repo | Haiku | ☑ |
| 5 | README: `mobile/lib/l10n` tree, setup with bun, Android emulator URL note | docs | Haiku | ☑ |

Steps 2 and 3 run in parallel after step 1. Commit per step: `chore(db)`, `chore(web)`, `chore(mobile)`, `chore(repo)`, `docs`.
AC3 and AC5 are tested in verification (browser / manual); AC6 at the first CI run on the PR.

Plan validation (Sonnet): ☑ OK with changes · notes: Nuxt script and config made explicit, deps reduced (YAGNI), `.gitignore` brought forward, AC3/AC5/AC6 assigned to verification.

---

## 7. Verification (when the work is finished)

| Check | Command / action | Result |
|---|---|---|
| DB | `supabase db reset && supabase test db` | ☑ 3/3 |
| Web | `bun run lint && bun run typecheck && bun run test && bun run build` | ☑ (2 tests) |
| Mobile | `dart format --set-exit-if-changed . && flutter analyze && flutter test` | ☑ (2 tests) |
| Browser check | AC3 | ☑ `/` → "Catalogo in arrivo", `/en` → "Catalog coming soon", no console errors |
| Mobile check | AC5 | ☐ manual check in review |

Notes, screenshots, problems found: local Node 25.5 is outside the range supported by Nuxt (warning, not blocking). AC6 to be confirmed at the PR's first CI run.

## 8. Outcome
- What was actually done (differences from the plan): as per the plan. TypeScript pinned to `~5.9` in web (7.x breaks typescript-eslint and `nuxt typecheck`). Mobile l10n in `lib/l10n`.
- Technical debt left (with TODO or linked issue): unblock TypeScript 7 once typescript-eslint/vue-tsc support it.
- Follow-up: F1 (catalog) with `@pinia/nuxt`, `@nuxt/image`, Playwright, dio/freezed.
