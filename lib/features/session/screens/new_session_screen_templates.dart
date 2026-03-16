part of 'new_session_screen.dart';

class SessionTemplate {
  const SessionTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
  });

  final String id;
  final String name;
  final IconData icon;
  final String description;
  final Color color;
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final SessionTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2 - 8,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected
              ? template.color.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected ? template.color : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(template.icon, color: template.color, size: 28),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? template.color : AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.neutral600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
