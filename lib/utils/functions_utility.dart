import 'package:flutter/material.dart';

Color diffColor(String d) {
  switch (d) {
    case 'Easy':
      return const Color(0xFF06D6A0);
    case 'Medium':
      return const Color(0xFFFFD166);
    case 'Hard':
      return const Color(0xFFFF6B9D);
    default:
      return const Color(0xFFFF4D6D);
  }
}
