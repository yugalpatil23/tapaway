import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/arrow_block.dart';
import 'arrow_block_widget.dart';

class GameGrid extends StatelessWidget {
  final String? hintedBlockId;

  const GameGrid({super.key, this.hintedBlockId});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, game, __) => LayoutBuilder(
        builder: (_, constraints) {
          final side = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;
          final gs = game.gridSize;
          final cellSize = side / gs;
          const boardRadius = 18.0;

          return ClipRRect(
            borderRadius: BorderRadius.circular(boardRadius),
            child: SizedBox(
              width: side,
              height: side,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Board background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BoardPainter(
                        gridSize: gs,
                        themeColor: game.currentLevel.themeColor,
                      ),
                    ),
                  ),
                  // Blocks
                  ...game.allBlocks.map((block) {
                    if (block.isRemoved && !block.isSliding) {
                      return const SizedBox.shrink();
                    }
                    return AnimatedPositioned(
                      key: ValueKey(block.id),
                      duration: Duration.zero,
                      top: block.row * cellSize,
                      left: block.col * cellSize,
                      width: cellSize,
                      height: cellSize,
                      child: ArrowBlockWidget(
                        block: block,
                        cellSize: cellSize,
                        isHinted: block.id == hintedBlockId,
                        onTap: () => game.tapBlock(block),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final int gridSize;
  final Color themeColor;
  const _BoardPainter({required this.gridSize, required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF12121F),
    );

    // Cell backgrounds (slight alternating)
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final isAlt = (r + c) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH),
          Paint()
            ..color = isAlt ? const Color(0xFF161625) : const Color(0xFF111120),
        );
      }
    }

    // Grid lines
    final linePaint = Paint()
      ..color = themeColor.withOpacity(0.08)
      ..strokeWidth = 0.8;

    for (int i = 1; i < gridSize; i++) {
      canvas.drawLine(
        Offset(i * cellW, 0),
        Offset(i * cellW, size.height),
        linePaint,
      );
      canvas.drawLine(
        Offset(0, i * cellH),
        Offset(size.width, i * cellH),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.gridSize != gridSize || old.themeColor != themeColor;
}
