import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'arrow_block.dart';

class GameLevel {
  final int levelNumber;
  final int gridSize;
  final List<ArrowBlock> blocks;
  final String difficulty;
  final Color themeColor;
  final Color themeDark;

  const GameLevel({
    required this.levelNumber,
    required this.gridSize,
    required this.blocks,
    required this.difficulty,
    required this.themeColor,
    required this.themeDark,
  });
}

class LevelGenerator {
  // ── Colour palettes per difficulty ──────────────────────────────────────────
  static const _easyPalette = [
    [Color(0xFF4CC9F0), Color(0xFF023E8A)],
    [Color(0xFF80FFDB), Color(0xFF0F6E47)],
    [Color(0xFFFFD166), Color(0xFF8B5A00)],
    [Color(0xFFFF6B9D), Color(0xFF8B0038)],
    [Color(0xFFA29BFE), Color(0xFF3D2D9E)],
  ];
  static const _medPalette = [
    [Color(0xFFFF9F1C), Color(0xFF8B4500)],
    [Color(0xFF2EC4B6), Color(0xFF0A4D47)],
    [Color(0xFFE71D36), Color(0xFF6B0015)],
    [Color(0xFF9B5DE5), Color(0xFF4A1A8C)],
    [Color(0xFF00BBF9), Color(0xFF004F73)],
  ];
  static const _hardPalette = [
    [Color(0xFFFF4D6D), Color(0xFF7A0026)],
    [Color(0xFF7B2FBE), Color(0xFF2D0057)],
    [Color(0xFFFF6B35), Color(0xFF7A2500)],
    [Color(0xFF14213D), Color(0xFF070D1E)],
    [Color(0xFF06D6A0), Color(0xFF024034)],
  ];
  static const _expertPalette = [
    [Color(0xFF560BAD), Color(0xFF1A0035)],
    [Color(0xFFD62828), Color(0xFF5C0000)],
    [Color(0xFF023E8A), Color(0xFF00072B)],
    [Color(0xFF1B4332), Color(0xFF081A11)],
    [Color(0xFF9D0208), Color(0xFF3D0003)],
  ];

  static GameLevel generate(int level) {
    // Use a seeded RNG per level for reproducibility
    final rng = Random(level * 31337 + 7);
    final gridSize = _gridSize(level);
    final difficulty = _difficulty(level);
    final themePair = _themePair(level);
    final themeColor = themePair[0];
    final themeDark = themePair[1];

    final blocks = _buildLevel(level, gridSize, rng);

    return GameLevel(
      levelNumber: level,
      gridSize: gridSize,
      blocks: blocks,
      difficulty: difficulty,
      themeColor: themeColor,
      themeDark: themeDark,
    );
  }

  static int _gridSize(int level) {
    if (level <= 3) return 4; // Levels   1–3   → 4×4  (3 levels,  Cyan)
    if (level <= 7) return 6; // Levels   4–10  → 5×5  (7 levels,  Green)
    if (level <= 10) return 8; // Levels   4–10  → 5×5  (7 levels,  Green)
    if (level <= 17) return 12; // Levels  11–27  → 6×6  (17 levels, Yellow)
    if (level <= 25) return 18; // Levels  28–50  → 7×7
    if (level <= 32) return 22; // Levels  51–150 → 8×8
    if (level <= 45) return 27; // Levels 151–400 → 9×9
    return 30; // Levels 401–1000 → 10×10
  }

  static String _difficulty(int level) {
    if (level <= 22) return 'Easy';
    if (level <= 200) return 'Medium';
    if (level <= 500) return 'Hard';
    return 'Expert';
  }

  /// Returns [themeColor, themeDark] for the given level.
  static List<Color> _themePair(int level) {
    if (level <= 3)
      return _easyPalette[0]; // Cyan  & Sky Blue  (4×4, levels 1–3)
    if (level <= 10)
      return _easyPalette[1]; // Green & Teal      (5×5, levels 4–10)
    if (level <= 22)
      return _easyPalette[2]; // Yellow & Orange   (6×6, levels 11–22)
    final pool = level <= 200
        ? _medPalette
        : level <= 500
        ? _hardPalette
        : _expertPalette;
    // Rotate through the pool so each group of levels gets a different hue
    return pool[((level - 23) ~/ 20) % pool.length];
  }

  static List<Color> _blockColors(int level, Random rng) {
    // Per-block: pick from a wider set
    return [
      const Color(0xFF4CC9F0),
      const Color(0xFF80FFDB),
      const Color(0xFFFFD166),
      const Color(0xFFFF6B9D),
      const Color(0xFFA29BFE),
      const Color(0xFFFF9F1C),
      const Color(0xFF2EC4B6),
      const Color(0xFFE71D36),
      const Color(0xFF9B5DE5),
      const Color(0xFF06D6A0),
    ];
  }

