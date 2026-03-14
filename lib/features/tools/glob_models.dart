part of 'glob_tool_screen.dart';

class GlobMatch {
  const GlobMatch({
    required this.path,
    this.isDirectory = false,
    this.size,
    this.modifiedAt,
  });

  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? modifiedAt;
}

class GlobState {
  const GlobState({
    this.isSearching = false,
    this.matches = const [],
    this.error,
    this.currentPattern = '',
    this.currentPath = '.',
  });

  final bool isSearching;
  final List<GlobMatch> matches;
  final String? error;
  final String currentPattern;
  final String currentPath;

  GlobState copyWith({
    bool? isSearching,
    List<GlobMatch>? matches,
    String? error,
    String? currentPattern,
    String? currentPath,
  }) {
    return GlobState(
      isSearching: isSearching ?? this.isSearching,
      matches: matches ?? this.matches,
      error: error ?? this.error,
      currentPattern: currentPattern ?? this.currentPattern,
      currentPath: currentPath ?? this.currentPath,
    );
  }
}
