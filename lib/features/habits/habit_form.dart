import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/habit.dart';

const _dayShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

enum _Days { every, weekdays, chosen }

/// Yeni alışkanlık ya da düzenleme. Kaydedilen alışkanlığın kimliğini,
/// silindiyse boş metni döndürür.
Future<String?> showHabitForm(BuildContext context, {Habit? habit}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _HabitForm(habit: habit),
    );

class _HabitForm extends ConsumerStatefulWidget {
  const _HabitForm({this.habit});

  final Habit? habit;

  @override
  ConsumerState<_HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends ConsumerState<_HabitForm> {
  late final _title = TextEditingController(text: widget.habit?.title);
  late _Days _mode = _modeOf(widget.habit?.weekdays ?? const {});
  late Set<int> _days = {...?widget.habit?.weekdays};
  late bool _counted = widget.habit?.isCounted ?? false;
  late int _target = widget.habit?.target ?? 8;
  late int? _color = widget.habit?.color;
  bool _saving = false;

  static _Days _modeOf(Set<int> days) {
    if (days.isEmpty || days.length == 7) return _Days.every;
    if (days.length == 5 && days.containsAll({1, 2, 3, 4, 5})) {
      return _Days.weekdays;
    }
    return _Days.chosen;
  }

  Set<int> get _weekdays => switch (_mode) {
    _Days.every => const {},
    _Days.weekdays => const {1, 2, 3, 4, 5},
    _Days.chosen => _days,
  };

  bool get _valid =>
      _title.text.trim().isNotEmpty &&
      (_mode != _Days.chosen || _days.isNotEmpty);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final service = ref.read(habitServiceProvider);
    final target = _counted ? _target : null;
    final old = widget.habit;
    final String id;
    if (old == null) {
      id = (await service.create(
        title: _title.text,
        weekdays: _weekdays,
        target: target,
        color: _color,
      )).id;
    } else {
      await service.save(
        old.copyWith(
          title: _title.text,
          weekdays: _weekdays,
          target: () => target,
          color: _color,
        ),
      );
      id = old.id;
    }
    if (mounted) Navigator.pop(context, id);
  }

  Future<void> _delete() async {
    final habit = widget.habit!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alışkanlık silinsin mi?'),
        content: Text('“${habit.title}” ve tüm geçmişi silinir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: context.colors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(habitServiceProvider).delete(habit.id);
    if (mounted) Navigator.pop(context, '');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = ref.watch(habitsProvider).value?.length ?? 0;
    final color = _color ?? count % habitColors.length;

    return AlertDialog(
      title: Text(widget.habit == null ? 'Yeni alışkanlık' : 'Alışkanlık'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _title,
              autofocus: widget.habit == null,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'ör. Su iç, Kitap oku',
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            Text(
              'GÜNLER',
              style: context.type.labelSmall?.copyWith(color: c.muted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (mode, label) in [
                  (_Days.every, 'Her gün'),
                  (_Days.weekdays, 'Hafta içi'),
                  (_Days.chosen, 'Seçili günler'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _mode == mode,
                    onSelected: (_) => setState(() {
                      _mode = mode;
                      if (mode == _Days.chosen && _days.isEmpty) {
                        _days = {DateTime.now().weekday};
                      }
                    }),
                  ),
              ],
            ),
            if (_mode == _Days.chosen) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(_dayShort[d - 1]),
                      selected: _days.contains(d),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (on) => setState(() {
                        _days = on ? {..._days, d} : ({..._days}..remove(d));
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Günlük hedef sayısı'),
              subtitle: Text(
                _counted ? 'Her dokunuş 1 artırır' : 'Yaptım / yapmadım',
                style: context.type.bodySmall?.copyWith(color: c.muted),
              ),
              value: _counted,
              onChanged: (on) => setState(() => _counted = on),
            ),
            if (_counted)
              Row(
                children: [
                  IconButton(
                    tooltip: 'Azalt',
                    onPressed: _target > 2
                        ? () => setState(() => _target--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_target', style: context.type.titleMedium),
                  IconButton(
                    tooltip: 'Artır',
                    onPressed: _target < 99
                        ? () => setState(() => _target++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 4),
                  const Text('kez / gün'),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              'RENK',
              style: context.type.labelSmall?.copyWith(color: c.muted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                for (var i = 0; i < habitColors.length; i++)
                  Semantics(
                    button: true,
                    selected: i == color,
                    label: 'Renk ${i + 1}',
                    child: GestureDetector(
                      onTap: () => setState(() => _color = i),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(habitColors[i]),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i == color ? c.text : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.habit != null)
          TextButton(
            onPressed: _delete,
            child: Text('Sil', style: TextStyle(color: c.danger)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: _valid ? _save : null,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
