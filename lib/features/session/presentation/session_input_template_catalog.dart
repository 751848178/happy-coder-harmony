import 'package:flutter/material.dart';

class SessionInputTemplatePreset {
  const SessionInputTemplatePreset({
    required this.id,
    required this.label,
    required this.content,
    required this.icon,
  });

  final String id;
  final String label;
  final String content;
  final IconData icon;
}

const List<SessionInputTemplatePreset> defaultSessionInputTemplatePresets = [
  SessionInputTemplatePreset(
    id: 'explain',
    label: '解释这段代码',
    content: '请解释这段代码的功能和实现方式。',
    icon: Icons.lightbulb_outline_rounded,
  ),
  SessionInputTemplatePreset(
    id: 'comment',
    label: '添加注释',
    content: '请为这段代码添加清晰、简洁的注释。',
    icon: Icons.comment_outlined,
  ),
  SessionInputTemplatePreset(
    id: 'bug',
    label: '查找 Bug',
    content: '请帮我排查这段代码中可能存在的问题，并给出修复建议。',
    icon: Icons.bug_report_outlined,
  ),
  SessionInputTemplatePreset(
    id: 'optimize',
    label: '性能优化',
    content: '请分析这段代码的性能瓶颈，并给出可落地的优化方案。',
    icon: Icons.speed_rounded,
  ),
  SessionInputTemplatePreset(
    id: 'review',
    label: 'Code Review',
    content: '请帮我做一次代码审查，重点关注潜在 Bug、性能问题和可维护性。',
    icon: Icons.rate_review_outlined,
  ),
  SessionInputTemplatePreset(
    id: 'test',
    label: '编写测试',
    content: '请为这段代码编写测试，覆盖主要场景和边界情况。',
    icon: Icons.science_outlined,
  ),
];
