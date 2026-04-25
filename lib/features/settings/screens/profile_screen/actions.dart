part of 'profile_screen.dart';

void _loadProfileUserData(_ProfileScreenState state) {
  final settings = state.ref.read(settingsStateProvider);
  state._usernameController.text = settings.username;
  state._emailController.text = settings.email;
}

String _resolveProfileMachineId(dynamic credentials) {
  try {
    if (credentials is Map) {
      return credentials['machineId']?.toString().substring(0, 12) ?? 'unknown';
    }
    return 'unknown';
  } catch (_) {
    return 'unknown';
  }
}

void _showProfileEditDialog(
  _ProfileScreenState state,
  BuildContext context,
) {
  final settings = state.ref.read(settingsStateProvider);
  state._usernameController.text = settings.username;
  state._emailController.text = settings.email;
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('编辑资料'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: state._usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          TextField(
            controller: state._emailController,
            decoration: const InputDecoration(
              labelText: '邮箱',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            _saveProfileChanges(state);
            Navigator.pop(dialogContext);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

void _saveProfileChanges(_ProfileScreenState state) {
  final username = state._usernameController.text.trim();
  final email = state._emailController.text.trim();
  if (username.isNotEmpty) {
    state.ref.read(settingsStateProvider.notifier).setUsername(username);
  }
  if (email.isNotEmpty) {
    state.ref.read(settingsStateProvider.notifier).setEmail(email);
  }
  if (!state.mounted) {
    return;
  }
  ScaffoldMessenger.of(state.context).showSnackBar(
    const SnackBar(
      content: Text('资料已保存'),
      backgroundColor: AppTheme.successColor,
    ),
  );
}

Future<void> _shareProfileApp(_ProfileScreenState state) async {
  try {
    await Share.share(
      '${AppConfig.appName}\n${AppConfig.appTagline}\n\nhttps://github.com/slopus/happy',
      subject: AppConfig.appName,
    );
  } catch (error) {
    if (!state.mounted) {
      return;
    }
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(
        content: Text('分享失败: $error'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}
