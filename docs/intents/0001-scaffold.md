# INTENT 0001 — Scaffold di web, mobile e Supabase

| Campo | Valore |
|---|---|
| Stato | `in review` |
| Tipo | `chore` |
| Aree | `web` · `mobile` · `db` |
| Feature README | — (prerequisito di F1–F8) |
| Branch | `chore/0001-scaffold` |
| PR | #… |

---

## 1. Perché
Il repo contiene solo documentazione e skill. Prima di sviluppare qualsiasi feature servono progetti funzionanti per web, mobile e backend, con i comandi di qualità del README che passano. Senza questa base ogni PR di feature dovrebbe anche fare setup, e diventerebbe impossibile da revisionare.

## 2. Cosa (scope)
Non cambia niente per l'utente finale: si avviano app vuote con la struttura descritta nelle skill.

**Incluso**
- `supabase/`: `supabase init`, migration `collection` (tabella, indice, RLS, trigger `updated_at`) come da skill `supabase-backend`, `seed.sql` vuoto, test pgTAP RLS.
- `web/`: progetto Nuxt 4 con **bun**, moduli `@nuxtjs/supabase`, `@nuxtjs/i18n` (it/en), `@nuxt/eslint`, `@nuxt/test-utils` (`@pinia/nuxt` e `@nuxt/image` arrivano con F1, quando servono); TypeScript strict; una pagina `index.vue` placeholder tradotta; `.env.example`; un test unitario Vitest di esempio; `database.types.ts` generato.
- `mobile/`: progetto Flutter (`com.notthadev.tcdex`, Android + iOS) con le sole dipendenze usate dallo scaffold (flutter_riverpod, riverpod_annotation/generator, build_runner, go_router, supabase_flutter, flutter_localizations, intl, very_good_analysis; dio/freezed/cached_network_image/mocktail arrivano con F1), `main.dart` + `app/app.dart` + `app/router.dart` + `core/env.dart`, l10n it/en con una schermata placeholder, `env/dev.example.json`, un widget test.
- CI GitHub Actions: un workflow con tre job (db, web, mobile) che eseguono i comandi di qualità del README.

**Escluso**
- Qualsiasi chiamata a TCGdex, pagine di catalogo, auth UI, collezione (F1–F8).
- Playwright e test e2e (arrivano con F1, quando c'è una pagina da provare).
- Progetto Supabase remoto, deploy, `supabase db push`.
- Edge Functions.
- Piattaforme Flutter diverse da Android e iOS (web, desktop).

## 3. Criteri di accettazione
- [ ] AC1 — Dato un clone pulito, quando eseguo `supabase start && supabase db reset && supabase test db`, allora la migration si applica e i test RLS passano (un utente non vede né inserisce righe di un altro).
- [ ] AC2 — Dato `web/.env` compilato dall'esempio, quando eseguo `bun run lint && bun run typecheck && bun run test && bun run build` in `web/`, allora tutti i comandi passano.
- [ ] AC3 — Quando apro `http://localhost:3000` e `/en` con `bun run dev`, allora vedo il testo placeholder rispettivamente in italiano e in inglese, senza errori in console.
- [ ] AC4 — Quando eseguo `dart format --set-exit-if-changed . && flutter analyze && flutter test` in `mobile/`, allora tutti i comandi passano.
- [ ] AC5 — Quando avvio l'app su emulatore con `flutter run --dart-define-from-file=env/dev.json`, allora vedo la schermata placeholder localizzata e Supabase si inizializza senza errori. (Prova manuale; su emulatore Android l'URL locale è `http://10.0.2.2:54321`.)
- [ ] AC6 — Quando apro una PR, allora la CI esegue i tre job e sono verdi.

## 4. Design tecnico
- **Dati / schema**: `supabase/migrations/<ts>_collection.sql` = template della skill `supabase-backend` (tabella `collection`, indice `(user_id, set_id)`, 4 policy, trigger). Test: `supabase/tests/collection_rls.test.sql`.
- **API usate**: nessuna chiamata TCGdex. Supabase solo come inizializzazione del client.
- **Web**: `nuxt.config.ts` come da skill `nuxt-web` (sezione "Config base"); `app/app.vue`, `app/pages/index.vue`, `i18n/locales/{it,en}.json`, `shared/types/database.types.ts`, `tests/unit/`. Package manager: bun (`bun install`, script in `package.json`: `dev`, `build`, `lint`, `typecheck`, `test` → vitest).
- **Mobile**: struttura `lib/{app,core,features}` della skill `flutter-mobile`; per ora nessuna feature, solo `HomeScreen` placeholder in `app/`. Riverpod codegen configurato (`build_runner`), anche se non c'è ancora un provider generato oltre a quello del router.
- **Parità web/mobile**: sì, entrambi scaffoldati in questa PR.
- **Alternative scartate**:
  - pnpm → sostituito da bun su richiesta dell'utente.
  - Migration `collection` in una PR separata → il README permette di metterla all'inizio della prima PR; senza almeno una tabella `supabase test db` e la generazione dei tipi non hanno senso.
  - Monorepo tool (Turborepo/Nx) → non serve con due app di stack diversi.

