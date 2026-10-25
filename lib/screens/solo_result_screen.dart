import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../models/game_config.dart';
import '../models/question_model.dart';
import '../services/audio_service.dart';
import '../utils/app_route.dart';
import '../utils/constants.dart';
import '../widgets/animated_background.dart';
import '../widgets/app_button.dart';
import '../widgets/confetti.dart';
import '../widgets/quiz_widgets.dart';
import '../widgets/reveal.dart';
import 'game_screen.dart';

class SoloResultScreen extends StatefulWidget {
  final GameConfig config;
  final int score;
  final int correct;
  final int answered;
  final int bestStreak;
  final List<AnswerRecord> records;
  final bool isNewBest;
  final int bestScore;

  const SoloResultScreen({
    super.key,
    required this.config,
    required this.score,
    required this.correct,
    required this.answered,
    required this.bestStreak,
    required this.records,
    required this.isNewBest,
    required this.bestScore,
  });

  @override
  State<SoloResultScreen> createState() => _SoloResultScreenState();
}

class _SoloResultScreenState extends State<SoloResultScreen> {
  double get _accuracy =>
      widget.answered == 0 ? 0 : widget.correct / widget.answered;

  int get _stars {
    if (_accuracy >= 0.9) return 3;
    if (_accuracy >= 0.6) return 2;
    if (_accuracy >= 0.3) return 1;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    if (_accuracy >= 0.6 || widget.isNewBest) AudioService().playWin();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final mistakes =
        widget.records.where((r) => !r.skipped && !r.correct).toList();
    final avgMs = widget.records.where((r) => !r.skipped).isEmpty
        ? 0
        : widget.records
                .where((r) => !r.skipped)
                .fold<int>(0, (a, r) => a + r.timeMs) ~/
            widget.records.where((r) => !r.skipped).length;

    final title = _stars == 3
        ? lang.t('result_great')
        : _stars == 2
            ? lang.t('result_good')
            : lang.t('result_try');

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                child: Column(
                  children: [
                    // ── Ситораҳо ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 3; i++)
                          _Star(filled: i < _stars, delayMs: 250 + i * 280),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Reveal(
                      delayMs: 200,
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AnimatedScore(
                      value: widget.score,
                      prefix: '⭐ ',
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFB800),
                      ),
                    ),
                    if (widget.isNewBest)
                      Reveal(
                        delayMs: 900,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppColors.brand,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('🎉 ${lang.t('new_record')}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ),
                      )
                    else if (widget.bestScore > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${lang.t('best_score')}: ${widget.bestScore}',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    const SizedBox(height: 22),

                    // ── Омор ──
                    Reveal(
                      delayMs: 500,
                      child: Row(
                        children: [
                          Expanded(
                              child: _StatBox(
                                  icon: '✅',
                                  value: '${widget.correct}/${widget.answered}',
                                  label: lang.t('correct_answers'))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _StatBox(
                                  icon: '🎯',
                                  value: '${(_accuracy * 100).round()}%',
                                  label: lang.t('accuracy'))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Reveal(
                      delayMs: 620,
                      child: Row(
                        children: [
                          Expanded(
                              child: _StatBox(
                                  icon: '🔥',
                                  value: '${widget.bestStreak}',
                                  label: lang.t('best_streak'))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _StatBox(
                                  icon: '⏱️',
                                  value:
                                      '${(avgMs / 1000).toStringAsFixed(1)} ${lang.t('sec_short')}',
                                  label: lang.t('avg_time'))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Баррасии хатоҳо ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        mistakes.isEmpty
                            ? '🌟 ${lang.t('no_mistakes')}'
                            : '${lang.t('review_mistakes')} (${mistakes.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (int i = 0; i < mistakes.length; i++)
                      Reveal(
                        delayMs: 700 + (i < 6 ? i * 90 : 540),
                        child: _MistakeCard(record: mistakes[i], lang: lang),
                      ),
                    const SizedBox(height: 22),

                    AppButton(
                      text: lang.t('play_again'),
                      icon: Icons.replay_rounded,
                      onTap: () => Navigator.pushReplacement(
                        context,
                        appRoute(GameScreen(config: widget.config)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: lang.t('back_home'),
                      icon: Icons.home_rounded,
                      color: const Color(0xFF475569),
                      onTap: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_accuracy >= 0.7 || widget.isNewBest)
            const Positioned.fill(child: Confetti()),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  final bool filled;
  final int delayMs;
  const _Star({required this.filled, required this.delayMs});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 700 + delayMs),
      curve: Interval(delayMs / (700 + delayMs), 1, curve: Curves.elasticOut),
      builder: (_, t, __) => Transform.scale(
        scale: t,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 62,
            color: filled ? const Color(0xFFFFC21A) : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _StatBox({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final AnswerRecord record;
  final AppLanguage lang;
  const _MistakeCard({required this.record, required this.lang});

  @override
  Widget build(BuildContext context) {
    final q = record.question;
    final mine = record.given ?? lang.t('time_up');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.wrong.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.question,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.close_rounded,
                size: 18, color: AppColors.wrong),
            const SizedBox(width: 6),
            Expanded(
                child: Text(mine,
                    style: const TextStyle(color: AppColors.wrong))),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.check_rounded,
                size: 18, color: AppColors.correct),
            const SizedBox(width: 6),
            Expanded(
                child: Text(q.correctAnswerText,
                    style: const TextStyle(
                        color: AppColors.correct,
                        fontWeight: FontWeight.w700))),
          ]),
        ],
      ),
    );
  }
}
