import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/dates.dart';
import '../domain/reminder_planner.dart';

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
