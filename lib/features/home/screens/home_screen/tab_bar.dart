part of 'home_screen.dart';

class _HomeTabBar extends StatelessWidget {
  const _HomeTabBar({
    required this.activeTab,
    required this.onTabSelected,
  });

  final HomeTab activeTab;
  final ValueChanged<HomeTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.neutral200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TabBarItem(
                  label: '会话',
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  selected: activeTab == HomeTab.sessions,
                  onTap: () => onTabSelected(HomeTab.sessions),
                ),
              ),
              Expanded(
                child: _TabBarItem(
                  label: '设置',
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  selected: activeTab == HomeTab.settings,
                  onTap: () => onTabSelected(HomeTab.settings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarItem extends StatelessWidget {
  const _TabBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.textPrimary : AppTheme.neutral500;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child:
                    Icon(selected ? activeIcon : icon, size: 24, color: color),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
