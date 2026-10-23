import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_route.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/animated_background.dart';
import '../widgets/app_button.dart';
import '../widgets/quiz_widgets.dart';
import '../widgets/reveal.dart';
import 'waiting_room_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});
  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _auth = AuthService();
  final _db = FirestoreService();
  String _source = 'json';
  String _category = 'all';
  String _difficulty = 'all';
  int _questionCount = 10;
  int _timePerQuestion = AppConstants.defaultTimePerQuestion;
  bool _creating = false;

  Future<void> _create() async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    if (_auth.displayName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lang.t('enter_name'))));
      return;
    }
    setState(() => _creating = true);
    try {
      final roomId = await _db.createRoom(
        questionSource: _source,
        questionCount: _questionCount,
        timePerQuestion: _timePerQuestion,
        category: _category,
        difficulty: _difficulty,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          appRoute(WaitingRoomScreen(roomId: roomId, isHost: true)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      final msg = e.toString().contains('no_questions')
          ? lang.t('no_questions_filter')
          : '${lang.t('error')}: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      );

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(lang.t('create_room'))),
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 64, 24, 12),
                  child: Reveal(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(lang.t('question_source')),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          SelectChip(
                              label: lang.t('from_json'),
                              selected: _source == 'json',
                              onTap: () => setState(() => _source = 'json')),
                          SelectChip(
                              label: lang.t('from_admin'),
                              selected: _source == 'admin',
                              onTap: () => setState(() => _source = 'admin')),
                          SelectChip(
                              label: lang.t('from_both'),
                              selected: _source == 'both',
                              onTap: () => setState(() => _source = 'both')),
                        ]),
                        const SizedBox(height: 22),
                        _label(lang.t('category')),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final c in ['all', ...AppConstants.categories])
                            SelectChip(
                              label:
                                  '${AppHelpers.categoryEmoji(c)} ${lang.t('cat_$c')}',
                              selected: _category == c,
                              onTap: () => setState(() => _category = c),
                            ),
                        ]),
                        const SizedBox(height: 22),
                        _label(lang.t('difficulty')),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          SelectChip(
                              label: lang.t('cat_all'),
                              selected: _difficulty == 'all',
                              onTap: () => setState(() => _difficulty = 'all')),
                          for (final d in AppConstants.difficulties)
                            SelectChip(
                              label: lang.t(d),
                              color: AppHelpers.difficultyColor(d),
                              selected: _difficulty == d,
                              onTap: () => setState(() => _difficulty = d),
                            ),
                        ]),
                        const SizedBox(height: 22),
                        _label('${lang.t('question_count')}: $_questionCount'),
                        Slider(
                          value: _questionCount.toDouble(),
                          min: 5,
                          max: 30,
                          divisions: 5,
                          label: '$_questionCount',
                          onChanged: (v) =>
                              setState(() => _questionCount = v.round()),
                        ),
                        const SizedBox(height: 10),
                        _label(
                            '${lang.t('time_per_question')}: $_timePerQuestion ${lang.t('sec_short')}'),
                        Slider(
                          value: _timePerQuestion.toDouble(),
                          min: 10,
                          max: 60,
                          divisions: 10,
                          label: '$_timePerQuestion',
                          onChanged: (v) =>
                              setState(() => _timePerQuestion = v.round()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
                child: AppButton(
                  text: lang.t('create_room'),
                  loading: _creating,
                  onTap: _create,
                  icon: Icons.add_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
