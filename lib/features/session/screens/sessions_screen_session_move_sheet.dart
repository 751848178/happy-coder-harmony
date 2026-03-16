part of 'sessions_screen.dart';

extension on _SessionsScreenState {
  Future<void> _showMoveSessionSheet(Session session) async {
    final currentGroupId = _groupingService.groupIdForSession(
      _groupingState,
      session.id,
    );
    final currentGroupName = currentGroupId == null
        ? '未分组'
        : _groupNameForSession(session.id) ?? '未分组';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '移动到分组',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '当前所在：$currentGroupName',
                style:
                    const TextStyle(fontSize: 13, color: AppTheme.neutral600),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              FilledButton.tonalIcon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _showCreateGroupDialog(moveSessionId: session.id);
                },
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('新建分组并移动'),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _SessionGroupOptionTile(
                label: '未分组',
                subtitle: '移出当前分组',
                selected: currentGroupId == null,
                onTap: () async {
                  Navigator.pop(context);
                  await _updateGroupingState(
                    () => _groupingService.assignSession(sessionId: session.id),
                  );
                },
              ),
              for (final group in _groupingState.groups)
                _SessionGroupOptionTile(
                  label: group.name,
                  subtitle: group.id == currentGroupId ? '当前分组' : '点击移动到这里',
                  selected: currentGroupId == group.id,
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateGroupingState(
                      () => _groupingService.assignSession(
                        sessionId: session.id,
                        groupId: group.id,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
