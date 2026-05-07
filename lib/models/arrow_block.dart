import 'package:flutter/material.dart';

enum ArrowDirection { up, down, left, right }

extension ArrowDirectionExt on ArrowDirection {
  Offset get delta {
    switch (this) {
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

  // Rotation in radians — arrow art points UP by default
  double get rotationAngle {
    switch (this) {
      case ArrowDirection.up:
        return 0;
      case ArrowDirection.down:
        return 3.14159265;
      case ArrowDirection.left:
        return -1.5707963;
      case ArrowDirection.right:
        return 1.5707963;
    }
  }
}

class ArrowBlock {
  final String id;
  int row;
  int col;
  final ArrowDirection direction;
  bool isSliding;
  bool isRemoved;
  bool isShaking;
  final Color color;
  final Color darkColor;

  ArrowBlock({
    required this.id,
    required this.row,
    required this.col,
    required this.direction,
    required this.color,
    required this.darkColor,
    this.isSliding = false,
    this.isRemoved = false,
    this.isShaking = false,
  });

  ArrowBlock copyWith({
    int? row,
    int? col,
    bool? isSliding,
    bool? isRemoved,
    bool? isShaking,
  }) => ArrowBlock(
    id: id,
    row: row ?? this.row,
    col: col ?? this.col,
    direction: direction,
    color: color,
    darkColor: darkColor,
    isSliding: isSliding ?? this.isSliding,
    isRemoved: isRemoved ?? this.isRemoved,
    isShaking: isShaking ?? this.isShaking,
  );
}
