import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ═════════════ Ларзиш (барои ҷавоби хато) ═════════════

class Shake extends StatefulWidget {
  final int trigger;
  final Widget child;
  const Shake({super.key, required this.trigger, required this.child});

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        return Transform.translate(
          offset: Offset(sin(t * pi * 7) * 10 * (1 - t), 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ═════════════ Дурахши рангин дар тамоми экран ═════════════

class FlashOverlay extends StatefulWidget {
  final int trigger;
  final Color color;
  const FlashOverlay({super.key, required this.trigger, required this.color});

  @override
  State<FlashOverlay> createState() => _FlashOverlayState();
}

class _FlashOverlayState extends State<FlashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void didUpdateWidget(FlashOverlay old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
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
        builder: (_, __) {
          final a = _c.value == 0
              ? 0.0
              : (1 - Curves.easeOut.transform(_c.value)) * 0.30;
          return ColoredBox(color: widget.color.withValues(alpha: a));
        },
      ),
    );
  }
}

// ═════════════ Таркиши ситорачаҳо (барои ҷавоби дуруст) ═════════════

class _Particle {
  final double angle, speed, size;
  final Color color;
  final bool star;
  _Particle(this.angle, this.speed, this.size, this.color, this.star);
}

class BurstEffect extends StatefulWidget {
  final int trigger;
  const BurstEffect({super.key, required this.trigger});

  @override
  State<BurstEffect> createState() => _BurstEffectState();
}

