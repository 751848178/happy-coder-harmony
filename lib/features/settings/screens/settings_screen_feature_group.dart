part of 'settings_screen.dart';

Widget _buildSettingsFeaturesGroup(
  _SettingsScreenState state,
) {
  return Column(
    children: [
      _SettingsGroup(
        title: '账户',
        children: [
          _SettingsItem(
            icon: Icons.person_outline,
            color: const Color(0xFF007AFF),
            title: '账户',
            subtitle: '服务器地址、退出登录与本地数据',
            onTap: () => state.context.push(AppRoutes.settingsAccount),
          ),
        ],
      ),
      _SettingsGroup(
        title: '会话',
        children: [
          _SettingsItem(
            icon: Icons.tune_rounded,
            color: const Color(0xFF16A085),
            title: '功能设置',
            subtitle: '实验功能、后台持续更新与交互偏好',
            onTap: () => state.context.push(AppRoutes.settingsFeatures),
          ),
          _SettingsItem(
            icon: Icons.auto_awesome_rounded,
            color: AppTheme.brandColor,
            title: '快捷模板',
            subtitle: '管理输入 ^ 时可快速插入的模板',
            onTap: () => state.context.push(AppRoutes.settingsInputTemplates),
          ),
        ],
      ),
    ],
  );
}
