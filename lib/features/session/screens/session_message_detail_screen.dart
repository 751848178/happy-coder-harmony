import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../chat/components/message_bubble.dart';

/// 消息详情页
class SessionMessageDetailScreen extends ConsumerStatefulWidget {
  const SessionMessageDetailScreen({
    super.key,
    required this.sessionId,
    required this.messageId,
  });

  final String sessionId;
  final String messageId;

  @override
  ConsumerState<SessionMessageDetailScreen> createState() =>
      _SessionMessageDetailScreenState();
}

class _SessionMessageDetailScreenState
    extends ConsumerState<SessionMessageDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(sessionStateProvider.notifier)
          .loadSessionMessages(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionStateProvider.select(
      (s) => s.whenOrNull(
        ready: (_, sessionMessages, __) =>
            sessionMessages[widget.sessionId],
      ),
    ));
    final sessionMessages = ref
        .read(sessionStateProvider.notifier)
        .getSessionMessages(widget.sessionId);
    final matchingMessages = sessionMessages?.messages
            .where((item) => item.id == widget.messageId)
            .toList() ??
        const [];
    final message = matchingMessages.isEmpty ? null : matchingMessages.first;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text('消息详情'),
      ),
      body: message == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MessageBubble(message: message),
                const SizedBox(height: 16),
                _MetadataCard(message: message),
              ],
            ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.message});

  final ReducerMessage message;

  @override
  Widget build(BuildContext context) {
    final metadata = <String, dynamic>{
      'id': message.id,
      'kind': message.kind,
      'createdAt': message.createdAt.toIso8601String(),
      if (message.text != null) 'textLength': message.text!.length,
      if (message.tool != null) 'tool': message.tool!.toJson(),
      if (message.permission != null)
        'permission': message.permission!.toJson(),
      if (message.turnClose != null) 'turnClose': message.turnClose!.toJson(),
      if (message.metadata != null) 'metadata': message.metadata,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '结构化数据',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(metadata),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
