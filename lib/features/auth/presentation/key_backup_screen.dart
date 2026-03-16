import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 密钥备份/恢复页面
///
/// 提供密钥备份和恢复功能
class KeyBackupScreen extends StatefulWidget {
  const KeyBackupScreen({super.key});

  @override
  State<KeyBackupScreen> createState() => _KeyBackupScreenState();
}

class _KeyBackupScreenState extends State<KeyBackupScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isBackupMode = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isBackupMode ? '备份密钥' : '恢复密钥'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            // 说明文字
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingMd),
                child: Text(
                  _isBackupMode
                      ? '创建一个密钥备份，确保即使忘记密码也能恢复。备份文件将保存加密后的密钥数据。'
                      : '使用备份 ID 和密码恢复密钥。密钥将解密并保存到本地安全存储。',
                  style: TextStyle(
                    color: AppTheme.brandColor,
                    fontSize: AppTheme.fontSizeMd,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            // 备份表单
            if (_isBackupMode) ...[
              _buildPasswordField(theme, '设置备份密码'),
              ElevatedButton.icon(
                onPressed: () {
                  final password = _passwordController.text;
                  if (password.isNotEmpty && password.length >= 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('备份功能待实现')),
                    );
                  }
                },
                icon: const Icon(Icons.backup),
                label: const Text('生成备份'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              _buildPasswordField(theme, '输入备份 ID'),
              ElevatedButton.icon(
                onPressed: () {
                  final backupId = _passwordController.text.trim();
                  if (backupId.isNotEmpty && backupId.length >= 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('恢复功能待实现')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的备份 ID')),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('恢复密钥'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingXl),
            // 最近备份记录
            _buildRecentBackupsSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(ThemeData theme, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppTheme.neutral300),
          ),
          filled: true,
          fillColor: AppTheme.neutral50,
          contentPadding: EdgeInsets.all(AppTheme.spacingMd),
        ),
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildRecentBackupsSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Text(
              '最近的备份',
              style: theme.textTheme.titleMedium,
            ),
          ),
          Container(
            height: 200,
            padding: EdgeInsets.all(AppTheme.spacingSm),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: AppTheme.neutral400,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    '暂无备份记录',
                    style: TextStyle(
                      color: AppTheme.neutral600,
                      fontSize: AppTheme.fontSizeSm,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
