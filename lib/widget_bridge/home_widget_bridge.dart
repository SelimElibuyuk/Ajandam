import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/dates.dart';
import '../domain/habit_service.dart';
import '../domain/widget_snapshot.dart';

const _receiver = 'com.selimelibuyuk.ajandam.widget.AjandamWidgetReceiver';
const _habitReceiver = 'com.selimelibuyuk.ajandam.widget.HabitWidgetReceiver';
const _snapshotKey = 'snapshot';
const _pendingKey = 'pending_actions';
const _habitsKey = 'habits';
const _habitPendingKey = 'habit_actions';

class HomeWidgetBridge implements WidgetGateway, HabitWidgetGateway {
  const HomeWidgetBridge();

  @override
  Future<void> publishHabits(String snapshot) async {
    await HomeWidget.saveWidgetData<String>(_habitsKey, snapshot);
    await HomeWidget.updateWidget(qualifiedAndroidName: _habitReceiver);
  }

  @override
  Future<List<HabitAction>> takeHabitActions() async {
    final raw = await HomeWidget.getWidgetData<String>(_habitPendingKey);
    if (raw == null) return const [];
    await HomeWidget.saveWidgetData<String>(_habitPendingKey, null);
    return [
      for (final entry in jsonDecode(raw) as List)
        HabitAction(
          habitId: entry['id'] as String,
          day: parseDayKey(entry['day'] as String),
          count: entry['count'] as int,
          at: DateTime.fromMillisecondsSinceEpoch(entry['at'] as int),
        ),
    ];
  }

  @override
  Future<void> publish(String snapshot, List<DateTime> refreshTimes) async {
    await HomeWidget.saveWidgetData<String>(_snapshotKey, snapshot);
    await HomeWidget.updateWidget(qualifiedAndroidName: _receiver);
    try {
      await HomeWidget.scheduleWidgetUpdates(
        refreshTimes,
        qualifiedAndroidName: _receiver,
      );
    } on PlatformException {
      // Zamanlama olmasa da widget 30 dakikada bir kendini yeniler.
    }
  }

  @override
  Future<List<WidgetAction>> takeActions() async {
    final raw = await HomeWidget.getWidgetData<String>(_pendingKey);
    if (raw == null) return const [];
    await HomeWidget.saveWidgetData<String>(_pendingKey, null);
    return [
      for (final entry in jsonDecode(raw) as List)
        WidgetAction(
          id: entry['id'] as String,
          done: entry['done'] as bool,
          at: DateTime.fromMillisecondsSinceEpoch(entry['at'] as int),
        ),
    ];
  }
}

/// Widget'tan uygulamaya gelen bağlantılar.
class WidgetLinks {
  const WidgetLinks();

  Future<Uri?> initial() => HomeWidget.initiallyLaunchedFromHomeWidget();

  Stream<Uri?> get clicks => HomeWidget.widgetClicked;
}

/// Launcher destekliyorsa ekleme penceresini açar.
Future<bool> requestPinWidget() async {
  if (await HomeWidget.isRequestPinWidgetSupported() != true) return false;
  await HomeWidget.requestPinWidget(qualifiedAndroidName: _receiver);
  return true;
}
