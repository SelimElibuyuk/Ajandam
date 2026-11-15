import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app/theme.dart';

/// Bir baloncuk: [target] varsa onun çevresi aydınlatılır, yoksa ortada durur.
class CoachStep {
  const CoachStep({
    this.target,
    required this.title,
    required this.text,
    this.example,
  });

  final GlobalKey? target;
  final String title;
  final String text;

  /// Yazı örneği, ör. “yarın 15:30 dişçi”.
  final String? example;
}

/// Açık baloncuk turu: [done] kullanıcı bitirince ya da geçince tamamlanır,
/// [close] turu dışarıdan kapatır (ör. altındaki pencere kapanınca).
class CoachTour {
  CoachTour._(this._entry);

  final OverlayEntry _entry;
  final _done = Completer<void>();

  Future<void> get done => _done.future;

  void close() {
    if (_done.isCompleted) return;
    _entry.remove();
    _done.complete();
  }
}

/// Baloncukları sırayla gösterir.
CoachTour showCoachTour(BuildContext context, List<CoachStep> steps) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final CoachTour tour;
  final entry = OverlayEntry(
    builder: (_) => _CoachOverlay(steps: steps, onDone: () => tour.close()),
  );
  tour = CoachTour._(entry);
  overlay.insert(entry);
  return tour;
}

class _CoachOverlay extends StatefulWidget {
  const _CoachOverlay({required this.steps, required this.onDone});

  final List<CoachStep> steps;
  final VoidCallback onDone;

  @override
  State<_CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<_CoachOverlay> {
  int _index = 0;
  Rect? _rect;
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    _skipMissing();
    SchedulerBinding.instance.addPostFrameCallback(_follow);
  }

  /// Her çizimden sonra hedef yeniden ölçülür; klavye ya da animasyonla
  /// kayarsa aydınlık alan onu izler. Kendisi çizim istemez, yalnızca ölçü
  /// değişince yeniler.
  void _follow(Duration _) {
    if (!mounted) return;
    final rect = _measure();
    if (rect != _rect || !_measured) {
      setState(() {
        _rect = rect;
        _measured = true;
      });
    }
    SchedulerBinding.instance.addPostFrameCallback(_follow);
  }

  CoachStep get _step => widget.steps[_index];

  /// Ekranda olmayan hedefin baloncuğu atlanır.
  void _skipMissing() {
    while (_index < widget.steps.length - 1 &&
        widget.steps[_index].target != null &&
        widget.steps[_index].target!.currentContext == null) {
      _index++;
    }
  }

  Rect? _measure() {
    final box = _step.target?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final me = context.findRenderObject();
    final origin = box.localToGlobal(
      Offset.zero,
      ancestor: me is RenderBox && me.attached ? me : null,
    );
    return (origin & box.size).inflate(6);
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onDone();
      return;
    }
    setState(() {
      _index++;
      _skipMissing();
      _rect = _measure();
    });
  }

  @override
  Widget build(BuildContext context) {
    // İlk çizimde hedef henüz ölçülmedi; baloncuk yanlış yerde görünmesin.
    if (!_measured) return const SizedBox.expand();
    final c = context.colors;
    final media = MediaQuery.of(context);
    final rect = _rect;
    final last = _index == widget.steps.length - 1;
    final screen = media.size;
    final bottomLimit = screen.height - media.viewInsets.bottom;

    const width = 320.0;
    final left = rect == null
        ? (screen.width - width) / 2
        : (rect.center.dx - width / 2).clamp(16.0, screen.width - width - 16);
    final below = rect != null && rect.center.dy < bottomLimit / 2;

    final bubble = _Bubble(
      step: _step,
      position: '${_index + 1}/${widget.steps.length}',
      last: last,
      onNext: _next,
      onSkip: widget.onDone,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: CustomPaint(
                painter: _Scrim(
                  hole: rect,
                  color: Colors.black.withValues(alpha: 0.62),
                  ring: c.accent,
                ),
              ),
            ),
          ),
          if (rect == null)
            Positioned(
              left: left,
              width: width,
              top: 0,
              bottom: media.viewInsets.bottom,
              child: Center(child: bubble),
            )
          else if (below)
            Positioned(
              left: left,
              width: width,
              top: rect.bottom + 12,
              child: bubble,
            )
          else
            Positioned(
              left: left,
              width: width,
              bottom: screen.height - rect.top + 12,
              child: bubble,
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.step,
    required this.position,
    required this.last,
    required this.onNext,
    required this.onSkip,
  });

  final CoachStep step;
  final String position;
  final bool last;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.type;
    final tone = c.tone();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
      decoration: BoxDecoration(
        color: c.high,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.title, style: t.titleMedium),
          const SizedBox(height: 4),
          Text(step.text, style: t.bodyMedium?.copyWith(color: c.textSoft)),
          if (step.example != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                step.example!,
                style: t.bodyMedium?.copyWith(color: tone.foreground),
              ),
            ),
          ],
          Row(
            children: [
              Text(position, style: t.labelSmall?.copyWith(color: c.muted)),
              const Spacer(),
              if (!last)
                TextButton(onPressed: onSkip, child: const Text('Geç')),
              TextButton(
                onPressed: onNext,
                child: Text(last ? 'Tamam' : 'İleri'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Scrim extends CustomPainter {
  _Scrim({required this.hole, required this.color, required this.ring});

  final Rect? hole;
  final Color color;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Path()..addRect(Offset.zero & size);
    final h = hole;
    if (h == null) {
      canvas.drawPath(all, Paint()..color = color);
      return;
    }
    final cut = RRect.fromRectAndRadius(h, const Radius.circular(10));
    canvas.drawPath(
      Path.combine(PathOperation.difference, all, Path()..addRRect(cut)),
      Paint()..color = color,
    );
    canvas.drawRRect(
      cut,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_Scrim old) =>
      old.hole != hole || old.color != color || old.ring != ring;
}
