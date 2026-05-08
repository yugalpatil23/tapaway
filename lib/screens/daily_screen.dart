import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/daily_challenge.dart';
import '../models/game_state.dart';
import '../audio/audio_manager.dart';
import '../widgets/game_grid.dart';
import '../widgets/level_complete_overlay.dart';
import '../widgets/top_btn.dart';
import '../widgets/glass_chip.dart';

/// Dedicated screen for the Daily Challenge.
/// Completely separate from main game flow — no shared level/unlock state.
class DailyScreen extends StatefulWidget {
  final int slot; // 1, 2, or 3
  const DailyScreen({super.key, required this.slot});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  String? _hintedBlockId;
  bool _awardingStars = false;
  // Store reference early — context.read() in dispose() is illegal (widget deactivated)
  late GameState _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game = context.read<GameState>();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final daily = DailyChallenge();
    final level = daily.getDailyLevel(widget.slot);

    // Wire up after first frame so _game is guaranteed initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.onSound = AudioManager().play;
      _game.onLevelComplete = (_) async {
        if (_awardingStars) return;
        _awardingStars = true;
        AudioManager().haptic(HapticType.heavy);
        final earned = await daily.completeDailyLevel(widget.slot);
        if (earned > 0) _game.addBonusStars(earned);
      };
      _game.loadDailyLevel(level, slot: widget.slot);
    });
  }

  @override
  void dispose() {
    // Use stored reference — context.read() is illegal in dispose()
    _game.exitDailyMode();
    super.dispose();
  }

  void _useHint() {
    final game = _game;
    if (game.totalStars < kHintStarCost) {
      _showNotEnoughStars();
      return;
    }
    final block = game.useHint();
    if (block != null) {
      AudioManager().play('hint');
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
        final daily = DailyChallenge();
        final tc = game.currentLevel.themeColor;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(ctx, game, daily, tc),
                  _buildHintAndProgress(game, tc),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          _buildStats(game, daily, tc),
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

              if (game.isDeadlocked)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: _DeadlockBanner(
                    onRestart: () {
                      final level = DailyChallenge().getDailyLevel(widget.slot);
                      game.loadDailyLevel(level, slot: widget.slot);
                    },
                  ),
                ),

              if (game.levelComplete)
                Positioned.fill(
                  child: _DailyLevelCompleteOverlay(
                    slot: widget.slot,
                    starsEarned: daily.starsPerLevel,
                    onNext: game.levelComplete && widget.slot < 3
                        ? () => _goToNextSlot(ctx)
                        : null,
                    onHome: () => Navigator.of(ctx).pop(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _goToNextSlot(BuildContext context) {
    // Replace current daily screen with the next slot
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: _game,
          child: DailyScreen(slot: widget.slot + 1),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext ctx,
    GameState game,
    DailyChallenge daily,
    Color tc,
  ) {
    final slotNames = ['Hard', 'Harder', 'Hardest'];
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
                  Row(
                    children: [
                      const Text(
                        '⚡ DAILY ',
                        style: TextStyle(
                          color: Color(0xFFFFD60A),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      // Slot dots
                      Row(
                        children: List.generate(
                          3,
                          (i) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < widget.slot
                                  ? const Color(0xFF4CAF50)
                                  : i == widget.slot - 1
                                  ? const Color(0xFFFFD60A)
                                  : const Color(0xFF2A2A45),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    slotNames[widget.slot - 1],
                    style: TextStyle(
                      color: tc,
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
                AudioManager().haptic(HapticType.light);
                final level = DailyChallenge().getDailyLevel(widget.slot);
                game.loadDailyLevel(level, slot: widget.slot);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintAndProgress(GameState game, Color tc) {
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
                  builder: (_, box) => Row(
                    children: List.generate(
                      total,
                      (i) => Expanded(
                        child: Container(
                          height: 5,
                          margin: EdgeInsets.only(right: i < total - 1 ? 2 : 0),
                          decoration: BoxDecoration(
                            color: i < done ? tc : const Color(0xFF2A2A45),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(GameState game, DailyChallenge daily, Color tc) {
    return Row(
      children: [
        _Pill(
          label: 'MOVES',
          value: '${game.moves}',
          icon: Icons.touch_app_rounded,
          color: tc,
        ),
        const SizedBox(width: 8),
        _Pill(
          label: 'GRID',
          value: '${game.gridSize}×${game.gridSize}',
          icon: Icons.grid_4x4_rounded,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        _Pill(
          label: 'REWARD',
          value: '+${daily.starsPerLevel}★',
          icon: Icons.star_rounded,
          color: const Color(0xFFFFD60A),
        ),
      ],
    );
  }
}

// ── Daily level complete overlay (distinct from main) ──────────────────────────
class _DailyLevelCompleteOverlay extends StatefulWidget {
  final int slot;
  final int starsEarned;
  final VoidCallback? onNext;
  final VoidCallback onHome;

  const _DailyLevelCompleteOverlay({
    required this.slot,
    required this.starsEarned,
    required this.onNext,
    required this.onHome,
  });

  @override
  State<_DailyLevelCompleteOverlay> createState() =>
      _DailyLevelCompleteOverlayState();
}

class _DailyLevelCompleteOverlayState extends State<_DailyLevelCompleteOverlay>
    with TickerProviderStateMixin {
  late AnimationController _panelCtrl;
  late Animation<double> _panelScale;

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _panelScale = CurvedAnimation(parent: _panelCtrl, curve: Curves.elasticOut);
    _panelCtrl.forward();
    AudioManager().play(widget.slot == 3 ? 'milestone' : 'complete');
  }

  @override
  void dispose() {
    _panelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = widget.slot == 3;
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: ScaleTransition(
          scale: _panelScale,
          child: Container(
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
              border: Border.all(
                color: const Color(0xFFFFD60A).withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD60A).withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isLast ? '🏆' : '⚡', style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 10),
                Text(
                  isLast ? 'ALL 3 DONE!' : 'LEVEL ${widget.slot} DONE!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLast
                      ? 'Daily challenge complete! 🔥'
                      : 'Level ${widget.slot + 1} unlocked!',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),

                // Stars reward
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD60A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFD60A).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD60A),
                        size: 24,
                        shadows: [
                          Shadow(color: Color(0xFFFFD60A), blurRadius: 10),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${widget.starsEarned} stars earned',
                        style: const TextStyle(
                          color: Color(0xFFFFD60A),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => widget.onHome(),
                          );
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A45),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Home',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.onNext != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => widget.onNext!(),
                            );
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD60A), Color(0xFFFF9F1C)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFD60A,
                                  ).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Next Level',
                                  style: TextStyle(
                                    color: Color(0xFF1A1000),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF1A1000),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _ctrl.forward();
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
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
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

// ── Small stat pill ───────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Pill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF16162A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
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
