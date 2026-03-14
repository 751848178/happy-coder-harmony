part of 'grep_tool_screen.dart';

class GrepNotifier extends StateNotifier<GrepState> {
  GrepNotifier() : super(const GrepState());

  Future<void> search(
    String pattern,
    String path, {
    bool caseSensitive = false,
    bool useRegex = false,
    int maxResults = 100,
  }) async {
    state = state.copyWith(
      isSearching: true,
      error: null,
      currentPattern: pattern,
      currentPath: path,
      caseSensitive: caseSensitive,
      useRegex: useRegex,
      maxResults: maxResults,
    );

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
        isSearching: false,
        matches: <GrepMatch>[
          GrepMatch(
            filePath: '$path/lib/main.dart',
            lineNumber: 10,
            lineContent: 'void main() {',
          ),
          GrepMatch(
            filePath: '$path/lib/main.dart',
            lineNumber: 12,
            lineContent: '  runApp(const MyApp());',
          ),
          GrepMatch(
            filePath: '$path/lib/app.dart',
            lineNumber: 15,
            lineContent: 'class MyApp extends StatelessWidget {',
          ),
          GrepMatch(
            filePath: '$path/features/chat/chat_screen.dart',
            lineNumber: 23,
            lineContent: 'class ChatScreen extends ConsumerWidget {',
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
    state = const GrepState();
  }
}

final grepNotifierProvider =
    StateNotifierProvider<GrepNotifier, GrepState>((ref) {
  return GrepNotifier();
});
