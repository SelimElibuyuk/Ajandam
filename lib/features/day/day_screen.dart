import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../ui/app_chrome.dart';
import 'day_list.dart';

class DayScreen extends StatelessWidget {
  const DayScreen({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(DateFormat('d MMMM EEEE', 'tr').format(day))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DayList(day: day),
              ),
            ),
            QuickAddBar(day: day),
          ],
        ),
      ),
    );
  }
}
