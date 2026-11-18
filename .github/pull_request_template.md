<!-- Follow the clear-description skill (.claude/skills/clear-description/SKILL.md). -->
## Purpose
<!-- 1-2 sentences: the problem and what this PR does. Intent: `docs/intents/NNNN-slug.md` -->

## What it touches
- `supabase/`:
- `web/`:
- `mobile/`:
- DB: <!-- migration name, or "no schema change" -->

## Idea and implementation
<!-- A few lines, then 1-3 Mermaid diagrams (flowchart / sequenceDiagram / erDiagram). -->

## Risks
-

## Things to check
- [ ] Intent approved and updated (sections 7–8 filled in)
- [ ] All acceptance criteria verified
- [ ] DB: `supabase db reset && supabase test db`
- [ ] Web: `bun run lint && bun run typecheck && bun run test && bun run build`
- [ ] Mobile: `dart format --set-exit-if-changed . && flutter analyze && flutter test`
- [ ] Tested in the browser / on the emulator
- [ ] No secrets committed
- [ ] UI strings translated into IT and EN

## Screenshots
<!-- Only for visible changes: desktop 800 px, mobile 375 px, attached with `gh pr edit --attach`. -->
