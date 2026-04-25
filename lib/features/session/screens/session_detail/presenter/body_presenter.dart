part of '../session_detail.dart';

class _SessionScreenBodyViewState {
  const _SessionScreenBodyViewState({
    required this.messages,
    required this.showMessageLoading,
    required this.turnGroups,
    required this.sessionStats,
    required this.thinkingSnapshot,
    required this.effectiveConversationBusy,
    required this.shouldKeepScreenAwake,
    required this.latestTurnMessages,
    required this.showLiveReplyBadge,
    required this.hasStickyCandidates,
  });

  final List<ReducerMessage> messages;
  final bool showMessageLoading;
  final List<_MessageTurnGroup> turnGroups;
  final SessionStats? sessionStats;
  final SessionThinkingSnapshot thinkingSnapshot;
  final bool effectiveConversationBusy;
  final bool shouldKeepScreenAwake;
  final List<ReducerMessage> latestTurnMessages;
  final bool showLiveReplyBadge;
  final bool hasStickyCandidates;
}

class _SessionScreenBodyPresenter {
  static const int _slowStructureBuildThresholdMs = 8;
  static const int _largeStructureMessageThreshold = 120;

  _SessionScreenBodyPresenter(this._state);

  final _SessionScreenState _state;

  Session? _cachedStatsSession;
  List<ReducerMessage>? _cachedStatsMessages;
  SessionStats? _cachedSessionStats;
  Session? _cachedThinkingSession;
  List<ReducerMessage>? _cachedThinkingMessages;
  SessionThinkingSnapshot _cachedThinkingSnapshot =
      const SessionThinkingSnapshot(isThinking: false);
  List<ReducerMessage>? _cachedTurnGroupMessages;
  List<_MessageTurnGroup> _cachedTurnGroups = const <_MessageTurnGroup>[];
  List<_MessageTurnGroup>? _cachedFlatItemTurnGroups;
  List<_FlatMessageItem> _cachedFlatItems = const <_FlatMessageItem>[];
  Map<String, int> _cachedFlatItemIndexes = const <String, int>{};
  bool _hasStickyCandidates = false;

  bool get hasStickyCandidates => _hasStickyCandidates;

  int? findFlatItemIndexByRenderId(String renderId) {
    return _cachedFlatItemIndexes[renderId];
  }
}
