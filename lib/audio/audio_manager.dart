import 'package:audioplayers/audioplayers.dart';

/// Manages all game audio. Uses synthetic beeps via AudioPool since we
/// generate sounds programmatically without bundled asset files.
///
/// SOUND FILE SOURCES (free, open-licensed):
/// ─────────────────────────────────────────────────────────────────
/// All sounds below are FREE to download from:
///
/// 1. freesound.org   → Create free account → search & download
/// 2. zapsplat.com    → Free with account
/// 3. mixkit.co       → 100% free, no account needed
/// 4. pixabay.com/music → Free music + SFX
///
/// RECOMMENDED FILES:
/// sounds/slide.mp3    → mixkit.co search "whoosh" → "Swoosh"
/// sounds/blocked.mp3  → freesound.org search "thud" or "error"
/// sounds/complete.mp3 → mixkit.co search "success" → "Winning chime"
/// sounds/milestone.mp3→ mixkit.co search "achievement"
/// sounds/hint.mp3     → freesound.org search "sparkle" or "ding"
/// sounds/bgmusic.mp3  → pixabay.com search "puzzle ambient"
/// ─────────────────────────────────────────────────────────────────
///
/// Put all files in: assets/sounds/
/// Then run: flutter pub get && flutter run

class AudioManager {
  static final AudioManager _instance = AudioManager._();
  factory AudioManager() => _instance;
  AudioManager._();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();
  bool _soundEnabled = true;
  bool _musicEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> init() async {
    await _bgPlayer.setVolume(0.4);
    await _bgPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playBgMusic() async {
    if (!_musicEnabled) return;
    try {
      await _bgPlayer.play(AssetSource('sounds/bgmusic.mp3'));
    } catch (_) {}
  }

  Future<void> stopBgMusic() async {
    await _bgPlayer.stop();
  }

  Future<void> play(String name) async {
    if (!_soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('sounds/$name.mp3'));
    } catch (_) {}
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  void toggleMusic() {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) {
      playBgMusic();
    } else {
      stopBgMusic();
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _bgPlayer.dispose();
  }
}
