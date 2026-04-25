part of 'about_screen.dart';

Widget _buildAboutHero() {
  return Center(
    child: Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.brandColor,
                AppTheme.brandDark,
              ],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(Icons.code, size: 50, color: Colors.white),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        const Text(
          AppConfig.appName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.neutral900,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          AppConfig.appTagline,
          style: const TextStyle(fontSize: 14, color: AppTheme.neutral600),
        ),
        const SizedBox(height: 4),
        Text(
          AppConfig.appDescription,
          style: const TextStyle(fontSize: 13, color: AppTheme.neutral500),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: AppTheme.brandColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            AppConfig.appVersion,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.brandColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAboutSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Text(
      title,
      style: const TextStyle(
        color: AppTheme.neutral600,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );
}

Widget _buildAboutInfoItem({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Container(
    margin:
        const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 4),
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.brandColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: AppTheme.brandColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral900,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 14, color: AppTheme.neutral600),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );
}

Widget _buildAboutLinkItem({
  required IconData icon,
  required String title,
  String? subtitle,
  VoidCallback? onTap,
}) {
  return Container(
    margin:
        const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 4),
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.infoColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: AppTheme.infoColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutral900,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppTheme.neutral600),
            ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.neutral400),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );
}

Widget _buildAboutOpenSourceSection() {
  return Column(
    children: [
      _buildAboutSectionHeader('开源'),
      Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Text(
          '${AppConfig.appName} 是一个开源项目，遵循 MIT 协议开源。感谢所有贡献者的支持！',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.neutral600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        child: OutlinedButton.icon(
          onPressed: () => _openAboutLink('https://github.com/slopus/happy'),
          icon: const Icon(Icons.code),
          label: const Text('查看源代码'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.brandColor,
            side: const BorderSide(color: AppTheme.brandColor),
          ),
        ),
      ),
    ],
  );
}
