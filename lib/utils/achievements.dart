/// Нишонҳо (достижения). Шарт аз рӯи омори корбар санҷида мешавад.
class Achievement {
  final String id;
  final String emoji;
  final bool Function(Map<String, dynamic> stats) unlocked;

  const Achievement(this.id, this.emoji, this.unlocked);

  String get titleKey => 'ach_$id';
  String get descKey => 'ach_${id}_d';
}

int _n(Map<String, dynamic> s, String k) => (s[k] as num?)?.toInt() ?? 0;

final List<Achievement> allAchievements = [
  Achievement('first_game', '🎮', (s) => _n(s, 'gamesPlayed') >= 1),
  Achievement('ten_games', '🔟', (s) => _n(s, 'gamesPlayed') >= 10),
  Achievement('first_win', '🥇', (s) => _n(s, 'gamesWon') >= 1),
  Achievement('five_wins', '🏆', (s) => _n(s, 'gamesWon') >= 5),
  Achievement('streak5', '🔥', (s) => _n(s, 'bestStreak') >= 5),
  Achievement('streak10', '⚡', (s) => _n(s, 'bestStreak') >= 10),
  Achievement('perfect', '💯', (s) => _n(s, 'perfectGames') >= 1),
  Achievement('score10k', '⭐', (s) => _n(s, 'totalScore') >= 10000),
];
