import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../models/question_model.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_route.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/animated_background.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/quiz_widgets.dart';
import '../widgets/reveal.dart';
import 'winner_screen.dart';

/// Бозии онлайн.
///
/// Муҳим: ҳолати бозӣ (index, phase) дар Firestore нигоҳ дошта мешавад.
/// Гузариш байни марҳилаҳо тавассути транзаксияи идемпотентӣ (advance) анҷом
/// меёбад, бинобар ин савол ҳеҷ гоҳ ду бор ё зуд иваз намешавад ва бозӣ
/// ба як дастгоҳ (мизбон) вобаста нест.
class OnlineGameScreen extends StatefulWidget {
  final String roomId;
  final bool isHost;
  final Map<String, dynamic> roomData;

  const OnlineGameScreen({
    super.key,
    required this.roomId,
    required this.isHost,
    required this.roomData,
  });

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final _auth = AuthService();
  final _db = FirestoreService();
  final _audio = AudioService();
  final _timerCtrl = CountdownController();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  final List<Timer> _timers = [];
  final Set<String> _scheduled = {};

  bool _ready = false;
  bool _finishedHandled = false;
  bool _closedHandled = false;

  List<QuestionModel> _questions = [];
  List<PlayerModel> _players = [];
  int _qIndex = -1;
  String _phase = 'question';
  int _timePerQ = AppConstants.defaultTimePerQuestion;

  int? _selected;
  bool _answered = false;
  int _popGain = 0;
  int _popId = 0;
  final Set<int> _eliminated = {};
  bool _used5050 = false;

  PlayerModel? get _me {
    for (final p in _players) {
      if (p.uid == _auth.uid) return p;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _sub = _db.streamRoom(widget.roomId).listen(_onRoom, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  // ─── Гирифтани навсозии ҳуҷра ─────────────────────────────
  List<QuestionModel> _parseQuestions(Map<String, dynamic> data) {
    return (data['questions'] as List? ?? [])
        .map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();
  }

  void _onRoom(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!mounted || _finishedHandled || _closedHandled) return;
    final data = snap.data();
    if (!snap.exists || data == null) {
      _handleClosed();
      return;
    }

    final playersMap = Map<String, dynamic>.from(data['players'] ?? {});
    final players = playersMap.values
        .map((p) => PlayerModel.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList()
      ..sort((a, b) {
        final c = b.score.compareTo(a.score);
        return c != 0 ? c : b.correct.compareTo(a.correct);
      });

    final status = data['status'] as String? ?? 'playing';
    if (status == 'finished') {
      _handleFinished(data, players);
      return;
    }
    if (status != 'playing') return;

    if (_questions.isEmpty) _questions = _parseQuestions(data);
    final idx = (data['currentQuestionIndex'] as num?)?.toInt() ?? 0;
    final phase = data['phase'] as String? ?? 'question';
    final isNew = idx != _qIndex;

    PlayerModel? me;
    for (final p in players) {
      if (p.uid == _auth.uid) me = p;
    }

    setState(() {
      _players = players;
      _timePerQ = (data['timePerQuestion'] as num?)?.toInt() ?? _timePerQ;
      _phase = phase;
      if (isNew) {
        _qIndex = idx;
        _selected = null;
        _answered = false;
        _eliminated.clear();
        _popGain = 0;
      }
      // Агар сервер мегӯяд, ки ман ҷавоб додаам (масалан, вақт тамом шуд)
      if (me != null && me.answered && !_answered) {
        _answered = true;
        if (me.answerIndex >= 0) _selected = me.answerIndex;
      }
      _ready = true;
    });

    _scheduleLogic(idx, phase, players);
  }

  // ─── Идоракунии марҳилаҳо ─────────────────────────────────
  void _scheduleOnce(String key, int ms, VoidCallback fn) {
    if (!_scheduled.add(key)) return;
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (mounted) fn();
    }));
  }

  void _advance(int idx, String phase) {
    _db.advance(
      roomId: widget.roomId,
      expectedIndex: idx,
      expectedPhase: phase,
    );
  }

