part of 'home_screen.dart';

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.activeTab,
    required this.isRefreshingStatus,
    required this.onLeadingAction,
    required this.onPrimaryAction,
    this.onStatusTap,
    this.selectedMachineLabel,
  });

  final HomeTab activeTab;
  final bool isRefreshingStatus;
  final VoidCallback onLeadingAction;
  final VoidCallback onPrimaryAction;
  final Future<void> Function()? onStatusTap;
  final String? selectedMachineLabel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _HeaderLeadingButton(
                    activeTab: activeTab,
                    onTap: onLeadingAction,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _titleForTab(activeTab),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildStatusPill(),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _HeaderActionButton(
                    activeTab: activeTab,
                    onPressed: onPrimaryAction,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    // Socket status is isolated here — only this pill rebuilds when
    // socket state changes, not the entire home screen.
    return Consumer(
      builder: (context, ref, _) {
        final socketState = ref.watch(socketStateProvider);
        final status = _buildHomeConnectionStatus(socketState);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onStatusTap == null ? null : () => onStatusTap!(),
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: status.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: status.color,
                    ),
                  ),
                  if (activeTab == HomeTab.sessions &&
                      selectedMachineLabel != null &&
                      selectedMachineLabel!.isNotEmpty)
                    ..._buildSelectedMachineLabel(),
                  if (onStatusTap != null) ...[
                    const SizedBox(width: 6),
                    isRefreshingStatus
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.7,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  status.color),
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: AppTheme.neutral500,
                          ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSelectedMachineLabel() {
    return [
      const SizedBox(width: 6),
      const Text(
        '·',
        style: TextStyle(fontSize: 12, color: AppTheme.neutral400),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          selectedMachineLabel!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.neutral600,
          ),
        ),
      ),
    ];
  }
}

String _titleForTab(HomeTab tab) {
  switch (tab) {
    case HomeTab.sessions:
      return '会话';
    case HomeTab.settings:
      return '设置';
  }
}
