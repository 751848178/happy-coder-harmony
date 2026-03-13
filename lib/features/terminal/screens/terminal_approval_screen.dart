import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

/// Terminal approval request model
class TerminalApprovalRequest {
  final String id;
  final String sessionId;
  final String machine;
  final String path;
  final String? command;
  final String requestingApp;
  final DateTime requestedAt;
  final bool isApproved;
  final bool isRejected;

  const TerminalApprovalRequest({
    required this.id,
    required this.sessionId,
    required this.machine,
    required this.path,
    this.command,
    required this.requestingApp,
    required this.requestedAt,
    this.isApproved = false,
    this.isRejected = false,
  });

  TerminalApprovalRequest copyWith({
    String? id,
    String? sessionId,
    String? machine,
    String? path,
    String? command,
    String? requestingApp,
    DateTime? requestedAt,
    bool? isApproved,
    bool? isRejected,
  }) {
    return TerminalApprovalRequest(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      machine: machine ?? this.machine,
      path: path ?? this.path,
      command: command ?? this.command,
      requestingApp: requestingApp ?? this.requestingApp,
      requestedAt: requestedAt ?? this.requestedAt,
      isApproved: isApproved ?? this.isApproved,
      isRejected: isRejected ?? this.isRejected,
    );
  }
}

/// Terminal Approval Screen
///
/// Handles terminal connection approval via happy://terminal? deep link
class TerminalApprovalScreen extends ConsumerStatefulWidget {
  const TerminalApprovalScreen({
    super.key,
    required this.request,
  });

  final TerminalApprovalRequest request;

  @override
  ConsumerState<TerminalApprovalScreen> createState() => _TerminalApprovalScreenState();

}

class _TerminalApprovalScreenState extends ConsumerState<TerminalApprovalScreen> {
  bool _isApproving = false;
  bool _isRemembered = true;

  TerminalApprovalRequest get request => widget.request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('终端连接请求'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.brandColor,
                              AppTheme.brandColor.withValues(alpha: 0.7),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.terminal,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        '终端连接请求',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        '${request.requestingApp} 请求访问终端连接',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.neutral600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Connection details
                      _buildDetailsCard(),

                      const SizedBox(height: 24),

                      // Warning message
                      _buildWarning(),

                      const SizedBox(height: 24),

                      // Remember option
                      _buildRememberOption(),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isApproving ? null : _rejectRequest,
                              icon: const Icon(Icons.close),
                              label: const Text('拒绝'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isApproving ? null : _approveRequest,
                              icon: _isApproving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(_isApproving ? '处理中...' : '批准'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
            icon: Icons.computer,
            label: '主机',
            value: request.machine,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.folder,
            label: '路径',
            value: request.path,
          ),
          if (request.command != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.code,
              label: '命令',
              value: request.command!,
            ),
          ],
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.access_time,
            label: '请求时间',
            value: _formatTime(request.requestedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '批准后，该应用将获得终端访问权限。请确认您信任此应用。',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRememberOption() {
    return InkWell(
      onTap: () => setState(() => _isRemembered = !_isRemembered),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _isRemembered,
              onChanged: (value) => setState(() => _isRemembered = value ?? false),
              activeColor: AppTheme.brandColor,
            ),
            const SizedBox(width: 8),
            const Text(
              '记住此决定',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _approveRequest() async {
    setState(() => _isApproving = true);

    // Simulate approval process
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      _showApprovalDialog(true);
      setState(() => _isApproving = false);
    }
  }

  void _rejectRequest() {
    _showApprovalDialog(false);
  }

  void _showApprovalDialog(bool approved) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          approved ? Icons.check_circle : Icons.cancel,
          color: approved ? AppTheme.successColor : AppTheme.errorColor,
          size: 48,
        ),
        title: Text(approved ? '已批准' : '已拒绝'),
        content: Text(
          approved
              ? '终端连接请求已被批准，${request.requestingApp} 现在可以访问终端。'
              : '终端连接请求已被拒绝，${request.requestingApp} 无法访问终端。',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.neutral500,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

/// Terminal approval helper class
///
/// Handles parsing happy://terminal? deep links
class TerminalApprovalLinkParser {
  /// Parse a happy://terminal? deep link
  static TerminalApprovalRequest? parse(String url) {
    if (!url.startsWith('happy://terminal?')) {
      return null;
    }

    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    final sessionId = params['sessionId'] ?? params['session'];
    final machine = params['machine'] ?? params['host'] ?? 'localhost';
    final path = params['path'] ?? params['dir'] ?? '/home/user';
    final command = params['command'];
    final requestingApp = params['app'] ?? params['from'] ?? 'Unknown App';

    if (sessionId == null) {
      return null;
    }

    return TerminalApprovalRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      machine: machine,
      path: path,
      command: command,
      requestingApp: requestingApp,
      requestedAt: DateTime.now(),
    );
  }
}
