---
name: flutter-mobile
description: Struttura e best practice dell'app Flutter del Pokédex TCG — architettura feature-first, Riverpod 3 con codegen, go_router, dio, supabase_flutter, modelli, l10n e test. Usare per qualsiasi modifica in mobile/.
---

# App mobile — Flutter

Stack: Flutter stable · Dart 3 · flutter_riverpod 3 + riverpod_annotation/riverpod_generator · go_router · dio · supabase_flutter · freezed + json_serializable · cached_network_image · flutter_localizations (gen-l10n) · very_good_analysis · mocktail.

## Struttura (feature-first, 3 livelli)
```
mobile/lib/
├── main.dart                     # bootstrap: Supabase.initialize, ProviderScope
├── app/
│   ├── app.dart                  # MaterialApp.router, tema, l10n
│   ├── router.dart               # go_router + redirect auth
│   └── theme.dart
├── core/
│   ├── env.dart                  # String.fromEnvironment('SUPABASE_URL'…)
│   ├── tcgdex/
│   │   ├── tcgdex_client.dart    # unico client dio
│   │   └── models/               # Card, CardBrief, SetBrief, Pricing (freezed)
│   ├── supabase/supabase_providers.dart
│   └── widgets/                  # AsyncValueView, CardImage, EmptyState
├── features/
│   ├── sets/        {data,domain,presentation}/
│   ├── cards/       {data,domain,presentation}/
│   ├── collection/  {data,domain,presentation}/
│   └── auth/        {data,domain,presentation}/
└── l10n/app_it.arb, app_en.arb
```
- `data/`: repository, che parlano con TCGdex o Supabase e restituiscono modelli di dominio.
- `domain/`: modelli e logica pura (per esempio il calcolo dell'avanzamento del set), senza Flutter.
- `presentation/`: schermate, widget e provider della UI.
- Una feature non importa mai il `presentation/` di un'altra feature; ciò che è condiviso va in `core/`.

## Bootstrap
```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseKey);
  runApp(const ProviderScope(child: App()));
}

// lib/core/env.dart
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
}
```
Avvio: `flutter run --dart-define-from-file=env/dev.json`. I file `env/*.json` sono in `.gitignore`.

## Riverpod 3 (codegen)
```dart
// features/cards/data/cards_repository.dart
@riverpod
CardsRepository cardsRepository(Ref ref) => CardsRepository(ref.watch(tcgdexClientProvider));

// features/cards/presentation/card_detail_provider.dart
@riverpod
Future<Card> cardDetail(Ref ref, String cardId) {
  final lang = ref.watch(dataLangProvider); // 'it' | 'en'
  return ref.watch(cardsRepositoryProvider).card(cardId, lang: lang);
}

// features/collection/presentation/collection_notifier.dart
@riverpod
class CollectionNotifier extends _$CollectionNotifier {
  @override
  Future<List<CollectionEntry>> build() => ref.watch(collectionRepositoryProvider).fetchAll();

  Future<void> add(CollectionEntry e) async {
    await ref.read(collectionRepositoryProvider).upsert(e);
    ref.invalidateSelf();
  }
}
```
- Provider generati con `@riverpod`; dopo ogni modifica lancia `dart run build_runner build -d` (oppure `watch`).
- `ref.watch` nel `build`, `ref.read` nei callback.
- Stati async renderizzati con `switch` su `AsyncValue` (o un widget `AsyncValueView` comune): loading → skeleton, error → retry, data vuoto → empty state.
- Niente `setState` per lo stato di dominio; `StatefulWidget` solo per controller locali (TextEditingController, animazioni).

## Rete (TCGdex)
- Un solo `Dio` con `baseUrl: 'https://api.tcgdex.net/v2'`, timeout di 10 s e un interceptor di log solo in debug.
- Ricerca: debounce di 300 ms e `CancelToken` per annullare la richiesta precedente.
- Fallback IT → EN su 404 nel dettaglio (vedi skill `tcgdex-data`).
- Immagini con `CachedNetworkImage` (`low.webp` in griglia, `high.webp` nel dettaglio) e placeholder se `image` è null.

## Supabase
- `Supabase.instance.client` esposto con un provider, mai usato direttamente nei widget.
- Auth: `onAuthStateChange` come stream provider; il `redirect` di go_router manda su `/login` le route `/collection/**`.
- Deep link per magic link/OAuth configurati per Android (intent-filter) e iOS (URL scheme), e annotati nell'intent.
- Modello `CollectionEntry` allineato alla tabella `public.collection` (snake_case in JSON tramite `@JsonKey`/`fieldRename`).

## Modelli
- `freezed` + `json_serializable`; campi opzionali TCGdex come nullable.
- `fromJson` testato con fixture reali in `test/fixtures/`.

## UI
- Material 3 e tema in `app/theme.dart`, senza colori hardcoded nei widget.
- Widget piccoli e `const` dove possibile; oltre circa 150 righe si estraggono.
- Liste con `ListView.builder`/`GridView.builder` e paginazione infinita (si carica la pagina successiva all'80% dello scroll).
- Accessibilità: `Semantics`/`semanticLabel` sulle immagini delle carte e tap target di almeno 48 dp.

## l10n
- `gen-l10n` con `app_it.arb` e `app_en.arb`; nessuna stringa hardcoded: `context.l10n.priceUnavailable`.
- La lingua dei dati TCGdex segue la locale dell'app (provider `dataLangProvider`).

## Test
- Unit: repository (dio mockato con mocktail e fixture), logica di dominio, notifier (con `ProviderContainer` e override).
- Widget: schermate principali con i provider in override (stati loading, error e data).
- Integration (`integration_test/`): flusso ricerca → dettaglio → aggiungi in collezione.
- Comandi: `dart format --set-exit-if-changed . && flutter analyze && flutter test`, poi la prova su emulatore.
