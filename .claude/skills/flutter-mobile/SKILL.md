---
name: flutter-mobile
description: Structure and best practices of the Pokédex TCG Flutter app — feature-first architecture, Riverpod 3 with codegen, go_router, dio, supabase_flutter, models, l10n and tests. Use for any change in mobile/.
---

# Mobile app — Flutter

Stack: Flutter stable · Dart 3 · flutter_riverpod 3 + riverpod_annotation/riverpod_generator · go_router · dio · supabase_flutter · freezed + json_serializable · cached_network_image · flutter_localizations (gen-l10n) · very_good_analysis · mocktail.

## Structure (feature-first, 3 levels)
```
mobile/lib/
├── main.dart                     # bootstrap: Supabase.initialize, ProviderScope
├── app/
│   ├── app.dart                  # MaterialApp.router, theme, l10n
│   ├── router.dart               # go_router + redirect auth
│   └── theme.dart
├── core/
│   ├── env.dart                  # String.fromEnvironment('SUPABASE_URL'…)
│   ├── tcgdex/
│   │   ├── tcgdex_client.dart    # single dio client
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
- `data/`: repositories that talk to TCGdex or Supabase and return domain models.
- `domain/`: models and pure logic (for example the set progress calculation), without Flutter.
- `presentation/`: screens, widgets and UI providers.
- A feature never imports the `presentation/` of another feature; what is shared goes in `core/`.

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
Launch: `flutter run --dart-define-from-file=env/dev.json`. The `env/*.json` files are listed in `.gitignore`.

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
- Providers generated with `@riverpod`; after every change run `dart run build_runner build -d` (or `watch`).
- `ref.watch` in `build`, `ref.read` in callbacks.
- Async states rendered with a `switch` on `AsyncValue` (or a shared `AsyncValueView` widget): loading → skeleton, error → retry, empty data → empty state.
- No `setState` for domain state; `StatefulWidget` only for local controllers (TextEditingController, animations).

## Network (TCGdex)
- A single `Dio` with `baseUrl: 'https://api.tcgdex.net/v2'`, a 10 s timeout and a log interceptor in debug only.
- Search: 300 ms debounce and a `CancelToken` to cancel the previous request.
- IT → EN fallback on 404 in detail (see skill `tcgdex-data`).
- Images with `CachedNetworkImage` (`low.webp` in grid, `high.webp` in detail) and a placeholder if `image` is null.

## Supabase
- `Supabase.instance.client` exposed through a provider, never used directly in widgets.
- Auth: `onAuthStateChange` as a stream provider; the go_router `redirect` sends `/collection/**` routes to `/login`.
- Deep links for magic link/OAuth configured for Android (intent-filter) and iOS (URL scheme), and documented in the intent.
- `CollectionEntry` model aligned with the `public.collection` table (snake_case in JSON via `@JsonKey`/`fieldRename`).

## Models
- `freezed` + `json_serializable`; optional TCGdex fields as nullable.
- `fromJson` tested with real fixtures in `test/fixtures/`.

## UI
- Material 3 and theme in `app/theme.dart`, no hardcoded colors in widgets.
- Small widgets and `const` where possible; beyond about 150 lines, extract them.
- Lists with `ListView.builder`/`GridView.builder` and infinite pagination (next page loaded at 80% of the scroll).
- Accessibility: `Semantics`/`semanticLabel` on card images and tap targets of at least 48 dp.

## l10n
- `gen-l10n` with `app_it.arb` and `app_en.arb`; no hardcoded strings: `context.l10n.priceUnavailable`.
- The TCGdex data language follows the app locale (`dataLangProvider` provider).

## Test
- Unit: repositories (dio mocked with mocktail and fixtures), domain logic, notifiers (with `ProviderContainer` and overrides).
- Widget: main screens with providers overridden (loading, error and data states).
- Integration (`integration_test/`): search → detail → add to collection flow.
- Commands: `dart format --set-exit-if-changed . && flutter analyze && flutter test`, then the check on an emulator.
