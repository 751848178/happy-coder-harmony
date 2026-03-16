part of 'enhanced_new_session_screen.dart';

class _TemplateGrid extends StatelessWidget {
  const _TemplateGrid({
    required this.selectedTag,
    required this.onSelected,
  });

  final String selectedTag;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const templates = [
      _TemplateItem(
        id: 'general',
        name: '通用对话',
        icon: Icons.chat_bubble_outline,
        color: AppTheme.brandColor,
      ),
      _TemplateItem(
          id: 'code', name: '代码开发', icon: Icons.code, color: Colors.blue),
      _TemplateItem(
        id: 'debug',
        name: '问题调试',
        icon: Icons.bug_report_outlined,
        color: Colors.orange,
      ),
      _TemplateItem(
        id: 'review',
        name: '代码审查',
        icon: Icons.find_in_page,
        color: Colors.green,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: templates
          .map(
            (template) => _TemplateCard(
              template: template,
              isSelected: selectedTag == template.id,
              onTap: () => onSelected(template.id),
            ),
          )
          .toList(),
    );
  }
}

class _TemplateItem {
  const _TemplateItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  final _TemplateItem template;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? template.color.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? template.color : AppTheme.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(template.icon, color: template.color, size: 32),
            const SizedBox(height: 8),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? template.color : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
