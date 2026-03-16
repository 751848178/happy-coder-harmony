part of 'session_type_selector.dart';

class SessionTypeInfo {
  const SessionTypeInfo({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.iconPath,
    this.isDefault = false,
  });

  final SessionType type;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final String iconPath;
  final bool isDefault;
}

class BuiltInSessionTypes {
  static const all = [
    SessionTypeInfo(
      type: SessionType.code,
      label: '代码',
      description: '代码生成与编辑',
      icon: Icons.code,
      color: Color(0xFF6366F1),
      iconPath: 'code',
      isDefault: true,
    ),
    SessionTypeInfo(
      type: SessionType.chat,
      label: '聊天',
      description: '对话式交互',
      icon: Icons.chat_bubble_outline,
      color: Color(0xFF10B981),
      iconPath: 'chat',
    ),
    SessionTypeInfo(
      type: SessionType.writing,
      label: '写作',
      description: '文档与内容创作',
      icon: Icons.edit_note_outlined,
      color: Color(0xFFF59E0B),
      iconPath: 'writing',
    ),
    SessionTypeInfo(
      type: SessionType.debug,
      label: '调试',
      description: '错误排查与诊断',
      icon: Icons.bug_report_outlined,
      color: Color(0xFFEF4444),
      iconPath: 'debug',
    ),
    SessionTypeInfo(
      type: SessionType.review,
      label: '审查',
      description: '代码审查与建议',
      icon: Icons.rate_review_outlined,
      color: Color(0xFF8B5CF6),
      iconPath: 'review',
    ),
    SessionTypeInfo(
      type: SessionType.translate,
      label: '翻译',
      description: '多语言翻译',
      icon: Icons.translate,
      color: Color(0xFFEC4899),
      iconPath: 'translate',
    ),
  ];

  static SessionTypeInfo? byType(SessionType type) {
    for (final info in all) {
      if (info.type == type) return info;
    }
    return null;
  }

  static SessionType get defaultType => SessionType.code;
}
