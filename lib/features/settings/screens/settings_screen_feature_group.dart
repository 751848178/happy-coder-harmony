part of 'settings_screen.dart';

Widget _buildSettingsFeaturesGroup(
  _SettingsScreenState state,
  bool experimentsEnabled,
) {
  return _SettingsGroup(
    title: '功能',
    children: [
      _SettingsItem(
        icon: Icons.person_outline,
        color: const Color(0xFF007AFF),
        title: '账户',
        subtitle: '账户信息与偏好',
        onTap: () => state.context.push(AppRoutes.settingsAccount),
      ),
      _SettingsItem(
        icon: Icons.palette_outlined,
        color: const Color(0xFF5856D6),
        title: '外观',
        subtitle: '主题与显示偏好',
        onTap: () => state.context.push(AppRoutes.settingsAppearance),
      ),
      _SettingsItem(
        icon: Icons.mic_none_outlined,
        color: const Color(0xFF34C759),
        title: '语音助手',
        subtitle: '语音相关语言与偏好',
        onTap: () => state.context.push(AppRoutes.settingsVoice),
      ),
      _SettingsItem(
        icon: Icons.science_outlined,
        color: const Color(0xFFFF9500),
        title: '功能开关',
        subtitle: '实验能力与交互选项',
        onTap: () => state.context.push(AppRoutes.settingsFeatures),
      ),
      _SettingsItem(
        icon: Icons.tune_outlined,
        color: const Color(0xFFAF52DE),
        title: 'Profiles',
        subtitle: 'AI 后端与模型配置',
        onTap: () => state.context.push(AppRoutes.settingsProfiles),
      ),
      if (experimentsEnabled)
        _SettingsItem(
          icon: Icons.analytics_outlined,
          color: const Color(0xFF007AFF),
          title: '使用统计',
          subtitle: '查看 Token 与模型使用情况',
          onTap: () => state.context.push(AppRoutes.settingsUsage),
        ),
    ],
  );
}
