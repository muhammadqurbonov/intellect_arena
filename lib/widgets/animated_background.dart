import 'dart:math';
import 'package:flutter/material.dart';

/// Фони градиентӣ бо доираҳои нурии оҳиста ҳаракаткунанда
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

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
              ),
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
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
