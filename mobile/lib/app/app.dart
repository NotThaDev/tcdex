import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tcdex/app/router.dart';
import 'package:tcdex/l10n/app_localizations.dart';

class App extends ConsumerWidget {
  const new({this.locale, super.key});

  final Locale? locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
    );
  }
}
