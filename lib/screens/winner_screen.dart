import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../models/question_model.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/animated_background.dart';
import '../widgets/app_button.dart';
import '../widgets/confetti.dart';
import '../widgets/player_tile.dart';
import '../widgets/quiz_widgets.dart';
import '../widgets/reveal.dart';

class WinnerScreen extends StatefulWidget {
  final List<PlayerModel> players;
  final bool isOnline;

  const WinnerScreen({super.key, required this.players, this.isOnline = false});

  @override
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final List<PlayerModel> _sorted;
  final _myUid = AuthService().uid;

  @override
  void initState() {
    super.initState();
    _sorted = List<PlayerModel>.from(widget.players)
      ..sort((a, b) {
        final c = b.score.compareTo(a.score);
        return c != 0 ? c : b.correct.compareTo(a.correct);
      });
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _anim.forward();
    AudioService().playWin();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  int get _myRank {
    final i = _sorted.indexWhere((p) => p.uid == _myUid);
    return i < 0 ? 0 : i + 1;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final winner = _sorted.isNotEmpty ? _sorted.first : null;
    final podium = _sorted.take(3).toList();
    final iWon = _myRank == 1;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBackground(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  ScaleTransition(
                    scale: _scale,
                    child: Column(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 68)),
                        Text(
                          lang.t('game_over'),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFB800),
                          ),
                        ),
                        if (winner != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${lang.t('winner')}: ${winner.name}',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey.shade500),
                            ),
                          ),
                        if (_myRank > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              iWon
                                  ? '🎉 ${lang.t('you_won')}'
                                  : '${lang.t('your_place')}: $_myRank',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (podium.length >= 2) _Podium(players: podium),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(lang.t('final_scores'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _sorted.length,
                      itemBuilder: (_, i) => Reveal(
                        delayMs: 500 + (i < 8 ? i * 90 : 720),
                        dy: 12,
                        child: PlayerTile(
                          player: _sorted[i],
                          rank: i + 1,
                          isMe: _sorted[i].uid == _myUid,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: AppButton(
                      text: lang.t('back_home'),
                      icon: Icons.home_rounded,
                      onTap: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (iWon || _myRank == 2 || _myRank == 3)
            const Positioned.fill(child: Confetti()),
        ],
      ),
    );
  }
}

/// Подиум: 2-юм | 1-ум | 3-юм. Сутунҳо аз поён мебароянд.
class _Podium extends StatelessWidget {
  final List<PlayerModel> players;
  const _Podium({required this.players});

  @override
  Widget build(BuildContext context) {
    final order = players.length >= 3 ? [1, 0, 2] : [1, 0];
    const heights = [110.0, 80.0, 60.0];

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final i in order)
            Expanded(
              child: _PodiumColumn(
                player: players[i],
                rank: i + 1,
                barHeight: heights[i],
                delayMs: 400 + (2 - i) * 350,
              ),
            ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final PlayerModel player;
  final int rank;
  final double barHeight;
  final int delayMs;

  const _PodiumColumn({
    required this.player,
    required this.rank,
    required this.barHeight,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppHelpers.getRankColor(rank);
    final name = player.name.trim().isEmpty ? '?' : player.name.trim();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Reveal(
          delayMs: delayMs + 500,
          child: Column(
            children: [
              Text(AppHelpers.getRankEmoji(rank),
                  style: const TextStyle(fontSize: 24)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  name.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _GrowBar(height: barHeight, color: color, delayMs: delayMs, score: player.score),
      ],
    );
  }
}

class _GrowBar extends StatefulWidget {
  final double height;
  final Color color;
  final int delayMs;
  final int score;

  const _GrowBar({
    required this.height,
    required this.color,
    required this.delayMs,
    required this.score,
  });

  @override
  State<_GrowBar> createState() => _GrowBarState();
}

class _GrowBarState extends State<_GrowBar> {
  bool _go = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _go = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      height: _go ? widget.height : 0,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.color.withValues(alpha: 0.55),
            widget.color.withValues(alpha: 0.2),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: widget.color.withValues(alpha: 0.7)),
      ),
      child: _go
          ? AnimatedScore(
              value: widget.score,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: widget.color,
              ),
            )
          : null,
    );
  }
}
