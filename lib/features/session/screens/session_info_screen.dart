import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/session_stats.dart';

part 'session_info_screen_actions.dart';
part 'session_info_screen_body.dart';
part 'session_info_screen_helpers.dart';
part 'session_info_screen_primary_sections.dart';
part 'session_info_screen_secondary_sections.dart';
part 'session_info_screen_widgets.dart';

/// 会话详情信息屏幕
///
/// 显示会话的详细信息，包括基本信息、状态、元数据等
class SessionInfoScreen extends ConsumerStatefulWidget {
  const SessionInfoScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<SessionInfoScreen> createState() => _SessionInfoScreenState();
}

class _SessionInfoScreenState extends ConsumerState<SessionInfoScreen> {
  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionStateProvider);
    final sessionNotifier = ref.read(sessionStateProvider.notifier);
    final session = sessionNotifier.getSession(widget.sessionId);
    final stats = session == null
        ? null
        : SessionStatsCalculator.fromSession(
            session: session,
            messages:
                sessionNotifier.getSessionMessages(widget.sessionId)?.messages,
          );

    if (session == null || stats == null) {
      return _buildLoadingView();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _navigateBack();
      },
      child: Scaffold(
        backgroundColor: AppTheme.neutral50,
        appBar: _buildAppBar(session),
        body: _SessionInfoBody(session: session, stats: stats),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Session session) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _navigateBack,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '会话信息',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            session.title.isNotEmpty ? session.title : '未命名会话',
            style: const TextStyle(fontSize: 12, color: AppTheme.neutral600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditSessionDialog(session),
          tooltip: '编辑会话',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDeleteSession(session);
            } else if (value == 'clone') {
              _openCloneSession(session);
            } else if (value == 'export') {
              _exportSession(session);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'clone',
              child: Row(
                children: [
                  Icon(Icons.control_point_duplicate_outlined, size: 18),
                  SizedBox(width: 12),
                  Text('克隆会话'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 18),
                  SizedBox(width: 12),
                  Text('导出会话'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18),
                  SizedBox(width: 12),
                  Text('删除会话'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
