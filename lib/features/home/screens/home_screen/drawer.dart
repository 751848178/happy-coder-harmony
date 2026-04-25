part of 'home_screen.dart';

Widget _buildHomeMachineDrawer(
  _HomeScreenState state, {
  required List<_HomeMachineFilterOption> options,
  required _HomeMachineFilterOption? selectedOption,
  required int totalSessionCount,
}) {
  return Drawer(
    width: 324,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '设备会话',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedOption == null
                      ? '当前显示全部设备的会话'
                      : '当前设备：${selectedOption.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 13, color: AppTheme.neutral600),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.neutral200),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              children: [
                _HomeMachineDrawerTile(
                  icon: Icons.apps_rounded,
                  label: '全部设备',
                  subtitle: '显示全部设备的会话',
                  count: totalSessionCount,
                  selected: selectedOption == null,
                  onTap: () {
                    Navigator.of(state.context).pop();
                    state._setSelectedMachineId(null);
                  },
                ),
                if (options.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Text(
                      '设备列表',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neutral500,
                      ),
                    ),
                  ),
                  for (final option in options)
                    _HomeMachineDrawerTile(
                      icon: option.isUnknown
                          ? Icons.device_unknown_rounded
                          : Icons.desktop_windows_outlined,
                      label: option.label,
                      subtitle: option.subtitle,
                      count: option.sessionCount,
                      selected: selectedOption?.id == option.id,
                      isOnline: option.isOnline,
                      onTap: () {
                        Navigator.of(state.context).pop();
                        state._setSelectedMachineId(option.id);
                      },
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
