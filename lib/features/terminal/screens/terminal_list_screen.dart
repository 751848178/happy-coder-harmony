import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

/// Terminal status
enum TerminalStatus {
  active,
  idle,
  disconnected,
  error,
}

/// Terminal session model
class TerminalSession {
  final String id;
  final String name;
  final String machine;
  final String? path;
  final TerminalStatus status;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final String? pid;
  final int? exitCode;

  const TerminalSession({
    required this.id,
    required this.name,
    required this.machine,
    this.path,
    this.status = TerminalStatus.idle,
    required this.createdAt,
    this.lastActivity,
    this.pid,
    this.exitCode,
  });

  Duration get age => DateTime.now().difference(createdAt);

  Duration get idle {
    if (lastActivity == null) return age;
    return DateTime.now().difference(lastActivity!);
  }

  String get _durationString {
    final d = idle;
    if (d.inSeconds < 60) {
      return '${d.inSeconds}s';
    } else if (d.inMinutes < 60) {
      return '${d.inMinutes}m';
    } else if (d.inHours < 24) {
      return '${d.inHours}h';
    }
    return '${d.inDays}d';
  }

  TerminalSession copyWith({
    String? id,
    String? name,
    String? machine,
    String? path,
    TerminalStatus? status,
    DateTime? createdAt,
    DateTime? lastActivity,
    String? pid,
    int? exitCode,
  }) {
    return TerminalSession(
      id: id ?? this.id,
      name: name ?? this.name,
      machine: machine ?? this.machine,
      path: path ?? this.path,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      pid: pid ?? this.pid,
      exitCode: exitCode ?? this.exitCode,
    );
  }
}

/// Terminal List Screen
///
/// Manages multiple terminal sessions
class TerminalListScreen extends ConsumerStatefulWidget {
  const TerminalListScreen({super.key});

  @override
  ConsumerState<TerminalListScreen> createState() => _TerminalListScreenState();
}

