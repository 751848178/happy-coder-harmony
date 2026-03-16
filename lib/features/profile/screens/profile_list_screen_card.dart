part of 'profile_list_screen.dart';

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  final AIProfile profile;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      elevation: isActive ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: isActive
            ? BorderSide(color: AppTheme.brandColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(child: _buildInfo()),
              const SizedBox(width: AppTheme.spacingSm),
              Icon(Icons.chevron_right, color: AppTheme.neutral400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.brandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Icon(_providerIconForProfile(profile),
          color: AppTheme.brandColor, size: 24),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              profile.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (profile.isBuiltIn) _buildTag('内置', AppTheme.infoColor),
            if (isActive) _buildTag('当前', AppTheme.successColor),
          ],
        ),
        if (profile.description != null) ...[
          const SizedBox(height: 4),
          Text(
            profile.description!,
            style: TextStyle(fontSize: 13, color: AppTheme.neutral600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              profile.providerDisplayName ?? '未知',
              style: TextStyle(fontSize: 12, color: AppTheme.neutral500),
            ),
            if (profile.defaultPermissionMode != null)
              _buildNeutralTag(profile.defaultPermissionMode!.displayName),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildNeutralTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.neutral200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: AppTheme.neutral700),
      ),
    );
  }
}
