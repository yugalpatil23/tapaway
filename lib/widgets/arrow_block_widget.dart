import 'package:flutter/material.dart';
import '../models/arrow_block.dart';
import 'dart:math';

class ArrowBlockWidget extends StatefulWidget {
  final ArrowBlock block;
  final double cellSize;
  final bool canSlide;
  final bool isHinted;
  final VoidCallback onTap;

  const ArrowBlockWidget({
    super.key,
    required this.block,
    required this.cellSize,
    required this.canSlide,
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
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _hintAnim;
  bool _wasSliding = false;
  bool _wasShaking = false;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: _slideEnd,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn));

    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideCtrl, curve: const Interval(0.4, 1.0)),
    );

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _hintAnim = Tween(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _hintCtrl, curve: Curves.easeInOut));
  }

  Offset get _slideEnd {
    const d = 9.0;
    switch (widget.block.direction) {
      case ArrowDirection.up:
        return Offset(0, -d);
      case ArrowDirection.down:
        return Offset(0, d);
      case ArrowDirection.left:
        return Offset(-d, 0);
      case ArrowDirection.right:
        return Offset(d, 0);
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
    final pad = cs * 0.06; // gap between cells

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeAnim, _hintAnim]),
      builder: (_, child) {
        return SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Transform.translate(
              offset: Offset(_shakeAnim.value, 0),
              child: GestureDetector(
                onTap: widget.canSlide ? widget.onTap : _onBlockedTap,
                child: Padding(
                  padding: EdgeInsets.all(pad),
                  child: _buildBlock(cs - pad * 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onBlockedTap() {
    widget.onTap(); // GameState handles shake + sound
  }

  Widget _buildBlock(double size) {
    final isHinted = widget.isHinted;
    final canSlide = widget.canSlide;

    return AnimatedBuilder(
      animation: _hintAnim,
      builder: (_, __) {
        final hintScale = isHinted ? _hintAnim.value : 1.0;
        return Transform.scale(
          scale: hintScale,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  canSlide
                      ? widget.block.color
                      : widget.block.color.withOpacity(0.35),
                  canSlide
                      ? widget.block.darkColor
                      : widget.block.darkColor.withOpacity(0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size * 0.22),
              border: isHinted
                  ? Border.all(color: const Color(0xFFFFD60A), width: 2.5)
                  : canSlide
                  ? Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 1.5,
                    )
                  : Border.all(color: Colors.white.withOpacity(0.08), width: 1),
              boxShadow: canSlide
                  ? [
                      BoxShadow(
                        color: widget.block.color.withOpacity(0.55),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      if (isHinted)
                        BoxShadow(
                          color: const Color(0xFFFFD60A).withOpacity(0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                    ]
                  : [],
            ),
            child: Center(child: _buildArrow(size)),
          ),
        );
      },
    );
  }

  Widget _buildArrow(double size) {
    return Transform.rotate(
      angle: widget.block.direction.rotationAngle,
      child: CustomPaint(
        size: Size(size * 0.48, size * 0.48),
        painter: _ArrowPainter(
          color: widget.canSlide ? Colors.white : Colors.white.withOpacity(0.3),
          glowing: widget.canSlide,
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool glowing;
  const _ArrowPainter({required this.color, required this.glowing});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = w * 0.15;

    final paint = Paint()
      ..color = color
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (glowing) {
      final glow = Paint()
        ..color = color.withOpacity(0.25)
        ..strokeWidth = sw * 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      _draw(canvas, glow, w, h);
    }
    _draw(canvas, paint, w, h);
  }

  void _draw(Canvas c, Paint p, double w, double h) {
    // Stem
    final stem = Path()
      ..moveTo(w / 2, h * 0.88)
      ..lineTo(w / 2, h * 0.32);
    c.drawPath(stem, p);

    // Head
    final head = Path()
      ..moveTo(w * 0.15, h * 0.52)
      ..lineTo(w / 2, h * 0.08)
      ..lineTo(w * 0.85, h * 0.52);
    c.drawPath(head, p);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.color != color || old.glowing != glowing;
}
