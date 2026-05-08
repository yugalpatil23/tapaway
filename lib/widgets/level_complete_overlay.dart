import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../audio/audio_manager.dart';
import 'dart:math';

class LevelCompleteOverlay extends StatefulWidget {
  const LevelCompleteOverlay({super.key});

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with TickerProviderStateMixin {
  late ConfettiController _confettiLeft;
  late ConfettiController _confettiRight;
  late AnimationController _panelCtrl;
  late AnimationController _starsCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _panelScale;
  late Animation<double> _panelOpacity;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _confettiLeft = ConfettiController(duration: const Duration(seconds: 4))
      ..play();
    _confettiRight = ConfettiController(duration: const Duration(seconds: 4))
      ..play();

    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _panelScale = CurvedAnimation(parent: _panelCtrl, curve: Curves.elasticOut);
    _panelOpacity = CurvedAnimation(parent: _panelCtrl, curve: Curves.easeOut);
    _pulseAnim = Tween(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _panelCtrl.forward().then((_) => _starsCtrl.forward());

    // Play sound
    final game = context.read<GameState>();
    AudioManager().play(game.isMilestone ? 'milestone' : 'complete');
  }

  @override
  void dispose() {
    _confettiLeft.dispose();
    _confettiRight.dispose();
    _panelCtrl.dispose();
    _starsCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameState>();
    final isMilestone = game.isMilestone;

    return Stack(
      children: [
        // Dim background
        GestureDetector(
          onTap: () {}, // absorb taps
          child: Container(color: Colors.black.withOpacity(0.65)),
        ),

        // Left confetti
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _confettiLeft,
            blastDirection: -pi / 4,
            emissionFrequency: 0.06,
            numberOfParticles: 18,
            maxBlastForce: 40,
            minBlastForce: 20,
            gravity: 0.3,
            colors: const [
              Color(0xFF4CC9F0),
              Color(0xFFFFD166),
              Color(0xFFFF6B9D),
              Color(0xFFA29BFE),
              Color(0xFF80FFDB),
            ],
          ),
        ),

        // Right confetti
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _confettiRight,
            blastDirection: -3 * pi / 4,
            emissionFrequency: 0.06,
            numberOfParticles: 18,
            maxBlastForce: 40,
            minBlastForce: 20,
            gravity: 0.3,
            colors: const [
              Color(0xFF4CC9F0),
              Color(0xFFFFD166),
              Color(0xFFFF6B9D),
              Color(0xFFA29BFE),
              Color(0xFF80FFDB),
            ],
          ),
        ),

        // Milestone badge (every 5 levels)
        if (isMilestone)
          Align(
            alignment: const Alignment(0, -0.75),
            child: ScaleTransition(
              scale: _panelScale,
              child: _MilestoneBadge(level: game.levelNumber),
            ),
          ),

        // Main panel
        Center(
          child: ScaleTransition(
            scale: _panelScale,
            child: FadeTransition(
              opacity: _panelOpacity,
              child: _buildPanel(context, game, isMilestone),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(BuildContext ctx, GameState game, bool isMilestone) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16162A), Color(0xFF1E1E38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: game.currentLevel.themeColor.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header emoji
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Text(
                isMilestone ? '🏆' : '🎉',
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isMilestone ? 'MILESTONE!' : 'LEVEL CLEAR!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isMilestone ? const Color(0xFFFFD60A) : Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Level ${game.levelNumber}  •  ${game.currentLevel.difficulty}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),

          // Stars row
          _buildStarsRow(game.starsEarned),
          const SizedBox(height: 8),

          // Stars earned this level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD60A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD60A).withOpacity(0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFD60A),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '+${game.starsEarned}  (Total: ${game.totalStars})',
                  style: const TextStyle(
                    color: Color(0xFFFFD60A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Moves
          Text(
            '${game.moves} moves',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 28),

          // Buttons
          Row(
            children: [
              // Restart
              _CircleBtn(
                icon: Icons.refresh_rounded,
                onTap: () => WidgetsBinding.instance.addPostFrameCallback(
                  (_) => game.restartLevel(),
                ),
                color: const Color(0xFF2A2A45),
              ),
              const SizedBox(width: 12),
              // Next level
              Expanded(
                child: GestureDetector(
                  onTap: game.levelNumber < kTotalLevels
                      ? () => WidgetsBinding.instance.addPostFrameCallback(
                          (_) => game.nextLevel(),
                        )
                      : null,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          game.currentLevel.themeColor,
                          game.currentLevel.themeDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: game.currentLevel.themeColor.withOpacity(0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'NEXT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarsRow(int count) {
    return AnimatedBuilder(
      animation: _starsCtrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i * 0.28;
            final t = ((_starsCtrl.value - delay) / (1.0 - delay)).clamp(
              0.0,
              1.0,
            );
            final filled = i < count;
            final scale = filled ? Curves.elasticOut.transform(t) : 1.0;
            return Transform.scale(
              scale: scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled
                      ? const Color(0xFFFFD60A)
                      : const Color(0xFF2A2A45),
                  size: 48,
                  shadows: filled
                      ? [const Shadow(color: Color(0xFFFFD60A), blurRadius: 12)]
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _MilestoneBadge extends StatelessWidget {
  final int level;
  const _MilestoneBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD60A), Color(0xFFFF9500)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD60A).withOpacity(0.5),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            'LEVEL $level MILESTONE! 🔥',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }
}
