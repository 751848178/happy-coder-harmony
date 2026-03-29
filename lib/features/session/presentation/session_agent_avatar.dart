import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/session_list_preview.dart';
import '../domain/session_models.dart';

class SessionAgentAvatar extends StatelessWidget {
  const SessionAgentAvatar({
    super.key,
    required this.session,
    required this.isActive,
    required this.isThinking,
    this.size = 40,
  });

  final Session session;
  final bool isActive;
  final bool isThinking;
  final double size;

  @override
  Widget build(BuildContext context) {
    final spec = sessionAgentVisualSpec(session);
    final radius = BorderRadius.circular(size * 0.28);
    final iconSize = size * spec.iconScale;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: radius,
        border: Border.all(
          color: spec.color.withValues(alpha: isThinking ? 0.30 : 0.16),
        ),
        boxShadow: isThinking ? AppTheme.shadowMd : AppTheme.shadowSm,
      ),
      child: Padding(
        padding: EdgeInsets.all(size * spec.paddingScale),
        child: Image.asset(
          spec.assetPath,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          color: spec.tintColor,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class SessionAgentVisualSpec {
  const SessionAgentVisualSpec({
    required this.assetPath,
    required this.color,
    required this.label,
    required this.iconScale,
    required this.paddingScale,
    this.tintColor,
  });

  final String assetPath;
  final Color color;
  final String label;
  final double iconScale;
  final double paddingScale;
  final Color? tintColor;
}

SessionAgentVisualSpec sessionAgentVisualSpec(Session session) {
  switch (resolveSessionListAgent(session)) {
    case 'codex':
      return const SessionAgentVisualSpec(
        assetPath: 'assets/images/icon-gpt.png',
        color: Color(0xFF10A37F),
        label: 'Codex',
        iconScale: 0.52,
        paddingScale: 0.24,
        tintColor: AppTheme.neutral900,
      );
    case 'gemini':
      return const SessionAgentVisualSpec(
        assetPath: 'assets/images/icon-gemini.png',
        color: Color(0xFF6366F1),
        label: 'Gemini',
        iconScale: 0.60,
        paddingScale: 0.18,
      );
    case 'claude':
    default:
      return const SessionAgentVisualSpec(
        assetPath: 'assets/images/icon-claude.png',
        color: Color(0xFFD97757),
        label: 'Claude Code',
        iconScale: 0.58,
        paddingScale: 0.20,
      );
  }
}
