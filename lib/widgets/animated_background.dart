import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'fx.dart';

/// Фони градиентӣ бо доираҳои нурии оҳиста ҳаракаткунанда ва аломатҳои шино (? ★ ✦).
/// [overlay] - эффектҳо аз боло, [shake] - ларзиши тамоми экран ҳангоми тағйир.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final Widget? overlay;
  final int shake;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.overlay,
    this.shake = 0,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 28))
      ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Агар корбар аниматсияро хомӯш карда бошад
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg1 = dark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F2FF);
    final bg2 = dark ? const Color(0xFF16213E) : const Color(0xFFE6E9FF);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bg1, bg2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(
                painter: _OrbPainter(_c.value, dark),
                foregroundPainter: _SymbolPainter(_c.value, dark),
              ),
            ),
          ),
        ),
        Positioned.fill(child: Shake(trigger: widget.shake, child: widget.child)),
        if (widget.overlay != null) Positioned.fill(child: widget.overlay!),
      ],
    );
  }
}

class _Orb {
  final double sx, sy, phase, radius;
  final Color color;
  const _Orb(this.sx, this.sy, this.phase, this.radius, this.color);
}

class _OrbPainter extends CustomPainter {
  final double t;
  final bool dark;
  _OrbPainter(this.t, this.dark);

  static const _orbs = [
    _Orb(1, 2, 0.00, 0.55, Color(0xFF6C63FF)),
    _Orb(2, 1, 0.30, 0.50, Color(0xFF03DAC6)),
    _Orb(1, 3, 0.60, 0.42, Color(0xFFEC4899)),
    _Orb(3, 1, 0.85, 0.38, Color(0xFFF59E0B)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final o in _orbs) {
      final cx = size.width * (0.5 + 0.42 * sin(2 * pi * (t * o.sx + o.phase)));
      final cy = size.height * (0.5 + 0.42 * cos(2 * pi * (t * o.sy + o.phase)));
      final r = size.shortestSide * o.radius;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            o.color.withValues(alpha: dark ? 0.22 : 0.18),
            o.color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t || old.dark != dark;
}

class _Sym {
  final String ch;
  final double x, speed, phase, size;
  final int color;
  const _Sym(this.ch, this.x, this.speed, this.phase, this.size, this.color);
}

/// Аломатҳои саволу ситора, ки оҳиста боло мебароянд ва нопадид мешаванд
class _SymbolPainter extends CustomPainter {
  final double t;
  final bool dark;
  _SymbolPainter(this.t, this.dark);

  static const _syms = [
    _Sym('?', 0.10, 1, 0.00, 30, 0),
    _Sym('★', 0.85, 2, 0.30, 20, 2),
    _Sym('✦', 0.30, 1, 0.55, 24, 1),
    _Sym('?', 0.62, 3, 0.80, 34, 3),
    _Sym('◆', 0.92, 1, 0.15, 16, 0),
    _Sym('✦', 0.05, 2, 0.70, 18, 2),
    _Sym('★', 0.48, 1, 0.42, 22, 1),
    _Sym('?', 0.75, 2, 0.10, 26, 3),
    _Sym('✦', 0.20, 3, 0.35, 16, 3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _syms) {
      final prog = (t * s.speed + s.phase) % 1.0;
      final y = size.height * (1.05 - prog * 1.1);
      final x = s.x * size.width + sin(prog * 2 * pi * 2 + s.phase * 6) * 16;
      final alpha = sin(prog * pi) * (dark ? 0.17 : 0.15);
      final tp = TextPainter(
        text: TextSpan(
          text: s.ch,
          style: TextStyle(
            fontSize: s.size,
            fontWeight: FontWeight.w900,
            color: AppColors.optionColors[s.color].withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(sin(prog * 6 + s.phase * 4) * 0.5);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SymbolPainter old) => old.t != t || old.dark != dark;
}
