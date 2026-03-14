part of 'glob_tool_screen.dart';

class GlobNotifier extends StateNotifier<GlobState> {
  GlobNotifier() : super(const GlobState());

  Future<void> search(String pattern, String path) async {
    state = state.copyWith(
      isSearching: true,
      error: null,
      currentPattern: pattern,
      currentPath: path,
    );

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
        isSearching: false,
        matches: <GlobMatch>[
          GlobMatch(
              path: '$path/lib/main.dart',
              size: 1234,
              modifiedAt: DateTime.now()),
          GlobMatch(
              path: '$path/lib/app.dart',
              size: 567,
              modifiedAt: DateTime.now()),
          GlobMatch(path: '$path/lib/features', isDirectory: true),
          GlobMatch(path: '$path/lib/core', isDirectory: true),
          GlobMatch(path: '$path/test', isDirectory: true),
          GlobMatch(
            path: '$path/pubspec.yaml',
            size: 234,
            modifiedAt: DateTime.now(),
          ),
        ],
      );
    } catch (error) {
      state = state.copyWith(
        isSearching: false,
        error: error.toString(),
        matches: [],
      );
    }
  }

  void clear() {
    state = const GlobState();
  }
}

final globNotifierProvider =
    StateNotifierProvider<GlobNotifier, GlobState>((ref) {
  return GlobNotifier();
});
