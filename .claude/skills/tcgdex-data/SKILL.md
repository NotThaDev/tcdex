---
name: tcgdex-data
description: Come usare l'API TCGdex nel Pokédex TCG — endpoint, lingue IT/EN con fallback, filtri, paginazione, prezzi Cardmarket/TCGplayer, immagini e caching. Usare ogni volta che web o mobile leggono dati delle carte o dei set.
---

# TCGdex: dati delle carte

Base URL: `https://api.tcgdex.net/v2/{lang}`, con `lang` uguale a `it` o `en`. È gratuita e non richiede chiave.
Prima di usare un campo nuovo, controlla la doc ufficiale: https://tcgdex.dev

## Endpoint usati
| Uso | Endpoint | Ritorna |
|---|---|---|
| Lista set | `GET /sets` | `SetBrief[]` (id, name, logo, symbol, cardCount) |
| Set + carte | `GET /sets/{setId}` | `Set` con `cards: CardBrief[]` |
| Ricerca carte | `GET /cards?name=…&types=…&rarity=…&illustrator=…` | `CardBrief[]` (id, localId, name, image) |
| Dettaglio | `GET /cards/{cardId}` | `Card` completa, con `pricing` e `variants` |
| Valori per i filtri | `GET /types`, `GET /rarities`, `GET /illustrators` | `string[]` |
| Serie | `GET /series`, `GET /series/{id}` | serie con i relativi set |

## Paginazione
Di default **non** è attiva, quindi senza parametri le liste arrivano intere. Sulle ricerche va sempre usata:
```
/cards?name=pika&pagination:page=1&pagination:itemsPerPage=30
```
Fine lista: una pagina con meno di `itemsPerPage` elementi.
Ordinamento: `sort:field=name&sort:order=ASC`.

## Lingue e fallback
- La lingua dei dati segue la lingua dell'interfaccia (`it` | `en`).
- Il catalogo IT è meno completo di quello EN. Regole:
  - dettaglio carta: se `/it/cards/{id}` risponde 404, riprova su `/en/` e mostra un badge "EN";
  - liste: usa la lingua corrente senza fondere i risultati con l'altra lingua.
- Il `card_id` è identico tra le lingue, quindi la collezione salva solo l'id.

## Prezzi
Ci sono solo nel dettaglio carta:
```jsonc
"pricing": {
  "cardmarket": { "unit": "EUR", "avg": …, "low": …, "trend": …, "avg1": …, "avg7": …, "avg30": …, /* *-holo */ },
  "tcgplayer":  { "unit": "USD", "normal": { "lowPrice", "midPrice", "marketPrice", … }, "holofoil": {…}, "reverse-holofoil": {…} }
}
```
- Cardmarket si aggiorna circa una volta al giorno, TCGplayer circa ogni ora.
- `pricing` o i singoli mercati possono mancare: gestisci sempre il caso null/undefined e mostra "n.d.".
- Mostra la valuta originale, senza conversioni.
- Per il valore totale della collezione non fare N chiamate dal client: servirà una Edge Function con cache (intent dedicato, F8).

## Immagini
`image` è un URL base **senza estensione**: componi `{image}/{quality}.{ext}`.
- Griglia: `low.webp`; dettaglio/zoom: `high.webp`; fallback: `.png`.
- `image` può mancare (carte senza scan): mostra un placeholder.
- Loghi e simboli dei set: `{logo}.webp`, `{symbol}.webp`.

## Tipi condivisi
I tipi stanno in `web/shared/types/tcgdex.ts` e nei modelli Dart in `mobile/lib/core/tcgdex/models/`. Ogni campo usato va tipizzato, e i campi opzionali vanno dichiarati come tali.
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

## Best practice
- Un solo client TCGdex per app (`useTcgdex` su web, `TcgdexClient` su mobile). Nessuna `fetch` sparsa nei componenti.
- Cache: liste di set e valori dei filtri cambiano raramente, quindi si tengono in cache per tutta la sessione. Il dettaglio carta si tiene in cache per chiave `lang:id`.
- Ricerca con debounce di 300 ms e richiesta precedente annullata (AbortController / CancelToken).
- Timeout di 10 s; errore di rete con UI di retry. L'API è pubblica e gratuita, quindi va trattata con rispetto: niente polling.
- Test: usa fixture JSON reali salvate in `tests/fixtures/tcgdex/` (web) e `test/fixtures/` (mobile), non l'API vera.
