import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Claude 连接说明页
///
/// 对齐原项目当前的受限实现，提示用户通过终端完成授权。
class ClaudeConnectScreen extends StatelessWidget {
  const ClaudeConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('连接 Claude'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                side: BorderSide(color: AppTheme.neutral200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.link, color: AppTheme.brandColor, size: 32),
                    SizedBox(height: 16),
                    Text(
                      '通过终端完成 Claude 授权',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '当前 Flutter + 鸿蒙版本与原项目保持相同限制：Claude OAuth 尚未在移动端直接打开，需在已连接的终端或桌面端执行授权命令。',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.neutral700,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 20),
                    _TerminalBlock(command: 'happy connect claude'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TerminalBlock extends StatelessWidget {
  const _TerminalBlock({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14171A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Colors.white,
          ),
          children: [
            const TextSpan(
              text: r'$ ',
              style: TextStyle(color: Color(0xFF7CFC00)),
            ),
            TextSpan(text: command),
          ],
        ),
      ),
    );
  }
}
