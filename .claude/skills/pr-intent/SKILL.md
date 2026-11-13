---
name: pr-intent
description: Workflow obbligatorio per ogni modifica al repo Pokédex TCG — scrivere l'INTENT, pianificare, validare, implementare con i modelli giusti e verificare prima di aprire la PR. Usare all'inizio di qualsiasi feature, fix o refactor.
---

# Workflow PR guidato da INTENT

Nessuna riga di codice applicativo prima che esista un intent approvato in `docs/intents/`.

## 1. Intent
1. Trova il prossimo numero libero: `ls docs/intents | sort | tail -1`.
2. Copia `docs/intents/_TEMPLATE.md` in `docs/intents/NNNN-slug.md` (slug in kebab-case, in inglese).
3. Compila le sezioni 1–5. Se qualcosa non è chiaro (scope, comportamento, UX), **chiedi all'utente**: non fare assunzioni.
4. Metti `Stato: bozza` e chiedi l'approvazione. Passa ad `approvato` solo dopo il sì esplicito dell'utente.

## 2. Piano (Opus)
- Compila la sezione 6 dividendo il lavoro in passi piccoli: ognuno tocca una sola area e si verifica da solo.
- Ordine tipico: `db` (migration + RLS + test) → tipi generati → `web` → `mobile`.
- Prima di pianificare carica le skill delle aree coinvolte: `supabase-backend`, `tcgdex-data`, `nuxt-web`, `flutter-mobile`.

## 3. Validazione del piano (Sonnet)
Lancia un subagente con `model: sonnet`, passandogli l'intent e le skill delle aree. Deve controllare:
- che ogni criterio di accettazione sia coperto da almeno un passo e da un test;
- la sicurezza: RLS presente, nessun segreto nei client;
- la parità web/mobile, oppure un'esclusione motivata;
- che non ci siano passi superflui (YAGNI).

Riporta l'esito nella riga "Validazione del piano" dell'intent. Se il validatore trova problemi, correggi il piano prima di proseguire.

## 4. Implementazione (Haiku)
- Crea il branch `feat|fix|chore/NNNN-slug`.
- Delega ogni passo a un subagente con `model: haiku`, passandogli: il passo, i file coinvolti, la skill dell'area e i criteri di accettazione collegati.
- I passi indipendenti (per esempio web e mobile dopo il db) possono andare in parallelo.
- Dopo ogni passo spunta la tabella del piano e fai un commit in Conventional Commits.
- Se un passo rivela che il piano è sbagliato, fermati, aggiorna l'intent e chiedi all'utente se cambia lo scope.

## 5. Verifica (obbligatoria prima di dire "fatto")
Esegui i comandi delle aree toccate e riporta l'esito reale nella sezione 7:

```bash
supabase db reset && supabase test db                                    # db
cd web && bun run lint && bun run typecheck && bun run test && bun run build         # web
cd mobile && dart format --set-exit-if-changed . && flutter analyze && flutter test  # mobile
```

- Se la modifica tocca il frontend, anche solo via endpoint o RLS: prova ogni criterio di accettazione nel browser (`bun run dev`) e/o su emulatore.
- Un comando fallito **non** si aggira: si corregge o si segnala all'utente.

## 6. PR
- Compila la sezione 8 e metti `Stato: in review`.
- Titolo in Conventional Commits; il corpo segue `.github/pull_request_template.md` e rimanda all'intent.
