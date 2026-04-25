part of 'session_grouping_service.dart';

extension _SessionGroupingServiceStorage on SessionGroupingService {
  Future<void> _persist(SessionGroupingState state) async {
    _cache = state;
    await _storage.write(
      key: SessionGroupingService._storageKey,
      value: jsonEncode(state.toJson()),
    );
  }

  void _ensureUniqueName(
    List<SessionGroup> groups, {
    required String candidate,
    String? excludingGroupId,
  }) {
    final normalized = candidate.trim().toLowerCase();
    if (normalized.isEmpty) {
      return;
    }
    final exists = groups.any(
      (group) =>
          group.id != excludingGroupId &&
          group.name.trim().toLowerCase() == normalized,
    );
    if (exists) {
      throw SessionGroupNameConflictException(candidate);
    }
  }
}
