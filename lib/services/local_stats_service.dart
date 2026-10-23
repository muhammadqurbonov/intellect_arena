import 'package:shared_preferences/shared_preferences.dart';

/// Беҳтарин натиҷаи офлайн дар худи телефон нигоҳ дошта мешавад
class LocalStatsService {
  static Future<int> bestScore(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('best_score_$mode') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// true бармегардонад, агар рекорди нав гузошта шуда бошад
  static Future<bool> recordScore(String mode, int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final old = prefs.getInt('best_score_$mode') ?? 0;
      if (score > old) {
        await prefs.setInt('best_score_$mode', score);
        return old > 0; // дафъаи аввал "рекорд" ҳисоб намешавад
      }
    } catch (_) {}
    return false;
  }
}
