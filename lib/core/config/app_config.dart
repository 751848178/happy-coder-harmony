import 'server_config_service.dart';

/// App 配置
///
/// 应用配置常量
class AppConfig {
  AppConfig._();

  /// 服务器地址
  static const String defaultServerUrl = ServerConfigService.defaultServerUrl;
  static const String builtInSvtonServerUrl =
      ServerConfigService.svtonServerUrl;

  static String get serverUrl => ServerConfigService.instance.serverUrl;

  /// Socket.IO 服务器地址
  ///
  /// Explicitly includes the default port so that socket_io_client
  /// (which constructs wss:// URLs) avoids Dart's Uri.port returning 0
  /// for unrecognised schemes like wss://.
  static String get socketUrl {
    final uri = Uri.parse(serverUrl);
    final hasExplicitPort = uri.hasPort && uri.port > 0;
    if (hasExplicitPort) return serverUrl;
    final defaultPort = uri.scheme == 'https' ? 443 : 80;
    return '${uri.scheme}://${uri.host}:$defaultPort';
  }

  /// Socket.IO 路径
  static const String socketPath = '/v1/updates';

  /// API 版本
  static const String apiVersion = 'v1';

  /// 应用名称
  static const String appName = 'Hapmony';

  /// 应用副标题
  static const String appTagline = 'Happy for HarmonyOS';

  /// 应用描述
  static const String appDescription = '为 HarmonyOS 打造的智能开发助手';

  /// 助手默认名称
  static const String assistantName = 'Hapmony 助手';

  /// 应用版本
  static const String appVersion = '1.0.0';

  /// User Agent
  static const String userAgent = 'Happy-Flutter/$appVersion';

  /// WebSocket 传输协议
  static const List<String> socketTransports = ['websocket'];

  /// HTTP 连接超时 (毫秒)
  static const int connectTimeout = 10000;

  /// Socket.IO 连接超时 (毫秒)
  static const int socketTimeout = 15000;

  /// Socket.IO 重连延迟 (毫秒)
  static const int socketReconnectDelay = 5000;

  /// 消息去重窗口 (毫秒)
  static const int deduplicationWindow = 5000;

  /// 默认每页消息数
  static const int defaultPageSize = 50;

  /// 最大本地存储消息数
  static const int maxLocalMessages = 1000;

  /// 会话心跳间隔 (秒)
  /// API 基础地址
  static String get apiBaseUrl => serverUrl;

  static const int sessionHeartbeatInterval = 30;

  /// 空闲会话超时 (秒)
  static const int idleSessionTimeout = 300; // 5 分钟

  /// LiveKit 服务器地址 (用于实时语音)
  static String get livekitUrl => String.fromEnvironment(
        'LIVEKIT_URL',
        defaultValue: 'wss://livekit.happy.engineering',
      );

  /// ElevenLabs API 地址
  static String get elevenLabsUrl => String.fromEnvironment(
        'ELEVENLABS_URL',
        defaultValue: 'https://api.elevenlabs.io',
      );

  /// Log 级别: debug, info, warning, error, none
  static LogLevel logLevel = LogLevel.debug;

  /// 是否启用遥测
  static const bool telemetryEnabled = true;

  /// PostHog API Key (生产环境)
  static const String? postHogKey = String.fromEnvironment('POSTHOG_KEY');

  /// PostHog Host (用于中国区)
  static const String? postHogHost = String.fromEnvironment('POSTHOG_HOST');
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
  none,
}
