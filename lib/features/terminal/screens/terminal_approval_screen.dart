import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

part 'terminal_approval_screen_actions.dart';
part 'terminal_approval_screen_content.dart';
part 'terminal_approval_screen_support.dart';

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

class TerminalApprovalScreen extends ConsumerStatefulWidget {
  const TerminalApprovalScreen({
    super.key,
    required this.request,
  });

  final TerminalApprovalRequest request;

  @override
  ConsumerState<TerminalApprovalScreen> createState() =>
      _TerminalApprovalScreenState();
}

class _TerminalApprovalScreenState
    extends ConsumerState<TerminalApprovalScreen> {
  bool _isApproving = false;
  bool _isRemembered = true;

  TerminalApprovalRequest get request => widget.request;

  void _setApproving(bool value) {
    setState(() => _isApproving = value);
  }

  void _setRemembered(bool value) {
    setState(() => _isRemembered = value);
  }

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
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
