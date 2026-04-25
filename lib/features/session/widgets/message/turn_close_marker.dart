import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/reducer.dart';

class TurnCloseMarker extends StatelessWidget {
  const TurnCloseMarker({required this.turnClose});
  final TurnClose turnClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(children: [
        Icon(turnClose.abandoned ? Icons.cancel : Icons.check_circle_outline,
            size: 16,
            color: turnClose.abandoned
                ? AppTheme.errorColor
                : AppTheme.neutral600),
        const SizedBox(width: 8),
        Text(turnClose.abandoned ? '回合已终止' : '回合已结束',
            style: TextStyle(fontSize: 12, color: AppTheme.neutral600)),
      ]),
    );
  }
}
