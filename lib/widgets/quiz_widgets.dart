import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'app_button.dart';
import 'fx.dart';

// ═══════════════════════════ OPTION TILE ═══════════════════════════

enum OptionState { idle, correct, wrong, dimmed, eliminated }

class OptionTile extends StatefulWidget {
  final int index;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  const OptionTile({
    super.key,
    required this.index,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  State<OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<OptionTile> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _fx;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _fx = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 560));
    Future.delayed(Duration(milliseconds: 70 * widget.index + 60), () {
      if (mounted) _enter.forward();
    });
  }

  @override
  void didUpdateWidget(OptionTile old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state &&
        (widget.state == OptionState.wrong ||
            widget.state == OptionState.correct)) {
      _fx.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _fx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letterColor = AppColors.optionColors[widget.index % 4];
    final st = widget.state;
    final isCorrect = st == OptionState.correct;
    final isWrong = st == OptionState.wrong;

    Color bg = theme.colorScheme.surface;
    Color border = letterColor.withValues(alpha: 0.55);
    Color? textColor;
    if (isCorrect) {
      bg = AppColors.correct;
      border = AppColors.correct;
      textColor = Colors.white;
    } else if (isWrong) {
      bg = AppColors.wrong;
      border = AppColors.wrong;
      textColor = Colors.white;
    }

    final opacity = st == OptionState.dimmed
        ? 0.45
        : st == OptionState.eliminated
            ? 0.12
            : 1.0;

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: (isCorrect || isWrong ? bg : letterColor)
                .withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isCorrect || isWrong)
                  ? Colors.white.withValues(alpha: 0.25)
                  : letterColor,
            ),
            child: isCorrect
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                : isWrong
                    ? const Icon(Icons.close_rounded,
                        color: Colors.white, size: 22)
                    : Text(
                        String.fromCharCode(65 + widget.index),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _fx]),
      builder: (_, child) {
        final e = Curves.easeOutCubic.transform(_enter.value);
        double dx = (1 - e) * 60;
        if (isWrong) dx += sin(_fx.value * pi * 6) * 10 * (1 - _fx.value);
        final scale = isCorrect ? 1 + 0.05 * sin(_fx.value * pi) : 1.0;
        return Opacity(
          opacity: e,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: opacity,
        child: PressableScale(
          pressedScale: 0.97,
          onTap: widget.onTap,
          child: tile,
        ),
      ),
    );
  }
}

// ═══════════════════════════ QUESTION CARD ═══════════════════════════

class QuestionCard extends StatelessWidget {
  final String question;
  final String category;
  final String categoryLabel;
  final String difficulty;
  final String difficultyLabel;
  final String? hint;

  const QuestionCard({
    super.key,
    required this.question,
    required this.category,
    required this.categoryLabel,
    required this.difficulty,
    required this.difficultyLabel,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dColor = AppHelpers.difficultyColor(difficulty);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniChip(
                text: '${AppHelpers.categoryEmoji(category)} $categoryLabel',
                color: AppColors.primary,
              ),
              _MiniChip(text: difficultyLabel, color: dColor),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ═══════════════════════════ STREAK ═══════════════════════════

class StreakBadge extends StatelessWidget {
  final int streak;
  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.elasticOut,
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: streak >= 2
          ? Pulse(
              key: ValueKey('p$streak'),
              amount: streak >= 5 ? 0.14 : 0.08,
              child: Container(
              key: ValueKey(streak),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.fire.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.fire.withValues(alpha: 0.6)),
              ),
              child: Text(
                '🔥 x$streak',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.fire,
                  fontSize: 14,
                ),
              ),
            ))
          : const SizedBox(key: ValueKey('none'), width: 1, height: 30),
    );
  }
}

// ═══════════════════════════ LIFELINE ═══════════════════════════

class LifelineButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const LifelineButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: enabled ? 1 : 0.35,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5), width: 1.6),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ POINTS POP ═══════════════════════════

/// "+850": боло мебарояд ва нопадид мешавад. Барои ҳар бор калиди нав диҳед.
class PointsPop extends StatelessWidget {
  final int points;
  const PointsPop({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(
        opacity: (1 - t * t).clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(
          offset: Offset(0, -46 * t),
          child: Transform.scale(scale: 0.85 + 0.35 * sin(min(t * 3, 1) * pi / 2), child: child),
        ),
      ),
      child: Text(
        '+$points',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: AppColors.correct,
        ),
      ),
    );
  }
}

// ═══════════════════════════ ANIMATED SCORE ═══════════════════════════

class AnimatedScore extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String prefix;

  const AnimatedScore({super.key, required this.value, this.style, this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$prefix$v', style: style),
    );
  }
}

// ═══════════════════════════ SELECT CHIP ═══════════════════════════

class SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.primaryColor;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : Colors.grey.withValues(alpha: 0.35),
          ),
          boxShadow: selected
              ? [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}
