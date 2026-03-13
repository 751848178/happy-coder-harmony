import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../app/providers/app_providers.dart';
import '../domain/session_models.dart';

/// 会话搜索屏幕
///
/// 支持搜索、过滤和归档会话
class SessionSearchScreen extends ConsumerStatefulWidget {
  const SessionSearchScreen({super.key});

  @override
  ConsumerState<SessionSearchScreen> createState() => _SessionSearchScreenState();
}

class _SessionSearchScreenState extends ConsumerState<SessionSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 搜索会话
  void _performSearch(String query) {
    setState(() {
      _isSearching = query.trim().isNotEmpty;
    });

    if (query.trim().isEmpty) {
      // 显示所有会话
      ref.read(sessionStateProvider.notifier).loadSessions();
      return;
    }

    // TODO: 保存搜索关键词并执行搜索
    ref.read(sessionStateProvider.notifier).loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('搜索会话'),
      ),
      body: Column(
        children: [
          // 搜索框
          _buildSearchBar(context),
          // 搜索结果
          Expanded(
            child: _buildSearchResults(context, sessionState),
          ),
        ],
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _performSearch,
        decoration: InputDecoration(
          hintText: '搜索会话或消息...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.neutral50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults(BuildContext context, dynamic sessionState) {
    // 根据状态显示不同内容
    final sessions = sessionState.maybeWhen(
      orElse: () => <Session>[],
      loading: () => <Session>[],
      ready: (sessions, _, __) => sessions,
    );

    if (sessionState.maybeWhen(
      orElse: () => false,
      loading: () => true,
    )) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (sessions.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildSessionCard(context, session);
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching ? '没有找到匹配的结果' : '输入关键词开始搜索',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '搜索会话标题或消息内容',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建会话卡片
  Widget _buildSessionCard(BuildContext context, Session session) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.brandColor.withValues(alpha: 0.2),
          child: Text(
            session.title.isNotEmpty ? session.title[0].toUpperCase() : '?',
            style: TextStyle(
              color: AppTheme.brandColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          session.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _formatDate(session.updatedAt),
          style: TextStyle(
            color: AppTheme.neutral500,
            fontSize: 12,
          ),
        ),
        onTap: () {
          // 导航到会话详情
          context.push('/session/${session.id}');
        },
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date!);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${date!.month}月${date!.day}日';
    }
  }
}
