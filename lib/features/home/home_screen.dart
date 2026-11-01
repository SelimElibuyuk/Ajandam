import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../month/month_screen.dart';
import '../week/week_screen.dart';

const _week = 0;
const _month = 1;

/// Hafta ve Ay'ı taşıyan ana ekran. İki ekran da canlı kalır, yatay kaydırma
/// her iki yönde de diğerine geçer. Gün bandı kendi kaydırmasını kullanır.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  int _page = _month;
  double _dx = 0;
  double _width = 1;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _slideTo(double target) async {
    final from = _dx;
    void tick() => setState(() {
      _dx = lerpDouble(
        from,
        target,
        Curves.easeOutCubic.transform(_anim.value),
      )!;
    });
    _anim.addListener(tick);
    await _anim.forward(from: 0);
    _anim.removeListener(tick);
  }

  /// Ekranı [direction] yönünde (-1 sola, 1 sağa) kaydırıp diğerine geçer.
  Future<void> _flip(int direction) async {
    await _slideTo(direction * _width);
    if (mounted) {
      setState(() {
        _page = 1 - _page;
        _dx = 0;
      });
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_anim.isAnimating) setState(() => _dx += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_anim.isAnimating) return;
    final velocity = details.primaryVelocity ?? 0;
    final far = _dx.abs() > _width * 0.22;
    final fast = velocity.abs() > 400 && velocity.sign == _dx.sign;
    if (_dx != 0 && (far || fast)) {
      _flip(_dx.sign.toInt());
    } else {
      _slideTo(0);
    }
  }

  void _openPage(int page) {
    if (page != _page && !_anim.isAnimating) _flip(page < _page ? 1 : -1);
  }

  Widget _slide(int page, Widget child) {
    final current = page == _page;
    final hidden = !current && _dx == 0;
    final offset = current ? _dx : (_dx < 0 ? _dx + _width : _dx - _width);
    return Offstage(
      offstage: hidden,
      child: TickerMode(
        enabled: !hidden,
        child: Transform.translate(
          offset: Offset(offset, 0),
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Metin alanları popup içinde; klavye açılırken ekran yeniden hesaplanmaz.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _slide(_week, const WeekScreen()),
                    _slide(_month, const MonthScreen()),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _BottomNav(page: _page, onSelect: _openPage),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.page, required this.onSelect});

  final int page;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavItem(
                icon: Icons.view_week_outlined,
                label: 'Hafta',
                selected: page == _week,
                onTap: () => onSelect(_week),
              ),
              const SizedBox(width: 24),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Ay',
                selected: page == _month,
                onTap: () => onSelect(_month),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.accentText : c.textSoft;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.container : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: context.type.labelMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
