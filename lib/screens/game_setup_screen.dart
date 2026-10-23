import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../models/game_config.dart';
import '../utils/app_route.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/animated_background.dart';
import '../widgets/app_button.dart';
import '../widgets/quiz_widgets.dart';
import '../widgets/reveal.dart';
import 'game_screen.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  String _mode = 'classic';
  String _category = 'all';
  String _difficulty = 'all';
  String _source = 'json';
  int _count = 10;
  int _time = AppConstants.defaultTimePerQuestion;

  void _start() {
    Navigator.push(
      context,
      appRoute(GameScreen(
        config: GameConfig(
          mode: _mode,
          category: _category,
          difficulty: _difficulty,
          count: _count,
          time: _time,
          source: _source,
        ),
      )),
    );
  }

  Widget _section(String title, Widget child, int delay) {
    return Reveal(
      delayMs: delay,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final survival = _mode == 'survival';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(lang.t('play_offline'))),
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 56, 22, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section(
                        lang.t('game_mode'),
                        Row(
                          children: [
                            Expanded(
                              child: _ModeCard(
                                emoji: '🎯',
                                title: lang.t('mode_classic'),
                                subtitle: lang.t('mode_classic_d'),
                                selected: _mode == 'classic',
                                onTap: () => setState(() => _mode = 'classic'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ModeCard(
                                emoji: '❤️',
                                title: lang.t('mode_survival'),
                                subtitle: lang.t('mode_survival_d'),
                                selected: _mode == 'survival',
                                onTap: () => setState(() => _mode = 'survival'),
                              ),
                            ),
                          ],
                        ),
                        0,
                      ),
                      _section(
                        lang.t('category'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in ['all', ...AppConstants.categories])
                              SelectChip(
                                label:
                                    '${AppHelpers.categoryEmoji(c)} ${lang.t('cat_$c')}',
                                selected: _category == c,
                                onTap: () => setState(() => _category = c),
                              ),
                          ],
                        ),
                        80,
                      ),
                      _section(
                        lang.t('difficulty'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SelectChip(
                              label: lang.t('cat_all'),
                              selected: _difficulty == 'all',
                              onTap: () => setState(() => _difficulty = 'all'),
                            ),
                            for (final d in AppConstants.difficulties)
                              SelectChip(
                                label: lang.t(d),
                                color: AppHelpers.difficultyColor(d),
                                selected: _difficulty == d,
                                onTap: () => setState(() => _difficulty = d),
                              ),
                          ],
                        ),
                        140,
                      ),
                      if (!survival)
                        _section(
                          lang.t('question_count'),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final n in [5, 10, 15, 20])
                                SelectChip(
                                  label: '$n',
                                  selected: _count == n,
                                  onTap: () => setState(() => _count = n),
                                ),
                            ],
                          ),
                          200,
                        ),
                      _section(
                        lang.t('time_per_question'),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final s in [15, 20, 30, 45])
                              SelectChip(
                                label: '$s ${lang.t('sec_short')}',
                                selected: _time == s,
                                onTap: () => setState(() => _time = s),
                              ),
                          ],
                        ),
                        260,
                      ),
                      _section(
                        lang.t('question_source'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SelectChip(
                              label: lang.t('from_json'),
                              selected: _source == 'json',
                              onTap: () => setState(() => _source = 'json'),
                            ),
                            SelectChip(
                              label: lang.t('from_admin'),
                              selected: _source == 'admin',
                              onTap: () => setState(() => _source = 'admin'),
                            ),
                            SelectChip(
                              label: lang.t('from_both'),
                              selected: _source == 'both',
                              onTap: () => setState(() => _source = 'both'),
                            ),
                          ],
                        ),
                        320,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                child: AppButton(
                  text: lang.t('start_game'),
                  icon: Icons.play_arrow_rounded,
                  onTap: _start,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.primaryColor.withValues(alpha: 0.18)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? theme.primaryColor
                : Colors.grey.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
