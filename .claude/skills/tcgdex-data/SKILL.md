---
name: tcgdex-data
description: How to use the TCGdex API in the Pokédex TCG — endpoints, IT/EN languages with fallback, filters, pagination, Cardmarket/TCGplayer prices, images and caching. Use whenever web or mobile read card or set data.
---

# TCGdex: card data

Base URL: `https://api.tcgdex.net/v2/{lang}`, with `lang` equal to `it` or `en`. It is free and needs no key.
Before using a new field, check the official docs: https://tcgdex.dev

## Endpoints used
| Use | Endpoint | Returns |
|---|---|---|
| Set list | `GET /sets` | `SetBrief[]` (id, name, logo, symbol, cardCount) |
| Set + cards | `GET /sets/{setId}` | `Set` with `cards: CardBrief[]` |
| Card search | `GET /cards?name=…&types=…&rarity=…&illustrator=…` | `CardBrief[]` (id, localId, name, image) |
| Detail | `GET /cards/{cardId}` | Full `Card`, with `pricing` and `variants` |
| Filter values | `GET /types`, `GET /rarities`, `GET /illustrators` | `string[]` |
| Series | `GET /series`, `GET /series/{id}` | series with their sets |

## Pagination
By default it is **not** enabled, so without parameters lists arrive whole. Always use it on searches:
```
/cards?name=pika&pagination:page=1&pagination:itemsPerPage=30
```
End of list: a page with fewer than `itemsPerPage` items.
Sorting: `sort:field=name&sort:order=ASC`.

## Languages and fallback
- The data language follows the interface language (`it` | `en`).
- The IT catalog is less complete than the EN one. Rules:
  - card detail: if `/it/cards/{id}` returns 404, retry on `/en/` and show an "EN" badge;
  - lists: use the current language without merging results with the other language.
- The `card_id` is identical across languages, so the collection stores only the id.

## Prices
They exist only in card detail:
```jsonc
"pricing": {
  "cardmarket": { "unit": "EUR", "avg": …, "low": …, "trend": …, "avg1": …, "avg7": …, "avg30": …, /* *-holo */ },
  "tcgplayer":  { "unit": "USD", "normal": { "lowPrice", "midPrice", "marketPrice", … }, "holofoil": {…}, "reverse-holofoil": {…} }
}
```
- Cardmarket updates about once a day, TCGplayer about every hour.
- `pricing` or the individual markets may be missing: always handle the null/undefined case and show "n/a".
- Show the original currency, without conversions.
- For the total collection value, do not make N calls from the client: it will need an Edge Function with cache (dedicated intent, F8).

## Images
`image` is a base URL **without extension**: compose `{image}/{quality}.{ext}`.
- Grid: `low.webp`; detail/zoom: `high.webp`; fallback: `.png`.
- `image` may be missing (cards without a scan): show a placeholder.
- Set logos and symbols: `{logo}.webp`, `{symbol}.webp`.

## Shared types
The types live in `web/shared/types/tcgdex.ts` and in the Dart models in `mobile/lib/core/tcgdex/models/`. Every field used must be typed, and optional fields must be declared as such.
```ts
export interface CardBrief { id: string; localId: string; name: string; image?: string }
export interface Card extends CardBrief {
  category: 'Pokemon' | 'Trainer' | 'Energy'
  rarity?: string; illustrator?: string; hp?: number; types?: string[]
  set: { id: string; name: string; logo?: string; symbol?: string; cardCount: { total: number; official: number } }
  variants?: { normal?: boolean; reverse?: boolean; holo?: boolean; firstEdition?: boolean }
  pricing?: { cardmarket?: CardmarketPrice | null; tcgplayer?: TcgplayerPrice | null }
}
```

## Best practices
- One single TCGdex client per app (`useTcgdex` on web, `TcgdexClient` on mobile). No scattered `fetch` calls in components.
- Cache: set lists and filter values change rarely, so they are cached for the whole session. Card detail is cached by the key `lang:id`.
- Search with a 300 ms debounce and the previous request cancelled (AbortController / CancelToken).
- 10 s timeout; network error with a retry UI. The API is public and free, so treat it with respect: no polling.
- Tests: use real JSON fixtures saved in `tests/fixtures/tcgdex/` (web) and `test/fixtures/` (mobile), not the real API.
