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
    this.subtle = false,
    this.trailingMenu,
    this.onTap,
  });

  final String title;
  final int? count;
  final bool collapsed;
  final bool subtle;
  final Widget? trailingMenu;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = subtle ? AppTheme.neutral500 : AppTheme.neutral700;
    final countColor = subtle ? AppTheme.neutral400 : AppTheme.neutral500;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(subtle ? 8 : 10),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: subtle ? 4 : 6),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: subtle ? 12 : 13,
                    fontWeight: subtle ? FontWeight.w600 : FontWeight.w700,
                    color: titleColor,
                  ),
                  children: [
                    TextSpan(text: title),
                    if (count != null)
                      TextSpan(
                        text: ' · $count',
                        style: TextStyle(
                          fontWeight:
                              subtle ? FontWeight.w500 : FontWeight.w600,
                          color: countColor,
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
                color: subtle ? AppTheme.neutral400 : AppTheme.neutral500,
                size: subtle ? 18 : 20,
              ),
          ],
        ),
      ),
    );
  }
}
