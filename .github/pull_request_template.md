## Intent
`docs/intents/NNNN-slug.md`

## Summary
<!-- 2-3 lines: what changes for the user -->

## Checklist
- [ ] Intent approved and updated (sections 7–8 filled in)
- [ ] All acceptance criteria verified
- [ ] DB: `supabase db reset && supabase test db`
- [ ] Web: `bun run lint && bun run typecheck && bun run test && bun run build`
- [ ] Mobile: `dart format --set-exit-if-changed . && flutter analyze && flutter test`
- [ ] Tested in the browser / on the emulator
- [ ] No secrets committed
- [ ] UI strings translated into IT and EN
