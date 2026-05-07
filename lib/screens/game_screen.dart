import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/arrow_block.dart';
import '../audio/audio_manager.dart';
import '../widgets/game_grid.dart';
import '../widgets/level_complete_overlay.dart';

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
                  _buildProgressBar(game, tc),
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
                          const SizedBox(height: 12),
                          _buildBottomBar(ctx, game, tc),
                          const SizedBox(height: 8),
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
            _TopBtn(
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
                      color: _diffColor(game.currentLevel.difficulty),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            // Stars
            _GlassChip(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFFFD60A),
              label: '${game.totalStars}',
            ),
            const SizedBox(width: 8),
            // Restart
            _TopBtn(
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

  Widget _buildProgressBar(GameState game, Color tc) {
    final total = game.currentLevel.blocks.length;
    final remaining = game.blocks.length;
    final done = total - remaining;
    final progress = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done / $total cleared',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: tc,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 300),
              widthFactor: 1,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: const Color(0xFF1E1E30),
                valueColor: AlwaysStoppedAnimation(tc),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMidStats(GameState game, Color tc) {
    final canMove = game.blocks.where((b) => game.canSlide(b)).length;
    return Row(
      children: [
        _StatPill(
          label: 'MOVES',
          value: '${game.moves}',
          icon: Icons.touch_app_rounded,
          color: tc,
        ),
        const SizedBox(width: 8),
        _StatPill(
          label: 'GRID',
          value: '${game.gridSize}×${game.gridSize}',
          icon: Icons.grid_4x4_rounded,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: canMove > 0
                  ? const Color(0xFF0A2A15)
                  : const Color(0xFF2A1010),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: canMove > 0
                    ? const Color(0xFF06D6A0).withOpacity(0.4)
                    : const Color(0xFFFF4D6D).withOpacity(0.4),
              ),
            ),
            child: Text(
              canMove > 0 ? '$canMove movable' : 'Stuck? Use hint!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: canMove > 0
                    ? const Color(0xFF06D6A0)
                    : const Color(0xFFFF4D6D),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext ctx, GameState game, Color tc) {
    return Row(
      children: [
        // Hint button
        GestureDetector(
          onTap: _useHint,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(
                  0xFFFFD60A,
                ).withOpacity(game.totalStars >= kHintStarCost ? 0.5 : 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: game.totalStars >= kHintStarCost
                      ? const Color(0xFFFFD60A)
                      : const Color(0xFF4A4A6A),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HINT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '-$kHintStarCost ★',
                      style: TextStyle(
                        color: game.totalStars >= kHintStarCost
                            ? const Color(0xFFFFD60A)
                            : const Color(0xFF4A4A6A),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Remaining blocks visual strip
        Expanded(child: _buildRemainingStrip(game, tc)),
      ],
    );
  }

  Widget _buildRemainingStrip(GameState game, Color tc) {
    final total = game.currentLevel.blocks.length;
    final remaining = game.blocks.length;
    final done = total - remaining;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Cleared $done of $total',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (_, box) {
              final w = box.maxWidth;
              final cellW = (w - (total - 1) * 2) / total;
              return Row(
                children: List.generate(total, (i) {
                  final cleared = i < done;
                  return Container(
                    width: cellW.clamp(3.0, 12.0),
                    height: 6,
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
    );
  }

  Color _diffColor(String d) {
    switch (d) {
      case 'Easy':
        return const Color(0xFF06D6A0);
      case 'Medium':
        return const Color(0xFFFFD166);
      case 'Hard':
        return const Color(0xFFFF6B9D);
      default:
        return const Color(0xFFFF4D6D);
    }
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _GlassChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4A4A6A),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
