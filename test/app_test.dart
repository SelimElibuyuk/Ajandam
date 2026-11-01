import 'package:ajandam/app/app.dart';
import 'package:ajandam/app/providers.dart';
import 'package:ajandam/app/router.dart';
import 'package:ajandam/data/db/app_database.dart';
import 'package:ajandam/domain/item_service.dart';
import 'package:ajandam/domain/reminder_planner.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _NoReminders implements ReminderGateway {
  @override
  Future<void> replaceAll(
    List<PlannedNotification> plans, {
    bool rearm = false,
  }) async {}
}

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  Future<void> pumpApp(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          reminderGatewayProvider.overrideWithValue(_NoReminders()),
        ],
        child: AjandamApp(router: buildRouter()),
      ),
    );
    addTearDown(db.close);
  }

  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Bugün açılır ve menü ekranlar arasında geçer', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    expect(find.text('Bugün boş. + ile ekle'), findsOneWidget);

    await tester.tap(find.text('Hafta'));
    await settle(tester);
    expect(find.text('Bu hafta'), findsOneWidget);
    expect(find.text('Boş'), findsWidgets);

    await tester.tap(
      find.widgetWithIcon(NavigationDestination, Icons.settings_outlined),
    );
    await settle(tester);
    expect(find.text('Otomatik taşıma'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Hızlı ekleme görevi kaydeder ve listede gösterir', (
    tester,
  ) async {
    await pumpApp(tester);
    await settle(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'bugün 23:59 dişçi');
    await tester.pump();
    expect(find.text('23:59'), findsOneWidget);

    await tester.tap(find.text('Kaydet'));
    await settle(tester);

    expect(find.text('dişçi'), findsOneWidget);
    expect(find.text('Bugün boş. + ile ekle'), findsNothing);
    await closeApp(tester);
  });

  testWidgets('Başlıksız kayıt yapılmaz', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'yarın 14:00');
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await settle(tester);

    expect(find.text('Başlık yaz'), findsOneWidget);
    await closeApp(tester);
  });
}
