import 'dart:math';
import 'package:flutter/material.dart';

/// Конфетти: як маротиба меафтад ва нопадид мешавад
class Confetti extends StatefulWidget {
  final int count;
  final Duration duration;

  const Confetti({
    super.key,
    this.count = 90,
    this.duration = const Duration(milliseconds: 4200),
  });

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Piece {
  final double x, delay, speed, size, sway, rot, rotSpeed;
  final Color color;
  final bool round;
  _Piece(this.x, this.delay, this.speed, this.size, this.sway, this.rot,
      this.rotSpeed, this.color, this.round);
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Piece> _pieces;

  static const _colors = [
    Color(0xFF6C63FF),
    Color(0xFF03DAC6),
    Color(0xFFFFD700),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
  ];

  @override
  void initState() {
    super.initState();
    final r = Random();
    _pieces = List.generate(widget.count, (_) {
      return _Piece(
        r.nextDouble(),
        r.nextDouble() * 0.35,
        0.75 + r.nextDouble() * 0.5,
        6 + r.nextDouble() * 8,
        0.02 + r.nextDouble() * 0.06,
        r.nextDouble() * pi * 2,
        (r.nextDouble() - 0.5) * 12,
        _colors[r.nextInt(_colors.length)],
        r.nextBool(),
      );
    });
    _c = AnimationController(vsync: this, duration: widget.duration)..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => _c.isCompleted
            ? const SizedBox.shrink()
            : CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(_pieces, _c.value),
              ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t;
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final prog = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0).toDouble();
      if (prog <= 0) continue;
      final y = -20 + prog * (size.height + 60) * p.speed;
      final x = size.width * p.x + sin(prog * pi * 4) * size.width * p.sway;
      final alpha = prog > 0.8 ? (1 - prog) / 0.2 : 1.0;
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + prog * p.rotSpeed);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
