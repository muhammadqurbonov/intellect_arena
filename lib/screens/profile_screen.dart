import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../services/auth_service.dart';
import '../utils/achievements.dart';
import '../utils/helpers.dart';
import '../widgets/app_button.dart';
import '../widgets/reveal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _ctrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _ctrl.text = _auth.displayName;
    _loadStats();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final s = await _auth.getUserStats();
    if (!mounted) return;
    setState(() {
      _stats = s;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lang.t('field_required'))));
      return;
    }
    setState(() => _saving = true);
    try {
      await _auth.saveProfile(name);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(lang.t('saved'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${lang.t('error')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _n(String k) => (_stats[k] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final theme = Theme.of(context);
    final total = _n('totalScore');
    final level = AppHelpers.levelFor(total);
    final progress = AppHelpers.levelProgress(total);
    final totalAnswers = _n('totalAnswers');
    final accuracy =
        totalAnswers == 0 ? 0 : (_n('correctAnswers') * 100 / totalAnswers).round();
    final name = _auth.displayName;
    final cardW = (MediaQuery.of(context).size.width - 48 - 20) / 3;

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('profile'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                children: [
                  // ── Аватар бо ҳалқаи пешрафт ──
                  Reveal(
                    child: SizedBox(
                      width: 128,
                      height: 128,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 128,
                            height: 128,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 1100),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => CircularProgressIndicator(
                                value: v,
                                strokeWidth: 6,
                                strokeCap: StrokeCap.round,
                                color: const Color(0xFF03DAC6),
                                backgroundColor:
                                    Colors.grey.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 100,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF03DAC6)],
                              ),
                            ),
                            child: Text(
                              AppHelpers.initial(name),
                              style: const TextStyle(
                                  fontSize: 42,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${lang.t('level')} $level',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(lang.t(AppHelpers.levelTitleKey(level)),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(
                    '$total / ${AppHelpers.scoreForLevel(level + 1)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 22),

                  // ── Омор ──
                  Reveal(
                    delayMs: 120,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _StatCard(w: cardW, label: lang.t('games_played'), value: '${_n('gamesPlayed')}', icon: Icons.sports_esports, color: const Color(0xFF6C63FF)),
                        _StatCard(w: cardW, label: lang.t('games_won'), value: '${_n('gamesWon')}', icon: Icons.emoji_events, color: const Color(0xFFFFB800)),
                        _StatCard(w: cardW, label: lang.t('total_score'), value: '$total', icon: Icons.star, color: const Color(0xFF03B5A8)),
                        _StatCard(w: cardW, label: lang.t('accuracy'), value: '$accuracy%', icon: Icons.track_changes, color: const Color(0xFF22C55E)),
                        _StatCard(w: cardW, label: lang.t('best_streak'), value: '${_n('bestStreak')}', icon: Icons.local_fire_department, color: const Color(0xFFFF8A3D)),
                        _StatCard(w: cardW, label: lang.t('best_score'), value: '${_n('bestScore')}', icon: Icons.military_tech, color: const Color(0xFFEC4899)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // ── Нишонҳо ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(lang.t('achievements'),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 10),
                  Reveal(
                    delayMs: 220,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final a in allAchievements)
                          _AchievementCard(
                            w: (MediaQuery.of(context).size.width - 48 - 10) / 2,
                            emoji: a.emoji,
                            title: lang.t(a.titleKey),
                            desc: lang.t(a.descKey),
                            unlocked: a.unlocked(_stats),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Ном ──
                  TextField(
                    controller: _ctrl,
                    maxLength: 20,
                    decoration: InputDecoration(
                      labelText: lang.t('your_name'),
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    text: lang.t('save'),
                    loading: _saving,
                    onTap: _save,
                    icon: Icons.save,
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double w;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.w,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(value,
                style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final double w;
  final String emoji;
  final String title;
  final String desc;
  final bool unlocked;

  const _AchievementCard({
    required this.w,
    required this.emoji,
    required this.title,
    required this.desc,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: unlocked ? 1 : 0.45,
      child: Container(
        width: w,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? const Color(0xFFFFB800).withValues(alpha: 0.7)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Text(unlocked ? emoji : '🔒', style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  Text(desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
