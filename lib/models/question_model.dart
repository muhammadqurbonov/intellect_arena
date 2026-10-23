import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;
  final String difficulty;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
    required this.difficulty,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString() ?? 'general',
      // Файли кӯҳна "level" дорад, нав "difficulty"
      difficulty:
          (json['difficulty'] ?? json['level'])?.toString() ?? 'easy',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'category': category,
        'difficulty': difficulty,
      };

  /// Вариантҳоро омехта мекунад, то ҷавоби дуруст ҳамеша "A" набошад
  QuestionModel shuffled([Random? rnd]) {
    if (correctIndex < 0 || correctIndex >= options.length) return this;
    final idx = List<int>.generate(options.length, (i) => i)
      ..shuffle(rnd ?? Random());
    return QuestionModel(
      id: id,
      question: question,
      options: [for (final i in idx) options[i]],
      correctIndex: idx.indexOf(correctIndex),
      category: category,
      difficulty: difficulty,
    );
  }
}

/// Сабти ҷавоб барои баррасии хатоҳо дар охири бозӣ
class AnswerRecord {
  final QuestionModel question;
  final int selected; // -1 = вақт тамом, -2 = гузаронида шуд
  final int timeMs;

  AnswerRecord({
    required this.question,
    required this.selected,
    required this.timeMs,
  });

  bool get skipped => selected == -2;
  bool get correct => selected == question.correctIndex;
}

class PlayerModel {
  final String uid;
  final String name;
  int score;
  bool answered;
  int answerIndex;
  int answerTimeMs;
  bool isHost;
  int streak;
  int bestStreak;
  int correct;
  int lastGain;

  PlayerModel({
    required this.uid,
    required this.name,
    this.score = 0,
    this.answered = false,
    this.answerIndex = -1,
    this.answerTimeMs = 0,
    this.isHost = false,
    this.streak = 0,
    this.bestStreak = 0,
    this.correct = 0,
    this.lastGain = 0,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    int n(String k, [int d = 0]) => (json[k] as num?)?.toInt() ?? d;
    return PlayerModel(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      score: n('score'),
      answered: json['answered'] == true,
      answerIndex: n('answerIndex', -1),
      answerTimeMs: n('answerTimeMs'),
      isHost: json['isHost'] == true,
      streak: n('streak'),
      bestStreak: n('bestStreak'),
      correct: n('correct'),
      lastGain: n('lastGain'),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'score': score,
        'answered': answered,
        'answerIndex': answerIndex,
        'answerTimeMs': answerTimeMs,
        'isHost': isHost,
        'streak': streak,
        'bestStreak': bestStreak,
        'correct': correct,
        'lastGain': lastGain,
      };
}

class RoomModel {
  final String roomId;
  final String code;
  final String hostId;
  final String hostName;
  String status; // waiting, playing, finished
  String phase; // question, reveal
  final String questionSource;
  final int timePerQuestion;
  final List<QuestionModel> questions;
  int currentQuestionIndex;
  final Map<String, PlayerModel> players;
  final DateTime createdAt;

  RoomModel({
    required this.roomId,
    required this.code,
    required this.hostId,
    required this.hostName,
    required this.status,
    required this.phase,
    required this.questionSource,
    required this.timePerQuestion,
    required this.questions,
    this.currentQuestionIndex = 0,
    required this.players,
    required this.createdAt,
  });

  QuestionModel? get currentQuestion =>
      currentQuestionIndex < questions.length
          ? questions[currentQuestionIndex]
          : null;

  factory RoomModel.fromJson(Map<String, dynamic> json, String id) {
    final playersMap = <String, PlayerModel>{};
    (json['players'] as Map? ?? {}).forEach((key, value) {
      playersMap[key.toString()] =
          PlayerModel.fromJson(Map<String, dynamic>.from(value as Map));
    });
    final questionsList = <QuestionModel>[
      for (final q in (json['questions'] as List? ?? []))
        QuestionModel.fromJson(Map<String, dynamic>.from(q as Map)),
    ];
    final created = json['createdAt'];
    return RoomModel(
      roomId: id,
      code: json['code']?.toString() ?? '',
      hostId: json['hostId']?.toString() ?? '',
      hostName: json['hostName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'waiting',
      phase: json['phase']?.toString() ?? 'question',
      questionSource: json['questionSource']?.toString() ?? 'json',
      timePerQuestion: (json['timePerQuestion'] as num?)?.toInt() ?? 20,
      questions: questionsList,
      currentQuestionIndex:
          (json['currentQuestionIndex'] as num?)?.toInt() ?? 0,
      players: playersMap,
      createdAt: created is Timestamp
          ? created.toDate()
          : created is int
              ? DateTime.fromMillisecondsSinceEpoch(created)
              : DateTime.now(),
    );
  }
}
