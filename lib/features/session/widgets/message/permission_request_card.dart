import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/reducer.dart';

class PermissionRequestCard extends StatelessWidget {
  const PermissionRequestCard({required this.permission});
  final PermissionRequest permission;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.warningColor, size: 20),
          const SizedBox(width: AppTheme.spacingSm),
          const Text('权限请求',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: AppTheme.spacingSm),
        Text('工具: ${permission.tool}'),
        if (permission.reason != null) ...[
          const SizedBox(height: 4),
          Text(permission.reason!,
              style: TextStyle(fontSize: 13, color: AppTheme.neutral700)),
        ],
      ]),
    );
  }
}
