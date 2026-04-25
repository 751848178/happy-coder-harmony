part of 'sessions_screen.dart';

class _SessionsGroupSection extends StatelessWidget {
  const _SessionsGroupSection({
    required this.header,
    required this.collapsed,
    required this.children,
  });

  final Widget header;
  final bool collapsed;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          if (!collapsed) ...[
            const SizedBox(height: 8),
            ...children,
          ],
        ],
      ),
    );
  }
}

class _SessionSectionHeader extends StatelessWidget {
  const _SessionSectionHeader({
    required this.title,
    required this.collapsed,
    this.count,
    this.trailingMenu,
    this.onTap,
  });

  final String title;
  final int? count;
  final bool collapsed;
  final Widget? trailingMenu;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neutral700,
                  ),
                  children: [
                    TextSpan(text: title),
                    if (count != null)
                      TextSpan(
                        text: ' · $count',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutral500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (trailingMenu != null) trailingMenu!,
            if (onTap != null)
              Icon(
                collapsed
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                color: AppTheme.neutral500,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
