part of 'encryption_screen.dart';

class _HasKeysView extends StatelessWidget {
  const _HasKeysView(this.ref);

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final repository = EncryptionRepository.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEncryptionStatusCard(),
          const SizedBox(height: 24),
          _SectionCard(
            title: '密钥信息',
            icon: Icons.vpn_key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  '公钥',
                  repository.ownPublicKey?.substring(0, 20) ?? '未设置',
                  '...',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  '服务器公钥',
                  repository.hasServerPublicKey ? '已设置' : '未设置',
                  '',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  '机器密钥',
                  repository.hasMachineKey ? '已设置' : '未设置',
                  '',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildEncryptionTestCard(),
          const SizedBox(height: 24),
          _buildDangerZone(context),
        ],
      ),
    );
  }

  Widget _buildEncryptionStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brandColor.withValues(alpha: 0.1),
            AppTheme.brandColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.brandColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '加密已启用',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '您的数据已使用端到端加密保护',
                  style: TextStyle(fontSize: 14, color: AppTheme.neutral600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncryptionTestCard() {
    return _SectionCard(
      title: '测试加密',
      icon: Icons.lock_clock,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: '输入测试文本',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.lock),
                  label: const Text('加密'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.lock_open),
                  label: const Text('解密'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.brandColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return _SectionCard(
      title: '危险操作',
      icon: Icons.warning,
      iconColor: Colors.red,
      child: Column(
        children: [
          const Text(
            '清除密钥将导致无法解密您的数据！',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showClearKeysDialog(context, ref),
              icon: const Icon(Icons.delete_forever),
              label: const Text('清除所有密钥'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showClearKeysDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('确认清除密钥'),
      content: const Text('清除所有密钥后，您将无法解密已加密的数据。此操作不可恢复！'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            ref.read(encryptionStateProvider.notifier).clearKeys();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('确认清除'),
        ),
      ],
    ),
  );
}
