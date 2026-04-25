part of 'derived_session_files_service.dart';

Iterable<String> _extractStructuredPaths(Session? session) sync* {
  if (session == null) {
    return;
  }
  final candidates = <Map<String, dynamic>?>[
    _asMap(session.metadata?['git']),
    _asMap(session.metadata?['gitStatus']),
    _asMap(session.metadata?['repository']),
    _asMap(session.metadata?['repo']),
    _asMap(session.agentState?['git']),
    _asMap(session.agentState?['gitStatus']),
    _asMap(session.agentState?['repository']),
    _asMap(session.agentState?['repo']),
  ];
  for (final candidate in candidates) {
    if (candidate == null) {
      continue;
    }
    for (final key in const ['stagedFiles', 'unstagedFiles', 'files']) {
      final files = candidate[key];
      if (files is! List) {
        continue;
      }
      for (final item in files.whereType<Map>()) {
        final map = _asMap(item);
        final path = _firstNonEmpty([
          map?['filePath']?.toString(),
          map?['path']?.toString(),
          map?['fullPath']?.toString(),
          map?['fileName']?.toString(),
        ]);
        if (path != null) {
          yield path;
        }
      }
    }
  }
}

List<String> _extractCandidatePaths(ToolInfo tool) {
  final paths = <String>[
    ..._extractToolPaths(tool),
    if (tool.name.toLowerCase() == 'file')
      ...[
        _stringValue(tool.arguments['name']),
        _stringValue(tool.arguments['path']),
      ].whereType<String>(),
  ];
  return paths;
}

Iterable<String> _extractToolPaths(ToolInfo tool) sync* {
  final arguments = tool.arguments;
  final scalars = <dynamic>[
    arguments['file_path'],
    arguments['path'],
    arguments['uri'],
    arguments['target_file'],
    arguments['source_path'],
    arguments['old_path'],
    arguments['new_path'],
    arguments['destination_path'],
    arguments['output_file'],
  ];
  for (final value in scalars) {
    final path = _stringValue(value);
    if (path != null) {
      yield path;
    }
  }
  for (final key in const ['files', 'paths']) {
    final list = arguments[key];
    if (list is! List) {
      continue;
    }
    for (final item in list) {
      if (item is String && item.trim().isNotEmpty) {
        yield item.trim();
        continue;
      }
      final map = _asMap(item);
      final path = _firstNonEmpty([
        map?['path']?.toString(),
        map?['file_path']?.toString(),
        map?['name']?.toString(),
      ]);
      if (path != null) {
        yield path;
      }
    }
  }
  final edits = arguments['edits'];
  if (edits is List) {
    for (final edit in edits.whereType<Map>()) {
      final map = _asMap(edit);
      final path = _firstNonEmpty([
        map?['path']?.toString(),
        map?['file_path']?.toString(),
        map?['target_file']?.toString(),
      ]);
      if (path != null) {
        yield path;
      }
    }
  }
  final locations = arguments['locations'];
  if (locations is List) {
    for (final location in locations.whereType<Map>()) {
      final map = _asMap(location);
      final path = _firstNonEmpty([
        map?['path']?.toString(),
        map?['file_path']?.toString(),
      ]);
      if (path != null) {
        yield path;
      }
    }
  }
  final diff = _extractDiff(tool);
  if (diff != null) {
    yield* _extractPathsFromDiff(diff);
  }
}

Iterable<String> _extractPathsFromDiff(String diff) sync* {
  for (final line in diff.split('\n')) {
    if (line.startsWith('+++ b/') || line.startsWith('--- a/')) {
      yield line.substring(6).trim();
      continue;
    }
    if (line.startsWith('diff --git ')) {
      final match = RegExp(r'^diff --git a/(.+?) b/(.+)$').firstMatch(line);
      if (match != null) {
        yield match.group(2)!.trim();
      }
      continue;
    }
    if (line.startsWith('*** Add File: ') ||
        line.startsWith('*** Update File: ') ||
        line.startsWith('*** Delete File: ')) {
      yield line.split(':').last.trim();
    }
  }
}
