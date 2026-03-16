import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

part 'avatar_styles_group_and_picker.dart';
part 'avatar_styles_presets_a.dart';
part 'avatar_styles_presets_b.dart';
part 'avatar_styles_widget.dart';

/// Avatar style type
enum AvatarStyle {
  gradient,
  pixelated,
  brutalist,
  minimalist,
  glass,
  outline,
}

/// Avatar colors
class AvatarColors {
  static const primary = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  static Color random(int seed) => primary[seed % primary.length];
}
