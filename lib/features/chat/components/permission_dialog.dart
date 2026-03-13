import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/extensions.dart';

import '../../session/domain/reducer.dart';

/// 权限请求对话框
class PermissionRequestDialog extends ConsumerWidget {
  const PermissionRequestDialog({
    super.key,
    required this.sessionId,
    required this.toolName,
    required this.arguments,
    this.onApprove,
    this.onReject,
  });

  final String sessionId;
  final String toolName;
  final Map<String, dynamic> arguments;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('权限请求'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Claude 正在请求使用以下工具',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // 工具信息卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '工具',
                  style: TextStyle(
                    color: AppTheme.neutral600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  toolName,
                  style: TextStyle(
                    color: AppTheme.brandColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '参数',
                  style: TextStyle(
                    color: AppTheme.neutral600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildArgumentList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '是否批准此工具调用？',
            style: TextStyle(
              color: AppTheme.neutral600,
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onReject?.call();
          },
          icon: const Icon(Icons.close, color: Colors.red),
          label: const Text('拒绝'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onApprove?.call();
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('批准'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildArgumentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: arguments.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: AppTheme.neutral600,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 显示权限请求对话框
  static Future<bool> show(
    BuildContext context, {
    required String sessionId,
    required String toolName,
    required Map<String, dynamic> arguments,
    VoidCallback? onApprove,
    VoidCallback? onReject,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PermissionRequestDialog(
        sessionId: sessionId,
        toolName: toolName,
        arguments: arguments,
        onApprove: () {
          Navigator.pop(context, true);
          onApprove?.call();
        },
        onReject: () {
          Navigator.pop(context, false);
          onReject?.call();
        },
      ),
    );

    return result ?? false;
  }
}
