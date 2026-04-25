part of 'user_card.dart';

extension _UserCardVariants on UserCard {
  Widget _buildMinimalCard() {
    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: _padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(),
            if (size != UserCardSize.small) ...[
              const SizedBox(width: 12),
              _buildName(),
            ],
          ],
        ),
      ),
    );
    if (trailing == null) return card;
    return Row(children: [Expanded(child: card), trailing!]);
  }

  Widget _buildDetailedCard() {
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: _padding,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildName(),
                  if (showBio && user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildBio(),
                  ],
                  if (user.email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildEmail(),
                  ],
                  _buildActions(),
                ],
              ),
            ),
            if (trailing != null) const SizedBox(width: 12),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
    return Card(elevation: 0, margin: EdgeInsets.zero, child: content);
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.neutral200),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surface,
                AppTheme.brandColor.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 16),
              _buildName(center: true),
              if (showBio && user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildBio(center: true),
              ],
              const SizedBox(height: 16),
              _buildEmail(center: true),
              const SizedBox(height: 20),
              _buildActions(center: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [_buildName()],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
