part of 'user_profile_screen.dart';

Widget _buildUserProfileScaffold(_UserProfileScreenState state) {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: const Text('用户资料'),
    ),
    body: SafeArea(child: _buildUserProfileBody(state)),
  );
}

Widget _buildUserProfileBody(_UserProfileScreenState state) {
  if (state._isLoading) {
    return _UserProfileLoadingView();
  }
  if (state._errorMessage != null) {
    return _UserProfileErrorView(errorMessage: state._errorMessage);
  }
  final user = state._user;
  if (user == null) {
    return const _UserProfileErrorView(errorMessage: '无法加载用户资料');
  }
  return Column(
    children: [
      _buildUserProfileHeader(user),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildUserBasicInfoCard(user),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildUserBioCard(user),
            ],
            const SizedBox(height: 24),
            _buildUserActionCard(state, user),
          ],
        ),
      ),
    ],
  );
}

class _UserProfileLoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.brandColor),
          const SizedBox(height: 16),
          Text('加载中...', style: TextStyle(color: AppTheme.neutral600)),
        ],
      ),
    );
  }
}

class _UserProfileErrorView extends StatelessWidget {
  const _UserProfileErrorView({required this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.neutral400),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? '加载失败',
            style: const TextStyle(fontSize: 16, color: AppTheme.neutral900),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}
