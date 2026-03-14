part of 'storage_service.dart';

class StorageState {
  const StorageState({
    this.isLoading = false,
    this.sessions = const [],
    this.searchResults,
    this.stats,
    this.cleanupResult,
    this.errorMessage,
  });

  final bool isLoading;
  final List<SessionStorageModel> sessions;
  final List<SessionStorageModel>? searchResults;
  final StorageStats? stats;
  final CleanupResult? cleanupResult;
  final String? errorMessage;

  StorageState copyWith({
    bool? isLoading,
    List<SessionStorageModel>? sessions,
    List<SessionStorageModel>? searchResults,
    StorageStats? stats,
    CleanupResult? cleanupResult,
    String? errorMessage,
  }) {
    return StorageState(
      isLoading: isLoading ?? this.isLoading,
      sessions: sessions ?? this.sessions,
      searchResults: searchResults ?? this.searchResults,
      stats: stats ?? this.stats,
      cleanupResult: cleanupResult ?? this.cleanupResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasSessions => sessions.isNotEmpty;
  bool get hasSearchResults =>
      searchResults != null && searchResults!.isNotEmpty;
  int get sessionCount => sessions.length;
}
