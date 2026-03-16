part of 'git_status_badge.dart';

class GitStatusCard extends StatelessWidget {
  const GitStatusCard({
    super.key,
    required this.repository,
    this.onCommit,
    this.onPull,
    this.onPush,
    this.onOpenSettings,
  });

  final GitRepository repository;
  final VoidCallback? onCommit;
  final VoidCallback? onPull;
  final VoidCallback? onPush;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildBranchInfo(),
            const SizedBox(height: 16),
            if (repository.hasChanges) _buildChangesSection(),
            if (!repository.hasChanges) _buildCleanState(),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }
}
