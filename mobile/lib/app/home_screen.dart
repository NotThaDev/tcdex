import 'package:material_ui/material_ui.dart';
import 'package:tcdex/l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(child: Text(l10n.homePlaceholder)),
    );
  }
}
