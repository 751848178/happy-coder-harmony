part of 'profile_screen.dart';

Widget _buildProfileScaffold(_ProfileScreenState state) {
  final authState = state.ref.watch(authStateProvider);
  final credentials = authState.credentials;
  final settings = state.ref.watch(settingsStateProvider);
  if (credentials == null) {
    return _buildProfileNotLoggedInView(state.context);
  }
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: const Text('个人资料'),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => state._showEditDialog(state.context),
        ),
      ],
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileAvatarSection(username: settings.username),
          const SizedBox(height: AppTheme.spacingLg),
          _buildProfileSectionHeader('基本信息'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              children: [
                _buildProfileInfoRow(
                  icon: Icons.person_outline,
                  label: '用户名',
                  value: settings.username,
                ),
                _buildProfileDivider(),
                _buildProfileInfoRow(
                  icon: Icons.email_outlined,
                  label: '邮箱',
                  value: settings.email,
                ),
                _buildProfileDivider(),
                _buildProfileInfoRow(
                  icon: Icons.fingerprint,
                  label: 'Machine ID',
                  value: state._getMachineId(credentials),
                ),
                _buildProfileDivider(),
                _buildProfileInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: '注册时间',
                  value: '2026年1月',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _buildProfileStatsCard(),
          const SizedBox(height: AppTheme.spacingLg),
          _buildProfileQuickActions(state.context, state._shareApp),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    ),
  );
}

Widget _buildProfileNotLoggedInView(BuildContext context) {
  return Scaffold(
    backgroundColor: AppTheme.neutral50,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: const Text('个人资料'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            '未登录',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '请先登录以访问个人资料',
            style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.auth),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('去登录'),
          ),
        ],
      ),
    ),
  );
}

Widget _buildProfileStatsCard() {
  return Column(
    children: [
      _buildProfileSectionHeader('使用统计'),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Column(
          children: [
            _buildProfileStatRow(
              icon: Icons.chat_bubble_outline,
              label: '总消息数',
              value: '0',
            ),
            _buildProfileDivider(),
            _buildProfileStatRow(
                icon: Icons.list_alt, label: '会话数', value: '0'),
            _buildProfileDivider(),
            _buildProfileStatRow(
              icon: Icons.access_time,
              label: '使用时长',
              value: '0 小时',
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildProfileQuickActions(
  BuildContext context,
  Future<void> Function() onShare,
) {
  return Column(
    children: [
      _buildProfileSectionHeader('快捷操作'),
      _buildProfileQuickAction(
        icon: Icons.settings_outlined,
        title: '账号设置',
        onTap: () => context.push(AppRoutes.settingsAccount),
      ),
      _buildProfileQuickAction(
        icon: Icons.backup_outlined,
        title: '密钥管理',
        onTap: () => context.push(AppRoutes.encryption),
      ),
      _buildProfileQuickAction(
        icon: Icons.history,
        title: '会话历史',
        onTap: () => context.push(AppRoutes.sessions),
      ),
      _buildProfileQuickAction(
        icon: Icons.share_outlined,
        title: '分享应用',
        onTap: () => onShare(),
      ),
    ],
  );
}
