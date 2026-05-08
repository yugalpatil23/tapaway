import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_generator.dart';
import 'arrow_block.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DAILY CHALLENGE DESIGN
// ─────────────────────────────────────────────────────────────────────────────
// • 3 levels per day (Hard, Harder, Hardest) — completely separate from main
// • Stars per level: day 1 = 5★, day 2 = 8★, day 3 = 11★ … cap = 20★
//   Formula: min(5 + (dayNumber - 1) * 3, 20)
// • Grid size grows daily: day 1 = 6×6, capped at 10×10 after day 14
// • Density grows daily: day 1 = 50%, day 14+ = 80%
// • Levels get harder each day via more blocks + lower edge-bias
// • All 3 levels must be completed to mark day as done
// • Solvability guaranteed via simulation before returning any level
// ─────────────────────────────────────────────────────────────────────────────

class DailyChallenge extends ChangeNotifier {
  static final DailyChallenge _i = DailyChallenge._();
  factory DailyChallenge() => _i;
  DailyChallenge._();

  // ── Persisted state ──────────────────────────────────────────────────────────
  int _streak = 0; // days in a row
  int _totalDaysPlayed = 0; // used to scale difficulty & stars
  DateTime? _lastPlayedDate;

  // ── Today's session state ────────────────────────────────────────────────────
  int _levelsCompletedToday = 0; // 0, 1, 2, or 3
  bool _initialized = false;

  // ── Getters ──────────────────────────────────────────────────────────────────
  int get streak => _streak;
  int get levelsCompletedToday => _levelsCompletedToday;
  bool get allCompletedToday => _levelsCompletedToday >= 3;
  bool get initialized => _initialized;
  int get totalDaysPlayed => _totalDaysPlayed;

  /// Stars awarded per level completion today.
  /// Day 1 → 5★, Day 2 → 8★, Day 3 → 11★ … capped at 20★
  int get starsPerLevel => (5 + (_totalDaysPlayed) * 3).clamp(5, 20);

  /// How many of today's 3 levels the player has unlocked (1, 2, or 3).
  int get levelsUnlocked => _levelsCompletedToday + 1;

  // ── Init ─────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _streak = prefs.getInt('dc_streak') ?? 0;
    _totalDaysPlayed = prefs.getInt('dc_totalDays') ?? 0;
    _levelsCompletedToday = prefs.getInt('dc_levelsToday') ?? 0;

    final lastStr = prefs.getString('dc_lastDate');
    if (lastStr != null) _lastPlayedDate = DateTime.tryParse(lastStr);

    _checkNewDay();
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  void _checkNewDay() {
    final today = _today();
    if (_lastPlayedDate == null) return;
    final last = DateTime(
      _lastPlayedDate!.year,
      _lastPlayedDate!.month,
      _lastPlayedDate!.day,
    );

    if (last == today) {
      // Same day — keep session state
    } else {
      // New day — reset today's progress
      _levelsCompletedToday = 0;
      if (last == today.subtract(const Duration(days: 1))) {
        // Played yesterday → streak alive
      } else {
        _streak = 0; // missed a day
      }
    }
  }

  // ── Level generation ─────────────────────────────────────────────────────────

  /// Returns the GameLevel for a specific daily slot (1, 2, or 3).
  /// Each slot is harder than the last. Solvability is guaranteed.
  GameLevel getDailyLevel(int slot) {
    assert(slot >= 1 && slot <= 3);
    final today = _today();
    // Seed: unique per day + slot so each is a different puzzle
    final seed =
        (today.year * 10000 + today.month * 100 + today.day) * 10 + slot;
    final rng = Random(seed);

    // Grid grows daily, min 6 on day 0, max 10
    final gridSize = (_totalDaysPlayed ~/ 2 + 6).clamp(6, 10);

    // Block density: 50% day 1, grows +2% per day, cap 80%
    final density = (0.50 + _totalDaysPlayed * 0.02).clamp(0.50, 0.80);

    // Edge bias decreases as days pass → harder puzzles
    // Day 0 = 75% edge bias, day 15+ = 35%
    final bias = (0.75 - _totalDaysPlayed * 0.025).clamp(0.35, 0.75);

    // Each slot is progressively harder via lower bias + more blocks
    final slotBias = bias - (slot - 1) * 0.08;
    final slotDensity = density + (slot - 1) * 0.05;

    final totalCells = gridSize * gridSize;
    final blockCount = (totalCells * slotDensity).round().clamp(
      8,
      totalCells - 4,
    );

    final blocks = _buildGuaranteedBlocks(
      rng,
      gridSize,
      blockCount,
      slotBias.clamp(0.30, 0.75),
    );

    // Theme colours per slot
    const themes = [
      [Color(0xFFFFD60A), Color(0xFF8B5A00)], // slot 1 — gold
      [Color(0xFFFF6B35), Color(0xFF7A2500)], // slot 2 — orange-red
      [Color(0xFFFF4D6D), Color(0xFF7A0026)], // slot 3 — red
    ];

    final diffNames = ['Hard', 'Harder', 'Hardest'];

    return GameLevel(
      levelNumber: seed,
      gridSize: gridSize,
      blocks: blocks,
      difficulty: diffNames[slot - 1],
      themeColor: themes[slot - 1][0],
      themeDark: themes[slot - 1][1],
    );
  }

  // ── Complete a daily level ────────────────────────────────────────────────────

