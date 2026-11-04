import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/palettes.dart';
import '../../domain/settings.dart';
import '../../ui/labels.dart';
import '../../widget_bridge/home_widget_bridge.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _update(WidgetRef ref, AppSettings next) async {
    await ref.read(settingsRepositoryProvider).save(next);
    await ref.read(itemServiceProvider).replan();
    await ref.read(habitServiceProvider).publishWidget();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = ref.watch(settingsProvider).value ?? const AppSettings();

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          const _Header('Ajanda'),
          _Choice<int>(
            title: 'Hafta başlangıcı',
            value: s.weekStart,
            options: const {
              DateTime.monday: 'Pazartesi',
              DateTime.sunday: 'Pazar',
            },
            onChanged: (v) => _update(ref, s.copyWith(weekStart: v)),
          ),
          ListTile(
            title: const Text('Varsayılan hatırlatma'),
            subtitle: Text(reminderLabel(s.defaultReminderMin)),
            onTap: () async {
              final picked = await pickReminder(context, s.defaultReminderMin);
              final minutes = picked?.$1;
              if (minutes != null) {
                await _update(ref, s.copyWith(defaultReminderMin: minutes));
              }
            },
          ),
          SwitchListTile(
            title: const Text('Otomatik taşıma'),
            subtitle: const Text('Tamamlanmayan görevler ertesi güne geçer'),
            value: s.autoRollover,
            onChanged: (v) => _update(ref, s.copyWith(autoRollover: v)),
          ),
          const _Header('Görev ömrü'),
          SwitchListTile(
            title: const Text('Yapılmayan görevleri sil'),
            subtitle: const Text('“Önemli” görevler silinmez'),
            value: s.lifecycleEnabled,
            onChanged: (v) => _update(ref, s.copyWith(lifecycleEnabled: v)),
          ),
          if (s.lifecycleEnabled) ...[
            _Choice<int>(
              title: 'Silinme süresi',
              value: s.lifecycleTtlDays,
              options: const {7: '7 gün', 15: '15 gün', 30: '30 gün'},
              onChanged: (v) => _update(ref, s.copyWith(lifecycleTtlDays: v)),
            ),
            _Choice<int>(
              title: 'Hatırlatma aralığı',
              value: s.lifecycleIntervalDays,
              options: const {1: 'Her gün', 2: '2 günde bir', 3: '3 günde bir'},
              onChanged: (v) =>
                  _update(ref, s.copyWith(lifecycleIntervalDays: v)),
            ),
          ],
          const _Header('Görünüm'),
          _PalettePicker(
            selected: s.palette,
            onChanged: (id) => _update(ref, s.copyWith(palette: id)),
          ),
          SwitchListTile(
            title: const Text('Yüksek kontrast'),
            subtitle: const Text(
              "Yazılar ve kenarlıklar daha belirgin; widget'lara da uygulanır",
            ),
            value: s.highContrast,
            onChanged: (v) => _update(ref, s.copyWith(highContrast: v)),
          ),
          _Choice<String>(
            title: 'Açık / koyu',
            value: s.theme,
            options: const {
              'system': 'Sistem',
              'light': 'Açık',
              'dark': 'Koyu',
            },
            onChanged: (v) => _update(ref, s.copyWith(theme: v)),
          ),
          const _Header('Widget'),
          _Choice<String>(
            title: 'Widget\'a dokununca',
            value: s.widgetTapMode,
            options: const {'week_view': 'Hafta', 'quick_add': 'Hızlı ekleme'},
            onChanged: (v) => _update(ref, s.copyWith(widgetTapMode: v)),
          ),
          ListTile(
            title: const Text('Ana ekrana widget ekle'),
            onTap: () => _addWidget(context),
          ),
          const _Header('Diğer'),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Çöp kutusu'),
            onTap: () => context.push('/trash'),
          ),
          ListTile(
            leading: const Icon(Icons.battery_alert_outlined),
            title: const Text('Bildirimler geç mi geliyor?'),
            onTap: () => _showBatteryHelp(context),
          ),
          const SizedBox(height: 16),
          Center(child: Text('Sürüm 0.1.0', style: theme.textTheme.bodySmall)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _addWidget(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await requestPinWidget()) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Ana ekranda boş bir yere basılı tut, Widget\'lar bölümünden '
            'Ajandam\'ı seç.',
          ),
        ),
      );
    }
  }

  void _showBatteryHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirimler geç mi geliyor?'),
        content: const Text(
          'Bazı telefonlar arka plandaki uygulamaları durdurur. Xiaomi için: '
          'Ayarlar > Uygulamalar > Ajandam bölümünde Otomatik başlatmayı aç, '
          'Pil tasarrufunu “Kısıtlama yok” yap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: context.colors.accentText,
        ),
      ),
    );
  }
}

class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [
          for (final MapEntry(:key, value: label) in options.entries)
            DropdownMenuItem(value: key, child: Text(label)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

/// Renk temaları: her biri kendi zemininde vurgu rengiyle küçük bir örnek.
/// Örnek, şu anki açık/koyu kipine göre gösterilir.
class _PalettePicker extends StatelessWidget {
  const _PalettePicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final current = paletteById(selected).id;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Renk teması', style: context.type.bodyLarge),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final palette in palettes)
                _PaletteSwatch(
                  palette: palette,
                  colors: dark ? palette.dark : palette.light,
                  selected: palette.id == current,
                  outline: c.accent,
                  hairline: c.hairline,
                  onTap: () => onChanged(palette.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.palette,
    required this.colors,
    required this.selected,
    required this.outline,
    required this.hairline,
    required this.onTap,
  });

  final ColorPalette palette;
  final PaletteColors colors;
  final bool selected;
  final Color outline;
  final Color hairline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${palette.name} teması',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(colors.surface),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? outline : hairline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final color in [
                    colors.accent,
                    colors.accentText,
                    colors.container,
                  ])
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(colors.hairline)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                palette.name,
                style: context.type.bodyMedium?.copyWith(
                  color: Color(colors.text),
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
