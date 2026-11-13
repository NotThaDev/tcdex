import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tcdex/app/app.dart';

void main() {
  testWidgets('shows Italian placeholder', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: App(locale: Locale('it'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Catalogo in arrivo'), findsOneWidget);
  });

  testWidgets('shows English placeholder', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: App(locale: Locale('en'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Catalog coming soon'), findsOneWidget);
  });
}
