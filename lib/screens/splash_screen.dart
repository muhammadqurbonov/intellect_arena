import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../utils/constants.dart';
import '../widgets/animated_background.dart';
import '../widgets/fx.dart';

/// Экрани оғозӣ: логотип ҷаҳида меояд, ном пайдо мешавад, баъд ба экрани асосӣ мегузарем.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2300));

  @override
  void initState() {
    super.initState();
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
    final lang = Provider.of<AppLanguage>(context);
    final logoAnim = CurvedAnimation(
        parent: _c, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut));
    final textAnim = CurvedAnimation(
        parent: _c, curve: const Interval(0.4, 0.75, curve: Curves.easeOutCubic));

    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: logoAnim.value,
                  child: Transform.rotate(
                    angle: (1 - logoAnim.value) * -0.6,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.brand,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.55),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          size: 70, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: textAnim.value.clamp(0.0, 1.0).toDouble(),
                  child: Transform.translate(
                    offset: Offset(0, (1 - textAnim.value) * 24),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (r) => AppColors.brand.createShader(r),
                          child: Text(
                            lang.t('app_name'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lang.t('splash_tagline'),
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Opacity(
                  opacity: textAnim.value.clamp(0.0, 1.0).toDouble(),
                  child: const BouncingDots(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
