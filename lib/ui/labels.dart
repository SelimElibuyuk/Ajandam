import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/dates.dart';
import '../domain/reminder_planner.dart';
import '../domain/untimed_reminder.dart';

String dayLabel(DateTime day, DateTime today) {
  final diff = daysBetween(today, day);
  if (diff == 0) return 'Bugün';
  if (diff == 1) return 'Yarın';
  if (diff == -1) return 'Dün';
  return DateFormat('d MMM EEE', 'tr').format(day);
}

String hhmmOf(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String reminderLabel(int? minutes) {
  if (minutes == null) return 'Hatırlatma yok';
  if (minutes == 0) return 'Tam zamanında';
  return '${offsetLabel(minutes)} önce';
}

const reminderOptions = <int?>[null, 0, 5, 15, 30, 60, 1440];

/// Seçim yapılırsa sonucu tek elemanlı kayıtla döndürür, vazgeçilirse null.
Future<(int?,)?> pickReminder(BuildContext context, int? current) {
  return showDialog<(int?,)>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Hatırlatma'),
      children: [
        for (final option in reminderOptions)
          ListTile(
            title: Text(reminderLabel(option)),
            trailing: option == current ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, (option,)),
          ),
        ListTile(
          title: const Text('Özel'),
          onTap: () async {
            final minutes = await _askMinutes(context);
            if (minutes != null && context.mounted) {
              Navigator.pop(context, (minutes,));
            }
          },
        ),
      ],
    ),
  );
}

String _minuteLabel(int minuteOfDay) =>
    hhmmOf(TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60));

String untimedReminderLabel(int offset) => switch (untimedModeOf(offset)) {
  UntimedMode.eveningBefore =>
    'Önceki akşam ${_minuteLabel(untimedMinuteOfDay(offset))}',
  UntimedMode.sameDay =>
    'Aynı gün sabah ${_minuteLabel(untimedMinuteOfDay(offset))}',
  UntimedMode.off => 'Kapalı',
};

/// Saatsiz görev hatırlatmasını seçtirir: önceki akşam, aynı gün veya kapalı.
/// Saatin üstüne dokunulursa saat de seçilir. Vazgeçilirse null döner.
Future<int?> pickUntimedReminder(BuildContext context, int current) {
  final mode = untimedModeOf(current);
  int timeOf(UntimedMode option, int fallback) =>
      mode == option ? untimedMinuteOfDay(current) : fallback;
  final options = {
    UntimedMode.eveningBefore: (
      'Önceki akşam',
      timeOf(UntimedMode.eveningBefore, untimedEveningDefault + 1440),
    ),
    UntimedMode.sameDay: (
      'Aynı gün sabah',
      timeOf(UntimedMode.sameDay, untimedMorningDefault),
    ),
  };
  return showDialog<int>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Saatsiz görev hatırlatması'),
      children: [
        for (final MapEntry(key: option, value: (label, minute))
            in options.entries)
          ListTile(
            title: Text(label),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: minute ~/ 60,
                        minute: minute % 60,
                      ),
                    );
                    if (picked != null && context.mounted) {
                      Navigator.pop(
                        context,
                        untimedOffset(option, picked.hour * 60 + picked.minute),
                      );
                    }
                  },
                  child: Text(_minuteLabel(minute)),
                ),
                Icon(
                  Icons.check,
                  color: option == mode ? null : Colors.transparent,
                ),
              ],
            ),
            onTap: () => Navigator.pop(context, untimedOffset(option, minute)),
          ),
        ListTile(
          title: const Text('Kapalı'),
          trailing: mode == UntimedMode.off ? const Icon(Icons.check) : null,
          onTap: () => Navigator.pop(context, untimedReminderOff),
        ),
      ],
    ),
  );
}

Future<int?> _askMinutes(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Kaç dakika önce?'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: '45'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, int.tryParse(controller.text.trim())),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
}
