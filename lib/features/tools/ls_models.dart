part of 'ls_tool_screen.dart';

class DirectoryEntry {
  const DirectoryEntry({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.size,
    this.modifiedAt,
    this.permissions,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? modifiedAt;
  final String? permissions;
}

class LsState {
  const LsState({
    this.isLoading = false,
    this.entries = const [],
    this.error,
    this.currentPath = '.',
    this.pathHistory = const [],
    this.sortField = SortField.name,
    this.sortOrder = SortOrder.ascending,
  });

  final bool isLoading;
  final List<DirectoryEntry> entries;
  final String? error;
  final String currentPath;
  final List<String> pathHistory;
  final SortField sortField;
  final SortOrder sortOrder;

  LsState copyWith({
    bool? isLoading,
    List<DirectoryEntry>? entries,
    String? error,
    String? currentPath,
    List<String>? pathHistory,
    SortField? sortField,
    SortOrder? sortOrder,
  }) {
    return LsState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
      error: error ?? this.error,
      currentPath: currentPath ?? this.currentPath,
      pathHistory: pathHistory ?? this.pathHistory,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

enum SortField { name, size, modified }

enum SortOrder { ascending, descending }