## 5. Rischi e impatti
- Sicurezza / RLS: RLS attiva dalla prima migration; solo chiave anon nei client; `.env` e `mobile/env/*.json` in `.gitignore`.
- Performance: n/a.
- Breaking change / migrazione dati: nessuna (repo nuovo).
- Dipendenze nuove: tutte quelle elencate nelle skill `nuxt-web` e `flutter-mobile`, alle ultime versioni stabili. Toolchain locale: bun 1.3.8, Supabase CLI 3.1.0, Flutter stable (Homebrew).
- CI: `supabase start` in GitHub Actions richiede Docker (disponibile su `ubuntu-latest`); il job db sarà il più lento (~2–3 min).

## 6. Piano
| # | Passo | Area | Modello | Fatto |
|---|---|---|---|---|
| 1 | `.gitignore` completo (env, `.nuxt`, `.output`, `.dart_tool`, `build/`, `supabase/.temp`); `supabase init`, migration `collection`, `seed.sql` vuoto, test pgTAP della skill; `db reset` + `test db` verdi; Supabase resta avviato | db | Haiku || ☑ |
| 2 | Nuxt 4 con bun. Script: `postinstall`/`lint`/`typecheck` preceduti da `nuxt prepare`, `test: vitest run`; `typeCheck: false` in config (typecheck solo da script); `supabase.redirect: false` fino a F5; `.env.example` con valori locali; `vitest.config.ts` con `defineVitestConfig`; test su una util pura; `database.types.ts` generato e committato. Niente Playwright, store, pagine oltre `index.vue` | web | Haiku || ☑ |
| 3 | `flutter create --org com.notthadev --project-name tcdex --platforms android,ios mobile`; deps minime; `analysis_options` con very_good_analysis (esclusi file generati, `public_member_api_docs: false`); l10n in `lib/l10n`; `router.dart` con un provider `@riverpod`; widget test su `App` senza `Supabase.initialize`; `env/dev.example.json` | mobile | Haiku || ☑ |
| 4 | `.github/workflows/ci.yml`: db (`supabase/setup-cli`, start, reset, test), web (`setup-bun` 1.3.8, `.env` fittizio, 4 comandi), mobile (`flutter-action` stable, pub get, build_runner, 3 comandi); `permissions: contents: read`, `concurrency` | repo | Haiku || ☑ |
| 5 | README: albero `mobile/lib/l10n`, setup con bun, nota URL emulatore Android | docs | Haiku || ☑ |

I passi 2 e 3 vanno in parallelo dopo il passo 1. Commit per passo: `chore(db)`, `chore(web)`, `chore(mobile)`, `chore(repo)`, `docs`.
AC3 e AC5 si provano nella verifica (browser / manuale); AC6 alla prima esecuzione della CI sulla PR.

Validazione del piano (Sonnet): ☑ OK con modifiche · note: script e config Nuxt resi espliciti, deps ridotte (YAGNI), `.gitignore` anticipato, AC3/AC5/AC6 assegnati alla verifica.

---

## 7. Verifica (a lavoro finito)

| Controllo | Comando / azione | Esito |
|---|---|---|
| DB | `supabase db reset && supabase test db` | ☑ 3/3 |
| Web | `bun run lint && bun run typecheck && bun run test && bun run build` | ☑ (2 test) |
| Mobile | `dart format --set-exit-if-changed . && flutter analyze && flutter test` | ☑ (2 test) |
| Prova browser | AC3 | ☑ `/` → "Catalogo in arrivo", `/en` → "Catalog coming soon", nessun errore in console |
| Prova mobile | AC5 | ☐ prova manuale in review |

Note, screenshot, problemi trovati: Node 25.5 locale fuori dal range supportato da Nuxt (warning, non bloccante). AC6 da confermare alla prima CI della PR.

## 8. Esito
- Cosa è stato fatto davvero (differenze rispetto al piano): come da piano. TypeScript fissato a `~5.9` nel web (la 7.x rompe typescript-eslint e `nuxt typecheck`). l10n mobile in `lib/l10n`.
- Debito tecnico lasciato (con TODO o issue collegata): sbloccare TypeScript 7 quando typescript-eslint/vue-tsc lo supportano.
- Follow-up: F1 (catalogo) con `@pinia/nuxt`, `@nuxt/image`, Playwright, dio/freezed.
