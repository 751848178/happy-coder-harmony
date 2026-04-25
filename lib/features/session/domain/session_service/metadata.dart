part of 'session_service.dart';

extension SessionServiceMetadata on SessionServiceNotifier {
  String _resolveSessionTitle({
    required String? path,
    required String? summary,
    required String? name,
    required String? title,
    required String fallback,
  }) {
    for (final candidate in [summary, name, title]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    if (path != null && path.trim().isNotEmpty) {
      final segments = path.split('/').where((segment) => segment.isNotEmpty);
      if (segments.isNotEmpty) {
        return segments.last;
      }
    }
    return fallback;
  }

  String? _resolveLocalSessionMode({
    required String? preferred,
    required String? explicit,
    required String? metadataValue,
  }) {
    return resolveLocalModeValue(
      preferredValue: preferred,
      explicitValue: explicit,
      metadataValue: metadataValue,
    );
  }

  String? _normalizeOptionalValue(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> _buildOutboundRawRecord({
    required Session session,
    required String text,
    Map<String, dynamic>? metadata,
  }) {
    final modeMeta = _resolveMessageModeMeta(session);
    return {
      'role': 'user',
      'content': {'type': 'text', 'text': text},
      'meta': {
        'sentFrom': _resolveSentFrom(),
        'permissionMode': modeMeta.$1,
        'model': modeMeta.$2,
        'fallbackModel': null,
        ...?metadata,
      },
    };
  }

  (String, String?) _resolveMessageModeMeta(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    final sandbox = _asStringMap(metadata['sandbox']);
    final sandboxEnabled = sandbox?['enabled'] == true;
    final resolvedPermissionMode = _normalizeOptionalValue(
      session.permissionMode,
    );
    final permissionMode =
        resolvedPermissionMode != null && resolvedPermissionMode != 'default'
            ? resolvedPermissionMode
            : (sandboxEnabled ? 'bypassPermissions' : 'default');
    final resolvedModelMode = _normalizeOptionalValue(session.modelMode);
    final modelMode =
        resolvedModelMode != null && resolvedModelMode != 'default'
            ? resolvedModelMode
            : null;
    return (permissionMode, modelMode);
  }

  String? _resolveSessionDraft({
    required String? remoteDraft,
    required String? cachedDraft,
  }) {
    return _normalizeOptionalValue(remoteDraft) ??
        _normalizeOptionalValue(cachedDraft);
  }

  String _resolveSentFrom() {
    if (kIsWeb) {
      return 'web';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return 'mac';
    }
    return 'android';
  }
}
