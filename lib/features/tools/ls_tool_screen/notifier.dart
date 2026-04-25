part of 'ls_tool_screen.dart';

class LsNotifier extends StateNotifier<LsState> {
  LsNotifier() : super(const LsState());

  Future<void> listDirectory(String path) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final mockEntries = <DirectoryEntry>[
        DirectoryEntry(
          name: 'lib',
          path: './lib',
          isDirectory: true,
          modifiedAt: DateTime(2026, 3, 1),
        ),
        DirectoryEntry(
          name: 'features',
          path: './features',
          isDirectory: true,
          modifiedAt: DateTime(2026, 3, 2),
        ),
        DirectoryEntry(
          name: 'test',
          path: './test',
          isDirectory: true,
          modifiedAt: DateTime(2026, 3, 1),
        ),
        DirectoryEntry(
          name: 'pubspec.yaml',
          path: './pubspec.yaml',
          size: 1234,
          modifiedAt: DateTime(2026, 2, 28),
          permissions: 'rw-r--r--',
        ),
        DirectoryEntry(
          name: 'README.md',
          path: './README.md',
          size: 5678,
          modifiedAt: DateTime(2026, 2, 25),
          permissions: 'rw-r--r--',
        ),
        DirectoryEntry(
          name: '.gitignore',
          path: './.gitignore',
          size: 234,
          modifiedAt: DateTime(2026, 2, 20),
          permissions: 'rw-------',
        ),
      ];

      final newHistory = path != state.currentPath
          ? [...state.pathHistory, state.currentPath]
          : state.pathHistory;

      state = state.copyWith(
        isLoading: false,
        entries: mockEntries,
        currentPath: path,
        pathHistory: newHistory,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
        entries: [],
      );
    }
  }

  void navigateUp() {
    if (state.pathHistory.isNotEmpty) {
      final pathHistory = List<String>.from(state.pathHistory);
      final newPath = pathHistory.removeLast();
      state = state.copyWith(pathHistory: pathHistory);
      listDirectory(newPath);
      return;
    }

    if (state.currentPath != '.' && state.currentPath.isNotEmpty) {
      final parts = state.currentPath.split('/');
      parts.removeLast();
      final newPath = parts.isEmpty ? '.' : parts.join('/');
      listDirectory(newPath);
    }
  }

  void setSort(SortField field) {
    final newOrder =
        field == state.sortField && state.sortOrder == SortOrder.ascending
            ? SortOrder.descending
            : SortOrder.ascending;

    final sorted = List<DirectoryEntry>.from(state.entries);
    sorted.sort((left, right) {
      final compare = switch (field) {
        SortField.name =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
        SortField.size => (left.size ?? 0).compareTo(right.size ?? 0),
        SortField.modified => (left.modifiedAt ?? DateTime(0))
            .compareTo(right.modifiedAt ?? DateTime(0)),
      };
      return newOrder == SortOrder.ascending ? compare : -compare;
    });

    state = state.copyWith(
      entries: sorted,
      sortField: field,
      sortOrder: newOrder,
    );
  }

  void refresh() {
    listDirectory(state.currentPath);
  }
}

final lsNotifierProvider = StateNotifierProvider<LsNotifier, LsState>((ref) {
  return LsNotifier();
});
