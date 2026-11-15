import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/sync/calendar_sync.dart';
import '../../data/sync/device_calendar.dart';

/// Ayarlar'daki Google Takvim bölümü.
class CalendarSection extends ConsumerWidget {
  const CalendarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendars = ref.watch(calendarsProvider).value ?? const <Calendar>[];
    final shown = calendars.where((c) => c.isVisible).toList();
    if (shown.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.event_available_outlined),
        title: const Text('Google Takvim\'i bağla'),
        subtitle: const Text(
          'Telefondaki Google takviminle iki yönlü eşitlenir',
        ),
        onTap: () => _pick(context, ref, const []),
      );
    }
    final target = shown.firstWhere(
      (c) => c.isDefault,
      orElse: () => shown.first,
    );
    final last = shown
        .map((c) => c.lastSyncedAt ?? 0)
        .reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.event_available_outlined),
          title: const Text('Takvimler'),
          subtitle: Text(
            shown.length == 1
                ? target.name
                : '${target.name} ve ${shown.length - 1} takvim daha',
          ),
          onTap: () => _pick(context, ref, shown),
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Şimdi eşitle'),
          subtitle: Text(_lastLabel(last)),
          onTap: () => _syncNow(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.link_off),
          title: const Text('Bağlantıyı kes'),
          onTap: () => _disconnect(context, ref),
        ),
      ],
    );
  }

  static String _lastLabel(int ms) {
    if (ms == 0) return 'Henüz eşitlenmedi';
    final time = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final sameDay =
        time.year == now.year && time.month == now.month && time.day == now.day;
    final clock = DateFormat('HH:mm').format(time);
    return sameDay
        ? 'Son eşitleme bugün $clock'
        : 'Son eşitleme ${DateFormat('d MMMM HH:mm', 'tr').format(time)}';
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    List<Calendar> current,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final gateway = ref.read(calendarGatewayProvider);
    if (!await gateway.requestPermission()) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Takvim izni verilmedi. Telefonun Ayarlar › Uygulamalar › '
            'Ajandam › İzinler bölümünden açabilirsin.',
          ),
        ),
      );
      return;
    }
    final available = await gateway.calendars();
    if (!context.mounted) return;
    if (available.where((c) => c.writable).isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Takvim bulunamadı'),
          content: const Text(
            'Telefonda yazılabilir bir takvim yok. Telefonun Ayarlar › '
            'Hesaplar › Google bölümünde Takvim eşitlemesinin açık olduğundan '
            'emin ol, sonra tekrar dene.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }
    final choice = await showModalBottomSheet<_Choice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CalendarPicker(
        available: available,
        shown: {for (final c in current) int.parse(c.id)},
        target: current
            .where((c) => c.isDefault)
            .map((c) => int.parse(c.id))
            .firstOrNull,
        connecting: current.isEmpty,
      ),
    );
    if (choice == null) return;
    final sync = ref.read(calendarSyncProvider);
    await sync.configure(shown: choice.shown, target: choice.target);
    final result = await sync.sync();
    if (result != null && current.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Bağlandı: ${result.pulled} girdi geldi, ${result.pushed} girdi '
            'takvime yazıldı.',
          ),
        ),
      );
    }
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final sync = ref.read(calendarSyncProvider);
    final result = await sync.sync();
    final text = switch (result) {
      null => 'Eşitlenemedi, sonra yeniden denenecek.',
      SyncResult(permission: false) =>
        'Takvim izni kapalı; telefonun ayarlarından açabilirsin.',
      SyncResult(pushed: 0, pulled: 0, removed: 0) => 'Her şey güncel.',
      final r =>
        'Eşitlendi: ${r.pulled + r.removed} değişiklik geldi, '
            '${r.pushed} gönderildi.',
    };
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bağlantı kesilsin mi?'),
        content: const Text(
          'Google Takvim\'den gelen girdiler Ajandam\'dan kalkar. Ajandam\'da '
          'eklediklerin kalır; Google Takvim\'deki kopyalarına dokunulmaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bağlantıyı kes'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(calendarSyncProvider).disconnect();
  }
}

typedef _Choice = ({List<DeviceCalendarInfo> shown, DeviceCalendarInfo target});

class _CalendarPicker extends StatefulWidget {
  const _CalendarPicker({
    required this.available,
    required this.shown,
    required this.target,
    required this.connecting,
  });

  final List<DeviceCalendarInfo> available;
  final Set<int> shown;
  final int? target;
  final bool connecting;

  @override
  State<_CalendarPicker> createState() => _CalendarPickerState();
}

class _CalendarPickerState extends State<_CalendarPicker> {
  late final Set<int> _shown;
  late int _target;

  @override
  void initState() {
    super.initState();
    final writable = widget.available.where((c) => c.writable).toList();
    final primary = writable
        .where((c) => c.isGoogle && c.primary)
        .followedBy(writable.where((c) => c.isGoogle))
        .followedBy(writable)
        .first;
    _target = widget.target ?? primary.id;
    _shown = widget.shown.isEmpty ? {primary.id} : {...widget.shown};
    _shown.add(_target);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.type;
    final writable = widget.available
        .where((cal) => cal.writable && _shown.contains(cal.id))
        .toList();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text('Gösterilecek takvimler', style: t.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Bu takvimlerdeki etkinlikler Ajandam\'da ve widget\'ta görünür.',
                style: t.bodySmall?.copyWith(color: c.textSoft),
              ),
            ),
            for (final cal in widget.available)
              CheckboxListTile(
                value: _shown.contains(cal.id),
                onChanged: cal.id == _target
                    ? null
                    : (on) => setState(() {
                        on == true ? _shown.add(cal.id) : _shown.remove(cal.id);
                      }),
                secondary: _Dot(color: cal.color),
                title: Text(cal.name),
                subtitle: Text(
                  cal.writable ? cal.account : '${cal.account} · salt okunur',
                ),
              ),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text(
                'Yeni girdiler şuraya yazılsın',
                style: t.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Ajandam\'da eklediğin görev ve etkinlikler (bugün ve sonrası) '
                'bu takvime yazılır. Görevler takvimde ✓ ile işaretlenir.',
                style: t.bodySmall?.copyWith(color: c.textSoft),
              ),
            ),
            RadioGroup<int>(
              groupValue: _target,
              onChanged: (id) {
                if (id != null) setState(() => _target = id);
              },
              child: Column(
                children: [
                  for (final cal in writable)
                    RadioListTile<int>(
                      value: cal.id,
                      title: Text(cal.name),
                      subtitle: Text(cal.account),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: FilledButton(
                onPressed: () {
                  final byId = {for (final c in widget.available) c.id: c};
                  Navigator.pop<_Choice>(context, (
                    shown: [for (final id in _shown) byId[id]!],
                    target: byId[_target]!,
                  ));
                },
                child: Text(widget.connecting ? 'Bağla' : 'Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final int? color;

  @override
  Widget build(BuildContext context) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: color == null ? context.colors.muted : Color(color! | 0xFF000000),
      shape: BoxShape.circle,
    ),
  );
}
