import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../utils/answer_check.dart';
import '../utils/constants.dart';
import 'app_button.dart';

// ═══════════════════ САВОЛИ ПӮШИДА: ҶАВОБРО МЕНАВИСАНД ═══════════════════

class TextAnswerInput extends StatefulWidget {
  final List<String> answers;
  final bool locked;
  final String hint;
  final String submitLabel;
  final String correctLabel;
  final ValueChanged<String> onSubmit;

  const TextAnswerInput({
    super.key,
    required this.answers,
    required this.locked,
    required this.hint,
    required this.submitLabel,
    required this.correctLabel,
    required this.onSubmit,
  });

  @override
  State<TextAnswerInput> createState() => _TextAnswerInputState();
}

class _TextAnswerInputState extends State<TextAnswerInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _didSubmit = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _ctrl.text.trim();
    if (t.isEmpty || widget.locked) return;
    _didSubmit = true;
    _focus.unfocus();
    widget.onSubmit(t);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = widget.locked;
    final ok = locked && _didSubmit && isTextCorrect(_ctrl.text, widget.answers);
    final bad = locked && !ok;
    final color = ok
        ? AppColors.correct
        : bad
            ? AppColors.wrong
            : theme.primaryColor;

    OutlineInputBorder border(double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color.withValues(alpha: 0.7), width: w),
        );

    return Column(
      children: [
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          readOnly: locked,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: theme.colorScheme.surface,
            prefixIcon: Icon(
              ok
                  ? Icons.check_circle_rounded
                  : bad
                      ? Icons.cancel_rounded
                      : Icons.edit_rounded,
              color: color,
            ),
            border: border(2),
            enabledBorder: border(2),
            focusedBorder: border(2.5),
          ),
        ),
        if (bad)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.correct.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.correct.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_rounded,
                    color: AppColors.correct, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.correctLabel}: ${widget.answers.isEmpty ? '' : widget.answers.first}',
                    style: const TextStyle(
                        color: AppColors.correct, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        if (!locked) ...[
          const SizedBox(height: 12),
          AppButton(
            text: widget.submitLabel,
            icon: Icons.send_rounded,
            onTap: _ctrl.text.trim().isEmpty ? null : _submit,
          ),
        ],
      ],
    );
  }
}

// ═══════════════════ САВОЛИ МУВОФИҚАТ: ҶУФТҲОРО МУВОФИҚ КУНЕД ═══════════════════

/// Тарафи чап собит аст. Тарафҳои рост дар "ҳавз" (поён) омехта меистанд.
/// Ҳавзро пахш кунед, то ба ҷойи холии интихобшуда равад.
/// Ҷойи пуршударо пахш кунед, то ҷавоб ба ҳавз баргардад.
class MatchAnswerInput extends StatefulWidget {
  final List<MatchPair> pairs;
  final bool locked;
  final String submitLabel;
  final ValueChanged<List<int>> onSubmit;

  const MatchAnswerInput({
    super.key,
    required this.pairs,
    required this.locked,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<MatchAnswerInput> createState() => _MatchAnswerInputState();
}

class _MatchAnswerInputState extends State<MatchAnswerInput> {
  late final List<int> _order; // тартиби омехтаи тарафҳои рост
  late final List<int?> _assign; // барои ҳар тарафи чап: индекси рости интихобшуда
  int? _active;

  @override
  void initState() {
    super.initState();
    final n = widget.pairs.length;
    _order = List<int>.generate(n, (i) => i)..shuffle();
    _assign = List<int?>.filled(n, null);
    _active = 0;
  }

  int? _firstEmpty() {
    for (var i = 0; i < _assign.length; i++) {
      if (_assign[i] == null) return i;
    }
    return null;
  }

  bool get _complete => !_assign.contains(null);

  void _pick(int r) {
    if (widget.locked || _assign.contains(r)) return;
    final a = _active ?? _firstEmpty();
    if (a == null) return;
    setState(() {
      _assign[a] = r;
      _active = _firstEmpty();
    });
  }

  void _clear(int i) {
    if (widget.locked) return;
    setState(() {
      _assign[i] = null;
      _active = i;
    });
  }

  void _submit() {
    if (!_complete || widget.locked) return;
    widget.onSubmit([for (final e in _assign) e!]);
  }

  Widget _row(int i) {
    final theme = Theme.of(context);
    final p = widget.pairs[i];
    final chosen = _assign[i];
    final locked = widget.locked;
    final correct = chosen == i;
    final letter = AppColors.optionColors[i % 4];

    Color border;
    Color fill;
    if (locked) {
      border = correct ? AppColors.correct : AppColors.wrong;
      fill = border.withValues(alpha: 0.14);
    } else {
      border = _active == i
          ? theme.primaryColor
          : Colors.grey.withValues(alpha: 0.45);
      fill = theme.colorScheme.surface;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: letter.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration:
                            BoxDecoration(color: letter, shape: BoxShape.circle),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(p.left,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Center(
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 16, color: Colors.grey.shade500),
                ),
              ),
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: () => _clear(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: border, width: _active == i && !locked ? 2.4 : 1.6),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        chosen != null ? widget.pairs[chosen].right : '· · ·',
                        key: ValueKey(chosen),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: chosen == null ? Colors.grey.shade500 : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
          if (locked && !correct)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '✓ ${p.right}',
                  style: const TextStyle(
                      color: AppColors.correct,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pool = [for (final r in _order) if (!_assign.contains(r)) r];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.pairs.length; i++) _row(i),
        if (!widget.locked) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in pool)
                PressableScale(
                  key: ValueKey('pool-$r'),
                  onTap: () => _pick(r),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(widget.pairs[r].right,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            text: widget.submitLabel,
            icon: Icons.check_rounded,
            onTap: _complete ? _submit : null,
          ),
        ],
      ],
    );
  }
}
