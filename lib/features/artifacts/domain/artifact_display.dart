import 'dart:convert';

import 'artifact_models.dart';

Map<String, dynamic> parseArtifactHeader(String? rawHeader) {
  if (rawHeader == null || rawHeader.trim().isEmpty) {
    return const <String, dynamic>{};
  }

  final candidates = <String>{rawHeader.trim()};
  try {
    candidates.add(Uri.decodeComponent(rawHeader.trim()));
  } catch (_) {
    // Keep the raw header when it is not URI-encoded.
  }

  for (final candidate in candidates) {
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      final fallback = _parseLooseMap(candidate);
      if (fallback.isNotEmpty) {
        return fallback;
      }
    }
  }

  return const <String, dynamic>{};
}

String artifactDisplayTitle(Artifact artifact) {
  final title = artifact.title?.trim();
  if (title != null && title.isNotEmpty) {
    return title;
  }

  final headerTitle = parseArtifactHeader(artifact.header)['title']?.toString().trim();
  if (headerTitle != null && headerTitle.isNotEmpty) {
    return headerTitle;
  }

  return 'Untitled';
}

String? artifactDisplayDescription(Artifact artifact) {
  final description = artifact.description?.trim();
  if (description != null && description.isNotEmpty) {
    return description;
  }

  final headerDescription =
      parseArtifactHeader(artifact.header)['description']?.toString().trim();
  if (headerDescription != null && headerDescription.isNotEmpty) {
    return headerDescription;
  }

  return null;
}

Map<String, dynamic> _parseLooseMap(String value) {
  final trimmed = value.trim();
  if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
    return const <String, dynamic>{};
  }

  final content = trimmed.substring(1, trimmed.length - 1).trim();
  if (content.isEmpty) {
    return const <String, dynamic>{};
  }

  final result = <String, dynamic>{};
  final matches = RegExp(r'([A-Za-z0-9_]+)\s*:\s*([^,}]+)').allMatches(content);
  for (final match in matches) {
    final key = match.group(1)?.trim();
    final value = match.group(2)?.trim();
    if (key == null || key.isEmpty || value == null || value.isEmpty) {
      continue;
    }
    result[key] = value;
  }
  return result;
}
