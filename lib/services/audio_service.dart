import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HapticKind { light, medium, heavy }

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    } catch (_) {}
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    if (value) haptic(HapticKind.medium);
  }

  void haptic(HapticKind kind) {
    if (!_vibrationEnabled) return;
    switch (kind) {
      case HapticKind.light:
        HapticFeedback.lightImpact();
        break;
      case HapticKind.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticKind.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  Future<void> _play(String asset) async {
    if (!_soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> playCorrect() => _play('sounds/correct.mp3');
  Future<void> playWrong() => _play('sounds/wrong.mp3');
  Future<void> playWin() => _play('sounds/win.mp3');

  void dispose() {
    _player.dispose();
  }
}