class _BurstEffectState extends State<BurstEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 950));
  List<_Particle> _parts = [];

  static const _colors = [
    Color(0xFFFFD700),
    Color(0xFF22C55E),
    Color(0xFF03DAC6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF7C6CFF),
  ];

  void _regen() {
    final r = Random();
    _parts = List.generate(
      22,
      (i) => _Particle(
        (i / 22) * pi * 2 + r.nextDouble() * 0.3,
        70 + r.nextDouble() * 70,
        4 + r.nextDouble() * 5,
        _colors[r.nextInt(_colors.length)],
        r.nextBool(),
      ),
    );
  }

  @override
  void didUpdateWidget(BurstEffect old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      _regen();
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 260,
        height: 260,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _BurstPainter(_parts, _c.value),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final List<_Particle> parts;
  final double t;
  _BurstPainter(this.parts, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1 || parts.isEmpty) return;
    final c = size.center(Offset.zero);
    final ease = Curves.easeOutCubic.transform(t);

    canvas.drawCircle(
      c,
      18 + 90 * ease,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * (1 - t)
        ..color = const Color(0xFF22C55E).withValues(alpha: (1 - t) * 0.6),
    );

    for (final p in parts) {
      final d = p.speed * ease;
      final pos = c + Offset(cos(p.angle) * d, sin(p.angle) * d + 24 * t * t);
      final paint = Paint()..color = p.color.withValues(alpha: (1 - t));
      final r = p.size * (1 - t * 0.5);
      if (p.star) {
        _star(canvas, pos, r * 1.6, paint, p.angle + t * 3);
      } else {
        canvas.drawCircle(pos, r, paint);
      }
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint, double rot) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = rot + i * pi / 5;
      final p = c + Offset(cos(a) * rad, sin(a) * rad);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

// ═════════════ Пайдошавии эмодзӣ ё матн (✅ ❌ 🔥) ═════════════

class PopBanner extends StatefulWidget {
  final int trigger;
  final Widget child;
  final Duration duration;
  const PopBanner({
    super.key,
    required this.trigger,
    required this.child,
    this.duration = const Duration(milliseconds: 1300),
  });

  @override
  State<PopBanner> createState() => _PopBannerState();
}

class _PopBannerState extends State<PopBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didUpdateWidget(PopBanner old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
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
        builder: (_, child) {
          final t = _c.value;
          if (t == 0 || _c.isCompleted) return const SizedBox.shrink();
          final scale = t < 0.2 ? Curves.easeOutBack.transform(t / 0.2) : 1.0;
          final opacity = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0).toDouble(),
            child: Transform.translate(
              offset: Offset(0, -26 * t),
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Ҳамаи эффектҳои бозӣ дар як қабат
class FxLayer extends StatelessWidget {
  final int goodTrigger;
  final int badTrigger;
  final String emoji;
  final int milestoneTrigger;
  final String milestoneText;

  const FxLayer({
    super.key,
    required this.goodTrigger,
    required this.badTrigger,
    required this.emoji,
    required this.milestoneTrigger,
    required this.milestoneText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
            child: FlashOverlay(trigger: goodTrigger, color: AppColors.correct)),
        Positioned.fill(
            child: FlashOverlay(trigger: badTrigger, color: AppColors.wrong)),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, -0.62),
            child: BurstEffect(trigger: goodTrigger),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, -0.2),
            child: PopBanner(
              trigger: goodTrigger + badTrigger,
              child: Text(emoji, style: const TextStyle(fontSize: 76)),
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, -0.82),
            child: PopBanner(
              trigger: milestoneTrigger,
              duration: const Duration(milliseconds: 2000),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A3D), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.fire.withValues(alpha: 0.5),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  milestoneText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════ Ҳисоби 3 - 2 - 1 - Шурӯъ ═════════════

class StartCountdown extends StatefulWidget {
  final VoidCallback onDone;
  final String readyText;
  final String goText;
  final VoidCallback? onStep;

  const StartCountdown({
    super.key,
    required this.onDone,
    required this.readyText,
    required this.goText,
    this.onStep,
  });

  @override
  State<StartCountdown> createState() => _StartCountdownState();
}

class _StartCountdownState extends State<StartCountdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3000));
  int _lastStep = -1;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final s = min((_c.value * 4).floor(), 3);
      if (s != _lastStep) {
        _lastStep = s;
        widget.onStep?.call();
      }
    });
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['3', '2', '1', widget.goText];
    final colors = [
      AppColors.optionColors[0],
      AppColors.optionColors[1],
      AppColors.optionColors[2],
      AppColors.correct,
    ];
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final raw = _c.value * 4;
        final idx = min(raw.floor(), 3);
        final local = raw - idx;
        final scale =
            1.9 - 0.9 * Curves.easeOutBack.transform(min(local * 2.2, 1.0));
        final opacity = local > 0.78 && idx < 3 ? (1 - (local - 0.78) / 0.22) : 1.0;
        final color = colors[idx];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.readyText,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(260, 260),
                    painter: _RingPainter(local, color),
                  ),
                  Opacity(
                    opacity: opacity.clamp(0.0, 1.0).toDouble(),
                    child: Transform.scale(
                      scale: scale,
                      child: Text(
                        steps[idx],
                        style: TextStyle(
                          fontSize: idx == 3 ? 72 : 120,
                          fontWeight: FontWeight.w900,
                          color: color,
                          shadows: [
                            Shadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  final Color color;
  _RingPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      50 + 80 * Curves.easeOut.transform(t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * (1 - t) + 1
        ..color = color.withValues(alpha: (1 - t) * 0.55),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.color != color;
}

// ═════════════ Дурахши рӯи тугмаҳои калон ═════════════

class ShimmerSweep extends StatefulWidget {
  final Widget child;
  final BorderRadius radius;
  final bool enabled;

  const ShimmerSweep({
    super.key,
    required this.child,
    required this.radius,
    this.enabled = true,
  });

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4200));

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return ClipRRect(
      borderRadius: widget.radius,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) =>
                    CustomPaint(painter: _SweepPainter(_c.value)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  final double t;
  _SweepPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t > 0.45) return;
    final p = t / 0.45;
    final w = size.width * 0.35;
    final x = -w + p * (size.width + w * 2);
    final rect = Rect.fromLTWH(x, 0, w, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0),
          ],
          begin: const Alignment(-1, -0.3),
          end: const Alignment(1, 0.3),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SweepPainter old) => old.t != t;
}

// ═════════════ Нуқтаҳои ҷаҳанда (интизорӣ) ═════════════

class BouncingDots extends StatefulWidget {
  final Color? color;
  final double size;
  const BouncingDots({super.key, this.color, this.size = 9});

  @override
  State<BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.28),
              child: Transform.translate(
                offset: Offset(0, _dy(i)),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _dy(int i) {
    final v = sin(2 * pi * _c.value - i * 0.9);
    return v > 0 ? -widget.size * 0.9 * v : 0;
  }
}

// ═════════════ Набзи оромона ═════════════

class Pulse extends StatefulWidget {
  final Widget child;
  final double amount;
  final Duration period;
  const Pulse({
    super.key,
    required this.child,
    this.amount = 0.08,
    this.period = const Duration(milliseconds: 700),
  });

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(
        scale: 1 + widget.amount * Curves.easeInOut.transform(_c.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}
