part of 'session_screen.dart';

extension _SessionScreenViewMetadata on _SessionScreenState {
  String _resolveHeaderTitle(Session? session) {
    if (session == null) {
      return '未命名会话';
    }
    final path = session.metadata?['path']?.toString() ?? session.path;
    if (path != null && path.isNotEmpty) {
      final parts = path.split('/').where((item) => item.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        return parts.last;
      }
    }
    if (session.title.isNotEmpty) {
      return session.title;
    }
    return '未命名会话';
  }

  String _formatPathForDisplay(String path, String? homeDir) {
    if (path.isEmpty) {
      return '';
    }
    if (homeDir == null || homeDir.isEmpty) {
      return path;
    }
    if (path == homeDir) {
      return '~';
    }
    if (path.startsWith('$homeDir/')) {
      return '~${path.substring(homeDir.length)}';
    }
    return path;
  }

  String _resolveFlavorLabel(String? flavor) {
    switch (flavor) {
      case 'claude':
        return 'Claude Code';
      case 'codex':
        return 'Codex';
      case 'gemini':
        return 'Gemini';
      case null:
      case '':
        return AppConfig.assistantName;
      default:
        return flavor;
    }
  }

  List<_ModeOption> _permissionOptionsFor(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    return permissionOptionsForAgent(
      metadata['flavor']?.toString(),
      metadataOptions: metadata['operatingModes'],
    ).map(_ModeOption.fromSessionModeOption).toList();
  }

  List<_ModeOption> _modelOptionsFor(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    return modelOptionsForAgent(
      metadata['flavor']?.toString(),
      metadataOptions: metadata['models'],
    ).map(_ModeOption.fromSessionModeOption).toList();
  }

  _ModeOption _resolveCurrentPermissionOption(Session session) {
    final options = _permissionOptionsFor(session);
    final currentKey =
        session.metadata?['currentOperatingModeCode']?.toString() ??
            session.permissionMode ??
            'default';
    return options.firstWhere(
      (option) => option.key == currentKey,
      orElse: () => options.first,
    );
  }

  _ModeOption _resolveCurrentModelOption(Session session) {
    final options = _modelOptionsFor(session);
    final metadata = session.metadata ?? const <String, dynamic>{};
    final currentKey = metadata['currentModelCode']?.toString() ??
        session.modelMode ??
        options.first.key;
    return options.firstWhere(
      (option) => option.key == currentKey,
      orElse: () => options.first,
    );
  }

  void _showModelDialog(Session session) {
    final options = _modelOptionsFor(session);
    final current = _resolveCurrentModelOption(session);
    _showModeSheet(
      title: '模型设置',
      options: options,
      current: current,
      onSelected: (option) {
        ref.read(sessionStateProvider.notifier).updateModelMode(
              widget.sessionId,
              option.key,
            );
        Navigator.pop(context);
      },
    );
  }
}
