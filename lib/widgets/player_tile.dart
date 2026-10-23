import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'quiz_widgets.dart';

class PlayerTile extends StatelessWidget {
  final PlayerModel player;
  final int rank;
  final bool showAnswered;
  final bool isMe;
  final bool showGain;

  const PlayerTile({
    super.key,
    required this.player,
    required this.rank,
    this.showAnswered = false,
    this.isMe = false,
    this.showGain = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankColor = AppHelpers.getRankColor(rank);
    final displayName =
        player.name.trim().isNotEmpty ? player.name : 'Бозигар $rank';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? theme.primaryColor.withValues(alpha: 0.14)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? theme.primaryColor.withValues(alpha: 0.6)
              : rank <= 3
                  ? rankColor.withValues(alpha: 0.55)
                  : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              AppHelpers.getRankEmoji(rank),
              style: TextStyle(fontSize: 19, color: rankColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppHelpers.avatarColor(displayName),
            child: Text(
              AppHelpers.initial(displayName),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (player.isHost) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child:
                        const Text('Host', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ],
            ),
          ),
          if (showAnswered) ...[
            Icon(
              player.answered ? Icons.check_circle : Icons.hourglass_empty,
              color: player.answered ? AppColors.correct : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          if (showGain && player.lastGain > 0) ...[
            Text(
              '+${player.lastGain}',
              style: const TextStyle(
                  color: AppColors.correct,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
            ),
            const SizedBox(width: 8),
          ],
          AnimatedScore(
            value: player.score,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: rankColor,
            ),
          ),
        ],
      ),
    );
  }
}
