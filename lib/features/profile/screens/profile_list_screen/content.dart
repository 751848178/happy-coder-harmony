part of 'profile_list_screen.dart';

Widget _buildProfileListScreen(_ProfileListScreenState state) {
  final profileState = state.ref.watch(profileStateProvider);

  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: const Text('AI 配置'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: state._showCreateProfileDialog,
          tooltip: '创建配置',
        ),
      ],
    ),
    body: _buildProfileListBody(state, profileState),
  );
}

Widget _buildProfileListBody(
  _ProfileListScreenState state,
  ProfileState profileState,
) {
  if (profileState.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  if (profileState.error != null) {
    return _buildProfileErrorView(state, profileState.error!);
  }

  final profiles = profileState.profiles;
  final activeProfileId =
      profileState is ProfileLoaded ? profileState.activeProfileId : null;
  if (profiles.isEmpty) {
    return _buildProfileEmptyView(state);
  }

  return ListView.builder(
    padding: const EdgeInsets.all(AppTheme.spacingMd),
    itemCount: profiles.length,
    itemBuilder: (context, index) {
      final profile = profiles[index];
      return _ProfileCard(
        profile: profile,
        isActive: profile.id == activeProfileId,
        onTap: () => state._showProfileOptions(profile),
      );
    },
  );
}

Widget _buildProfileEmptyView(_ProfileListScreenState state) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.psychology_outlined, size: 64, color: AppTheme.neutral400),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          '暂无配置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral900,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          '创建您的第一个 AI 配置',
          style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        ElevatedButton.icon(
          onPressed: state._showCreateProfileDialog,
          icon: const Icon(Icons.add),
          label: const Text('创建配置'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}

Widget _buildProfileErrorView(_ProfileListScreenState state, String error) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          '加载失败',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.neutral900,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            error,
            style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        ElevatedButton(
          onPressed: () =>
              state.ref.read(profileStateProvider.notifier).loadProfiles(),
          child: const Text('重试'),
        ),
      ],
    ),
  );
}
