part of 'home_screen.dart';

class _HeaderLeadingButton extends StatelessWidget {
  const _HeaderLeadingButton({
    required this.activeTab,
    required this.onTap,
  });

  final HomeTab activeTab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (activeTab == HomeTab.sessions) {
      return IconButton(
        icon: const Icon(Icons.menu_rounded),
        color: AppTheme.textPrimary,
        onPressed: onTap,
        tooltip: '选择设备',
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.neutral900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.code_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.activeTab,
    required this.onPressed,
  });

  final HomeTab activeTab;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    switch (activeTab) {
      case HomeTab.sessions:
        return IconButton(
          icon: const Icon(Icons.add_rounded),
          color: AppTheme.textPrimary,
          onPressed: onPressed,
          tooltip: '新建会话',
        );
      case HomeTab.settings:
        return const SizedBox(width: 40, height: 40);
    }
  }
}
