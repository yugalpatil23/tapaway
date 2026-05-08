import 'package:flutter/material.dart';
import '../models/arrow_block.dart';

class ArrowBlockWidget extends StatefulWidget {
  final ArrowBlock block;
  final double cellSize;
  final bool isHinted;
  final VoidCallback onTap;

  const ArrowBlockWidget({
    super.key,
    required this.block,
    required this.cellSize,
    required this.onTap,
    this.isHinted = false,
  });

  @override
  State<ArrowBlockWidget> createState() => _ArrowBlockWidgetState();
}

class _ArrowBlockWidgetState extends State<ArrowBlockWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _hintCtrl;

  // Slide: pixel offset in the arrow's direction
  late Animation<double> _slideAnim;

  // Fade: only kicks in at the very end (80–100%) so block is visible throughout
  late Animation<double> _fadeAnim;

  // Shake: left-right translation for blocked blocks
  late Animation<double> _shakeAnim;

  // Hint: subtle scale pulse
  late Animation<double> _hintPulse;

  bool _wasSliding = false;
  bool _wasShaking = false;

  @override
  void initState() {
    super.initState();

    // ── Slide: 600ms, accelerates like a real object being launched ──────────
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Travel distance in pixels: enough to fully exit the board.
    // cellSize * gridSize would be the max, but we don't know gridSize here,
    // so we use a large fixed pixel value — the ClipRRect on the board hides
    // anything that goes past the edge anyway.
    final travelPx = widget.cellSize * 12.0;

    _slideAnim = Tween<double>(begin: 0.0, end: travelPx).animate(
      CurvedAnimation(
        parent: _slideCtrl,
        // easeInQuart: starts slow (satisfying "thinking" moment), then
        // rockets off — feels like the block is being launched
        curve: Curves.easeInQuart,
      ),
    );

    // Fade: invisible until 75% of the journey, then quickly fades out.
    // This means the player sees the block travel most of the way
    // before it disappears — the removal feels physical.
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideCtrl,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Shake: 480ms left-right wobble ────────────────────────────────────────
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    // ── Hint: gentle scale pulse ───────────────────────────────────────────────
    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _hintPulse = Tween(
      begin: 0.93,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _hintCtrl, curve: Curves.easeInOut));
  }

  /// Returns the directional unit vector as an Offset
  Offset get _directionUnit {
    switch (widget.block.direction) {
      case ArrowDirection.up:
        return const Offset(0, -1);
      case ArrowDirection.down:
        return const Offset(0, 1);
      case ArrowDirection.left:
        return const Offset(-1, 0);
      case ArrowDirection.right:
        return const Offset(1, 0);
    }
  }

  @override
  void didUpdateWidget(ArrowBlockWidget old) {
    super.didUpdateWidget(old);

    if (widget.block.isSliding && !_wasSliding) {
      _wasSliding = true;
      _slideCtrl.forward();
    } else if (!widget.block.isSliding) {
      _wasSliding = false;
    }

    if (widget.block.isShaking && !_wasShaking) {
      _wasShaking = true;
      _shakeCtrl.forward(from: 0);
    } else if (!widget.block.isShaking) {
      _wasShaking = false;
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _shakeCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.block.isRemoved && !widget.block.isSliding) {
      return const SizedBox.shrink();
    }

    final cs = widget.cellSize;
    final pad = cs * 0.055;
    final unit = _directionUnit;

    return AnimatedBuilder(
      animation: Listenable.merge([_slideCtrl, _shakeCtrl, _hintCtrl]),
      builder: (_, __) {
        // Pixel translation: slide distance × direction unit
        final slide = _slideAnim.value;
        final slideOffset = Offset(
          unit.dx * slide + _shakeAnim.value,
          unit.dy * slide,
        );

        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.translate(
            offset: slideOffset,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Padding(
                padding: EdgeInsets.all(pad),
                child: _buildBlock(cs - pad * 2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlock(double size) {
    final isHinted = widget.isHinted;

    return Transform.scale(
      scale: isHinted ? _hintPulse.value : 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.block.color, widget.block.darkColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * 0.22),
          border: isHinted
              ? Border.all(color: const Color(0xFFFFD60A), width: 2.5)
              : Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: widget.block.color.withOpacity(0.30),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
            if (isHinted)
              BoxShadow(
                color: const Color(0xFFFFD60A).withOpacity(0.65),
                blurRadius: 18,
                spreadRadius: 3,
              ),
          ],
        ),
        child: Center(child: _buildArrow(size)),
      ),
    );
  }

  Widget _buildArrow(double size) {
    return Transform.rotate(
      angle: widget.block.direction.rotationAngle,
      child: CustomPaint(
        size: Size(size * 0.46, size * 0.46),
        painter: const _ArrowPainter(),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..strokeWidth = w * 0.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Stem
    canvas.drawPath(
      Path()
        ..moveTo(w / 2, h * 0.88)
        ..lineTo(w / 2, h * 0.32),
      paint,
    );

    // Arrowhead
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.15, h * 0.52)
        ..lineTo(w / 2, h * 0.08)
        ..lineTo(w * 0.85, h * 0.52),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter _) => false;
}