  void _scheduleLogic(int idx, String phase, List<PlayerModel> players) {
    final host = widget.isHost;
    if (phase == 'question') {
      final all = players.isNotEmpty && players.every((p) => p.answered);
      if (all) {
        // Мизбон зуд мегузарад, дигарон ҳамчун эҳтиёт каме дертар
        _scheduleOnce('all-$idx', host ? 700 : 3500, () => _advance(idx, 'question'));
      }
    } else if (phase == 'reveal') {
      _scheduleOnce(
        'rev-$idx',
        host ? AppConstants.revealMs : AppConstants.revealMs + 2500,
        () => _advance(idx, 'reveal'),
      );
    }
  }

  void _onTimeUp() {
    if (!mounted || _phase != 'question') return;
    final idx = _qIndex;
    if (!_answered) {
      setState(() => _answered = true);
      _audio.playWrong();
      _audio.haptic(HapticKind.heavy);
      _db.submitAnswer(
        roomId: widget.roomId,
        expectedIndex: idx,
        answerIndex: -1,
        timeLeftMs: 0,
      );
    }
    _scheduleOnce('time-$idx', widget.isHost ? 500 : 4500, () => _advance(idx, 'question'));
  }

  Future<void> _onAnswer(int i) async {
    if (_answered || _phase != 'question' || _qIndex < 0) return;
    final q = _questions[_qIndex];
    final left = _timerCtrl.remainingMs;
    final idx = _qIndex;

    setState(() {
      _answered = true;
      _selected = i;
    });
    if (i == q.correctIndex) {
      _audio.playCorrect();
      _audio.haptic(HapticKind.light);
    } else {
      _audio.playWrong();
      _audio.haptic(HapticKind.heavy);
    }

    final pts = await _db.submitAnswer(
      roomId: widget.roomId,
      expectedIndex: idx,
      answerIndex: i,
      timeLeftMs: left,
    );
    if (mounted && idx == _qIndex && pts > 0) {
      setState(() {
        _popGain = pts;
        _popId++;
      });
    }
  }

  void _use5050() {
    if (_answered || _used5050 || _qIndex < 0) return;
    final q = _questions[_qIndex];
    final wrong = [
      for (int i = 0; i < q.options.length; i++)
        if (i != q.correctIndex) i
    ]..shuffle();
    setState(() {
      _used5050 = true;
      _eliminated.addAll(wrong.take(2));
    });
    _audio.haptic(HapticKind.medium);
  }

  // ─── Анҷом ва баромад ─────────────────────────────────────
  void _handleFinished(Map<String, dynamic> data, List<PlayerModel> players) {
    if (_finishedHandled) return;
    _finishedHandled = true;

    final total = (data['questions'] as List? ?? []).length;
    PlayerModel? me;
    for (final p in players) {
      if (p.uid == _auth.uid) me = p;
    }
    final top = players.isNotEmpty ? players.first.score : 0;
    final won = me != null && top > 0 && me.score == top;
    if (me != null) {
      _auth.addGameResult(
        score: me.score,
        won: won,
        correct: me.correct,
        total: total,
        bestStreak: me.bestStreak,
      );
    }
    _db.leaveRoomLater(widget.roomId);

    Navigator.pushReplacement(
      context,
      appRoute(WinnerScreen(players: players, isOnline: true)),
    );
  }

