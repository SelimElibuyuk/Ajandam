import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/widget_snapshot.dart';

const _receiver = 'com.selimelibuyuk.ajandam.widget.AjandamWidgetReceiver';
const _snapshotKey = 'snapshot';
const _pendingKey = 'pending_actions';

class HomeWidgetBridge implements WidgetGateway {
  const HomeWidgetBridge();

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
