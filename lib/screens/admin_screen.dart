import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../models/question_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/app_button.dart';
import '../widgets/quiz_widgets.dart';
import '../widgets/reveal.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _showForm(BuildContext context, FirestoreService db, AppLanguage lang,
      {QuestionModel? existing, String? docId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) =>
          _QuestionForm(db: db, lang: lang, existing: existing, docId: docId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final db = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('admin_panel')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(context, db, lang),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.streamAdminQuestions(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(lang.t('error')));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(lang.t('no_questions'),
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  AppButton(
                    text: lang.t('add_question'),
                    onTap: () => _showForm(context, db, lang),
                    icon: Icons.add,
                    width: 220,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: docs.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('${lang.t('questions_list')}: ${docs.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                );
              }
              final d = docs[i - 1];
              final q = QuestionModel.fromJson(d.data());
              return Reveal(
                dy: 10,
                delayMs: i < 8 ? i * 50 : 0,
                child: _QuestionCard(
                  q: q,
                  docId: d.id,
                  db: db,
                  lang: lang,
                  onEdit: () =>
                      _showForm(context, db, lang, existing: q, docId: d.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, db, lang),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Корт ────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final QuestionModel q;
  final String docId;
  final FirestoreService db;
  final AppLanguage lang;
  final VoidCallback onEdit;

  const _QuestionCard({
    required this.q,
    required this.docId,
    required this.db,
    required this.lang,
    required this.onEdit,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.t('confirm_delete')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(lang.t('no'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(lang.t('yes')),
          ),
        ],
      ),
    );
    if (ok == true) await db.deleteAdminQuestion(docId);
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    final diffColor = AppHelpers.difficultyColor(q.difficulty);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _chip('${AppHelpers.typeEmoji(q.type)} ${lang.t('type_${q.type}')}',
                        AppColors.primary),
                    _chip(lang.t(q.difficulty), diffColor),
                    Text(
                        '${AppHelpers.categoryEmoji(q.category)} ${lang.t('cat_${q.category}')}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.edit, size: 18), onPressed: onEdit),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (q.type == 'choice')
            for (int i = 0; i < q.options.length; i++)
              Row(
                children: [
                  Icon(
                    i == q.correctIndex
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 16,
                    color: i == q.correctIndex ? AppColors.correct : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(q.options[i],
                        style: TextStyle(
                            color:
                                i == q.correctIndex ? AppColors.correct : null)),
                  ),
                ],
              ),
          if (q.type == 'text')
            Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 16, color: AppColors.correct),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(q.answers.join('  •  '),
                      style: const TextStyle(color: AppColors.correct)),
                ),
              ],
            ),
          if (q.type == 'match')
            for (final p in q.pairs)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 16, color: AppColors.correct),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${p.left}  →  ${p.right}',
                          style: const TextStyle(color: AppColors.correct)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

// ─── Форма ───────────────────────────────────────────────────

class _QuestionForm extends StatefulWidget {
  final FirestoreService db;
  final AppLanguage lang;
  final QuestionModel? existing;
  final String? docId;

  const _QuestionForm(
      {required this.db, required this.lang, this.existing, this.docId});

  @override
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
  late final TextEditingController _qCtrl;
  late final List<TextEditingController> _opts;
  late final TextEditingController _answerCtrl;
  late final TextEditingController _altCtrl;
  final List<TextEditingController> _lefts = [];
  final List<TextEditingController> _rights = [];
  late int _correctIndex;
  late String _category;
  late String _difficulty;
  late String _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? 'choice';
    _qCtrl = TextEditingController(text: e?.question ?? '');
    _opts = List.generate(
      4,
      (i) => TextEditingController(
          text: (e != null && e.type == 'choice' && e.options.length > i)
              ? e.options[i]
              : ''),
    );
    _answerCtrl = TextEditingController(
        text: (e != null && e.answers.isNotEmpty) ? e.answers.first : '');
    _altCtrl = TextEditingController(
        text: (e != null && e.answers.length > 1)
            ? e.answers.skip(1).join(', ')
            : '');
    if (e != null && e.type == 'match' && e.pairs.isNotEmpty) {
      for (final p in e.pairs) {
        _lefts.add(TextEditingController(text: p.left));
        _rights.add(TextEditingController(text: p.right));
      }
    } else {
      for (var i = 0; i < 4; i++) {
        _lefts.add(TextEditingController());
        _rights.add(TextEditingController());
      }
    }
    _correctIndex = e?.correctIndex ?? 0;
    _category = AppConstants.categories.contains(e?.category)
        ? e!.category
        : 'general';
    _difficulty = e?.difficulty ?? 'easy';
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _answerCtrl.dispose();
    _altCtrl.dispose();
    for (final c in [..._opts, ..._lefts, ..._rights]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  QuestionModel? _build() {
    final lang = widget.lang;
    final question = _qCtrl.text.trim();
    if (question.isEmpty) {
      _snack(lang.t('field_required'));
      return null;
    }
    final id =
        widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    if (_type == 'text') {
      final main = _answerCtrl.text.trim();
      if (main.isEmpty) {
        _snack(lang.t('field_required'));
        return null;
      }
      final alts = _altCtrl.text
          .split(RegExp(r'[,;\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e != main);
      return QuestionModel(
        id: id,
        question: question,
        options: const [],
        correctIndex: 0,
        category: _category,
        difficulty: _difficulty,
        type: 'text',
        answers: [main, ...alts],
      );
    }

    if (_type == 'match') {
      final pairs = <MatchPair>[];
      for (var i = 0; i < _lefts.length; i++) {
        final l = _lefts[i].text.trim();
        final r = _rights[i].text.trim();
        if (l.isEmpty || r.isEmpty) {
          _snack(lang.t('field_required'));
          return null;
        }
        pairs.add(MatchPair(l, r));
      }
      if (pairs.length < 3) {
        _snack(lang.t('min_pairs'));
        return null;
      }
      if (pairs.map((p) => p.right.toLowerCase()).toSet().length !=
          pairs.length) {
        _snack(lang.t('pairs_unique'));
        return null;
      }
      return QuestionModel(
        id: id,
        question: question,
        options: const [],
        correctIndex: 0,
        category: _category,
        difficulty: _difficulty,
        type: 'match',
        pairs: pairs,
      );
    }

    if (_opts.any((c) => c.text.trim().isEmpty)) {
      _snack(lang.t('field_required'));
      return null;
    }
    return QuestionModel(
      id: id,
      question: question,
      options: _opts.map((c) => c.text.trim()).toList(),
      correctIndex: _correctIndex,
      category: _category,
      difficulty: _difficulty,
    );
  }

  Future<void> _save() async {
    final lang = widget.lang;
    final q = _build();
    if (q == null) return;
    setState(() => _saving = true);
    try {
      if (widget.docId != null) {
        await widget.db.updateAdminQuestion(widget.docId!, q);
      } else {
        await widget.db.addAdminQuestion(q);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('${lang.t('error')}: $e');
    }
  }

  InputDecoration _dec(String label, {bool dense = false}) => InputDecoration(
        labelText: label,
        isDense: dense,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _choiceFields(AppLanguage lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.t('answer_options'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(lang.t('tap_correct'),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        for (int i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _correctIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _correctIndex == i
                            ? AppColors.correct
                            : Colors.grey,
                        width: 2,
                      ),
                      color: _correctIndex == i
                          ? AppColors.correct.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                    child: _correctIndex == i
                        ? const Icon(Icons.check,
                            size: 15, color: AppColors.correct)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _opts[i],
                    decoration: _dec(String.fromCharCode(65 + i), dense: true),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _textFields(AppLanguage lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _answerCtrl,
          decoration: _dec(lang.t('correct_answer')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _altCtrl,
          maxLines: 2,
          decoration: _dec(lang.t('alt_answers')),
        ),
        const SizedBox(height: 6),
        Text(lang.t('alt_answers_hint'),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _matchFields(AppLanguage lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.t('pairs_label'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var i = 0; i < _lefts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lefts[i],
                    decoration: _dec('${lang.t('left_item')} ${i + 1}', dense: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded, size: 16),
                ),
                Expanded(
                  child: TextField(
                    controller: _rights[i],
                    decoration:
                        _dec('${lang.t('right_item')} ${i + 1}', dense: true),
                  ),
                ),
                if (_lefts.length > 3)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 20, color: Colors.redAccent),
                    onPressed: () => setState(() {
                      _lefts.removeAt(i).dispose();
                      _rights.removeAt(i).dispose();
                    }),
                  ),
              ],
            ),
          ),
        if (_lefts.length < 5)
          TextButton.icon(
            onPressed: () => setState(() {
              _lefts.add(TextEditingController());
              _rights.add(TextEditingController());
            }),
            icon: const Icon(Icons.add),
            label: Text(lang.t('add_pair')),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing != null ? lang.t('edit') : lang.t('add_question'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Text(lang.t('q_type'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in ['choice', 'text', 'match'])
                  SelectChip(
                    label: '${AppHelpers.typeEmoji(t)} ${lang.t('type_$t')}',
                    selected: _type == t,
                    onTap: () => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(lang.t('type_${_type}_d'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 14),
            TextField(
              controller: _qCtrl,
              maxLines: 3,
              decoration: _dec(lang.t('question_text')),
            ),
            const SizedBox(height: 16),
            if (_type == 'choice') _choiceFields(lang),
            if (_type == 'text') _textFields(lang),
            if (_type == 'match') _matchFields(lang),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: _dec(lang.t('category'), dense: true),
                    items: AppConstants.categories
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                                '${AppHelpers.categoryEmoji(c)} ${lang.t('cat_$c')}',
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _difficulty,
                    isExpanded: true,
                    decoration: _dec(lang.t('difficulty'), dense: true),
                    items: AppConstants.difficulties
                        .map((d) =>
                            DropdownMenuItem(value: d, child: Text(lang.t(d))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _difficulty = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
