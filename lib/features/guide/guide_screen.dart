import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

/// İlk açılışta gösterilen üç sayfalık rehber; Ayarlar'dan yeniden açılır.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _count = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _next() {
    if (_page == _count - 1) {
      _close();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final last = _page == _count - 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: TextButton(
                    onPressed: last ? null : _close,
                    child: Text(last ? '' : 'Atla'),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: const [_WidgetPage(), _WritePage(), _KindPage()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    for (var i = 0; i < _count; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _page ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page ? c.accent : c.high,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _next,
                      child: Text(last ? 'Başla' : 'İleri'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sayfa iskeleti: simge, başlık, kısa açıklama ve altında içerik.
class _Page extends StatelessWidget {
  const _Page({
    required this.icon,
    required this.title,
    required this.lead,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String lead;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.type;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: c.accentText),
        ),
        const SizedBox(height: 16),
        Text(title, style: t.headlineSmall),
        const SizedBox(height: 8),
        Text(lead, style: t.bodyLarge?.copyWith(color: c.textSoft)),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

class _WidgetPage extends StatelessWidget {
  const _WidgetPage();

  @override
  Widget build(BuildContext context) {
    return const _Page(
      icon: Icons.widgets_outlined,
      title: 'Ajandan ana ekranında',
      lead:
          'Ajandam en çok widget ile işe yarar. Uygulamayı açmadan bugünü '
          'görür, görev ekler, işini bitirince tik atarsın.',
      children: [
        _Point(
          icon: Icons.add_to_home_screen_outlined,
          title: 'Widget ekle',
          body:
              'Ana ekranda boş bir yere basılı tut, Widget\'lar bölümünden '
              'Ajandam\'ı seç. Ayarlar\'dan da ekleyebilirsin.',
        ),
        _Point(
          icon: Icons.add,
          title: 'Hızlı ekle',
          body:
              'Widget\'taki + ya da uygulamanın altındaki çubuk ekleme '
              'kutusunu açar. Tek satır yazman yeter.',
        ),
        _Point(
          icon: Icons.mic_none,
          title: 'Sesle söyle',
          body:
              'Mikrofona bas, konuş. Kısa duraklamalarda dinlemeye devam '
              'eder; söylediklerin yazdıklarının sonuna eklenir.',
        ),
        _Point(
          icon: Icons.settings_outlined,
          title: 'Ayarlar',
          body:
              'Sağ üstteki dişli: renk teması, hatırlatma saatleri, widget '
              've bu rehber.',
        ),
      ],
    );
  }
}

class _WritePage extends StatelessWidget {
  const _WritePage();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Page(
      icon: Icons.edit_note,
      title: 'Yaz, gerisini Ajandam anlar',
      lead:
          'Günü, saati ve tekrarı ayrıca seçmene gerek yok. Konuşur gibi '
          'yaz; anladığı kısımlar renklenir, geri kalanı görevin adı olur.',
      children: [
        const _Example('yarın 15:30 dişçi', ['Yarın', '15:30']),
        const _Example("saat 2'yi çeyrek geçe toplantı", ['14:15']),
        const _Example('perşembe öğleden sonra 3te kuaför', [
          'Perşembe',
          '15:00',
        ]),
        const _Example('salıdan sonra fatura öde', ['Çarşamba']),
        const _Example('3 gün sonra kargo', ['3 gün sonra']),
        const _Example('her pazartesi spor', ['Her pazartesi']),
        const _Example('her gün 2 hafta boyunca ilaç', ['Her gün', '2 hafta']),
        const _Example("her ayın 15'i kira öde", ['Her ay 15\'i']),
        const SizedBox(height: 8),
        _Note(
          color: c.textSoft,
          text:
              'Yanlış anladıysa alttaki düğmenin × işaretine bas; o kelime '
              'görevin adında kalır. Küçük yazım hatalarını kendisi düzeltir: '
              '“saı” yazarsan salı anlar.',
        ),
      ],
    );
  }
}

class _KindPage extends StatelessWidget {
  const _KindPage();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Page(
      icon: Icons.event_outlined,
      title: 'Görev mi, etkinlik mi?',
      lead:
          'Görev yapılacak bir iştir, bitince tik atarsın. Etkinlik takvimde '
          'yer kaplar: bir başlangıcı ve bitişi vardır.',
      children: [
        const _Point(
          icon: Icons.check_box_outlined,
          title: 'Görev',
          body:
              'Gün ve saat yazman yeterli. Saatsiz görevi bir gün önce '
              'akşam hatırlatırız.',
        ),
        const _Example('yarın 10:00 rapor gönder', ['Görev', 'Yarın', '10:00']),
        const SizedBox(height: 8),
        const _Point(
          icon: Icons.event_outlined,
          title: 'Etkinlik',
          body:
              'Saat aralığı, süre ya da gün aralığı yazınca kendiliğinden '
              'etkinlik olur.',
        ),
        const _Example('cuma 14-16 toplantı', ['Etkinlik', '14:00', '2 saat']),
        const _Example('yarın 19:00 2 saat sinema', [
          'Etkinlik',
          '19:00',
          '2 saat',
        ]),
        const _Example('20-25 aralık tatil', ['Etkinlik', '20–25 Aralık']),
        const SizedBox(height: 8),
        _Note(
          color: c.textSoft,
          text:
              'Elle değiştirmek için ekleme kutusunda en soldaki Görev / '
              'Etkinlik düğmesine dokun.',
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.type;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: c.accentText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleSmall),
                const SizedBox(height: 2),
                Text(body, style: t.bodyMedium?.copyWith(color: c.textSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Yazılan örnek ve Ajandam'ın ondan anladıkları.
class _Example extends StatelessWidget {
  const _Example(this.input, this.result);

  final String input;
  final List<String> result;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.type;
    final tone = c.tone();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.container,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(input, style: t.bodyLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final part in result)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tone.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    part,
                    style: t.labelMedium?.copyWith(color: tone.foreground),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.type.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
