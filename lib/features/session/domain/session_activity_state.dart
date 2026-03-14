import 'session_models.dart';

Session applyEphemeralSessionActivity({
  required Session session,
  required bool? active,
  required DateTime? activeAt,
  required bool thinkingProvided,
  required bool? thinking,
}) {
  final nextActive = active ?? session.active;
  final nextActiveAt = activeAt ?? session.activeAt;
  final nextThinking = !nextActive
      ? false
      : thinkingProvided
          ? thinking
          : session.thinking;

  return session.copyWith(
    active: nextActive,
    activeAt: nextActiveAt,
    thinking: nextThinking,
    thinkingAt: nextThinking == true ? nextActiveAt : null,
  );
}
