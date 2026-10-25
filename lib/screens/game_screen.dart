import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../models/game_config.dart';
import '../models/question_model.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_stats_service.dart';
import '../utils/app_route.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/animated_background.dart';
import '../widgets/app_button.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/fx.dart';
import '../widgets/answer_inputs.dart';
import '../widgets/quiz_widgets.dart';
import 'solo_result_screen.dart';

class GameScreen extends StatefulWidget {
  final GameConfig config;
  const GameScreen({super.key, this.config = const GameConfig()});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _audio = AudioService();
  final _auth = AuthService();
  final _db = FirestoreService();
  final _timerCtrl = CountdownController();

  List<QuestionModel> _questions = [];
  bool _loading = true;

  int _index = 0;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _correctCount = 0;
  int _lives = AppConstants.lives;

  int? _selected;
  bool _answered = false;
  String _feedback = ''; // correct | wrong | time_up | ''
  int _lastGain = 0;
  int _popId = 0;

  final Set<int> _eliminated = {};
  bool _used5050 = false;
  bool _usedTime = false;
  bool _usedSkip = false;

  final List<AnswerRecord> _records = [];
  Timer? _nextTimer;
  bool _finishing = false;
  bool _intro = true;
  int _goodFx = 0;
  int _badFx = 0;
  int _milestoneFx = 0;
  String _fxEmoji = '✅';
  String _milestoneText = '';

  bool get _survival => widget.config.mode == 'survival';
  QuestionModel get _current => _questions[_index];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = widget.config;
      final qs = await _db.loadQuestions(
        source: c.source,
        count: _survival ? 60 : c.count,
        uid: _auth.uid,
        category: c.category,
        difficulty: c.difficulty,
      );
      if (!mounted) return;
      setState(() {
        _questions = qs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Ҷавоб ───────────────────────────────────────────────
  String _describe(QuestionModel q, dynamic answer) {
    if (q.type == 'text') return answer as String;
    if (q.type == 'match') {
      final list = answer as List;
      return [
        for (var i = 0; i < q.pairs.length; i++)
          '${q.pairs[i].left} → ${i < list.length && list[i] is int && list[i] < q.pairs.length ? q.pairs[list[i] as int].right : '—'}'
      ].join('\n');
    }
    final idx = answer as int;
    return (idx >= 0 && idx < q.options.length) ? q.options[idx] : '';
  }

  /// Ҷавоб: int (тест), String (пӯшида) ё List<int> (мувофиқат)
  void _submit(dynamic answer) {
    if (_answered || _finishing) return;
    _timerCtrl.pause();
    final q = _current;
    final totalMs = widget.config.time * 1000;
    final left = _timerCtrl.remainingMs;
    final fraction = q.evaluate(answer);
    final full = fraction >= 1.0;

    if (full) {
      _streak++;
      _bestStreak = max(_bestStreak, _streak);
      _correctCount++;
      _goodFx++;
      _fxEmoji = '✅';
      if (const [3, 5, 7, 10, 15, 20].contains(_streak)) {
        _milestoneFx++;
        _milestoneText =
            '🔥 ${Provider.of<AppLanguage>(context, listen: false).t('streak')} x$_streak';
      }
      _audio.playCorrect();
      _audio.haptic(HapticKind.light);
    } else {
      _streak = 0;
      _badFx++;
      _fxEmoji = '❌';
      if (_survival && fraction < 0.5) _lives--;
      _audio.playWrong();
      _audio.haptic(HapticKind.heavy);
    }
    final gain = AppHelpers.calculatePointsFor(
      fraction: fraction,
      timeLeftMs: left,
      totalSec: widget.config.time,
      difficulty: q.difficulty,
      streak: _streak,
    );
    _score += gain;

    _records.add(AnswerRecord(
      question: q,
      selected: answer is int ? answer : 0,
      timeMs: max(0, totalMs - left),
      fraction: fraction,
      given: _describe(q, answer),
    ));
    setState(() {
      _selected = answer is int ? answer : null;
      _answered = true;
      _feedback = full
          ? 'correct'
          : fraction > 0
              ? 'partial'
              : 'wrong';
      _lastGain = gain;
      if (gain > 0) _popId++;
    });
    // Ҷавоби дурустро хондан вақт мегирад
    _scheduleNext(q.type == 'choice' || full ? 1800 : 3800);
  }

  void _onTimeUp() {
    if (_answered || _finishing) return;
    _streak = 0;
    _badFx++;
    _fxEmoji = '⏰';
    if (_survival) _lives--;
    _audio.playWrong();
    _audio.haptic(HapticKind.heavy);
    _records.add(AnswerRecord(
        question: _current,
        selected: -1,
        timeMs: widget.config.time * 1000));
    setState(() {
      _answered = true;
      _selected = null;
      _feedback = 'time_up';
      _lastGain = 0;
    });
    _scheduleNext(_current.type == 'choice' ? 1800 : 3800);
  }

  void _scheduleNext([int ms = 1800]) {
    _nextTimer?.cancel();
    _nextTimer = Timer(Duration(milliseconds: ms), _next);
  }

  void _next() {
    _nextTimer?.cancel();
    if (!mounted || !_answered) return;
    final over = (_survival && _lives <= 0) || _index + 1 >= _questions.length;
    if (over) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
      _feedback = '';
      _lastGain = 0;
      _eliminated.clear();
    });
  }

