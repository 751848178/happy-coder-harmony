import 'dart:convert';

import '../../../shared/platform/platform_storage.dart';

class SessionInputTemplate {
  const SessionInputTemplate({
    required this.id,
    required this.label,
    required this.content,
  });

  final String id;
  final String label;
  final String content;

  factory SessionInputTemplate.fromJson(Map<String, dynamic> json) {
    return SessionInputTemplate(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString().trim() ?? '',
      content: json['content']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'content': content,
    };
  }

  SessionInputTemplate copyWith({
    String? id,
    String? label,
    String? content,
  }) {
    return SessionInputTemplate(
      id: id ?? this.id,
      label: label ?? this.label,
      content: content ?? this.content,
    );
  }
}

class SessionInputTemplateService {
  SessionInputTemplateService._();

  static final SessionInputTemplateService instance =
      SessionInputTemplateService._();

  static const String _storageKey = 'session_input_templates_v1';

  final PlatformStorage _storage = PlatformStorage.instance;

  Future<List<SessionInputTemplate>> loadTemplates() async {
    final raw = await _storage.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <SessionInputTemplate>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <SessionInputTemplate>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => SessionInputTemplate.fromJson(
              item.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            ),
          )
          .where(
            (item) => item.id.isNotEmpty && item.label.isNotEmpty,
          )
          .toList();
    } catch (_) {
      return const <SessionInputTemplate>[];
    }
  }

  Future<List<SessionInputTemplate>> saveTemplates(
    List<SessionInputTemplate> templates,
  ) async {
    final normalized = templates
        .where(
          (item) =>
              item.id.trim().isNotEmpty &&
              item.label.trim().isNotEmpty &&
              item.content.trim().isNotEmpty,
        )
        .map(
          (item) => item.copyWith(
            id: item.id.trim(),
            label: item.label.trim(),
            content: item.content.trim(),
          ),
        )
        .toList(growable: false);
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(
        normalized.map((item) => item.toJson()).toList(growable: false),
      ),
    );
    return normalized;
  }

  Future<List<SessionInputTemplate>> upsertTemplate(
    SessionInputTemplate template,
  ) async {
    final templates = List<SessionInputTemplate>.from(await loadTemplates());
    final index = templates.indexWhere((item) => item.id == template.id);
    final normalized = template.copyWith(
      id: template.id.trim(),
      label: template.label.trim(),
      content: template.content.trim(),
    );
    if (index >= 0) {
      templates[index] = normalized;
    } else {
      templates.add(normalized);
    }
    return saveTemplates(templates);
  }

  Future<List<SessionInputTemplate>> deleteTemplate(String id) async {
    final templates = List<SessionInputTemplate>.from(await loadTemplates());
    templates.removeWhere((item) => item.id == id);
    return saveTemplates(templates);
  }

  SessionInputTemplate createTemplate({
    required String label,
    required String content,
  }) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return SessionInputTemplate(
      id: 'tpl_$timestamp',
      label: label.trim(),
      content: content.trim(),
    );
  }
}
