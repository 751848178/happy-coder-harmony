part of 'storage_service.dart';

class StorageNotifier extends StateNotifier<StorageState> {
  StorageNotifier(this._service) : super(const StorageState()) {
    initialize();
  }

  final StorageService _service;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.initialize();
      final stats = await _service.getStats();
      state = state.copyWith(isLoading: false, stats: stats);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true);
    try {
      final sessions = await _service.getAllSessions();
      final stats = await _service.getStats();
      state =
          state.copyWith(isLoading: false, sessions: sessions, stats: stats);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> searchSessions(String query) async {
    try {
      final results = await _service.searchSessions(query);
      if (query.trim().isNotEmpty) {
        await _service.saveSearchKeyword(query);
      }
      state = state.copyWith(searchResults: results);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> togglePinSession(String id) async {
    try {
      await _service.togglePinSession(id);
      final sessions = await _service.getPinnedSessions();
      final stats = await _service.getStats();
      state = state.copyWith(sessions: sessions, stats: stats);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> toggleArchiveSession(String id) async {
    try {
      await _service.toggleArchiveSession(id);
      final sessions = await _service.getAllSessions();
      final stats = await _service.getStats();
      state = state.copyWith(sessions: sessions, stats: stats);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      await _service.deleteSession(id);
      final sessions = await _service.getAllSessions();
      final stats = await _service.getStats();
      state = state.copyWith(sessions: sessions, stats: stats);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> cleanupOldData() async {
    try {
      final result = await _service.cleanupOldData();
      final stats = await _service.getStats();
      state = state.copyWith(stats: stats, cleanupResult: result);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> clearAll() async {
    try {
      await _service.clearAll();
      state = const StorageState();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}
