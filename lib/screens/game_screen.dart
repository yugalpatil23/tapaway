import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../audio/audio_manager.dart';
import '../utils/functions_utility.dart';
import '../widgets/game_grid.dart';
import '../widgets/glass_chip.dart';
import '../widgets/level_complete_overlay.dart';
import '../widgets/state_pill.dart';
import '../widgets/top_btn.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // FIX #5 & #17: Removed 'late AnimationController _hintGlowCtrl' —
  // it was declared but never initialised → LateInitializationError on dispose
  String? _hintedBlockId;

  @override
  void initState() {
    super.initState();
    final game = context.read<GameState>();
    // Wire sound callbacks into GameState
    game.onSound = AudioManager().play;
    // FIX #7: Haptics now go through AudioManager so hapticsEnabled is respected
    game.onLevelComplete = (_) => AudioManager().haptic(HapticType.heavy);
  }

  // dispose() no longer needs to clean up _hintGlowCtrl (it's gone)

  void _useHint() {
    final game = context.read<GameState>();
    if (game.totalStars < kHintStarCost) {
      _showNotEnoughStars();
      return;
    }
    final block = game.useHint();
    if (block != null) {
      AudioManager().play('hint');
      // FIX #7: haptic respects user pref
      AudioManager().haptic(HapticType.medium);
      setState(() => _hintedBlockId = block.id);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _hintedBlockId = null);
      });
    }
  }

  void _showNotEnoughStars() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E38),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        content: const Row(
          children: [
            Icon(Icons.star_rounded, color: Color(0xFFFFD60A), size: 20),
            SizedBox(width: 10),
            Text(
              'Need 3 ★ for a hint!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (ctx, game, _) {
        final tc = game.currentLevel.themeColor;
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(ctx, game, tc),
                  _buildHintAndProgress(ctx, game, tc),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          _buildMidStats(game, tc),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: GameGrid(hintedBlockId: _hintedBlockId),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (game.levelComplete)
                const Positioned.fill(child: LevelCompleteOverlay()),

              // Deadlock banner — shown when no block can move
              if (game.isDeadlocked)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: _DeadlockBanner(onRestart: game.restartLevel),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext ctx, GameState game, Color tc) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            TopBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LEVEL ${game.levelNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    game.currentLevel.difficulty,
                    style: TextStyle(
                      color: diffColor(game.currentLevel.difficulty),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            GlassChip(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFFFD60A),
              label: '${game.totalStars}',
            ),
            const SizedBox(width: 8),
            TopBtn(
              icon: Icons.refresh_rounded,
              onTap: () {
                // FIX #7: haptic through AudioManager
                AudioManager().haptic(HapticType.light);
                game.restartLevel();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMidStats(GameState game, Color tc) {
    return Row(
      children: [
        StatePill(
          label: 'MOVES',
          value: '${game.moves}',
          icon: Icons.touch_app_rounded,
          color: tc,
        ),
        const SizedBox(width: 8),
        StatePill(
          label: 'GRID',
          value: '${game.gridSize}×${game.gridSize}',
          icon: Icons.grid_4x4_rounded,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        StatePill(
          label: 'LEFT',
          value: '${game.blocks.length}',
          icon: Icons.grid_view_rounded,
          color: const Color(0xFFA29BFE),
        ),
      ],
    );
  }

  Widget _buildHintAndProgress(BuildContext ctx, GameState game, Color tc) {
    final total = game.currentLevel.blocks.length;
    final done = total - game.blocks.length;
    final canHint = game.totalStars >= kHintStarCost;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _useHint,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: canHint
                      ? const Color(0xFFFFD60A).withOpacity(0.5)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: canHint
                        ? const Color(0xFFFFD60A)
                        : const Color(0xFF4A4A6A),
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'HINT  -$kHintStarCost★',
                    style: TextStyle(
                      color: canHint
                          ? const Color(0xFFFFD60A)
                          : const Color(0xFF4A4A6A),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$done / $total',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${total == 0 ? 0 : (done / total * 100).round()}%',
                      style: TextStyle(
                        color: tc,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LayoutBuilder(
                  builder: (_, box) {
                    // Fix overflow: use Expanded cells inside a Row so total
                    // always equals exactly box.maxWidth — no clamp mismatch
                    return Row(
                      children: List.generate(
                        total,
                        (i) => Expanded(
                          child: Container(
                            height: 5,
                            margin: EdgeInsets.only(
                              right: i < total - 1 ? 2 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: i < done ? tc : const Color(0xFF2A2A45),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Deadlock banner ───────────────────────────────────────────────────────────
class _DeadlockBanner extends StatefulWidget {
  final VoidCallback onRestart;
  const _DeadlockBanner({required this.onRestart});

  @override
  State<_DeadlockBanner> createState() => _DeadlockBannerState();
}

class _DeadlockBannerState extends State<_DeadlockBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    // Also play a blocked sound to alert player
    AudioManager().play('blocked');
    AudioManager().haptic(HapticType.medium);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slide),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E38),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF4D6D).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D6D).withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No moves left!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'All remaining arrows are blocked.',
                    style: TextStyle(color: Color(0xFF8B8FA8), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onRestart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4D6D), Color(0xFFFF6B35)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Restart',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
