part of '../session_detail.dart';

extension _SessionScreenViewMetadata on _SessionScreenState {
  Map<String, dynamic>? _readModeMetadataForSession(Session session) =>
      session.metadata;

  Map<String, dynamic>? _watchModeMetadataForSession(Session session) {
    return ref.watch(
      sessionStateProvider.select(
        (state) => state.whenOrNull<Map<String, dynamic>?>(
          ready: (sessions, _, machines) {
            final currentSession = sessions[session.id] ?? session;
            return currentSession.metadata;
          },
        ),
      ),
    );
  }

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

  List<SessionModeOption> _permissionOptionSourcesFor(
    Session session, {
    Map<String, dynamic>? modeMetadata,
  }) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    final resolvedModeMetadata =
        modeMetadata ?? _readModeMetadataForSession(session);
    return permissionOptionsForAgent(
      metadata['flavor']?.toString(),
      metadataOptions: resolvedModeMetadata?['operatingModes'],
    );
  }

  List<_ModeOption> _permissionOptionsFor(
    Session session, {
    Map<String, dynamic>? modeMetadata,
  }) {
    return _permissionOptionSourcesFor(
      session,
      modeMetadata: modeMetadata,
    ).map(_ModeOption.fromSessionModeOption).toList(growable: false);
  }

  List<SessionModeOption> _modelOptionSourcesFor(
    Session session, {
    Map<String, dynamic>? modeMetadata,
  }) {
    final metadata = session.metadata ?? const <String, dynamic>{};
    final resolvedModeMetadata =
        modeMetadata ?? _readModeMetadataForSession(session);
    return modelOptionsForAgent(
      metadata['flavor']?.toString(),
      metadataOptions: resolvedModeMetadata?['models'],
    );
  }

  List<_ModeOption> _modelOptionsFor(
    Session session, {
    Map<String, dynamic>? modeMetadata,
  }) {
    return _modelOptionSourcesFor(
      session,
      modeMetadata: modeMetadata,
    ).map(_ModeOption.fromSessionModeOption).toList(growable: false);
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

  String _displayModelKeyLabel(String? explicitKey) {
    if (explicitKey == null || explicitKey.isEmpty) {
      return '未设置';
    }
    if (explicitKey == 'default') {
      return '默认';
    }
    return explicitKey;
  }

  _ModeOption? _resolveCurrentPermissionOption(
    Session session, {
    Map<String, dynamic>? modeMetadata,
  }) {
    final option = findPreferredListedModeOption(
      _permissionOptionSourcesFor(
        session,
        modeMetadata: modeMetadata,
      ),
      _currentPermissionKeys(session),
    );
    return option == null ? null : _ModeOption.fromSessionModeOption(option);
  }

  _ModeOption? _resolveCurrentModelOption(
    Session session, {
    Map<String, dynamic>? modeMetadata,
  }) {
    final option = findPreferredListedModeOption(
      _modelOptionSourcesFor(
        session,
        modeMetadata: modeMetadata,
      ),
      _currentModelKeys(session),
    );
    return option == null ? null : _ModeOption.fromSessionModeOption(option);
  }

  void _showModelDialog(Session session) {
    final modeMetadata = _readModeMetadataForSession(session);
    final options = _modelOptionsFor(
      session,
      modeMetadata: modeMetadata,
    );
    if (options.isEmpty) {
      _showEmptyModelSheet();
      return;
    }
    final current = _resolveCurrentModelOption(
      session,
      modeMetadata: modeMetadata,
    );
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

  void _showEmptyModelSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '模型设置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Expanded(
                      child: Center(
                        child: Text(
                          '当前会话暂无可用模型选项',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
