import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String get uid => _auth.currentUser?.uid ?? '';

  String _displayName = '';
  String get displayName => _displayName;

  // ─── INIT ─────────────────────────────────────────────────
  Future<void> init() async {
    try {
      await ensureSignedIn();
    } catch (_) {
      // Бе интернет ҳам барнома кушода мешавад
    }
    await loadProfile();
  }

  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // ─── LOAD PROFILE ─────────────────────────────────────────
  Future<void> loadProfile() async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString('display_name') ?? '';

    if (_displayName.isEmpty) {
      try {
        final doc =
            await _db.collection(AppConstants.usersCollection).doc(uid).get();
        if (doc.exists) {
          _displayName = (doc.data()?['name'] as String? ?? '').trim();
          if (_displayName.isNotEmpty) {
            await prefs.setString('display_name', _displayName);
          }
        }
      } catch (_) {}
    }

    try {
      if (_auth.currentUser != null &&
          _displayName.isNotEmpty &&
          _auth.currentUser!.displayName != _displayName) {
        await _auth.currentUser!.updateDisplayName(_displayName);
      }
    } catch (_) {}
  }

  Future<String> getFreshName() async {
    await loadProfile();
    return _displayName;
  }

  // ─── SAVE PROFILE ─────────────────────────────────────────
  /// Танҳо ном навишта мешавад. Ҳисобкунакҳо (холҳо) ҳеҷ гоҳ даст намерасанд.
  Future<void> saveProfile(String name) async {
    await ensureSignedIn();
    if (uid.isEmpty) return;
    _displayName = name.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_name', _displayName);

    try {
      await _auth.currentUser?.updateDisplayName(_displayName);
    } catch (_) {}

    await _db.collection(AppConstants.usersCollection).doc(uid).set({
      'name': _displayName,
      'uid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── USER STATS ───────────────────────────────────────────
  Future<Map<String, dynamic>> getUserStats() async {
    if (uid.isEmpty) return {};
    try {
      final doc =
          await _db.collection(AppConstants.usersCollection).doc(uid).get();
      return doc.data() ?? {};
    } catch (_) {
      return {};
    }
  }

  // ─── NATIJAI BOZI ─────────────────────────────────────────
  Future<void> addGameResult({
    required int score,
    required bool won,
    required int correct,
    required int total,
    required int bestStreak,
  }) async {
    if (uid.isEmpty) return;
    final ref = _db.collection(AppConstants.usersCollection).doc(uid);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final d = snap.data() ?? <String, dynamic>{};
        int n(String k) => (d[k] as num?)?.toInt() ?? 0;
        final perfect = total >= 5 && correct == total;
        final data = <String, dynamic>{
          'uid': uid,
          'totalScore': n('totalScore') + score,
          'gamesPlayed': n('gamesPlayed') + 1,
          'gamesWon': n('gamesWon') + (won ? 1 : 0),
          'correctAnswers': n('correctAnswers') + correct,
          'totalAnswers': n('totalAnswers') + total,
          'bestStreak': max(n('bestStreak'), bestStreak),
          'bestScore': max(n('bestScore'), score),
          'perfectGames': n('perfectGames') + (perfect ? 1 : 0),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (_displayName.isNotEmpty) data['name'] = _displayName;
        tx.set(ref, data, SetOptions(merge: true));
      });
    } catch (_) {}
  }
}
