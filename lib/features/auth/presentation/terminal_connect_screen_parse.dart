part of 'terminal_connect_screen.dart';

bool _previewLinkImpl(
  _TerminalConnectScreenState state, {
  bool showError = true,
}) {
  final rawValue = _extractPublicKeyValue(state._linkController.text);
  if (rawValue == null || rawValue.isEmpty) {
    return _setPreviewError(state, showError);
  }

  try {
    _decodeBase64Flexible(rawValue);
  } catch (_) {
    return _setPreviewError(state, showError);
  }

  final preview = rawValue.length > 24
      ? '${rawValue.substring(0, 12)}...${rawValue.substring(rawValue.length - 12)}'
      : rawValue;
  state._updateView(() {
    state._errorMessage = null;
    state._parsedLink = state._linkController.text.trim();
    state._publicKeyPreview = preview;
  });
  return true;
}

bool _setPreviewError(
  _TerminalConnectScreenState state,
  bool showError,
) {
  if (showError) {
    state._updateView(() {
      state._errorMessage = '电脑端授权链接格式不正确';
      state._parsedLink = null;
      state._publicKeyPreview = null;
    });
  }
  return false;
}

String? _extractPublicKeyValue(String input) {
  final cleaned = input.trim();
  if (cleaned.isEmpty) {
    return null;
  }
  if (!cleaned.startsWith('happy://terminal?')) {
    return cleaned;
  }

  final uri = Uri.tryParse(cleaned);
  if (uri == null) {
    return cleaned.substring('happy://terminal?'.length);
  }

  final publicKey = uri.queryParameters['publicKey'] ??
      uri.queryParameters['key'] ??
      uri.queryParameters['token'];
  if (publicKey != null && publicKey.isNotEmpty) {
    return publicKey;
  }
  if (uri.queryParameters.length == 1) {
    final entry = uri.queryParameters.entries.first;
    if (entry.value.isEmpty && entry.key.isNotEmpty) {
      return entry.key;
    }
  }
  if (uri.query.isNotEmpty) {
    return uri.query;
  }
  return cleaned.substring('happy://terminal?'.length);
}

List<int> _decodeBase64Flexible(String input) {
  var standard = input.trim().replaceAll('-', '+').replaceAll('_', '/');
  while (standard.length % 4 != 0) {
    standard += '=';
  }
  return base64Decode(standard);
}

void _clearInputImpl(_TerminalConnectScreenState state) {
  state._linkController.clear();
  state._updateView(() {
    state._errorMessage = null;
    state._connectFailureMessage = null;
    state._parsedLink = null;
    state._publicKeyPreview = null;
  });
}

void _dismissScreenImpl(_TerminalConnectScreenState state) {
  if (state.context.canPop()) {
    state.context.pop();
    return;
  }
  state.context.go('${AppRoutes.home}?tab=sessions');
}

void _openEntrySheetImpl(_TerminalConnectScreenState state) {
  state._updateView(() {
    state._showEntrySheet = true;
    state._errorMessage = null;
    state._connectFailureMessage = null;
  });
}

void _closeEntrySheetImpl(_TerminalConnectScreenState state) {
  if (state._parsedLink == null) {
    state._dismissScreen();
    return;
  }
  state._updateView(() {
    state._showEntrySheet = false;
    state._errorMessage = null;
  });
}

void _submitEntrySheetImpl(_TerminalConnectScreenState state) {
  if (state._previewLink()) {
    state._updateView(() {
      state._showEntrySheet = false;
    });
  }
}
