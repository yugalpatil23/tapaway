import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'arrow_block.dart';
import 'level_generator.dart';

const int kTotalLevels = 1000;
const int kHintStarCost = 3;

class GameState extends ChangeNotifier {
  // ── Level state ──────────────────────────────────────────────────────────────
  late GameLevel _currentLevel;
  late List<ArrowBlock> _blocks;
  int _moves = 0;
  bool _isAnimating = false;
  bool _levelComplete = false;
  int _starsEarned = 0; // stars earned THIS level

  // ── Global progress ──────────────────────────────────────────────────────────
  int _currentLevelNumber = 1;
  int _highestUnlocked = 1; // next playable
  int _totalStars = 0;
  Map<int, int> _levelStars = {}; // level → stars earned (1‥3)

  // ── Audio callback (set by audio manager) ────────────────────────────────────
  void Function(String)? onSound;
  void Function(bool)? onLevelComplete; // true = success

  // ── Getters ──────────────────────────────────────────────────────────────────
  GameLevel get currentLevel => _currentLevel;
  List<ArrowBlock> get blocks => _blocks.where((b) => !b.isRemoved).toList();
  List<ArrowBlock> get allBlocks => _blocks;
  int get moves => _moves;
  int get levelNumber => _currentLevelNumber;
  bool get isAnimating => _isAnimating;
  bool get levelComplete => _levelComplete;
  int get starsEarned => _starsEarned;
  int get totalStars => _totalStars;
  int get highestUnlocked => _highestUnlocked;
  int get gridSize => _currentLevel.gridSize;
  Map<int, int> get levelStars => _levelStars;

  // Hints remaining (deducted from total stars)
  int get hintsAvailable => (_totalStars ~/ kHintStarCost);

  GameState() {
    _loadProgress().then((_) => loadLevel(_currentLevelNumber));
  }

  // ── Persistence ──────────────────────────────────────────────────────────────
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLevelNumber = prefs.getInt('currentLevel') ?? 1;
    _highestUnlocked = prefs.getInt('highestUnlocked') ?? 1;
    _totalStars = prefs.getInt('totalStars') ?? 0;
    final raw = prefs.getStringList('levelStars') ?? [];
    for (final s in raw) {
      final parts = s.split(':');
      if (parts.length == 2) {
        _levelStars[int.parse(parts[0])] = int.parse(parts[1]);
      }
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentLevel', _currentLevelNumber);
    await prefs.setInt('highestUnlocked', _highestUnlocked);
    await prefs.setInt('totalStars', _totalStars);
    await prefs.setStringList(
      'levelStars',
      _levelStars.entries.map((e) => '${e.key}:${e.value}').toList(),
    );
  }

  // ── Level management ─────────────────────────────────────────────────────────
  void loadLevel(int level) {
    _currentLevelNumber = level.clamp(1, kTotalLevels);
    _moves = 0;
    _levelComplete = false;
    _isAnimating = false;
    _starsEarned = 0;
    _currentLevel = LevelGenerator.generate(_currentLevelNumber);
    _blocks = List.from(_currentLevel.blocks);
    notifyListeners();
  }

  void nextLevel() {
    if (_currentLevelNumber < kTotalLevels) {
      loadLevel(_currentLevelNumber + 1);
    }
  }

  void restartLevel() => loadLevel(_currentLevelNumber);

  // ── Tap logic ────────────────────────────────────────────────────────────────
  Future<void> tapBlock(ArrowBlock block) async {
    if (_isAnimating || _levelComplete || block.isRemoved) return;

    if (!canSlide(block)) {
      // Shake the block + blocked sound
      _shakeBlock(block);
      onSound?.call('blocked');
      return;
    }

    _isAnimating = true;
    _moves++;

    final idx = _indexOf(block);
    _blocks[idx] = _blocks[idx].copyWith(isSliding: true);
    notifyListeners();

    onSound?.call('slide');

    await Future.delayed(const Duration(milliseconds: 620));

    _blocks[idx] = _blocks[idx].copyWith(isSliding: false, isRemoved: true);
    _isAnimating = false;

    _checkComplete();
    notifyListeners();
  }

  Future<void> _shakeBlock(ArrowBlock block) async {
    final idx = _indexOf(block);
    _blocks[idx] = _blocks[idx].copyWith(isShaking: true);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _blocks[idx] = _blocks[idx].copyWith(isShaking: false);
    notifyListeners();
  }

  bool canSlide(ArrowBlock block) {
    if (block.isRemoved) return false;
    final delta = block.direction.delta;
    int r = block.row + delta.dy.toInt();
    int c = block.col + delta.dx.toInt();
    while (r >= 0 && r < gridSize && c >= 0 && c < gridSize) {
      if (_hasBlock(r, c)) return false;
      r += delta.dy.toInt();
      c += delta.dx.toInt();
    }
    return true;
  }

  bool _hasBlock(int r, int c) =>
      _blocks.any((b) => !b.isRemoved && b.row == r && b.col == c);

  int _indexOf(ArrowBlock block) => _blocks.indexWhere((b) => b.id == block.id);

  // ── Hint ─────────────────────────────────────────────────────────────────────
  /// Returns the block that was hinted (for highlight), or null if no stars.
  ArrowBlock? useHint() {
    if (_totalStars < kHintStarCost) return null;
    // Find a block that CAN slide
    final slideable = blocks.where((b) => canSlide(b)).toList();
    if (slideable.isEmpty) return null;
    // Pick one randomly (or the first for simplicity)
    final hint = slideable.first;
    _totalStars -= kHintStarCost;
    _saveProgress();
    notifyListeners();
    return hint;
  }

  // ── Level complete ────────────────────────────────────────────────────────────
  void _checkComplete() {
    if (_blocks.any((b) => !b.isRemoved)) return;

    _levelComplete = true;
    _starsEarned = _calcStars();

    // Only update if better than previous
    final prev = _levelStars[_currentLevelNumber] ?? 0;
    if (_starsEarned > prev) {
      final gain = _starsEarned - prev;
      _totalStars += gain;
      _levelStars[_currentLevelNumber] = _starsEarned;
    }

    // Unlock next level
    if (_currentLevelNumber >= _highestUnlocked &&
        _currentLevelNumber < kTotalLevels) {
      _highestUnlocked = _currentLevelNumber + 1;
    }

    _saveProgress();
    onLevelComplete?.call(true);
  }

  int _calcStars() {
    final par = _currentLevel.blocks.length;
    if (_moves <= par) return 3;
    if (_moves <= par + (par ~/ 2)) return 2;
    return 1;
  }

  // ── Milestone ────────────────────────────────────────────────────────────────
  /// True if this completion hits a multiple-of-5 level milestone
  bool get isMilestone => _currentLevelNumber % 5 == 0;
}
