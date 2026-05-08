import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AudioManager — singleton for all game audio.
///
/// FIXES vs original:
/// • SFX files are .wav not .mp3 — _sfxMap maps names → real filenames
/// • AudioPool of 3 players — rapid taps never cut each other off
/// • All toggle states persisted to SharedPreferences (survive restart)
/// • Haptics centralised here so hapticsEnabled flag covers every callsite
/// • 'hint' falls back to complete.wav until hint.wav is added

class AudioManager {
  static final AudioManager _i = AudioManager._();
  factory AudioManager() => _i;
  AudioManager._();

  // 3-player SFX pool — round-robin so overlapping sounds work
  final List<AudioPlayer> _pool = List.generate(3, (_) => AudioPlayer());
  int _poolIdx = 0;
  final AudioPlayer _bg = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _hapticsEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  // Logical name → actual file in assets/sounds/
  // SFX are .wav; background music is .mp3
  static const _sfxMap = <String, String>{
    'slide': 'slide.wav',
    'blocked': 'blocked.wav',
    'complete': 'complete.wav',
    'milestone': 'milestone.wav',
    'hint': 'complete.wav', // replace with hint.wav when available
  };

  Future<void> init() async {
    await _bg.setVolume(0.35);
    await _bg.setReleaseMode(ReleaseMode.loop);
    for (final p in _pool) {
      await p.setVolume(1.0);
      await p.setReleaseMode(ReleaseMode.release);
    }
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('pref_sound') ?? true;
    _musicEnabled = prefs.getBool('pref_music') ?? true;
    _hapticsEnabled = prefs.getBool('pref_haptics') ?? true;
  }

  Future<void> playBgMusic() async {
    if (!_musicEnabled) return;
    try {
      await _bg.play(AssetSource('sounds/bgmusic.mp3'));
    } catch (e) {
      debugPrint('[Audio] bgmusic: $e');
    }
  }

  Future<void> stopBgMusic() async {
    try {
      await _bg.stop();
    } catch (_) {}
  }

  Future<void> play(String name) async {
    if (!_soundEnabled) return;
    final file = _sfxMap[name];
    if (file == null) return;
    final player = _pool[_poolIdx % _pool.length];
    _poolIdx++;
    try {
      await player.play(AssetSource('sounds/$file'));
    } catch (e) {
      debugPrint('[Audio] sfx "$name": $e');
    }
  }

  /// Central haptics — respects the user's haptics preference
  void haptic(HapticType type) {
    if (!_hapticsEnabled) return;
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final p = await SharedPreferences.getInstance();
    await p.setBool('pref_sound', _soundEnabled);
  }

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    final p = await SharedPreferences.getInstance();
    await p.setBool('pref_music', _musicEnabled);
    _musicEnabled ? playBgMusic() : stopBgMusic();
  }

  Future<void> toggleHaptics() async {
    _hapticsEnabled = !_hapticsEnabled;
    final p = await SharedPreferences.getInstance();
    await p.setBool('pref_haptics', _hapticsEnabled);
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _bg.dispose();
  }
}

enum HapticType { light, medium, heavy }
