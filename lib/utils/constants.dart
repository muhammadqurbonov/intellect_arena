import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF16213E);
  static const Color card = Color(0xFF0F3460);
  static const Color correct = Color(0xFF22C55E);
  static const Color wrong = Color(0xFFEF4444);
  static const Color warn = Color(0xFFF59E0B);
  static const Color fire = Color(0xFFFF8A3D);
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);

  /// Ранги ҳарфҳои A, B, C, D дар вариантҳои ҷавоб
  static const List<Color> optionColors = [
    Color(0xFF7C6CFF),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
  ];

  static const LinearGradient brand = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppConstants {
  static const int defaultQuestionCount = 10;
  static const int defaultTimePerQuestion = 20;
  static const int maxScore = 1000;
  static const int lives = 3;
  static const int bonusSeconds = 10;
  static const int maxPlayers = 20;
  static const int revealMs = 3000;
  static const String usersCollection = 'users';
  static const String roomsCollection = 'rooms';
  static const String adminQuestionsCollection = 'admin_questions';

  static const List<String> categories = [
    'general', 'geography', 'science', 'history', 'math',
    'tech', 'islam', 'culture', 'sport',
  ];
  static const List<String> difficulties = ['easy', 'medium', 'hard'];
}