  void _handleClosed() {
    if (_closedHandled) return;
    _closedHandled = true;
    final lang = Provider.of<AppLanguage>(context, listen: false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(lang.t('room_closed'))));
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _confirmExit() async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.t('exit_game_q')),
        content: Text(lang.t('exit_online_text')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(lang.t('no'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wrong, foregroundColor: Colors.white),
            child: Text(lang.t('yes')),
          ),
        ],
      ),
    );
    if (ok == true) {
      _closedHandled = true;
      await _db.leaveRoom(widget.roomId);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  OptionState _optionState(int i, QuestionModel q) {
    final show = _answered || _phase == 'reveal';
    if (!show) {
      return _eliminated.contains(i) ? OptionState.eliminated : OptionState.idle;
    }
    if (i == q.correctIndex) return OptionState.correct;
    if (_selected == i) return OptionState.wrong;
    return OptionState.dimmed;
  }

  // ─── UI ───────────────────────────────────────────────────
  Widget _revealBanner(AppLanguage lang, QuestionModel q) {
    final me = _me;
    final mine = me?.answerIndex ?? -1;
    String text;
    Color color;
    if (me == null || mine < 0) {
      text = lang.t('time_up');
      color = AppColors.warn;
    } else if (mine == q.correctIndex) {
      text = '${lang.t('correct')}  +${me.lastGain}';
      color = AppColors.correct;
    } else {
      text = lang.t('wrong');
      color = AppColors.wrong;
    }
    return Reveal(
      key: ValueKey('banner-$_qIndex'),
      dy: 10,
      child: Text(
        text,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);

    if (!_ready || _qIndex < 0 || _qIndex >= _questions.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = _questions[_qIndex];
    final revealing = _phase == 'reveal';
    final me = _me;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: AnimatedBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Column(
                children: [
                  // ── Навори боло ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _confirmExit,
                      ),
                      Text(
                        '${lang.t('question')} ${_qIndex + 1}/${_questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      AnimatedScore(
                        value: me?.score ?? 0,
                        prefix: '⭐ ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFFFFB800),
                        ),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: 0,
                          end: (_qIndex + (revealing ? 1 : 0)) / _questions.length),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 7,
                        backgroundColor: Colors.grey.withValues(alpha: 0.25),
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Бозингарон ──
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _players.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _PlayerChip(
                        key: ValueKey(_players[i].uid),
                        player: _players[i],
                        isMe: _players[i].uid == _auth.uid,
                        reveal: revealing,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Таймер ё натиҷаи савол ──
                  SizedBox(
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: revealing
                              ? _revealBanner(lang, q)
                              : CountdownTimer(
                                  key: ValueKey('timer-$_qIndex'),
                                  seconds: _timePerQ,
                                  controller: _timerCtrl,
                                  onFinished: _onTimeUp,
                                ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StreakBadge(streak: me?.streak ?? 0),
                        ),
                        if (_popGain > 0 && !revealing)
                          Align(
                            alignment: Alignment.centerRight,
                            child: PointsPop(
                                key: ValueKey('pop-$_popId'), points: _popGain),
                          ),
                      ],
                    ),
                  ),

                  // ── Савол ва вариантҳо ──
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          QuestionCard(
                            key: ValueKey('q-$_qIndex'),
                            question: q.question,
                            category: q.category,
                            categoryLabel: lang.t('cat_${q.category}'),
                            difficulty: q.difficulty,
                            difficultyLabel: lang.t(q.difficulty),
                          ),
                          const SizedBox(height: 12),
                          for (int i = 0; i < q.options.length; i++)
                            OptionTile(
                              key: ValueKey('opt-$_qIndex-$i'),
                              index: i,
                              text: q.options[i],
                              state: _optionState(i, q),
                              onTap: (_answered ||
                                      revealing ||
                                      _eliminated.contains(i))
                                  ? null
                                  : () => _onAnswer(i),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Поён ──
                  SizedBox(
                    height: 74,
                    child: Center(
                      child: revealing
                          ? Text(lang.t('next_soon'),
                              style: TextStyle(color: Colors.grey.shade500))
                          : _answered
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(lang.t('waiting_others')),
                                  ],
                                )
                              : LifelineButton(
                                  emoji: '✂️',
                                  label: '50/50',
                                  enabled: !_used5050,
                                  onTap: _use5050,
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final PlayerModel player;
  final bool isMe;
  final bool reveal;

  const _PlayerChip({
    super.key,
    required this.player,
    required this.isMe,
    required this.reveal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = player.name.trim().isEmpty ? '?' : player.name.trim();
    final first = name.split(' ').first;
    final showGain = reveal && player.lastGain > 0;

    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(
        color: isMe
            ? theme.primaryColor.withValues(alpha: 0.16)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? theme.primaryColor.withValues(alpha: 0.7)
              : Colors.transparent,
          width: 1.4,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppHelpers.avatarColor(name),
                child: Text(AppHelpers.initial(name),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
              Positioned(
                right: -4,
                bottom: -3,
                child: AnimatedScale(
                  scale: player.answered ? 1 : 0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.elasticOut,
                  child: const Icon(Icons.check_circle,
                      size: 14, color: AppColors.correct),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          Text(
            showGain ? '+${player.lastGain}' : '${player.score}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: showGain ? AppColors.correct : const Color(0xFFFFB800),
            ),
          ),
        ],
      ),
    );
  }
}
