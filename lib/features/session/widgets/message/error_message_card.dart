import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ErrorMessageCard extends StatelessWidget {
  const ErrorMessageCard({this.text});
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
            child: Text(
          text == null || text!.isEmpty ? '发生错误' : text!,
          style: const TextStyle(fontSize: 14, color: AppTheme.errorColor),
        )),
      ]),
    );
  }
}
