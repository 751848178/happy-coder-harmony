import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ChangelogEntry {
  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.summary,
    required this.changes,
  });

  final String version;
  final String date;
  final String summary;
  final List<String> changes;
}

const _entries = [
  ChangelogEntry(
    version: '1.0.0',
    date: '2026-03-07',
    summary: '补齐 Happy Coder Flutter + 鸿蒙版本的核心导航与设置能力。',
    changes: [
      '新增 `/settings/features`、`/settings/voice`、`/settings/connect/claude` 等对齐页面。',
      '新增 `/session/recent`、`/session/:id/message/:messageId`、`/machine/:id` 等原项目路由。',
      '打通增强新建会话向导与机器、路径、配置文件选择流程。',
    ],
  ),
  ChangelogEntry(
    version: '0.9.0',
    date: '2026-03-04',
    summary: '完成 Flutter + 鸿蒙混合工程基础功能迁移。',
    changes: [
      '接入会话、好友、工件、终端连接等基础页面。',
      '完善 Harmony Bridge 和基础存储、认证、Socket 通讯能力。',
    ],
  ),
];

/// 更新日志页
class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('更新日志'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              side: BorderSide(color: AppTheme.neutral200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '版本 ${entry.version}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.date,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.neutral600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    entry.summary,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.neutral700,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...entry.changes.map(
                    (change) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: AppTheme.brandColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              change,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _entries.length,
      ),
    );
  }
}
