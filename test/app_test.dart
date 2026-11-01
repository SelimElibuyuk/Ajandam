import 'package:ajandam/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  testWidgets('Bugün açılır ve menü ekranlar arasında geçer', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AjandamApp()));
    await tester.pumpAndSettle();

    expect(find.text('Bugün boş.'), findsOneWidget);

    await tester.tap(find.text('Hafta'));
    await tester.pumpAndSettle();
    expect(find.text('Bu hafta'), findsOneWidget);
    expect(find.text('Boş'), findsWidgets);

    await tester.tap(
      find.widgetWithIcon(NavigationDestination, Icons.settings_outlined),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sürüm 0.1.0'), findsOneWidget);
  });
}
