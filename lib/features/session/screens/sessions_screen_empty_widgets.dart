part of 'sessions_screen.dart';

class _SessionsEmptyState extends StatelessWidget {
  const _SessionsEmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.emphasizeTitle = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool emphasizeTitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.neutral400),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            title,
            style: TextStyle(
              fontSize: emphasizeTitle ? 18 : 16,
              fontWeight: emphasizeTitle ? FontWeight.w600 : FontWeight.w500,
              color: emphasizeTitle ? AppTheme.neutral900 : AppTheme.neutral700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyGroupCard extends StatelessWidget {
  const _EmptyGroupCard({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.neutral600,
          height: 1.5,
        ),
      ),
    );
  }
}

class _GroupNameDialog extends StatelessWidget {
  const _GroupNameDialog({
    required this.title,
    required this.actionLabel,
    required this.controller,
    required this.hintText,
  });

  final String title;
  final String actionLabel;
  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
