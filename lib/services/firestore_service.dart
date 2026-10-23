import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/question_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'auth_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  List<QuestionModel>? _jsonCache;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection(AppConstants.roomsCollection);

  CollectionReference<Map<String, dynamic>> _adminQCol(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection('admin_questions');

  // ═══════════════════════════ САВОЛҲО ═══════════════════════════

  Future<List<QuestionModel>> loadJsonQuestions() async {
    if (_jsonCache != null) return _jsonCache!;
    final String data = await rootBundle.loadString('lib/data/questions.json');
    final List list = json.decode(data) as List;
    _jsonCache = list
        .map((e) => QuestionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return _jsonCache!;
  }

  Future<List<QuestionModel>> loadAdminQuestions(String uid) async {
    try {
      final snap = await _adminQCol(uid).get();
      return snap.docs.map((d) => QuestionModel.fromJson(d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  /// Саволҳоро аз рӯи манбаъ, категория ва душворӣ интихоб мекунад.
  /// Вариантҳои ҷавоб омехта мешаванд.
  Future<List<QuestionModel>> loadQuestions({
    required String source,
    required int count,
    required String uid,
    String category = 'all',
    String difficulty = 'all',
  }) async {
    var all = <QuestionModel>[];
    if (source == 'json' || source == 'both') {
      all.addAll(await loadJsonQuestions());
    }
    if (source == 'admin' || source == 'both') {
      all.addAll(await loadAdminQuestions(uid));
    }
    if (category != 'all') {
      all = all.where((q) => q.category == category).toList();
    }
    if (difficulty != 'all') {
      all = all.where((q) => q.difficulty == difficulty).toList();
    }
    all.shuffle();
    if (all.length > count) all = all.sublist(0, count);
    return all.map((q) => q.shuffled()).toList();
  }

  Future<void> addAdminQuestion(QuestionModel q) async {
    await _adminQCol(_auth.uid).add(q.toJson());
  }

  Future<void> updateAdminQuestion(String docId, QuestionModel q) async {
    await _adminQCol(_auth.uid).doc(docId).update(q.toJson());
  }

  Future<void> deleteAdminQuestion(String docId) async {
    await _adminQCol(_auth.uid).doc(docId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAdminQuestions() {
    return _adminQCol(_auth.uid).snapshots();
  }

  // ═══════════════════════════ ҲУҶРАҲО ═══════════════════════════

  Future<String> _resolveName(String uid) async {
    String name = '';
    try {
      final doc =
          await _db.collection(AppConstants.usersCollection).doc(uid).get();
      name = (doc.data()?['name'] as String? ?? '').trim();
    } catch (_) {}
    if (name.isEmpty) name = _auth.displayName;
    if (name.isEmpty) name = 'Бозигар';
    return name;
  }

  Map<String, dynamic> _newPlayer(String uid, String name, bool isHost) => {
        'uid': uid,
        'name': name,
        'score': 0,
        'answered': false,
        'answerIndex': -1,
        'answerTimeMs': 0,
        'isHost': isHost,
        'streak': 0,
        'bestStreak': 0,
        'correct': 0,
        'lastGain': 0,
      };

  Future<String> createRoom({
    required String questionSource,
    required int questionCount,
    required int timePerQuestion,
    String category = 'all',
    String difficulty = 'all',
  }) async {
    final uid = _auth.uid;
    final name = await _resolveName(uid);

    final questions = await loadQuestions(
      source: questionSource,
      count: questionCount,
      uid: uid,
      category: category,
      difficulty: difficulty,
    );
    if (questions.isEmpty) throw Exception('no_questions');

    // Коди ягона
    String code = AppHelpers.generateRoomCode();
    for (int i = 0; i < 5; i++) {
      final exists = await _rooms
          .where('code', isEqualTo: code)
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();
      if (exists.docs.isEmpty) break;
      code = AppHelpers.generateRoomCode();
    }

    final ref = await _rooms.add({
      'code': code,
      'hostId': uid,
      'hostName': name,
      'status': 'waiting',
      'phase': 'question',
      'questionSource': questionSource,
      'category': category,
      'difficulty': difficulty,
      'questionCount': questions.length,
      'timePerQuestion': timePerQuestion,
      'questions': questions.map((q) => q.toJson()).toList(),
      'currentQuestionIndex': 0,
      'players': {uid: _newPlayer(uid, name, true)},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<Map<String, dynamic>?> findRoomByCode(String code) async {
    final c = code.toUpperCase();
    var snap = await _rooms
        .where('code', isEqualTo: c)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      snap = await _rooms.where('code', isEqualTo: c).limit(1).get();
    }
    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};
  }

  /// null = муваффақ, дар акси ҳол калиди хато
  Future<String?> joinRoom(String roomId) async {
    final uid = _auth.uid;
    final name = await _resolveName(uid);
    final ref = _rooms.doc(roomId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) throw Exception('room_not_found');
        if (data['status'] != 'waiting') {
          throw Exception('room_already_started');
        }
        final players = Map<String, dynamic>.from(data['players'] ?? {});
        if (!players.containsKey(uid) &&
            players.length >= AppConstants.maxPlayers) {
          throw Exception('room_full');
        }
        tx.update(ref, {'players.$uid': _newPlayer(uid, name, false)});
      });
      return null;
    } catch (e) {
      final msg = e.toString();
      for (final k in ['room_not_found', 'room_already_started', 'room_full']) {
        if (msg.contains(k)) return k;
      }
      return 'error';
    }
  }

  /// Хориҷ шудан. Агар мизбон дар интизорӣ бошад ё охирин бозигар бошад,
  /// ҳуҷра нест карда мешавад.
  Future<void> leaveRoom(String roomId) async {
    final uid = _auth.uid;
    final ref = _rooms.doc(roomId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) return;
        final players = Map<String, dynamic>.from(data['players'] ?? {});
        if (!players.containsKey(uid)) return;
        final isHost = data['hostId'] == uid;
        if ((data['status'] == 'waiting' && isHost) || players.length <= 1) {
          tx.delete(ref);
          return;
        }
        tx.update(ref, {'players.$uid': FieldValue.delete()});
      });
    } catch (_) {}
  }

  /// Пас аз тамом шудани бозӣ, баъд аз таъхир хориҷ мешавем,
  /// то ҳама натиҷаҳоро бубинанд. Охирин бозигар ҳуҷраро нест мекунад.
  void leaveRoomLater(String roomId,
      {Duration delay = const Duration(seconds: 25)}) {
    Future.delayed(delay, () => leaveRoom(roomId));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamRoom(String roomId) {
    return _rooms.doc(roomId).snapshots();
  }

  Future<void> startGame(String roomId) async {
    final ref = _rooms.doc(roomId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) return;
      if (data['hostId'] != _auth.uid || data['status'] != 'waiting') return;
      final players = Map<String, dynamic>.from(data['players'] ?? {});
      final updates = <String, dynamic>{
        'status': 'playing',
        'phase': 'question',
        'currentQuestionIndex': 0,
      };
      for (final k in players.keys) {
        updates['players.$k.score'] = 0;
        updates['players.$k.streak'] = 0;
        updates['players.$k.bestStreak'] = 0;
        updates['players.$k.correct'] = 0;
        updates['players.$k.lastGain'] = 0;
        updates['players.$k.answered'] = false;
        updates['players.$k.answerIndex'] = -1;
        updates['players.$k.answerTimeMs'] = 0;
      }
      tx.update(ref, updates);
    });
  }

  // ═══════════════ ҶАВОБ ВА ГУЗАРИШ БА САВОЛИ НАВБАТӣ ═══════════════

  /// Ҷавобро дар як транзаксия қабул мекунад ва холро ҳисоб мекунад.
  /// Такрорӣ ё дер ҷавоб додан рад мешавад. Холи бадастомада бармегардад.
  Future<int> submitAnswer({
    required String roomId,
    required int expectedIndex,
    required int answerIndex,
    required int timeLeftMs,
  }) async {
    final uid = _auth.uid;
    final ref = _rooms.doc(roomId);
    try {
      return await _db.runTransaction<int>((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) return 0;
        if (data['status'] != 'playing') return 0;
        if ((data['phase'] ?? 'question') != 'question') return 0;
        if (((data['currentQuestionIndex'] as num?)?.toInt() ?? 0) !=
            expectedIndex) {
          return 0;
        }
        final players = Map<String, dynamic>.from(data['players'] ?? {});
        final rawMe = players[uid];
        if (rawMe == null) return 0;
        final me = Map<String, dynamic>.from(rawMe as Map);
        if (me['answered'] == true) return 0;

        final questions = (data['questions'] as List? ?? []);
        if (expectedIndex >= questions.length) return 0;
        final q = QuestionModel.fromJson(
            Map<String, dynamic>.from(questions[expectedIndex] as Map));

        final total = (data['timePerQuestion'] as num?)?.toInt() ?? 20;
        final left = timeLeftMs.clamp(0, total * 1000);
        final correct = answerIndex == q.correctIndex;
        final oldStreak = (me['streak'] as num?)?.toInt() ?? 0;
        final streak = correct ? oldStreak + 1 : 0;
        final points = correct
            ? AppHelpers.calculatePoints(
                timeLeftMs: left,
                totalSec: total,
                difficulty: q.difficulty,
                streak: streak,
              )
            : 0;

        tx.update(ref, {
          'players.$uid.answered': true,
          'players.$uid.answerIndex': answerIndex,
          'players.$uid.answerTimeMs': left,
          'players.$uid.lastGain': points,
          'players.$uid.streak': streak,
          'players.$uid.bestStreak':
              max(streak, (me['bestStreak'] as num?)?.toInt() ?? 0),
          'players.$uid.score': ((me['score'] as num?)?.toInt() ?? 0) + points,
          'players.$uid.correct':
              ((me['correct'] as num?)?.toInt() ?? 0) + (correct ? 1 : 0),
        });
        return points;
      });
    } catch (_) {
      return 0;
    }
  }

  /// Идемпотентӣ: ҳар бозигар метавонад даъват кунад, аммо танҳо яке
  /// (аввалӣ) муваффақ мешавад. Дигарон мебинанд, ки ҳолат аллакай иваз шудааст.
  ///
  /// question -> reveal : ҷавобнадодаҳо "ҷавоб додашуда" ҳисоб мешаванд
  /// reveal   -> savoli navbati (ё finished) : ҳолати ҳамаи бозигарон
  ///                                           дар ҳамон транзаксия нав мешавад
  Future<void> advance({
    required String roomId,
    required int expectedIndex,
    required String expectedPhase,
  }) async {
    final ref = _rooms.doc(roomId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) return;
        if (data['status'] != 'playing') return;
        final idx = (data['currentQuestionIndex'] as num?)?.toInt() ?? 0;
        final phase = (data['phase'] ?? 'question') as String;
        if (idx != expectedIndex || phase != expectedPhase) return;

        final players = Map<String, dynamic>.from(data['players'] ?? {});
        final updates = <String, dynamic>{};

        if (phase == 'question') {
          updates['phase'] = 'reveal';
          players.forEach((k, v) {
            final p = Map<String, dynamic>.from(v as Map);
            if (p['answered'] != true) {
              updates['players.$k.answered'] = true;
              updates['players.$k.answerIndex'] = -1;
              updates['players.$k.lastGain'] = 0;
              updates['players.$k.streak'] = 0;
            }
          });
        } else {
          final total = (data['questions'] as List? ?? []).length;
          final next = idx + 1;
          if (next >= total) {
            updates['status'] = 'finished';
          } else {
            updates['currentQuestionIndex'] = next;
            updates['phase'] = 'question';
            for (final k in players.keys) {
              updates['players.$k.answered'] = false;
              updates['players.$k.answerIndex'] = -1;
              updates['players.$k.answerTimeMs'] = 0;
              updates['players.$k.lastGain'] = 0;
            }
          }
        }
        tx.update(ref, updates);
      });
    } catch (_) {}
  }

  // ═══════════════════════════ РЕЙТИНГ ═══════════════════════════

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTopPlayers({
    String orderBy = 'totalScore',
    int limit = 50,
  }) {
    return _db
        .collection(AppConstants.usersCollection)
        .orderBy(orderBy, descending: true)
        .limit(limit)
        .snapshots();
  }
}
