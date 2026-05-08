import 'package:flutter/material.dart';

import 'star_painter.dart';

class LevelCell extends StatelessWidget {
  final int level;
  final int stars;
  final bool unlocked;
  final bool isCurrent;
  final VoidCallback? onTap;

  const LevelCell({
    super.key,
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.isCurrent,
    this.onTap,
  });

  // Pre-computed accent colours — no branching in build()
  static const _accents = [
    Color(0xFF4CC9F0), // Easy   lv 1–50
    Color(0xFF80FFDB), // Medium lv 51–200
    Color(0xFFFFD166), // Hard   lv 201–500
    Color(0xFFFF6B9D), // Expert lv 501–1000
  ];

  Color get _accent {
    if (level <= 50) return _accents[0];
    if (level <= 200) return _accents[1];
    if (level <= 500) return _accents[2];
    return _accents[3];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    // Pre-resolve all colours once — avoids repeated withOpacity() in build
    final bgColor = isCurrent
        ? Color.fromRGBO(accent.red, accent.green, accent.blue, 0.20)
        : unlocked
        ? const Color(0x0FFFFFFF)
        : const Color(0x05FFFFFF);
    final borderColor = isCurrent
        ? accent
        : unlocked
        ? Color.fromRGBO(accent.red, accent.green, accent.blue, 0.25)
        : const Color(0x0DFFFFFF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock, size: 14, color: Color(0xFF4A4A6A))
            else
              Text(
                '$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            if (stars > 0) ...[
              const SizedBox(height: 3),
              // Fixed-width Row avoids layout recalculation — 3 icons always same size
              SizedBox(
                width: 33,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StarDot(filled: stars >= 1),
                    _StarDot(filled: stars >= 2),
                    _StarDot(filled: stars >= 3),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// _StarDot: raw CustomPaint — no widget subtree, no package, raster-cached.
// Lightest possible approach: single canvas drawPath call.
class _StarDot extends StatelessWidget {
  final bool filled;
  const _StarDot({required this.filled});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(9, 9),
      painter: StarPainter(filled: filled),
    );
  }
}
