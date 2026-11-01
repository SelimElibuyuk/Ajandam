import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../quick_add/quick_add_sheet.dart';
import 'day_agenda.dart';

class DayScreen extends StatelessWidget {
  const DayScreen({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(DateFormat('d MMMM EEEE', 'tr').format(day))),
      body: DayAgenda(day: day),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ekle',
        onPressed: () => showQuickAdd(context, day: day),
        child: const Icon(Icons.add),
      ),
    );
  }
}