  /// Call when the player finishes a daily level.
  /// Returns the stars earned (starsPerLevel), or 0 if already completed.
  Future<int> completeDailyLevel(int slot) async {
    // Only award stars for the NEXT slot to complete (in order)
    if (slot != _levelsCompletedToday + 1) return 0;
    if (_levelsCompletedToday >= 3) return 0;

    _levelsCompletedToday++;
    _lastPlayedDate = _today();

    // If all 3 done → increment day counters
    if (_levelsCompletedToday >= 3) {
      _streak++;
      _totalDaysPlayed++;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dc_streak', _streak);
    await prefs.setInt('dc_totalDays', _totalDaysPlayed);
    await prefs.setInt('dc_levelsToday', _levelsCompletedToday);
    await prefs.setString('dc_lastDate', _lastPlayedDate!.toIso8601String());

    notifyListeners();
    return starsPerLevel;
  }

  // ── Block generation (deadlock-safe) ─────────────────────────────────────────

  /// Generates a block layout guaranteed to be solvable.
  /// Retries up to 30 times with different seeds, falls back to edge-only if needed.
  List<ArrowBlock> _buildGuaranteedBlocks(
    Random rng,
    int gs,
    int blockCount,
    double bias,
  ) {
    const colors = [
      Color(0xFFFFD60A),
      Color(0xFFFF9F1C),
      Color(0xFF4CC9F0),
      Color(0xFFFF6B9D),
      Color(0xFFA29BFE),
      Color(0xFF80FFDB),
    ];
    const darks = [
      Color(0xFF8B5A00),
      Color(0xFF8B4500),
      Color(0xFF023E8A),
      Color(0xFF8B0038),
      Color(0xFF3D2D9E),
      Color(0xFF0F6E47),
    ];

    for (int attempt = 0; attempt < 30; attempt++) {
      final tryRng = Random(rng.nextInt(0x7FFFFFFF));
      final positions = _allPositions(gs)..shuffle(tryRng);
      final blocks = <ArrowBlock>[];

      for (int i = 0; i < blockCount && i < positions.length; i++) {
        final r = positions[i][0];
        final c = positions[i][1];
        blocks.add(
          ArrowBlock(
            id: 'dc_$i',
            row: r,
            col: c,
            direction: _edgeBiasedDir(r, c, gs, tryRng, bias: bias),
            color: colors[i % colors.length],
            darkColor: darks[i % darks.length],
          ),
        );
      }

      if (isSolvable(blocks, gs)) return blocks;
    }

    // Guaranteed fallback — every block points to its nearest edge
    final positions = _allPositions(gs)..shuffle(rng);
    return List.generate(blockCount, (i) {
      final r = positions[i][0];
      final c = positions[i][1];
      return ArrowBlock(
        id: 'dc_$i',
        row: r,
        col: c,
        direction: _nearestEdgeDir(r, c, gs),
        color: colors[i % colors.length],
        darkColor: darks[i % darks.length],
      );
    });
  }

  // ── Solvability check (public so GameState can also call it) ─────────────────

  /// Greedy simulation: repeatedly remove any block that can currently slide.
  /// Returns true only if every block can eventually be removed → no deadlock.
  /// This is the single source of truth for deadlock detection.
  static bool isSolvable(List<ArrowBlock> blocks, int gs) {
    final rows = List<int>.from(blocks.map((b) => b.row));
    final cols = List<int>.from(blocks.map((b) => b.col));
    final removed = List<bool>.filled(blocks.length, false);

    bool progress = true;
    while (progress) {
      progress = false;
      for (int i = 0; i < blocks.length; i++) {
        if (removed[i]) continue;
        if (_blockCanSlide(i, blocks, rows, cols, removed, gs)) {
          removed[i] = true;
          progress = true;
        }
      }
    }
    return removed.every((r) => r);
  }

  static bool _blockCanSlide(
    int idx,
    List<ArrowBlock> blocks,
    List<int> rows,
    List<int> cols,
    List<bool> removed,
    int gs,
  ) {
    final delta = blocks[idx].direction.delta;
    int r = rows[idx] + delta.dy.toInt();
    int c = cols[idx] + delta.dx.toInt();
    while (r >= 0 && r < gs && c >= 0 && c < gs) {
      for (int j = 0; j < blocks.length; j++) {
        if (!removed[j] && j != idx && rows[j] == r && cols[j] == c)
          return false;
      }
      r += delta.dy.toInt();
      c += delta.dx.toInt();
    }
    return true;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  List<List<int>> _allPositions(int gs) => [
    for (int r = 0; r < gs; r++)
      for (int c = 0; c < gs; c++) [r, c],
  ];

  ArrowDirection _edgeBiasedDir(
    int row,
    int col,
    int gs,
    Random rng, {
    double bias = 0.7,
  }) {
    if (rng.nextDouble() > bias) return ArrowDirection.values[rng.nextInt(4)];
    return _nearestEdgeDir(row, col, gs);
  }

  ArrowDirection _nearestEdgeDir(int row, int col, int gs) {
    final d = [row, gs - 1 - row, col, gs - 1 - col];
    final best = d.reduce(min);
    if (d[0] == best) return ArrowDirection.up;
    if (d[2] == best) return ArrowDirection.left;
    if (d[1] == best) return ArrowDirection.down;
    return ArrowDirection.right;
  }

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}