class _TerminalListScreenState extends ConsumerState<TerminalListScreen> {
  final List<TerminalSession> _sessions = [];
  final _nameController = TextEditingController();
  final _machineController = TextEditingController();
  final _pathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    // Sample sessions
    setState(() {
      _sessions.clear();
      _sessions.addAll([
        TerminalSession(
          id: '1',
          name: '主终端',
          machine: 'localhost',
          path: '/home/user/project',
          status: TerminalStatus.active,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          lastActivity: DateTime.now(),
          pid: '12345',
        ),
        TerminalSession(
          id: '2',
          name: '开发环境',
          machine: 'dev-server',
          path: '/app',
          status: TerminalStatus.idle,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          lastActivity: DateTime.now().subtract(const Duration(minutes: 15)),
          pid: '12346',
        ),
        TerminalSession(
          id: '3',
          name: '生产环境',
          machine: 'prod-server',
          path: '/var/www/app',
          status: TerminalStatus.disconnected,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          lastActivity: DateTime.now().subtract(const Duration(hours: 5)),
          exitCode: 0,
        ),
        TerminalSession(
          id: '4',
          name: '测试终端',
          machine: 'localhost',
          status: TerminalStatus.error,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          lastActivity: DateTime.now().subtract(const Duration(minutes: 10)),
          exitCode: 1,
        ),
      ]);
    });
  }

  void _addSession() {
    _nameController.clear();
    _machineController.clear();
    _pathController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建终端会话'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '会话名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _machineController,
                decoration: const InputDecoration(
                  labelText: '主机地址',
                  border: OutlineInputBorder(),
                  hintText: 'localhost',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pathController,
                decoration: const InputDecoration(
                  labelText: '工作目录',
                  border: OutlineInputBorder(),
                  hintText: '/home/user',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) {
                _showSnackBar('请输入会话名称', isError: true);
                return;
              }

              final session = TerminalSession(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text.trim(),
                machine: _machineController.text.trim().isEmpty
                    ? 'localhost'
                    : _machineController.text.trim(),
                path: _pathController.text.trim().isEmpty
                    ? null
                    : _pathController.text.trim(),
                status: TerminalStatus.idle,
                createdAt: DateTime.now(),
                lastActivity: DateTime.now(),
              );

              setState(() => _sessions.insert(0, session));
              Navigator.pop(context);
              _showSnackBar('终端会话已创建', isError: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _connectToSession(TerminalSession session) {
    setState(() {
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _sessions[index] = session.copyWith(
          status: TerminalStatus.active,
          lastActivity: DateTime.now(),
        );
      }
    });
    // Navigate to terminal screen (would use go_router in real app)
    _showSnackBar('已连接到 ${session.name}', isError: false);
  }

  void _disconnectSession(TerminalSession session) {
    setState(() {
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _sessions[index] = session.copyWith(
          status: TerminalStatus.disconnected,
          lastActivity: DateTime.now(),
          pid: null,
          exitCode: 0,
        );
      }
    });
    _showSnackBar('已断开 ${session.name}', isError: false);
  }

  void _deleteSession(String id) {
    setState(() {
      _sessions.removeWhere((s) => s.id == id);
    });
    _showSnackBar('终端会话已删除', isError: false);
  }

  void _reconnectSession(TerminalSession session) {
    setState(() {
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _sessions[index] = session.copyWith(
          status: TerminalStatus.active,
          lastActivity: DateTime.now(),
          pid: '12345',
          exitCode: null,
        );
      }
    });
    _showSnackBar('已重新连接到 ${session.name}', isError: false);
  }

  void _showSessionDetails(TerminalSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('状态', _buildStatusBadge(session.status)),
              _DetailRow('主机', session.machine),
              _DetailRow('路径', session.path ?? '未设置'),
              _DetailRow('PID', session.pid ?? '-'),
              _DetailRow('创建时间', _formatTime(session.createdAt)),
              _DetailRow('空闲时间', session._durationString),
              if (session.exitCode != null)
                _DetailRow('退出码', session.exitCode.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int get _activeCount => _sessions.where((s) => s.status == TerminalStatus.active).length;
  int get _disconnectedCount => _sessions.where((s) => s.status == TerminalStatus.disconnected).length;
  int get _errorCount => _sessions.where((s) => s.status == TerminalStatus.error).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('终端会话'),
        actions: [
          if (_sessions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.brandColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_activeCount > 0) ...[
                    const Icon(
                      Icons.lens,
                      size: 8,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_activeCount',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_errorCount > 0 && _activeCount > 0)
                    const SizedBox(width: 8),
                  if (_errorCount > 0) ...[
                    const Icon(
                      Icons.error,
                      size: 12,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_errorCount',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _showSnackBar('正在刷新终端列表...', isError: false);
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: _sessions.isEmpty
          ? _buildEmptyState()
          : _buildSessionList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSession,
        backgroundColor: AppTheme.brandColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('新建会话'),
      ),
    );
  }

  Widget _buildSessionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _TerminalSessionCard(
          session: session,
          onTap: () => _connectToSession(session),
          onDisconnect: session.status == TerminalStatus.active
              ? () => _disconnectSession(session)
              : session.status == TerminalStatus.disconnected
                  ? () => _reconnectSession(session)
                  : null,
          onDetails: () => _showSessionDetails(session),
          onDelete: () => _showDeleteConfirmation(session),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.terminal_outlined,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: 16),
          const Text(
            '没有终端会话',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.neutral600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击 + 按钮创建新的终端会话',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral400,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(TerminalSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除终端会话'),
        content: Text('确认要删除 "${session.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSession(session.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TerminalStatus status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case TerminalStatus.active:
        color = AppTheme.successColor;
        icon = Icons.lens;
        label = '活动';
        break;
      case TerminalStatus.idle:
        color = AppTheme.infoColor;
        icon = Icons.circle_outlined;
        label = '空闲';
        break;
      case TerminalStatus.disconnected:
        color = AppTheme.neutral400;
        icon = Icons.power_off;
        label = '已断开';
        break;
      case TerminalStatus.error:
        color = AppTheme.errorColor;
        icon = Icons.error;
        label = '错误';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _machineController.dispose();
    _pathController.dispose();
    super.dispose();
  }
}

/// Terminal session card widget
class _TerminalSessionCard extends StatelessWidget {
  const _TerminalSessionCard({
    required this.session,
    required this.onTap,
    required this.onDisconnect,
    this.onDetails,
    required this.onDelete,
  });

  final TerminalSession session;
  final VoidCallback onTap;
  final VoidCallback? onDisconnect;
  final VoidCallback? onDetails;
  final VoidCallback onDelete;

  Color get _statusColor {
    switch (session.status) {
      case TerminalStatus.active:
        return AppTheme.successColor;
      case TerminalStatus.idle:
        return AppTheme.infoColor;
      case TerminalStatus.disconnected:
        return AppTheme.neutral400;
      case TerminalStatus.error:
        return AppTheme.errorColor;
    }
  }

  IconData get _statusIcon {
    switch (session.status) {
      case TerminalStatus.active:
        return Icons.lens;
      case TerminalStatus.idle:
        return Icons.circle_outlined;
      case TerminalStatus.disconnected:
        return Icons.power_off;
      case TerminalStatus.error:
        return Icons.error_outline;
    }
  }

  String get _statusLabel {
    switch (session.status) {
      case TerminalStatus.active:
        return '活动';
      case TerminalStatus.idle:
        return '空闲';
      case TerminalStatus.disconnected:
        return '已断开';
      case TerminalStatus.error:
        return '错误';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _statusIcon,
                  color: _statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.computer,
                          size: 14,
                          color: AppTheme.neutral500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.machine,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.neutral600,
                          ),
                        ),
                        if (session.path != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.folder,
                            size: 14,
                            color: AppTheme.neutral500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              session.path!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.neutral600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '空闲 ${session._durationString}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'details':
                      onDetails?.call();
                      break;
                    case 'disconnect':
                      onDisconnect?.call();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18),
                        SizedBox(width: 12),
                        Text('详情'),
                      ],
                    ),
                  ),
                  if (session.status == TerminalStatus.active)
                    PopupMenuItem(
                      value: 'disconnect',
                      child: Row(
                        children: [
                          Icon(Icons.link_off, size: 18),
                          SizedBox(width: 12),
                          Text('断开连接'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                        SizedBox(width: 12),
                        Text('删除', style: TextStyle(color: AppTheme.errorColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.neutral600,
              ),
            ),
          ),
          Expanded(
            child: value is Widget
                ? value as Widget
                : Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
