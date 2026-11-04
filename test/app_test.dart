import 'dart:async';

import 'package:ajandam/app/app.dart';
import 'package:ajandam/app/providers.dart';
import 'package:ajandam/app/router.dart';
import 'package:ajandam/data/db/app_database.dart';
import 'package:ajandam/domain/dates.dart';
import 'package:ajandam/domain/habit_service.dart';
import 'package:ajandam/domain/item_service.dart';
import 'package:ajandam/domain/reminder_planner.dart';
import 'package:ajandam/domain/week.dart';
import 'package:ajandam/domain/widget_snapshot.dart';
import 'package:ajandam/voice/voice_input.dart';
import 'package:ajandam/widget_bridge/home_widget_bridge.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class _FakeLinks extends WidgetLinks {
  final controller = StreamController<Uri?>.broadcast();

  @override
  Future<Uri?> initial() async => null;

  @override
  Stream<Uri?> get clicks => controller.stream;
}

class _FakeVoice implements VoiceInput {
  VoiceText? onText;
  void Function()? onDone;
  bool listening = false;
  int starts = 0;

  @override
  Future<bool> start({
    required VoiceText onText,
    required void Function() onDone,
    required void Function(VoiceError error) onError,
  }) async {
    this.onText = onText;
    this.onDone = onDone;
    listening = true;
    starts++;
    return true;
  }

  @override
  Future<void> stop() async => listening = false;

  /// Bir cümle söylenir, Android oturumu kapatır.
  void say(String text) {
    onText!(text, true);
    onDone!();
  }
}