  // ─── Кӯмакҳо ─────────────────────────────────────────────
  void _use5050() {
    if (_answered || _used5050 || _current.type != 'choice') return;
    final wrong = [
      for (int i = 0; i < _current.options.length; i++)
        if (i != _current.correctIndex && !_eliminated.contains(i)) i
    ]..shuffle();
    setState(() {
      _used5050 = true;
      _eliminated.addAll(wrong.take(2));
    });
    _audio.haptic(HapticKind.medium);
  }

  void _useTime() {
    if (_answered || _usedTime) return;
    _timerCtrl.addSeconds(AppConstants.bonusSeconds);
    setState(() => _usedTime = true);
    _audio.haptic(HapticKind.medium);
  }

  void _useSkip() {
    if (_answered || _usedSkip) return;
    _timerCtrl.pause();
    _records.add(AnswerRecord(question: _current, selected: -2, timeMs: 0));
    setState(() {
      _usedSkip = true;
      _answered = true;
      _feedback = '';
    });
    _audio.haptic(HapticKind.medium);
    _next();
  }

  // ─── Анҷом ───────────────────────────────────────────────
  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _timerCtrl.pause();

    final answered = _records.where((r) => !r.skipped).length;
    final isNewBest =
        await LocalStatsService.recordScore(widget.config.mode, _score);
    final best = await LocalStatsService.bestScore(widget.config.mode);

