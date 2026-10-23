import 'dart:math';
import 'package:flutter/material.dart';

class AppHelpers {
  static String generateRoomCode() {
    // Ҳарфу рақамҳои шабеҳ (O/0, I/1) нест карда шудаанд
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (i) => chars[random.nextInt(chars.length)]).join();
  }

  /// Холи асосӣ: 100..1000 вобаста ба вақти боқимонда
  static int calculateScore(int timeLeftMs, int totalSec) {
    if (totalSec <= 0) return 100;
    final ratio = (timeLeftMs / (totalSec * 1000)).clamp(0.0, 1.0);
    return (100 + 900 * ratio).round();
  }

  static double difficultyMultiplier(String d) {
    switch (d) {
      case 'hard':
        return 1.5;
      case 'medium':
        return 1.25;
      default:
        return 1.0;
    }
  }

  /// Бонус барои силсилаи ҷавобҳои дуруст (streak)
  static int streakBonus(int streak) {
    if (streak < 2) return 0;
    return min(streak - 1, 5) * 30;
  }

  static int calculatePoints({
    required int timeLeftMs,
    required int totalSec,
    required String difficulty,
    required int streak,
  }) {
    final base = calculateScore(timeLeftMs, totalSec);
    return (base * difficultyMultiplier(difficulty)).round() +
        streakBonus(streak);
  }

  // ─── Сатҳҳо ───────────────────────────────────────────────
  static int levelFor(int totalScore) =>
      sqrt(max(0, totalScore) / 5000).floor() + 1;

  static int scoreForLevel(int level) => 5000 * (level - 1) * (level - 1);

  static double levelProgress(int totalScore) {
    final lvl = levelFor(totalScore);
    final lo = scoreForLevel(lvl);
    final hi = scoreForLevel(lvl + 1);
    return ((totalScore - lo) / (hi - lo)).clamp(0.0, 1.0);
  }

  static String levelTitleKey(int level) => 'level_${min(level, 6)}';

  // ─── Ранг ва эмодзиҳо ─────────────────────────────────────
  static Color getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFFB0B0B0);
    }
  }

  static String getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank.';
    }
  }

  static String categoryEmoji(String c) {
    switch (c) {
      case 'geography':
        return '🌍';
      case 'science':
        return '🔬';
      case 'history':
        return '🏛️';
      case 'math':
        return '➗';
      case 'tech':
        return '💻';
      case 'islam':
        return '🕌';
      case 'culture':
        return '🎭';
      case 'sport':
        return '⚽';
      case 'all':
        return '🎲';
      default:
        return '💡';
    }
  }

  static Color difficultyColor(String d) {
    switch (d) {
      case 'hard':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF22C55E);
    }
  }

  static String initial(String name) {
    final n = name.trim();
    return n.isEmpty ? '?' : n.characters.first.toUpperCase();
  }

  /// Рангӣ собит барои аватар аз рӯи ном
  static Color avatarColor(String name) {
    final h = name.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0xFFFF);
    return HSLColor.fromAHSL(1, (h % 360).toDouble(), 0.55, 0.5).toColor();
  }
}
