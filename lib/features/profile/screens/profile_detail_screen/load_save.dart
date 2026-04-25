part of 'profile_detail_screen.dart';

extension _ProfileDetailScreenLoadSave on _ProfileDetailScreenState {
  Future<void> _loadProfile() async {
    _updateView(() => _isLoading = true);
    try {
      final profileState = ref.read(profileStateProvider);
      if (profileState is! ProfileLoaded) {
        _updateView(() => _isLoading = false);
        return;
      }

      final profile = profileState.profiles.firstWhereOrNull(
        (p) => p.id == widget.profileId,
      );
      if (profile == null) {
        _updateView(() => _isLoading = false);
        return;
      }

      _updateView(() {
        _profile = profile;
        _nameController.text = profile.name;
        _descriptionController.text = profile.description ?? '';
        _environmentVariables
          ..clear()
          ..addAll(
              profile.environmentVariables.map((envVar) => EnvironmentVariable(
                    name: envVar.name,
                    value: envVar.value,
                  )));
        _nameControllers
          ..clear()
          ..addAll(profile.environmentVariables
              .map((envVar) => TextEditingController(text: envVar.name)));
        _valueControllers
          ..clear()
          ..addAll(profile.environmentVariables
              .map((envVar) => TextEditingController(text: envVar.value)));
        _isLoading = false;
      });
    } catch (e) {
      _updateView(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载配置失败: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showEditDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑配置'),
        content: const Text('此功能将在后续版本中开放'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: Text('确认要删除 "${_profile!.name}" 配置吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProfile();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProfile() async {
    try {
      await ref
          .read(profileStateProvider.notifier)
          .deleteProfile(widget.profileId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('配置已删除'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
