---
name: pr-intent
description: Mandatory workflow for every change to the Pokédex TCG repo — write the INTENT, plan, validate, implement with the right models and verify before opening the PR. Use at the start of any feature, fix or refactor.
---

# INTENT-driven PR workflow

No application code line before an approved intent exists in `docs/intents/`.

## 1. Intent
1. Find the next free number: `ls docs/intents | sort | tail -1`.
2. Copy `docs/intents/_TEMPLATE.md` to `docs/intents/NNNN-slug.md` (slug in kebab-case, in English).
3. Fill in sections 1–5. If anything is unclear (scope, behavior, UX), **ask the user**: do not make assumptions.
4. Set `Status: draft` and ask for approval. Move to `approved` only after the user's explicit yes.

## 2. Plan (Opus)
- Fill in section 6 by splitting the work into small steps: each touches only one area and verifies itself.
- Typical order: `db` (migration + RLS + tests) → generated types → `web` → `mobile`.
- Before planning, load the skills of the areas involved: `supabase-backend`, `tcgdex-data`, `nuxt-web`, `flutter-mobile`.

## 3. Plan validation (Sonnet)
Launch a subagent with `model: sonnet`, passing it the intent and the area skills. It must check:
- that every acceptance criterion is covered by at least one step and one test;
- security: RLS present, no secrets in clients;
- web/mobile parity, or a justified exclusion;
- that there are no superfluous steps (YAGNI).

Report the result in the "Plan validation" line of the intent. If the validator finds problems, fix the plan before continuing.

## 4. Implementation (Haiku)
- Create the branch `feat|fix|chore/NNNN-slug`.
- Delegate each step to a subagent with `model: haiku`, passing it: the step, the files involved, the area skill and the linked acceptance criteria.
- Independent steps (for example web and mobile after db) can run in parallel.
- After each step, tick the plan table and make a Conventional Commits commit.
- If a step reveals the plan is wrong, stop, update the intent and ask the user whether the scope changes.

## 5. Verification (mandatory before saying "done")
Run the commands for the areas touched and report the real result in section 7:

```bash
supabase db reset && supabase test db                                    # db
cd web && bun run lint && bun run typecheck && bun run test && bun run build         # web
cd mobile && dart format --set-exit-if-changed . && flutter analyze && flutter test  # mobile
```

- If the change touches the frontend, even only via an endpoint or RLS: test every acceptance criterion in the browser (`bun run dev`) and/or on an emulator.
- A failed command is **not** worked around: fix it or report it to the user.

## 6. PR
- Fill in section 8 and set `Status: in review`.
- Title in Conventional Commits; the body follows `.github/pull_request_template.md` and links to the intent.
