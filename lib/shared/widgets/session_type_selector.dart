import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Session type
enum SessionType {
  code,
  chat,
  writing,
  debug,
  review,
  translate,
}

/// Session type configuration
class SessionTypeInfo {
  final SessionType type;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final String iconPath;
  final bool isDefault;

  const SessionTypeInfo({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.iconPath,
    this.isDefault = false,
  });
}

/// Built-in session types
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

/// Session Type Selector Widget
///
/// Allows users to select a session type
class SessionTypeSelector extends StatelessWidget {
  const SessionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.grid = false,
    this.compact = false,
    this.showDescription = true,
  });

  final SessionType selectedType;
  final ValueChanged<SessionType> onTypeChanged;
  final bool grid;
  final bool compact;
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    if (grid) {
      return _buildGridSelector();
    } else if (compact) {
      return _buildCompactSelector();
    }
    return _buildListSelector();
  }

  Widget _buildListSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: BuiltInSessionTypes.all.map((info) {
        final isSelected = info.type == selectedType;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SessionTypeListTile(
            info: info,
            isSelected: isSelected,
            onTap: () => onTypeChanged(info.type),
            showDescription: showDescription,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompactSelector() {
    return SegmentedButton<SessionType>(
      segments: BuiltInSessionTypes.all.map((info) {
        return ButtonSegment(
          value: info.type,
          label: Text(info.label),
          icon: Icon(info.icon, size: 18),
        );
      }).toList(),
      selected: {selectedType},
      onSelectionChanged: (Set<SessionType> newSelection) {
        onTypeChanged(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color?>(AppTheme.neutral100),
        foregroundColor: WidgetStateProperty.all<Color?>(AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildGridSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: BuiltInSessionTypes.all.length,
      itemBuilder: (context, index) {
        final info = BuiltInSessionTypes.all[index];
        final isSelected = info.type == selectedType;
        return _SessionTypeGridCard(
          info: info,
          isSelected: isSelected,
          onTap: () => onTypeChanged(info.type),
        );
      },
    );
  }
}

/// Session type list tile
class _SessionTypeListTile extends StatelessWidget {
  const _SessionTypeListTile({
    required this.info,
    required this.isSelected,
    required this.onTap,
    this.showDescription = true,
  });

  final SessionTypeInfo info;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? info.color.withValues(alpha: 0.15)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? info.color : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: isSelected ? 1.0 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                info.icon,
                color: isSelected ? Colors.white : info.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        info.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? info.color
                              : AppTheme.textPrimary,
                        ),
                      ),
                      if (info.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.brandColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '默认',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (showDescription) ...[
                    const SizedBox(height: 2),
                    Text(
                      info.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? info.color.withValues(alpha: 0.8)
                            : AppTheme.neutral600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: info.color,
              ),
          ],
        ),
      ),
    );
  }
}

/// Session type grid card
class _SessionTypeGridCard extends StatelessWidget {
  const _SessionTypeGridCard({
    required this.info,
    required this.isSelected,
    required this.onTap,
  });

  final SessionTypeInfo info;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? info.color.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? info.color : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: info.color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? info.color
                      : info.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  info.icon,
                  color: isSelected ? Colors.white : info.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                info.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? info.color
                      : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                info.description,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? info.color.withValues(alpha: 0.7)
                      : AppTheme.neutral500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Session type chip
class SessionTypeChip extends StatelessWidget {
  const SessionTypeChip({
    super.key,
    required this.type,
    this.onTap,
    this.showLabel = true,
    this.deletable = false,
    this.onDelete,
  });

  final SessionType type;
  final VoidCallback? onTap;
  final bool showLabel;
  final bool deletable;
  final VoidCallback? onDelete;

  SessionTypeInfo? get info => BuiltInSessionTypes.byType(type);

  @override
  Widget build(BuildContext context) {
    if (info == null) return const SizedBox.shrink();

    final chip = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: info!.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: info!.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              info!.icon,
              size: 16,
              color: info!.color,
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                info!.label,
                style: TextStyle(
                  fontSize: 13,
                  color: info!.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (deletable && onDelete != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  onDelete?.call();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: info!.color.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!deletable) return chip;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip,
      ],
    );
  }
}

/// Session type quick picker
class SessionTypeQuickPicker extends StatelessWidget {
  const SessionTypeQuickPicker({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.label = '会话类型',
  });

  final SessionType selectedType;
  final ValueChanged<SessionType> onTypeChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final info = BuiltInSessionTypes.byType(selectedType);

    return DropdownButtonFormField<SessionType>(
      value: selectedType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: BuiltInSessionTypes.all.map((info) {
        return DropdownMenuItem<SessionType>(
          value: info.type,
          child: Row(
            children: [
              Icon(info.icon, color: info.color, size: 18),
              const SizedBox(width: 12),
              Text(info.label),
            ],
          ),
        );
      }).toList(),
      onChanged: (type) {
        if (type != null) {
          onTypeChanged(type);
        }
      },
    );
  }
}

/// Session type icon widget
class SessionTypeIcon extends StatelessWidget {
  const SessionTypeIcon({
    super.key,
    required this.type,
    this.size = 24,
    this.showBackground = true,
  });

  final SessionType type;
  final double size;
  final bool showBackground;

  SessionTypeInfo? get info => BuiltInSessionTypes.byType(type);

  @override
  Widget build(BuildContext context) {
    if (info == null) return const SizedBox.shrink();

    if (!showBackground) {
      return Icon(
        info!.icon,
        size: size,
        color: info!.color,
      );
    }

    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        color: info!.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        info!.icon,
        size: size,
        color: info!.color,
      ),
    );
  }
}
