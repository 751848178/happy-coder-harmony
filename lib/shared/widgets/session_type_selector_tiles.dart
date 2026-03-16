part of 'session_type_selector.dart';

class _SessionTypeListTile extends StatelessWidget {
  const _SessionTypeListTile({
    required this.info,
    required this.isSelected,
    required this.onTap,
    required this.showDescription,
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
                          color: isSelected ? info.color : AppTheme.textPrimary,
                        ),
                      ),
                      if (info.isDefault) ...[
                        const SizedBox(width: 8),
                        const _DefaultTypeBadge(),
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
            if (isSelected) Icon(Icons.check_circle, color: info.color),
          ],
        ),
      ),
    );
  }
}

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
          color:
              isSelected ? info.color.withValues(alpha: 0.1) : AppTheme.surface,
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
              : const [],
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
                  color: isSelected ? info.color : AppTheme.textPrimary,
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

class _DefaultTypeBadge extends StatelessWidget {
  const _DefaultTypeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
