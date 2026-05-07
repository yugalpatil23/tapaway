import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../audio/audio_manager.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioManager().playBgMusic();
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
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
          // Music toggle
          _IconBtn(
            icon: AudioManager().musicEnabled
                ? Icons.music_note
                : Icons.music_off,
            onTap: () {
              setState(() => AudioManager().toggleMusic());
            },
          ),
          const SizedBox(width: 8),
          // Sound toggle
          _IconBtn(
            icon: AudioManager().soundEnabled
                ? Icons.volume_up
                : Icons.volume_off,
            onTap: () {
              setState(() => AudioManager().toggleSound());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHero(GameState game) {
    return Column(
      children: [
        // App icon
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4361EE), Color(0xFF7B2FBE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4361EE).withOpacity(0.5),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '→',
              style: TextStyle(fontSize: 42, color: Colors.white),
            ),
          ),
        ),
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
        return _LevelCell(
          level: level,
          stars: stars,
          unlocked: unlocked,
          isCurrent: isCurrent,
          onTap: unlocked ? () => _openLevel(context, level) : null,
        );
      },
    );
  }

  void _openLevel(BuildContext context, int level) {
    AudioManager().play('slide');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<GameState>()..loadLevel(level),
          child: const GameScreen(),
        ),
      ),
    );
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

class _LevelCell extends StatelessWidget {
  final int level;
  final int stars;
  final bool unlocked;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _LevelCell({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.isCurrent,
    this.onTap,
  });

  Color get _accent {
    if (level <= 50) return const Color(0xFF4CC9F0);
    if (level <= 200) return const Color(0xFF80FFDB);
    if (level <= 500) return const Color(0xFFFFD166);
    return const Color(0xFFFF6B9D);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isCurrent
              ? _accent.withOpacity(0.2)
              : unlocked
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? _accent
                : unlocked
                ? _accent.withOpacity(0.25)
                : Colors.white.withOpacity(0.05),
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock, size: 14, color: Color(0xFF4A4A6A))
            else
              Text(
                '$level',
                style: TextStyle(
                  color: unlocked ? Colors.white : const Color(0xFF4A4A6A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            if (stars > 0) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 9,
                    color: i < stars
                        ? const Color(0xFFFFD60A)
                        : const Color(0xFF3A3A5A),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
