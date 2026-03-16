import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'app_routes.dart';

/// 错误页面
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('页面未找到'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.neutral600),
              const SizedBox(height: 16),
              Text(
                '页面不存在',
                style: TextStyle(fontSize: 18, color: AppTheme.neutral600),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
