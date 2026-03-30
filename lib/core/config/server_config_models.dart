class ServerProbeResult {
  const ServerProbeResult({
    required this.ok,
    required this.supportsTerminalAuth,
    this.errorMessage,
  });

  final bool ok;
  final bool supportsTerminalAuth;
  final String? errorMessage;
}

class BuiltInServerOption {
  const BuiltInServerOption({
    required this.id,
    required this.name,
    required this.url,
    required this.description,
  });

  final String id;
  final String name;
  final String url;
  final String description;
}

class ServerConfigSnapshot {
  const ServerConfigSnapshot({
    required this.selectedServerId,
    this.customServerUrl,
  });

  final String selectedServerId;
  final String? customServerUrl;
}
