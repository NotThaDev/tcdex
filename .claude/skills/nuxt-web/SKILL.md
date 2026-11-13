---
name: nuxt-web
description: Struttura e best practice della web app Nuxt 4 del Pokédex TCG — cartelle, composable, data fetching, Pinia, @nuxtjs/supabase v2, i18n, componenti e test. Usare per qualsiasi modifica in web/.
---

# Web app — Nuxt 4

Stack: Nuxt 4 · Vue 3 `<script setup lang="ts">` · TypeScript strict · Pinia · @nuxtjs/supabase v2 · @nuxtjs/i18n · Vitest + @nuxt/test-utils · Playwright · ESLint (@nuxt/eslint).

## Struttura
```
web/
├── app/                         # srcDir di Nuxt 4
│   ├── app.vue
│   ├── assets/
│   ├── components/
│   │   ├── ui/                  # componenti generici (Button, Badge, Skeleton…)
│   │   ├── card/                # CardTile, CardGrid, CardPrice, CardVariantPicker
│   │   ├── set/                 # SetTile, SetProgress
│   │   └── filters/             # FilterBar, FilterSelect
│   ├── composables/
│   │   ├── useTcgdex.ts         # unico client TCGdex
│   │   ├── useCardSearch.ts     # filtri + paginazione + debounce
│   │   └── useCollection.ts     # query Supabase della collezione
│   ├── layouts/default.vue
│   ├── middleware/auth.ts
│   ├── pages/
│   │   ├── index.vue            # lista set
│   │   ├── sets/[id].vue
│   │   ├── cards/index.vue      # ricerca/filtri
│   │   ├── cards/[id].vue       # dettaglio + prezzi
│   │   ├── collection/index.vue
│   │   ├── login.vue
│   │   └── confirm.vue          # callback auth
│   ├── stores/                  # Pinia: solo stato client condiviso
│   └── utils/                   # funzioni pure (cardImage, formatPrice…)
├── server/                      # server route Nitro (solo se servono)
├── shared/types/                # tcgdex.ts, database.types.ts (generato)
├── i18n/locales/{it,en}.json
├── tests/{unit,e2e,fixtures}/
└── nuxt.config.ts
```

## Config base
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
- Nelle pagine usa `useAsyncData` / `useFetch` (compatibili con SSR), con chiave che include la lingua: `` `card:${locale.value}:${id}` ``.
- `watch: [locale]` per ricaricare i dati quando cambia la lingua.
- Nei composable, `$fetch` solo per azioni (click, submit), mai nel setup senza `useAsyncData`.
- Stati sempre gestiti: `pending` → skeleton, `error` → messaggio + retry, lista vuota → empty state.

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

## Supabase (v2 del modulo)
- `useSupabaseClient<Database>()` per le query; i tipi vengono da `database.types.ts`.
- `useSupabaseUser()` nella v2 restituisce i **JWT claims**, non l'oggetto User: l'id utente è `user.value?.sub`. Per i dati completi dell'utente usa `supabase.auth.getUser()`.
- La protezione delle pagine si fa con `redirectOptions.include`, ma la vera sicurezza è la RLS: mai filtrare per `user_id` "per sicurezza" lato client (filtrare per comodità va bene).
- Upsert per aggiungere una carta, con `onConflict: 'user_id,card_id,lang,variant'`.

## Stato
- Dati server: `useAsyncData` (cache di Nuxt). Pinia solo per lo stato client condiviso tra pagine (filtri attivi, preferenze UI).
- Filtri di ricerca sincronizzati con la query string (`useRoute`/`navigateTo`), così le URL sono condivisibili.

## Componenti
- `<script setup lang="ts">`, `defineProps` tipizzate, `defineEmits` tipizzati; niente Options API.
- Un componente fa una sola cosa; se supera circa 150 righe, va diviso.
- Nessuna chiamata API dentro `components/`: i dati arrivano via props o dai composable delle pagine.
- Immagini con `<NuxtImg>`, `loading="lazy"` nelle griglie e `alt` col nome della carta.
- Accessibilità: elementi interattivi nativi (`button`, `a`), focus visibile, contrasto AA.

## i18n
- Nessuna stringa UI hardcoded: `t('cards.price.unavailable')`.
- Chiavi annidate per area (`sets.*`, `cards.*`, `collection.*`, `auth.*`); IT ed EN sempre allineati.
- Prezzi formattati con `Intl.NumberFormat(locale, { style: 'currency', currency: unit })`.

## Test
- Unit (Vitest): utils, composable (con TCGdex mockato tramite fixture) e componenti con `mountSuspended`.
- E2E (Playwright): un flusso per ogni criterio di accettazione che tocca la UI (ricerca → dettaglio → aggiungi in collezione).
- Comandi: `bun run lint && bun run typecheck && bun run test && bun run build`, poi la prova manuale con `bun run dev`.
