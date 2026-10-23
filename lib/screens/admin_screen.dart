import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../models/question_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/app_button.dart';
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(lang.t(q.difficulty),
                    style: TextStyle(
                        fontSize: 11,
                        color: diffColor,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text('${AppHelpers.categoryEmoji(q.category)} ${lang.t('cat_${q.category}')}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const Spacer(),
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
                          color: i == q.correctIndex ? AppColors.correct : null)),
                ),
              ],
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
  late int _correctIndex;
  late String _category;
  late String _difficulty;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _qCtrl = TextEditingController(text: e?.question ?? '');
    _opts = List.generate(
      4,
      (i) => TextEditingController(
          text: (e != null && e.options.length > i) ? e.options[i] : ''),
    );
    _correctIndex = e?.correctIndex ?? 0;
    _category = AppConstants.categories.contains(e?.category)
        ? e!.category
        : 'general';
    _difficulty = e?.difficulty ?? 'easy';
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    for (final c in _opts) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final lang = widget.lang;
    if (_qCtrl.text.trim().isEmpty || _opts.any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lang.t('field_required'))));
      return;
    }
    setState(() => _saving = true);

    final q = QuestionModel(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      question: _qCtrl.text.trim(),
      options: _opts.map((c) => c.text.trim()).toList(),
      correctIndex: _correctIndex,
      category: _category,
      difficulty: _difficulty,
    );

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${lang.t('error')}: $e')));
    }
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
            const SizedBox(height: 16),
            TextField(
              controller: _qCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: lang.t('question_text'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
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
                        decoration: InputDecoration(
                          labelText: String.fromCharCode(65 + i),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: lang.t('category'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
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
                    decoration: InputDecoration(
                      labelText: lang.t('difficulty'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
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