class _NoReminders implements ReminderGateway {
  @override
  Future<void> replaceAll(
    List<PlannedNotification> plans, {
    bool rearm = false,
  }) async {}
}

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  late _FakeLinks links;
  late _FakeVoice voice;

  Future<void> pumpApp(WidgetTester tester) async {
    links = _FakeLinks();
    voice = _FakeVoice();
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          reminderGatewayProvider.overrideWithValue(_NoReminders()),
          widgetGatewayProvider.overrideWithValue(const NoWidget()),
          habitWidgetProvider.overrideWithValue(const NoHabitWidget()),
          widgetLinksProvider.overrideWithValue(links),
          voiceInputProvider.overrideWithValue(voice),
        ],
        child: AjandamApp(router: buildRouter()),
      ),
    );
    addTearDown(db.close);
  }

  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openQuickAdd(WidgetTester tester) async {
    await tester.tap(find.text('Hızlı görev ekle (ör. 15:30 Arama)'));
    await settle(tester);
  }

  testWidgets('Ay açılır, Hafta ve Ayarlar geçişleri çalışır', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    expect(find.text('Bugün boş.'), findsOneWidget);
    expect(find.text('Ajandam'), findsOneWidget);

    await tester.tap(find.text('Hafta'));
    await settle(tester);
    expect(find.textContaining('HAFTA '), findsOneWidget);
    expect(find.text('Planlanan görev yok.'), findsWidgets);

    await tester.tap(find.byTooltip('Ayarlar').first);
    await settle(tester);
    expect(find.text('Otomatik taşıma'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Popup görevi kaydeder ve listede gösterir', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    await openQuickAdd(tester);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byTooltip('Tarih ve saat seç'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bugün 23:59 dişçi');
    await tester.pump();
    expect(find.text('23:59'), findsOneWidget);

    await tester.tap(find.text('Kaydet'));
    await settle(tester);

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('dişçi'), findsOneWidget);
    expect(find.text('Bugün boş.'), findsNothing);
    await closeApp(tester);
  });

  testWidgets('Popup tekrarlı etkinliği kaydeder', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    await openQuickAdd(tester);
    await tester.enterText(find.byType(TextField), 'her gün 23:58 ilaç');
    await tester.pump();
    expect(find.text('Her gün'), findsOneWidget);
    expect(find.text('Görev'), findsOneWidget);

    await tester.tap(find.text('Görev'));
    await tester.pump();
    expect(find.text('Etkinlik'), findsOneWidget);

    await tester.tap(find.text('Kaydet'));
    await settle(tester);

    expect(find.text('ilaç'), findsOneWidget);
    expect(find.byIcon(Icons.repeat), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Sesle yazılan metin anlaşılır ve kaydedilir', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    await openQuickAdd(tester);
    await tester.tap(find.byTooltip('Sesle yaz'));
    await tester.pump();
    expect(voice.listening, isTrue);
    expect(find.text('Dinliyorum…'), findsOneWidget);

    voice.say('bugün 23:59 dişçi');
    await tester.pump();
    expect(find.text('23:59'), findsOneWidget);

    // Duraklamadan sonra dinleme sürer, ikinci parça sona eklenir.
    await tester.pump(const Duration(milliseconds: 300));
    expect(voice.starts, 2);
    expect(find.byTooltip('Dinlemeyi durdur'), findsOneWidget);
    voice.say('kontrolü');
    await tester.pump();
    expect(find.text('bugün 23:59 dişçi kontrolü'), findsOneWidget);

    await tester.tap(find.text('Kaydet'));
    await settle(tester);
    expect(voice.listening, isFalse);
    expect(find.text('dişçi kontrolü'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Widget mikrofonu pencereyi dinlerken açar', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    links.controller.add(
      Uri.parse('ajandam://quick-add?date=2026-11-03&voice=1'),
    );
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Dialog), findsOneWidget);
    expect(voice.listening, isTrue);
    voice.say('kitap oku');
    await tester.pump();
    expect(find.text('kitap oku'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Başlıksız kayıt yapılmaz', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    await openQuickAdd(tester);
    await tester.enterText(find.byType(TextField), 'yarın 14:00');
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await settle(tester);

    expect(find.text('Başlık yaz'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Takvim dışında kaydırma iki yönde de ekran değiştirir', (
    tester,
  ) async {
    await pumpApp(tester);
    await settle(tester);
    final outside = find.text('Bugün boş.');

    await tester.fling(outside, const Offset(-300, 0), 1500);
    await settle(tester);
    expect(find.textContaining('HAFTA '), findsOneWidget);

    await tester.fling(
      find.text('Planlanan görev yok.').first,
      const Offset(300, 0),
      1500,
    );
    await settle(tester);
    expect(find.text('Bugün boş.'), findsOneWidget);
    expect(find.textContaining('HAFTA '), findsNothing);

    await tester.fling(outside, const Offset(300, 0), 1500);
    await settle(tester);
    expect(find.textContaining('HAFTA '), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Takvim üzerinde kaydırma ayı değiştirir, ekranı değiştirmez', (
    tester,
  ) async {
    await pumpApp(tester);
    await settle(tester);
    final now = DateTime.now();
    final next = DateFormat(
      'MMMM y',
      'tr',
    ).format(DateTime(now.year, now.month + 1));

    await tester.fling(find.text('15'), const Offset(-300, 0), 1500);
    await settle(tester);

    expect(find.text(next), findsOneWidget);
    expect(find.textContaining('HAFTA '), findsNothing);
    await closeApp(tester);
  });

  testWidgets('Gün bandı yalnızca kayar, dokunulan gün haftayı açar', (
    tester,
  ) async {
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(find.text('Hafta'));
    await settle(tester);

    String week() => tester.widget<Text>(find.textContaining('HAFTA ')).data!;
    final before = week();

    await tester.drag(find.byKey(const Key('day-band')), const Offset(-400, 0));
    await settle(tester);
    expect(week(), before);
    expect(find.textContaining('HAFTA '), findsOneWidget);

    final thisWeek = weekDays(DateTime.now()).first;
    final later = dayKey(addDays(thisWeek, 8));
    await tester.tap(find.byKey(ValueKey(later)));
    await settle(tester);
    expect(week(), isNot(before));

    await tester.tap(find.text('Bugün'));
    await settle(tester);
    expect(week(), before);
    await closeApp(tester);
  });

  testWidgets('Widget bağlantısı Haftayı üstteki ekranın önüne getirir', (
    tester,
  ) async {
    await pumpApp(tester);
    await settle(tester);
    await tester.tap(find.byTooltip('Ayarlar').first);
    await settle(tester);
    expect(find.text('Otomatik taşıma'), findsOneWidget);

    links.controller.add(Uri.parse('ajandam://week?focus=2026-11-03'));
    await settle(tester);

    expect(find.text('Otomatik taşıma'), findsNothing);
    expect(find.textContaining('HAFTA '), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Widget bağlantısı girdi ekranını açmaz, gün açar', (
    tester,
  ) async {
    await pumpApp(tester);
    await settle(tester);

    links.controller.add(Uri.parse('ajandam://day?date=2026-11-03'));
    await settle(tester);

    expect(find.text('3 Kasım Salı'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Ayda başka gün seçilince liste değişir', (tester) async {
    await pumpApp(tester);
    await settle(tester);

    await tester.tap(find.byTooltip('Sonraki ay'));
    await settle(tester);
    await tester.tap(find.text('15'));
    await settle(tester);

    expect(find.text('Bu gün boş.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Bugün'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Alışkanlık eklenir, takvimi işaretlenir, ajandayı karıştırmaz', (
    tester,
  ) async {
    await pumpApp(tester);
    await settle(tester);

    await tester.tap(find.byTooltip('Alışkanlık ekle'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Su iç');
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await settle(tester);

    expect(find.text('Bugün yapılmadı'), findsOneWidget);
    expect(find.text('Hızlı görev ekle (ör. 15:30 Arama)'), findsOneWidget);
    await tester.tap(find.text('Bugün yapılmadı'));
    await settle(tester);
    expect(find.text('Bugün yapıldı'), findsOneWidget);
    expect(find.text('1 gün'), findsNWidgets(2));

    await tester.tap(find.text('Ajanda'));
    await settle(tester);
    expect(find.text('Bugün boş.'), findsOneWidget);
    expect(find.text('Bugün yapıldı'), findsNothing);
    await closeApp(tester);
  });
}
