import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_generator.dart';
import 'arrow_block.dart';

/// Manages the daily challenge — one special level per calendar day.
/// Completing it rewards bonus stars and keeps the streak alive.
class DailyChallenge extends ChangeNotifier {
  static final DailyChallenge _instance = DailyChallenge._();
  factory DailyChallenge() => _instance;
  DailyChallenge._();

  int _streak = 0;
  DateTime? _lastCompletedDate;
  bool _completedToday = false;
  int _bonusStarsEarned = 0;

  int get streak => _streak;
  bool get completedToday => _completedToday;
  int get bonusStarsEarned => _bonusStarsEarned;

  // Bonus stars scale with streak: day 1 = 5, day 7 = 15, day 30 = 30
  int get todayBonusStars => (_streak * 1 + 5).clamp(5, 30);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _streak = prefs.getInt('dailyStreak') ?? 0;
    final lastStr = prefs.getString('lastDailyDate');
    if (lastStr != null) {
      _lastCompletedDate = DateTime.tryParse(lastStr);
    }
    _checkStreak();
    notifyListeners();
  }

  void _checkStreak() {
    final today = _today();
    if (_lastCompletedDate == null) {
      _completedToday = false;
      return;
    }
    final last = DateTime(
      _lastCompletedDate!.year,
      _lastCompletedDate!.month,
      _lastCompletedDate!.day,
    );
    if (last == today) {
      _completedToday = true;
    } else if (last == today.subtract(const Duration(days: 1))) {
      // Completed yesterday — streak is still alive
      _completedToday = false;
    } else {
      // Missed a day — reset streak
      _streak = 0;
      _completedToday = false;
    }
  }

  GameLevel getTodayLevel() {
    // Use today's date as seed so everyone gets same puzzle
    final today = _today();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    // Daily levels are harder: grid 7×7, moderate density
    final rng = Random(seed);
    const gridSize = 7;
    const difficulty = 'Daily';
    final blocks = _buildDailyBlocks(rng, gridSize);
    return GameLevel(
      levelNumber: seed,
      gridSize: gridSize,
      blocks: blocks,
      difficulty: difficulty,
      themeColor: const Color(0xFFFFD60A),
      themeDark: const Color(0xFF8B5A00),
    );
  }

  List<ArrowBlock> _buildDailyBlocks(Random rng, int gs) {
    final positions = [
      for (int r = 0; r < gs; r++)
        for (int c = 0; c < gs; c++) [r, c],
    ]..shuffle(rng);

    const blockCount = 28; // fixed count for daily
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

    final blocks = <ArrowBlock>[];
    for (int i = 0; i < blockCount && i < positions.length; i++) {
      final r = positions[i][0];
      final c = positions[i][1];
      final toEdge = [r, gs - 1 - r, c, gs - 1 - c];
      final minD = toEdge.reduce(min);
      final dirs = <ArrowDirection>[];
      if (r == minD) dirs.add(ArrowDirection.up);
      if (gs - 1 - r == minD) dirs.add(ArrowDirection.down);
      if (c == minD) dirs.add(ArrowDirection.left);
      if (gs - 1 - c == minD) dirs.add(ArrowDirection.right);
      // 50% chance of random direction for daily challenge
      final dir = rng.nextBool() && dirs.isNotEmpty
          ? dirs[rng.nextInt(dirs.length)]
          : ArrowDirection.values[rng.nextInt(4)];
      final ci = i % colors.length;
      blocks.add(
        ArrowBlock(
          id: 'daily_$i',
          row: r,
          col: c,
          direction: dir,
          color: colors[ci],
          darkColor: darks[ci],
        ),
      );
    }
    return blocks;
  }

  Future<int> completeDaily() async {
    if (_completedToday) return 0;
    final today = _today();
    _lastCompletedDate = today;
    _completedToday = true;
    _streak++;
    _bonusStarsEarned = todayBonusStars;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyStreak', _streak);
    await prefs.setString('lastDailyDate', today.toIso8601String());
    notifyListeners();
    return _bonusStarsEarned;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
