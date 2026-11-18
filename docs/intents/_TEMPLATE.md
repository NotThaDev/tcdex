# INTENT NNNN — <short title>

> Copy this file to `docs/intents/NNNN-slug.md` **before** writing any code.
> Sections 1–6 must be filled in and approved before implementation; sections 7–8 are filled in when the work is finished.

| Field | Value |
|---|---|
| Status | `draft` · `approved` · `in development` · `in review` · `closed` |
| Type | `feat` · `fix` · `refactor` · `chore` · `docs` |
| Areas | `web` · `mobile` · `db` · `fn` |
| Feature README | F? |
| Branch | `feat/NNNN-slug` |
| PR | #… |

---

## 1. Why
The problem or need, in 2–4 sentences. What cannot be done today, or what does not work.

## 2. What (scope)
What changes from the user's point of view.

**Included**
- …

**Excluded** (explicit: avoids scope creep)
- …

## 3. Acceptance criteria
Verifiable, preferably in the *Given / When / Then* format. Each one becomes at least one test or a step of the manual check.

- [ ] AC1 — Given … when … then …
- [ ] AC2 — …

## 4. Technical design
- **Data / schema**: new tables, columns, migrations, RLS policies (paste the SQL or refer to the file).
- **APIs used**: TCGdex endpoints, Supabase queries, Edge Functions.
- **Web**: pages, components and composables touched.
- **Mobile**: features, providers, screens and routes touched.
- **Web/mobile parity**: is it done on both? If not, why and when.
- **Discarded alternatives**: what and why, one line each.

## 5. Risks and impacts
- Security / RLS:
- Performance (number of TCGdex calls, list size, pagination):
- Breaking change / data migration:
- New dependencies (name, version, reason):

## 6. Plan
Small steps, each verifiable. Indicate the assigned model.

| # | Step | Area | Model | Done |
|---|---|---|---|---|
| 1 | … | db | Haiku | ☐ |
| 2 | … | web | Haiku | ☐ |

Plan validation (Sonnet): ☐ OK · notes: …

---

## 7. Verification (when the work is finished)

| Check | Command / action | Result |
|---|---|---|
| DB | `supabase db reset && supabase test db` | ☐ |
| Web | `bun run lint && bun run typecheck && bun run test && bun run build` | ☐ |
| Mobile | `dart format --set-exit-if-changed . && flutter analyze && flutter test` | ☐ |
| Browser check | steps performed for each AC | ☐ |
| Mobile check | emulator/device, steps for each AC | ☐ |

Notes, screenshots, problems found:

## 8. Outcome
- What was actually done (differences from the plan):
- Technical debt left (with TODO or linked issue):
- Follow-up:
