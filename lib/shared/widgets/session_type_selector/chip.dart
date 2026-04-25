part of 'session_type_selector.dart';

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
    return InkWell(
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
            Icon(info!.icon, size: 16, color: info!.color),
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
                onTap: onDelete,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
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
  }
}

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
    return DropdownButtonFormField<SessionType>(
      initialValue: selectedType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        if (type != null) onTypeChanged(type);
      },
    );
  }
}

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
      return Icon(info!.icon, size: size, color: info!.color);
    }
    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        color: info!.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(info!.icon, size: size, color: info!.color),
    );
  }
}
