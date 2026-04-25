part of '../session_detail.dart';

/// 会话详情屏幕
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}
