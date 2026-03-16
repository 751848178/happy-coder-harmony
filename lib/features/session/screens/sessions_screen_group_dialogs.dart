part of 'sessions_screen.dart';

extension on _SessionsScreenState {
  Future<void> _showCreateGroupDialog({String? moveSessionId}) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _GroupNameDialog(
        title: '新建分组',
        actionLabel: '创建',
        controller: controller,
        hintText: '例如：正在处理 / 已归档 / 客户项目',
      ),
    );
    if (confirmed != true) {
      return;
    }

    final name = controller.text.trim();
    if (name.isEmpty) {
      _showGroupingSnackBar('请输入分组名称');
      return;
    }

    try {
      await _updateGroupingState(() => _groupingService.createGroup(name));
      if (moveSessionId != null) {
        final createdGroup = _groupingState.groups.lastWhere(
          (group) => group.name == name,
        );
        await _updateGroupingState(
          () => _groupingService.assignSession(
            sessionId: moveSessionId,
            groupId: createdGroup.id,
          ),
        );
      }
      _showGroupingSnackBar(
        moveSessionId == null ? '已创建分组「$name」' : '已创建分组「$name」并完成移动',
        backgroundColor: AppTheme.successColor,
      );
    } on SessionGroupNameConflictException {
      _showGroupingSnackBar(
        '分组名称已存在，请换一个名称',
        backgroundColor: AppTheme.warningColor,
      );
    }
  }

  Future<void> _showRenameGroupDialog(SessionGroup group) async {
    final controller = TextEditingController(text: group.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _GroupNameDialog(
        title: '重命名分组',
        actionLabel: '保存',
        controller: controller,
        hintText: '输入新的分组名称',
      ),
    );
    if (confirmed != true) {
      return;
    }

    final name = controller.text.trim();
    if (name.isEmpty) {
      return;
    }

    try {
      await _updateGroupingState(
        () => _groupingService.renameGroup(groupId: group.id, name: name),
      );
      _showGroupingSnackBar(
        '已重命名为「$name」',
        backgroundColor: AppTheme.successColor,
      );
    } on SessionGroupNameConflictException {
      _showGroupingSnackBar(
        '分组名称已存在，请换一个名称',
        backgroundColor: AppTheme.warningColor,
      );
    }
  }

  Future<void> _deleteGroup(SessionGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分组'),
        content: Text('删除分组「${group.name}」后，其中的会话会回到未分组。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await _updateGroupingState(() => _groupingService.deleteGroup(group.id));
    _showGroupingSnackBar(
      '已删除分组「${group.name}」',
      backgroundColor: AppTheme.successColor,
    );
  }

  void _showGroupingSnackBar(
    String message, {
    Color? backgroundColor,
  }) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}
