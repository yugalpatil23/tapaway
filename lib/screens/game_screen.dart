import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/arrow_block.dart';
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

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  String? _hintedBlockId;
  late AnimationController _hintGlowCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _hintGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    final game = context.read<GameState>();
    game.onSound = (name) => AudioManager().play(name);
    game.onLevelComplete = (_) {
      HapticFeedback.heavyImpact();
    };
  }

  @override
  void dispose() {
    _hintGlowCtrl.dispose();
    super.dispose();
  }

  void _useHint() {
    final game = context.read<GameState>();
    if (game.totalStars < kHintStarCost) {
      _showNotEnoughStars();
      return;
    }
    final block = game.useHint();
    if (block != null) {
      AudioManager().play('hint');
      HapticFeedback.mediumImpact();
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
              // Content
              Column(
                children: [
                  _buildTopBar(ctx, game, tc),
                  // Hint + progress strip just below top bar
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
                          // Grid — takes all remaining space
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: GameGrid(hintedBlockId: _hintedBlockId),
                              ),
                            ),
                          ),
                          // Bottom is clean — no widgets here
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Level complete
              if (game.levelComplete)
                const Positioned.fill(child: LevelCompleteOverlay()),
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
            // Back
            TopBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(width: 10),
            // Level + difficulty
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
            // Stars
            GlassChip(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFFFD60A),
              label: '${game.totalStars}',
            ),
            const SizedBox(width: 8),
            // Restart
            TopBtn(
              icon: Icons.refresh_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
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

  // Removed — merged into _buildHintAndProgress above the grid

  /// Combined hint button + progress strip — sits between top bar and grid
  Widget _buildHintAndProgress(BuildContext ctx, GameState game, Color tc) {
    final total = game.currentLevel.blocks.length;
    final remaining = game.blocks.length;
    final done = total - remaining;
    final canHint = game.totalStars >= kHintStarCost;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          // ── Hint button ──────────────────────────────────────────────────
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
          // ── Progress strip ───────────────────────────────────────────────
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
                    final w = box.maxWidth;
                    final cellW = (w - (total - 1) * 2) / total;
                    return Row(
                      children: List.generate(total, (i) {
                        final cleared = i < done;
                        return Container(
                          width: cellW.clamp(2.0, 14.0),
                          height: 5,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: cleared ? tc : const Color(0xFF2A2A45),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
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
