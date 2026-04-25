import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

part 'support.dart';

class PermissionRequestDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const _PermissionDialogTitle(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Claude 正在请求使用以下工具',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _PermissionCard(toolName: toolName, arguments: arguments),
          const SizedBox(height: 16),
          Text(
            '是否批准此工具调用？',
            style: TextStyle(color: AppTheme.neutral600, fontSize: 14),
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
          style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      builder: (dialogContext) => PermissionRequestDialog(
        sessionId: sessionId,
        toolName: toolName,
        arguments: arguments,
        onApprove: () {
          Navigator.pop(dialogContext, true);
          onApprove?.call();
        },
        onReject: () {
          Navigator.pop(dialogContext, false);
          onReject?.call();
        },
      ),
    );
    return result ?? false;
  }
}
