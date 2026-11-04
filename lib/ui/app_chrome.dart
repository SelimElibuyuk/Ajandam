import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../features/quick_add/quick_add_dialog.dart';

/// Ekranların üst şeridi: Solda başlık, sağda ayarları açan profil simgesi.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.action});

  final Widget title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: c.header,
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Row(
        children: [
          Expanded(child: title),
          ?action,
          IconButton(
            tooltip: 'Ayarlar',
            onPressed: () => context.push('/settings'),
            icon: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: c.high, shape: BoxShape.circle),
              child: Icon(Icons.person_outline, size: 17, color: c.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Altta sabit duran satır, dokununca hızlı ekleme kutusunu açar.
class QuickAddBar extends StatelessWidget {
  const QuickAddBar({super.key, this.day});

  final DateTime? day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: c.container,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: c.hairline),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showQuickAdd(context, day: day),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18, color: c.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hızlı görev ekle (ör. 15:30 Arama)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.bodySmall?.copyWith(
                            color: c.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            height: 42,
            child: IconButton(
              tooltip: 'Ekle',
              style: IconButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => showQuickAdd(context, day: day),
              icon: const Icon(Icons.arrow_upward, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
