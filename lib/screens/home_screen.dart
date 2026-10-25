import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../language.dart';
import '../services/auth_service.dart';
import '../utils/app_route.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/animated_background.dart';
import '../widgets/app_button.dart';
import '../widgets/confetti.dart';
import '../widgets/fx.dart';
import '../widgets/name_gate.dart';
import '../widgets/reveal.dart';
import 'admin_screen.dart';
import 'game_setup_screen.dart';
import 'online_menu_screen.dart';
import 'profile_screen.dart';
import 'rating_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeToggle;
  final bool isDark;

  const HomeScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDark,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  Map<String, dynamic> _stats = {};
  int _confettiId = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final s = await _auth.getUserStats();
    if (mounted) setState(() => _stats = s);
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, appRoute(page));
    if (mounted) {
      setState(() {});
      _loadStats();
    }
  }

  Future<void> _askName() async {
    await NameGate.check(context);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final isDark = widget.isDark;
    final totalScore = (_stats['totalScore'] as num?)?.toInt() ?? 0;
    final level = AppHelpers.levelFor(totalScore);
    final progress = AppHelpers.levelProgress(totalScore);
    final hasName = _auth.displayName.isNotEmpty;

    return Scaffold(
      body: AnimatedBackground(
        overlay: _confettiId > 0
            ? Confetti(key: ValueKey(_confettiId), count: 80)
            : null,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Column(
              children: [
                // ── Сарлавҳа ──
                Reveal(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (r) =>
                                  AppColors.brand.createShader(r),
                              child: Text(
                                lang.t('app_name'),
                                style: const TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: hasName ? null : _askName,
                              child: Text(
                                hasName
                                    ? '👋 ${_auth.displayName}'
                                    : '✏️ ${lang.t('enter_name')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: hasName
                                      ? Colors.grey
                                      : Theme.of(context).primaryColor,
                                  fontWeight:
                                      hasName ? FontWeight.normal : FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (c, a) => RotationTransition(
                              turns: Tween(begin: 0.75, end: 1.0).animate(a),
                              child: FadeTransition(opacity: a, child: c)),
                          child: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            key: ValueKey(isDark),
                          ),
                        ),
                        onPressed: () => widget.onThemeToggle(!isDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_rounded),
                        onPressed: () => _open(const ProfileScreen()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Корти сатҳ ──
                Reveal(
                  delayMs: 100,
                  child: _LevelCard(
                    level: level,
                    title: lang.t(AppHelpers.levelTitleKey(level)),
                    progress: progress,
                    score: totalScore,
                    nextScore: AppHelpers.scoreForLevel(level + 1),
                    levelLabel: lang.t('level'),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Трофей ──
                Reveal(
                  delayMs: 180,
                  child: _FloatingTrophy(
                    onTap: () => setState(() => _confettiId++),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Меню ──
                Reveal(
                  delayMs: 260,
                  child: _MenuCard(
                    icon: Icons.sports_esports_rounded,
                    label: lang.t('play_offline'),
                    subtitle: lang.t('play_offline_d'),
                    color: const Color(0xFF6C63FF),
                    big: true,
                    onTap: () => _open(const GameSetupScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                Reveal(
                  delayMs: 340,
                  child: _MenuCard(
                    icon: Icons.wifi_rounded,
                    label: lang.t('play_online'),
                    subtitle: lang.t('play_online_d'),
                    color: const Color(0xFF03B5A8),
                    big: true,
                    onTap: () => _open(const OnlineMenuScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                Reveal(
                  delayMs: 420,
                  child: Row(
                    children: [
                      Expanded(
                        child: _MenuCard(
                          icon: Icons.leaderboard_rounded,
                          label: lang.t('rating'),
                          color: const Color(0xFFF5A700),
                          onTap: () => _open(const RatingScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MenuCard(
                          icon: Icons.settings_rounded,
                          label: lang.t('settings'),
                          color: const Color(0xFFFF6B6B),
                          onTap: () => _open(SettingsScreen(
                            isDark: widget.isDark,
                            onThemeToggle: widget.onThemeToggle,
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Reveal(delayMs: 500, child: _AdminButton(lang: lang)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Корти сатҳ ──────────────────────────────────────────────
class _LevelCard extends StatelessWidget {
  final int level;
  final String title;
  final double progress;
  final int score;
  final int nextScore;
  final String levelLabel;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.progress,
    required this.score,
    required this.nextScore,
    required this.levelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, gradient: AppColors.brand),
            child: Text('$level',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$levelLabel $level · $title',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('$score / $nextScore',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withValues(alpha: 0.25),
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Трофеи шиновар ──────────────────────────────────────────
class _FloatingTrophy extends StatefulWidget {
  final VoidCallback onTap;
  const _FloatingTrophy({required this.onTap});

  @override
  State<_FloatingTrophy> createState() => _FloatingTrophyState();
}

class _FloatingTrophyState extends State<_FloatingTrophy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
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
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_c.value);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Transform.translate(
          offset: Offset(0, -8 * t),
          child: Container(
            height: 104,
            width: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brand,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30 + 0.25 * t),
                  blurRadius: 26 + 14 * t,
                  spreadRadius: 2 + 4 * t,
                ),
              ],
            ),
            child:
                const Icon(Icons.emoji_events_rounded, size: 56, color: Colors.white),
          ),
        ));
      },
    );
  }
}

// ─── Корти меню ──────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final bool big;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: ShimmerSweep(
        enabled: big,
        radius: BorderRadius.circular(20),
        child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: big ? 18 : 16, horizontal: 18),
        decoration: BoxDecoration(
          gradient: big
              ? LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, 0.22)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: big ? null : color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: big ? null : Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: big
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment:
              big ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: big ? Colors.white : color, size: big ? 32 : 26),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: big ? Colors.white : color,
                      fontSize: big ? 18 : 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}

// ─── Тугмаи админ ────────────────────────────────────────────
class _AdminButton extends StatefulWidget {
  final AppLanguage lang;
  const _AdminButton({required this.lang});

  @override
  State<_AdminButton> createState() => _AdminButtonState();
}

class _AdminButtonState extends State<_AdminButton> {
  static const _prefKey = 'admin_password';

  Future<String?> _getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _openAdmin() {
    if (!mounted) return;
    Navigator.push(context, appRoute(const AdminScreen()));
  }

  Future<void> _showSetPasswordDialog() async {
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    final lang = widget.lang;
    bool ok = false;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.lock_outline, color: Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          Text(lang.t('admin_panel')),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.t('set_password_hint'),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl1,
              obscureText: true,
              decoration: InputDecoration(
                labelText: lang.t('password'),
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl2,
              obscureText: true,
              decoration: InputDecoration(
                labelText: lang.t('confirm_password'),
                prefixIcon: const Icon(Icons.lock_reset),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (ctrl1.text.length < 4) {
                _snack(lang.t('password_short'));
                return;
              }
              if (ctrl1.text != ctrl2.text) {
                _snack(lang.t('password_mismatch'));
                return;
              }
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_prefKey, ctrl1.text);
              ok = true;
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(lang.t('save')),
          ),
        ],
      ),
    );
    ctrl1.dispose();
    ctrl2.dispose();
    if (ok) _openAdmin();
  }

  Future<void> _showCheckPasswordDialog(String savedPass) async {
    final ctrl = TextEditingController();
    final lang = widget.lang;
    bool ok = false;
    bool reset = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        void verify() {
          if (ctrl.text == savedPass) {
            ok = true;
            Navigator.pop(ctx);
          } else {
            _snack(lang.t('wrong_password'));
          }
        }

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.admin_panel_settings, color: Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            Text(lang.t('admin_panel')),
          ]),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: lang.t('password'),
              prefixIcon: const Icon(Icons.lock),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => verify(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                reset = true;
                Navigator.pop(ctx);
              },
              child: Text(lang.t('forgot_password'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(lang.t('cancel'))),
            ElevatedButton(onPressed: verify, child: Text(lang.t('ok'))),
          ],
        );
      },
    );
    ctrl.dispose();
    if (ok) _openAdmin();
    if (reset && mounted) await _showResetDialog();
  }

  Future<void> _showResetDialog() async {
    final lang = widget.lang;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.t('reset_password_q')),
        content: Text(lang.t('reset_password_text')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(lang.t('no'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(lang.t('yes')),
          ),
        ],
      ),
    );
    if (yes == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
      if (mounted) _onAdminTap();
    }
  }

  Future<void> _onAdminTap() async {
    final saved = await _getSavedPassword();
    if (!mounted) return;
    if (saved == null || saved.isEmpty) {
      await _showSetPasswordDialog();
    } else {
      await _showCheckPasswordDialog(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _onAdminTap,
      icon: const Icon(Icons.admin_panel_settings, size: 18),
      label: Text(widget.lang.t('admin_panel')),
    );
  }
}