    // Интизор намешавем: бе интернет ҳам натиҷа нишон дода мешавад
    _auth.addGameResult(
      score: _score,
      won: false,
      correct: _correctCount,
      total: answered,
      bestStreak: _bestStreak,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      appRoute(SoloResultScreen(
        config: widget.config,
        score: _score,
        correct: _correctCount,
        answered: answered,
        bestStreak: _bestStreak,
        records: _records,
        isNewBest: isNewBest,
        bestScore: best,
      )),
    );
  }

  Future<bool> _confirmExit() async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    _timerCtrl.pause();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.t('exit_game_q')),
        content: Text(lang.t('exit_game_text')),
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
    if (ok != true && !_answered) _timerCtrl.resume();
    return ok == true;
  }

  OptionState _optionState(int i) {
    if (_eliminated.contains(i) && !_answered) return OptionState.eliminated;
    if (!_answered) return OptionState.idle;
    if (i == _current.correctIndex) return OptionState.correct;
    if (i == _selected) return OptionState.wrong;
    return OptionState.dimmed;
  }

  Widget _buildAnswerArea(QuestionModel q, AppLanguage lang) {
    if (q.type == 'text') {
      return TextAnswerInput(
        key: ValueKey('txt-$_index'),
        answers: q.answers,
        locked: _answered,
        hint: lang.t('type_here'),
        submitLabel: lang.t('submit'),
        correctLabel: lang.t('correct_answer'),
        onSubmit: _submit,
      );
    }
    if (q.type == 'match') {
      return MatchAnswerInput(
        key: ValueKey('mat-$_index'),
        pairs: q.pairs,
        locked: _answered,
        submitLabel: lang.t('submit'),
        onSubmit: _submit,
      );
    }
    return Column(
      children: [
        for (int i = 0; i < q.options.length; i++)
          OptionTile(
            key: ValueKey('opt-$_index-$i'),
            index: i,
            text: q.options[i],
            state: _optionState(i),
            onTap: (_answered || _eliminated.contains(i))
                ? null
                : () => _submit(i),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🤷', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(lang.t('no_questions_filter'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                AppButton(
                  text: lang.t('back'),
                  width: 180,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_intro) {
      return Scaffold(
        body: AnimatedBackground(
          child: Center(
            child: StartCountdown(
              readyText: lang.t('get_ready'),
              goText: lang.t('go'),
              onStep: () => _audio.haptic(HapticKind.light),
              onDone: () {
                if (mounted) setState(() => _intro = false);
              },
            ),
          ),
        ),
      );
    }

    final q = _current;
    final progress = (_index + (_answered ? 1 : 0)) / _questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmExit();
        if (ok && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: AnimatedBackground(
          shake: _badFx,
          overlay: FxLayer(
            goodTrigger: _goodFx,
            badTrigger: _badFx,
            emoji: _fxEmoji,
            milestoneTrigger: _milestoneFx,
            milestoneText: _milestoneText,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Column(
                children: [
                  // ── Навори боло ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () async {
                          final ok = await _confirmExit();
                          if (ok && mounted) Navigator.pop(context);
                        },
                      ),
                      _survival
                          ? Row(children: [
                              for (int i = 0; i < AppConstants.lives; i++)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (c, a) =>
                                      ScaleTransition(scale: a, child: c),
                                  child: Text(
                                    i < _lives ? '❤️' : '🖤',
                                    key: ValueKey('$i-${i < _lives}'),
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                            ])
                          : Text(
                              '${lang.t('question')} ${_index + 1}/${_questions.length}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                      AnimatedScore(
                        value: _score,
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
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: _survival ? null : v,
                        minHeight: 7,
                        backgroundColor: Colors.grey.withValues(alpha: 0.25),
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  if (_survival)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${lang.t('question')} ${_index + 1}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // ── Таймер, серия, холи нав ──
                  SizedBox(
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: CountdownTimer(
                            key: ValueKey('timer-$_index'),
                            seconds: widget.config.time,
                            controller: _timerCtrl,
                            onFinished: _onTimeUp,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StreakBadge(streak: _streak),
                        ),
                        if (_lastGain > 0)
                          Align(
                            alignment: Alignment.centerRight,
                            child: PointsPop(
                                key: ValueKey('pop-$_popId'), points: _lastGain),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Савол ва вариантҳо ──
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.08),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                            child: QuestionCard(
                              key: ValueKey('q-$_index'),
                              question: q.question,
                              category: q.category,
                              categoryLabel: lang.t('cat_${q.category}'),
                              difficulty: q.difficulty,
                              difficultyLabel: lang.t(q.difficulty),
                              hint: q.type == 'text'
                                  ? lang.t('hint_text')
                                  : q.type == 'match'
                                      ? lang.t('hint_match')
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildAnswerArea(q, lang),
                        ],
                      ),
                    ),
                  ),

                  // ── Поён: кӯмакҳо ё "Давом" ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _answered
                        ? Column(
                            key: const ValueKey('after'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_feedback.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    lang.t(_feedback),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: _feedback == 'correct'
                                          ? AppColors.correct
                                          : _feedback == 'partial'
                                              ? AppColors.warn
                                              : AppColors.wrong,
                                    ),
                                  ),
                                ),
                              AppButton(
                                text: lang.t('next_question'),
                                icon: Icons.arrow_forward_rounded,
                                onTap: _next,
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('lifelines'),
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              LifelineButton(
                                emoji: '✂️',
                                label: '50/50',
                                enabled: !_used5050 && q.type == 'choice',
                                onTap: _use5050,
                              ),
                              LifelineButton(
                                emoji: '⏱️',
                                label: '+${AppConstants.bonusSeconds} ${lang.t('sec_short')}',
                                enabled: !_usedTime,
                                onTap: _useTime,
                              ),
                              LifelineButton(
                                emoji: '⏭️',
                                label: lang.t('skip'),
                                enabled: !_usedSkip,
                                onTap: _useSkip,
                              ),
                            ],
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
