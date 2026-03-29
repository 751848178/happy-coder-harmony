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

  List<SessionModeOption> _permissionOptionSourcesFor(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    return permissionOptionsForAgent(
      metadata['flavor']?.toString(),
      metadataOptions: metadata['operatingModes'],
    );
  }

  List<_ModeOption> _permissionOptionsFor(Session session) {
    return _permissionOptionSourcesFor(session)
        .map(_ModeOption.fromSessionModeOption)
        .toList(growable: false);
  }

  List<SessionModeOption> _modelOptionSourcesFor(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    return modelOptionsForAgent(
      metadata['flavor']?.toString(),
      metadataOptions: metadata['models'],
    );
  }

  List<_ModeOption> _modelOptionsFor(Session session) {
    return _modelOptionSourcesFor(session)
        .map(_ModeOption.fromSessionModeOption)
        .toList(growable: false);
  }

  List<String?> _currentPermissionKeys(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    final flavor = metadata['flavor']?.toString();
    return <String?>[
      session.permissionMode,
      metadata['currentOperatingModeCode']?.toString(),
      defaultPermissionModeForAgent(flavor),
    ];
  }

  String? _currentExplicitPermissionKey(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    return resolveModeKey(<String?>[
      session.permissionMode,
      metadata['currentOperatingModeCode']?.toString(),
    ]);
  }

  List<String?> _currentModelKeys(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    final flavor = metadata['flavor']?.toString();
    return <String?>[
      session.modelMode,
      metadata['currentModelCode']?.toString(),
      defaultModelModeForAgent(flavor),
    ];
  }

  String? _currentExplicitModelKey(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    return resolveModeKey(<String?>[
      session.modelMode,
      metadata['currentModelCode']?.toString(),
    ]);
  }

  _ModeOption? _resolveCurrentPermissionOption(Session session) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    final option = findPreferredListedModeOption(
      _permissionOptionSourcesFor(session),
      _currentPermissionKeys(session),
    );
    return option == null ? null : _ModeOption.fromSessionModeOption(option);
  }

  _ModeOption? _resolveCurrentModelOption(Session session) {
    final option = findPreferredListedModeOption(
      _modelOptionSourcesFor(session),
      _currentModelKeys(session),
    );
    return option == null ? null : _ModeOption.fromSessionModeOption(option);
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