  static List<Color> _blockDark(int level) => [
    const Color(0xFF023E8A),
    const Color(0xFF0F6E47),
    const Color(0xFF8B5A00),
    const Color(0xFF8B0038),
    const Color(0xFF3D2D9E),
    const Color(0xFF8B4500),
    const Color(0xFF0A4D47),
    const Color(0xFF6B0015),
    const Color(0xFF4A1A8C),
    const Color(0xFF024034),
  ];

  // ── Core generation ──────────────────────────────────────────────────────────
  static List<ArrowBlock> _buildLevel(int level, int gridSize, Random rng) {
    // final density = 0.30 + (level - 1) * (0.50 / 999.0);
    final totalCells = gridSize * gridSize;
    // final blockCount = (totalCells * density).round().clamp(3, totalCells);
    final blockCount = totalCells;
    final colors = _blockColors(level, rng);
    final darks = _blockDark(level);

    // Try up to 15 seeds to find a deadlock-free layout
    for (int attempt = 0; attempt < 15; attempt++) {
      final seed = rng.nextInt(999999) ^ (attempt * 7919);
      final tryRng = Random(seed);

      final positions = [
        for (int r = 0; r < gridSize; r++)
          for (int c = 0; c < gridSize; c++) [r, c],
      ]..shuffle(tryRng);

      final List<ArrowBlock> blocks = [];
      for (int i = 0; i < blockCount; i++) {
        final r = positions[i][0];
        final c = positions[i][1];
        blocks.add(
          ArrowBlock(
            id: 'b$i',
            row: r,
            col: c,
            direction: _pickDirection(r, c, gridSize, level, tryRng),
            color: colors[i % colors.length],
            darkColor: darks[i % darks.length],
          ),
        );
      }

      if (_isSolvable(blocks, gridSize)) return blocks;
    }

    // Guaranteed fallback: all blocks point toward nearest edge
    final positions = [
      for (int r = 0; r < gridSize; r++)
        for (int c = 0; c < gridSize; c++) [r, c],
    ]..shuffle(rng);

    return List.generate(blockCount, (i) {
      final r = positions[i][0];
      final c = positions[i][1];
      return ArrowBlock(
        id: 'b$i',
        row: r,
        col: c,
        direction: _nearestEdge(r, c, gridSize),
        color: colors[i % colors.length],
        darkColor: darks[i % darks.length],
      );
    });
  }

  /// Direction toward the nearest grid edge — always escapable.
  static ArrowDirection _nearestEdge(int row, int col, int gs) {
    final d = [row, gs - 1 - row, col, gs - 1 - col];
    final best = d.reduce(min);
    if (d[0] == best) return ArrowDirection.up;
    if (d[2] == best) return ArrowDirection.left;
    if (d[1] == best) return ArrowDirection.down;
    return ArrowDirection.right;
  }

  /// Greedy simulation: repeatedly remove any block that can currently slide.
  /// True = all blocks can be removed → no deadlock.
  static bool _isSolvable(List<ArrowBlock> blocks, int gs) {
    final rows = List<int>.from(blocks.map((b) => b.row));
    final cols = List<int>.from(blocks.map((b) => b.col));
    final removed = List<bool>.filled(blocks.length, false);

    bool progress = true;
    while (progress) {
      progress = false;
      for (int i = 0; i < blocks.length; i++) {
        if (removed[i]) continue;
        if (_slideCheck(i, blocks, rows, cols, removed, gs)) {
          removed[i] = true;
          progress = true;
        }
      }
    }
    return removed.every((r) => r);
  }

  static bool _slideCheck(
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

  static ArrowDirection _pickDirection(
    int row,
    int col,
    int gs,
    int level,
    Random rng,
  ) {
    // Higher levels → more random (less edge-bias)
    // At level 1: 80% toward nearest edge, 20% random
    // At level 1000: 30% toward nearest edge
    final biasFactor = (0.80 - (level - 1) * 0.50 / 999.0).clamp(0.30, 0.80);

    if (rng.nextDouble() > biasFactor) {
      // Completely random
      return ArrowDirection.values[rng.nextInt(4)];
    }

    // Pick the direction toward nearest edge
    final toTop = row;
    final toBottom = gs - 1 - row;
    final toLeft = col;
    final toRight = gs - 1 - col;

    final minDist = [toTop, toBottom, toLeft, toRight].reduce(min);

    final candidates = <ArrowDirection>[];
    if (toTop == minDist) candidates.add(ArrowDirection.up);
    if (toBottom == minDist) candidates.add(ArrowDirection.down);
    if (toLeft == minDist) candidates.add(ArrowDirection.left);
    if (toRight == minDist) candidates.add(ArrowDirection.right);

    return candidates[rng.nextInt(candidates.length)];
  }
}
