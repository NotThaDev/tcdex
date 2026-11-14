---
name: nuxt-web
description: Structure and best practices of the Pokédex TCG Nuxt 4 web app — folders, composables, data fetching, Pinia, @nuxtjs/supabase v2, i18n, components and tests. Use for any change in web/.
---

# Web app — Nuxt 4

Stack: Nuxt 4 · Vue 3 `<script setup lang="ts">` · TypeScript strict · Pinia · @nuxtjs/supabase v2 · @nuxtjs/i18n · Vitest + @nuxt/test-utils · Playwright · ESLint (@nuxt/eslint).

## Structure
```
web/
├── app/                         # Nuxt 4 srcDir
│   ├── app.vue
│   ├── assets/
│   ├── components/
│   │   ├── ui/                  # generic components (Button, Badge, Skeleton…)
│   │   ├── card/                # CardTile, CardGrid, CardPrice, CardVariantPicker
│   │   ├── set/                 # SetTile, SetProgress
│   │   └── filters/             # FilterBar, FilterSelect
│   ├── composables/
│   │   ├── useTcgdex.ts         # single TCGdex client
│   │   ├── useCardSearch.ts     # filters + pagination + debounce
│   │   └── useCollection.ts     # Supabase queries for the collection
│   ├── layouts/default.vue
│   ├── middleware/auth.ts
│   ├── pages/
│   │   ├── index.vue            # set list
│   │   ├── sets/[id].vue
│   │   ├── cards/index.vue      # search/filters
│   │   ├── cards/[id].vue       # detail + prices
│   │   ├── collection/index.vue
│   │   ├── login.vue
│   │   └── confirm.vue          # auth callback
│   ├── stores/                  # Pinia: shared client state only
│   └── utils/                   # pure functions (cardImage, formatPrice…)
├── server/                      # Nitro server routes (only if needed)
├── shared/types/                # tcgdex.ts, database.types.ts (generated)
├── i18n/locales/{it,en}.json
├── tests/{unit,e2e,fixtures}/
└── nuxt.config.ts
```

## Base config
```ts
// nuxt.config.ts
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  modules: ['@nuxtjs/supabase', '@nuxtjs/i18n', '@pinia/nuxt', '@nuxt/eslint', '@nuxt/image', '@nuxt/test-utils/module'],
  typescript: { strict: true, typeCheck: true },
  supabase: {
    types: '~~/shared/types/database.types.ts',
    redirectOptions: { login: '/login', callback: '/confirm', include: ['/collection(/*)?'], exclude: [] },
  },
  i18n: {
    defaultLocale: 'it',
    strategy: 'prefix_except_default',
    locales: [{ code: 'it', file: 'it.json' }, { code: 'en', file: 'en.json' }],
  },
  image: { domains: ['assets.tcgdex.net'] },
})
```

## Data fetching
- In pages use `useAsyncData` / `useFetch` (SSR-compatible), with a key that includes the language: `` `card:${locale.value}:${id}` ``.
- `watch: [locale]` to reload the data when the language changes.
- In composables, `$fetch` only for actions (click, submit), never in setup without `useAsyncData`.
- States always handled: `pending` → skeleton, `error` → message + retry, empty list → empty state.

```ts
// app/composables/useTcgdex.ts
import type { Card, CardBrief, SetBrief, SetFull } from '~~/shared/types/tcgdex'

const BASE = 'https://api.tcgdex.net/v2'

export function useTcgdex() {
  const { locale } = useI18n()
  const get = <T>(path: string, query?: Record<string, unknown>, lang = locale.value) =>
    $fetch<T>(`${BASE}/${lang}${path}`, { query, timeout: 10_000 })

  return {
    sets: () => get<SetBrief[]>('/sets'),
    set: (id: string) => get<SetFull>(`/sets/${id}`),
    searchCards: (q: Record<string, unknown>, page = 1) =>
      get<CardBrief[]>('/cards', { ...q, 'pagination:page': page, 'pagination:itemsPerPage': 30 }),
    async card(id: string): Promise<Card & { fallbackLang?: 'en' }> {
      try { return await get<Card>(`/cards/${id}`) }
      catch (e: any) {
        if (locale.value !== 'en' && e?.statusCode === 404)
          return { ...(await get<Card>(`/cards/${id}`, undefined, 'en')), fallbackLang: 'en' }
        throw e
      }
    },
  }
}
```

## Supabase (module v2)
- `useSupabaseClient<Database>()` for queries; the types come from `database.types.ts`.
- In v2, `useSupabaseUser()` returns the **JWT claims**, not the User object: the user id is `user.value?.sub`. For full user data use `supabase.auth.getUser()`.
- Page protection is done with `redirectOptions.include`, but the real security is RLS: never filter by `user_id` "for security" on the client side (filtering for convenience is fine).
- Upsert to add a card, with `onConflict: 'user_id,card_id,lang,variant'`.

## State
- Server data: `useAsyncData` (Nuxt cache). Pinia only for client state shared across pages (active filters, UI preferences).
- Search filters synced with the query string (`useRoute`/`navigateTo`), so the URLs are shareable.

## Components
- `<script setup lang="ts">`, typed `defineProps`, typed `defineEmits`; no Options API.
- A component does one thing; if it exceeds about 150 lines, split it.
- No API calls inside `components/`: data arrives via props or from the page composables.
- Images with `<NuxtImg>`, `loading="lazy"` in grids, and `alt` with the card name.
- Accessibility: native interactive elements (`button`, `a`), visible focus, AA contrast.

## i18n
- No hardcoded UI strings: `t('cards.price.unavailable')`.
- Nested keys per area (`sets.*`, `cards.*`, `collection.*`, `auth.*`); IT and EN always aligned.
- Prices formatted with `Intl.NumberFormat(locale, { style: 'currency', currency: unit })`.

## Test
- Unit (Vitest): utils, composables (with TCGdex mocked via fixtures) and components with `mountSuspended`.
- E2E (Playwright): one flow for each acceptance criterion that touches the UI (search → detail → add to collection).
- Commands: `bun run lint && bun run typecheck && bun run test && bun run build`, then the manual check with `bun run dev`.
