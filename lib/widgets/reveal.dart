import 'package:flutter/material.dart';

/// Пайдошавии ҳамвор (fade + slide-up) бо таъхир, барои ҷойгиршавии пай дар пай
class Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double dy;

  const Reveal({super.key, required this.child, this.delayMs = 0, this.dy = 18});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * widget.dy),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
