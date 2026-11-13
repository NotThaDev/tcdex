## Intent
`docs/intents/NNNN-slug.md`

## Riepilogo
<!-- 2-3 righe: cosa cambia per l'utente -->

## Checklist
- [ ] Intent approvato e aggiornato (sezioni 7–8 compilate)
- [ ] Tutti i criteri di accettazione verificati
- [ ] DB: `supabase db reset && supabase test db`
- [ ] Web: `bun run lint && bun run typecheck && bun run test && bun run build`
- [ ] Mobile: `dart format --set-exit-if-changed . && flutter analyze && flutter test`
- [ ] Provato nel browser / su emulatore
- [ ] Nessun segreto committato
- [ ] Stringhe UI tradotte in IT e EN
