import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../audio/audio_manager.dart';
import '../utils/game_assets.dart';
import '../widgets/level_cell.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'daily_screen.dart';
import '../models/daily_challenge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioManager().playBgMusic();
      DailyChallenge().init();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return Consumer<GameState>(
      builder: (ctx, game, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          body: Stack(
            children: [
              _buildBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(game),
                    const SizedBox(height: 8),
                    _buildHero(game),
                    const SizedBox(height: 20),
                    _buildDailyBanner(),
                    const SizedBox(height: 12),
                    _buildSectionTitle('SELECT LEVEL'),
                    const SizedBox(height: 10),
                    Expanded(child: _buildLevelGrid(context, game)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(child: CustomPaint(painter: _BgPainter()));
  }

  Widget _buildTopBar(GameState game) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Stars total
          _GlassChip(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFFFD60A),
            label: '${game.totalStars}',
          ),
          const Spacer(),
          // Settings button
          _IconBtn(
            icon: Icons.settings_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(GameState game) {
    return Column(
      children: [
        // App icon
        SvgPicture.asset(GameAssets.gameLogoSvg, height: 70),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFF4CC9F0), Color(0xFFA29BFE)],
          ).createShader(b),
          child: const Text(
            'TAP AWAY',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 7,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'ARROW PUZZLE',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        // Big play button
        GestureDetector(
          onTap: () => _openLevel(context, game.highestUnlocked),
          child: Container(
            width: 180,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4361EE), Color(0xFF7B2FBE)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4361EE).withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 6),
                Text(
                  'PLAY  LV ${game.highestUnlocked}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyBanner() {
    return ListenableBuilder(
      listenable: DailyChallenge(),
      builder: (_, __) {
        final daily = DailyChallenge();
        final completed = daily.levelsCompletedToday;
        final allDone = daily.allCompletedToday;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: allDone
                  ? [const Color(0xFF1E2A1E), const Color(0xFF162016)]
                  : [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: allDone
                  ? const Color(0xFF4CAF50).withOpacity(0.4)
                  : const Color(0xFFFFD60A).withOpacity(0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Text(
                    allDone ? '✅' : '⚡',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              allDone ? 'DAILY COMPLETE' : 'DAILY CHALLENGE',
                              style: TextStyle(
                                color: allDone
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFFD60A),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (daily.streak > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF6B35,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF6B35,
                                    ).withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  '🔥 ${daily.streak}d',
                                  style: const TextStyle(
                                    color: Color(0xFFFF6B35),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          allDone
                              ? 'Come back tomorrow!'
                              : '+${daily.starsPerLevel}★ per level · ${3 - completed} remaining',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 3 level slots
              Row(
                children: List.generate(3, (i) {
                  final slot = i + 1;
                  final done = i < completed;
                  final isNext = i == completed && !allDone;
                  final locked = i > completed;
                  return Expanded(
                    child: GestureDetector(
                      onTap: (done || locked)
                          ? null
                          : () => _openDailySlot(context, slot),
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: done
                              ? const Color(0xFF4CAF50).withOpacity(0.15)
                              : isNext
                              ? const Color(0xFFFFD60A).withOpacity(0.12)
                              : const Color(0xFF1E1E30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: done
                                ? const Color(0xFF4CAF50).withOpacity(0.5)
                                : isNext
                                ? const Color(0xFFFFD60A).withOpacity(0.5)
                                : Colors.white.withOpacity(0.06),
                            width: isNext ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              done
                                  ? '✅'
                                  : isNext
                                  ? '▶'
                                  : '🔒',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ['LVL 1', 'LVL 2', 'LVL 3'][i],
                              style: TextStyle(
                                color: done
                                    ? const Color(0xFF4CAF50)
                                    : isNext
                                    ? const Color(0xFFFFD60A)
                                    : const Color(0xFF4A4A6A),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            t,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: const Color(0xFF1E1E30))),
        ],
      ),
    );
  }

  Widget _buildLevelGrid(BuildContext context, GameState game) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // addRepaintBoundaries: false avoids per-cell layer creation for
      // simple cells — reduces compositor overhead significantly
      addRepaintBoundaries: false,
      // cacheExtent: pre-render cells 600px above/below the viewport
      // so scrolling never hits a blank frame
      cacheExtent: 600,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: 1000,
      itemBuilder: (_, i) {
        final level = i + 1;
        final stars = game.levelStars[level] ?? 0;
        final unlocked = level <= game.highestUnlocked;
        final isCurrent = level == game.highestUnlocked;
        return LevelCell(
          // Key by level number so Flutter reuses cells correctly
          key: ValueKey(level),
          level: level,
          stars: stars,
          unlocked: unlocked,
          isCurrent: isCurrent,
          onTap: unlocked ? () => _openLevel(context, level) : null,
        );
      },
    );
  }

  void _openDailySlot(BuildContext context, int slot) {
    AudioManager().play('slide');
    final game = context.read<GameState>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: game,
          child: DailyScreen(slot: slot),
        ),
      ),
    );
  }

  void _openLevel(BuildContext context, int level) {
    AudioManager().play('slide');
    final game = context.read<GameState>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: game,
          child: const GameScreen(),
        ),
      ),
      // Load the level AFTER the new route is fully mounted — never during build
    ).then((_) => null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      game.loadLevel(level);
    });
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Subtle dot grid
    final p = Paint()..color = const Color(0xFF1A1A2E);
    for (double x = 0; x < size.width; x += 28) {
      for (double y = 0; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1.5, p);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}
