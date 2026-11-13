# INTENT NNNN — <titolo breve>

> Copia questo file in `docs/intents/NNNN-slug.md` **prima** di scrivere codice.
> Le sezioni 1–6 vanno compilate e approvate prima dell'implementazione; le sezioni 7–8 si compilano a lavoro finito.

| Campo | Valore |
|---|---|
| Stato | `bozza` · `approvato` · `in sviluppo` · `in review` · `chiuso` |
| Tipo | `feat` · `fix` · `refactor` · `chore` · `docs` |
| Aree | `web` · `mobile` · `db` · `fn` |
| Feature README | F? |
| Branch | `feat/NNNN-slug` |
| PR | #… |

---

## 1. Perché
Il problema o il bisogno, in 2–4 frasi. Cosa non si può fare oggi, o cosa non funziona.

## 2. Cosa (scope)
Cosa cambia dal punto di vista dell'utente.

**Incluso**
- …

**Escluso** (esplicito: evita lo scope creep)
- …

## 3. Criteri di accettazione
Verificabili, possibilmente nel formato *Dato / Quando / Allora*. Ognuno diventa almeno un test o un passo della prova manuale.

- [ ] AC1 — Dato … quando … allora …
- [ ] AC2 — …

## 4. Design tecnico
- **Dati / schema**: nuove tabelle, colonne, migration, policy RLS (incolla lo SQL o rimanda al file).
- **API usate**: endpoint TCGdex, query Supabase, Edge Functions.
- **Web**: pagine, componenti e composable toccati.
- **Mobile**: feature, provider, schermate e route toccate.
- **Parità web/mobile**: si fa su entrambi? Se no, perché e quando.
- **Alternative scartate**: cosa e perché, una riga ciascuna.

## 5. Rischi e impatti
- Sicurezza / RLS:
- Performance (numero di chiamate a TCGdex, dimensione delle liste, paginazione):
- Breaking change / migrazione dati:
- Dipendenze nuove (nome, versione, motivo):

## 6. Piano
Passi piccoli, ognuno verificabile. Indica il modello assegnato.

| # | Passo | Area | Modello | Fatto |
|---|---|---|---|---|
| 1 | … | db | Haiku | ☐ |
| 2 | … | web | Haiku | ☐ |

Validazione del piano (Sonnet): ☐ OK · note: …

---

## 7. Verifica (a lavoro finito)

| Controllo | Comando / azione | Esito |
|---|---|---|
| DB | `supabase db reset && supabase test db` | ☐ |
| Web | `bun run lint && bun run typecheck && bun run test && bun run build` | ☐ |
| Mobile | `dart format --set-exit-if-changed . && flutter analyze && flutter test` | ☐ |
| Prova browser | passi eseguiti per ogni AC | ☐ |
| Prova mobile | emulatore/dispositivo, passi per ogni AC | ☐ |

Note, screenshot, problemi trovati:

## 8. Esito
- Cosa è stato fatto davvero (differenze rispetto al piano):
- Debito tecnico lasciato (con TODO o issue collegata):
- Follow-up:
