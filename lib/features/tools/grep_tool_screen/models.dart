part of 'grep_tool_screen.dart';

class GrepMatch {
  const GrepMatch({
    required this.filePath,
    required this.lineNumber,
    required this.lineContent,
    this.startColumn,
    this.endColumn,
  });

  final String filePath;
  final int lineNumber;
  final String lineContent;
  final int? startColumn;
  final int? endColumn;
}

class GrepState {
  const GrepState({
    this.isSearching = false,
    this.matches = const [],
    this.error,
    this.currentPattern = '',
    this.currentPath = '.',
    this.caseSensitive = false,
    this.useRegex = false,
    this.maxResults = 100,
  });

  final bool isSearching;
  final List<GrepMatch> matches;
  final String? error;
  final String currentPattern;
  final String currentPath;
  final bool caseSensitive;
  final bool useRegex;
  final int maxResults;

  GrepState copyWith({
    bool? isSearching,
    List<GrepMatch>? matches,
    String? error,
    String? currentPattern,
    String? currentPath,
    bool? caseSensitive,
    bool? useRegex,
    int? maxResults,
  }) {
    return GrepState(
      isSearching: isSearching ?? this.isSearching,
      matches: matches ?? this.matches,
      error: error ?? this.error,
      currentPattern: currentPattern ?? this.currentPattern,
      currentPath: currentPath ?? this.currentPath,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      useRegex: useRegex ?? this.useRegex,
      maxResults: maxResults ?? this.maxResults,
    );
  }
}
