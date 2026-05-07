import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../audio/audio_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _arrowCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _arrowRotate;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _logoScale = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4)),
    );
    _textOpacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _arrowRotate = Tween(begin: 0.0, end: 1.0).animate(_arrowCtrl);

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _arrowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon / logo
            AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, __) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: _buildIcon(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Title
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF4CC9F0), Color(0xFFA29BFE)],
                      ).createShader(bounds),
                      child: const Text(
                        'TAP AWAY',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ARROW PUZZLE',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8B8FA8),
                        letterSpacing: 5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
            // Loading dots
            FadeTransition(opacity: _textOpacity, child: _buildLoadingDots()),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4361EE), Color(0xFF7B2FBE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4361EE).withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _arrowCtrl,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Orbiting small arrows
              for (int i = 0; i < 4; i++)
                Transform.rotate(
                  angle: _arrowRotate.value * 2 * 3.14159 + i * 3.14159 / 2,
                  child: Transform.translate(
                    offset: const Offset(0, -32),
                    child: const Text(
                      '→',
                      style: TextStyle(fontSize: 14, color: Colors.white54),
                    ),
                  ),
                ),
              // Center main arrow
              const Text(
                '→',
                style: TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _arrowCtrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (_arrowCtrl.value * 3 - i).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(
              0.3,
              1.0,
            );
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF4CC9F0).withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
