part of 'session_service.dart';

extension SessionServiceMessageReducerHelpers on SessionServiceNotifier {
  ReducerMessage _buildTextReducerMessage({
    required String id,
    required DateTime createdAt,
    required String text,
    required Map<String, dynamic>? metadata,
  }) {
    return ReducerMessage(
      id: id,
      kind: 'text',
      createdAt: createdAt,
      text: text,
      metadata: metadata,
    );
  }

  ReducerMessage _buildEventReducerMessage({
    required String id,
    required DateTime createdAt,
    required String text,
    required Map<String, dynamic>? metadata,
  }) {
    return ReducerMessage(
      id: id,
      kind: 'agent-event',
      createdAt: createdAt,
      text: text,
      metadata: {...?metadata, 'role': 'agent'},
    );
  }

  ReducerMessage _buildToolReducerMessage({
    required String id,
    required DateTime createdAt,
    required String toolId,
    required String name,
    required Map<String, dynamic> arguments,
    required ToolCallStatus status,
    required Map<String, dynamic>? metadata,
    String? result,
    String? error,
    String? description,
  }) {
    return ReducerMessage(
      id: id,
      kind: 'tool-call',
      createdAt: createdAt,
      metadata: {...?metadata, 'role': 'agent'},
      tool: ToolInfo(
        id: toolId,
        name: name,
        arguments: arguments,
        status: status,
        result: result,
        error: error,
        description: description,
      ),
    );
  }

  String _toolMessageId(String toolId) => 'tool:$toolId';

  String? _stringifyStructuredContent(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final trimmed = value.trimRight();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    if (value is List) {
      final textParts = <String>[];
      for (final entry in value) {
        final map = _asStringMap(entry);
        final text = map?['text']?.toString();
        if (text != null && text.isNotEmpty) {
          textParts.add(text);
        }
      }
      if (textParts.isNotEmpty) {
        return textParts.join('\n');
      }
      try {
        return const JsonEncoder.withIndent('  ').convert(value);
      } catch (_) {
        return value.toString();
      }
    }
    if (value is Map) {
      try {
        return const JsonEncoder.withIndent('  ').convert(value);
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString();
  }

  String? _firstNonEmptyString(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  DateTime? _parseMessageDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is double)
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    if (value is String) {
      if (value.isEmpty) return null;
      final asInt = int.tryParse(value);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic>? _decodeMaybeJsonMap(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      return null;
    }
    try {
      return _asStringMap(jsonDecode(trimmed));
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeBase64(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return false;
    }
    return RegExp(r'^[A-Za-z0-9+/=_-]+$').hasMatch(normalized);
  }

  int? _parseSeq(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) {
      return value.toInt();
    }
    return null;
  }
}
