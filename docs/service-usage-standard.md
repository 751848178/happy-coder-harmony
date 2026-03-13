# Service 使用规范 Skill

## Skill 信息

- **名称**: `service-usage-standard`
- **版本**: `1.0.0`
- **描述**: 统一和规范化服务接口使用方式
- **分类**: 开发规范
- **适用服务**: @svton/service、通用 API 服务、WebSocket 连接

## 适用范围

本规范适用于以下服务场景：

| 服务类型 | 适用范围 |
|---------|---------|
| API 调用 | RESTful API、GraphQL、WebSocket |
| 状态管理 | Provider、Bloc、Riverpod |
| 数据存储 | 本地数据库、缓存层 |
| 错误处理 | 统一异常捕获和上报 |
| 日志记录 | 结构化日志输出 |
| 实时通信 | Socket.IO、WebSocket 长连接 |

---

## 核心原则

### 1. 单一职责原则 (SRP)

每个服务应该只负责一个明确的功能领域：

```
✅ 推荐: UserService → 只负责用户相关操作
✅ 推荐: ChatService → 只负责会话管理
✅ 推荐: FileService → 只负责文件操作
❌ 避免: ChatService → 直接处理文件保存逻辑
```

### 2. 接口设计原则

| 原则 | 说明 |
|------|------|
| RESTful | 使用标准 HTTP 方法和状态码 |
| 命名规范 | 使用小写 + 下划线（如 `get_user_info`） |
| 响应统一 | 统一使用 `ApiResponse<T>` 包装 |
| 错误统一 | 统一使用 `ServiceException` 处理 |

### 3. 错误处理规范

```dart
/// 统一 API 响应模型
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? code;
  final Map<String, dynamic>? meta;

  const ApiResponse.success(this.data)
      : success = true,
        data = data;

  const ApiResponse.failure(this.message, {this.code, this.meta})
      : success = false,
        message = message,
        code = code,
        meta = meta;
}

/// 统一服务异常
class ServiceException implements Exception {
  final String message;
  final int? code;
  final dynamic details;

  ServiceException(this.message, {this.code, this.details});

  factory ServiceException.fromApiError(ApiResponse response) {
    return ServiceException(
      response.message ?? 'Unknown error',
      code: response.code,
    );
  }
}
```

### 4. 日志规范

```dart
/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// 统一日志服务
class Logger {
  static const _tag = 'HappyCoder';

  static void debug(String message) {
    log(LogLevel.debug, message);
  }

  static void info(String message) {
    log(LogLevel.info, message);
  }

  static void warning(String message) {
    log(LogLevel.warning, message);
  }

  static void error(String message, [Object? error]) {
    log(LogLevel.error, message, error: error);
  }

  static void critical(String message, [Object? error]) {
    log(LogLevel.critical, message, error: error);
  }

  static void log(LogLevel level, String message, {Object? error}) {
    // 实现日志输出
  }
}
```

---

## 命名规范

### 服务命名

| 类型 | 格式 | 示例 |
|------|------|------|
| 服务类 | `XxxService` | `UserService`, `ChatService` |
| 数据模型 | `Xxx` | `User`, `Message` |
| 仓库类 | `XxxRepository` | `UserRepository`, `ChatRepository` |
| Provider | `xxxProvider` | `userProvider`, `chatProvider` |

### API 端点命名

| 类型 | 格式 | 示例 |
|------|------|------|
| 用户信息 | `/api/v1/user/info` | `getUserInfo()` |
| 会话列表 | `/api/v1/sessions` | `getSessions()` |
| 发送消息 | `/api/v1/messages` | `sendMessage()` |

---

## Service 层架构

### 基础服务模板

```dart
/// 基础服务抽象类
abstract class BaseService {
  final String baseUrl;
  final Dio client;
  final Logger logger;

  BaseService(this.baseUrl, this.client, this.logger);

  /// GET 请求
  Future<ApiResponse<T>> get<T>(String path) async {
    try {
      final response = await client.get('$baseUrl$path');
      return _handleResponse<T>(response);
    } catch (e) {
      logger.error('GET $path failed', e);
      throw ServiceException.fromError(e);
    }
  }

  /// POST 请求
  Future<ApiResponse<T>> post<T>(String path, dynamic data) async {
    try {
      final response = await client.post('$baseUrl$path', data: data);
      return _handleResponse<T>(response);
    } catch (e) {
      logger.error('POST $path failed', e);
      throw ServiceException.fromError(e);
    }
  }

  /// 处理响应
  ApiResponse<T> _handleResponse<T>(Response response) {
    // 统一处理逻辑
  }
}

/// 具体服务实现
class UserService extends BaseService {
  UserService(Dio client, Logger logger)
      : super('/api/v1', client, logger);

  /// 获取用户信息
  Future<ApiResponse<User>> getUserInfo(String userId) async {
    return get<User>('/user/$userId');
  }

  /// 更新用户信息
  Future<ApiResponse<void>> updateUser(String userId, Map<String, dynamic> data) async {
    return post<void>('/user/$userId', data);
  }
}
```

---

## Provider 使用规范

### Provider 命名和职责

| Provider | 状态 | 管理范围 |
|---------|--------|----------|
| `userProvider` | 读写 | 用户认证状态、基本信息 |
| `chatProvider` | 读写 | 当前会话、消息列表 |
| `settingsProvider` | 读写 | 用户设置、偏好 |
| `networkProvider` | 只读 | 网络状态、连接信息 |

### Provider 状态模型

```dart
/// 用户状态
class UserState {
  final User? currentUser;
  final bool isLoading;
  final String? errorMessage;

  const UserState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
  });
}

/// 会话状态
class ChatState {
  final List<Session> sessions;
  final Session? currentSession;
  final List<Message> messages;
  final bool isLoading;

  const ChatState({
    this.sessions = const [],
    this.currentSession,
    this.messages = const [],
    this.isLoading = false,
  });
}
```

---

## 缓存策略

### 缓存层级

| 层级 | 说明 | 过期时间 |
|------|------|--------|
| 内存缓存 | 使用 Map 存储热数据 | 30 分钟 |
| 本地存储 | 使用 hive 持久化数据 | 永久 |
| 网络缓存 | Dio 的 ResponseCache | 5 分钟 |

### 缓存键命名

```dart
/// 缓存键常量
class CacheKeys {
  static const String userToken = 'user_token';
  static const String userInfo = 'user_info';
  static const String sessions = 'sessions_list';
  static const String messages = 'messages_{session_id}';
  static const String settings = 'user_settings';
}
```

---

## 检查清单

在使用服务时，确保满足以下规范：

### 代码检查

- [ ] 服务类继承自 `BaseService`
- [ ] 使用统一 `ApiResponse<T>` 响应模型
- [ ] 异常统一使用 `ServiceException`
- [ ] 日志使用统一 `Logger` 服务
- [ ] Provider 命名遵循规范（xxxProvider）

### 功能检查

- [ ] GET/POST/PUT/DELETE 使用正确方法
- [ ] 请求包含必要的认证头
- [ ] 超时正确重试
- [ ] 缓存策略一致

### 文档检查

- [ ] API 文档已更新
- [ ] 错误码文档已维护
- [ ] 变更日志已记录
- [ ] 示例代码已同步

---

## 工具函数

```dart
/// 服务工具类
class ServiceUtils {
  /// 检查网络连接
  static Future<bool> hasNetworkConnection() async {
    // 实现
  }

  /// 格式化错误消息
  static String formatErrorMessage(dynamic error) {
    if (error is ServiceException) {
      return error.message;
    }
    // 其他处理
    return 'Unknown error';
  }

  /// 获取认证 Token
  static Future<String?> getAuthToken() async {
    // 实现
  }
}
```

---

## 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| 1.0.0 | 2026-03-01 | 初始版本 |
| 1.1.0 | - | - |

---

**文档版本**: 1.0.0
**最后更新**: 2026-03-04
**维护者**: Happy Coder Team

### 功能检查
- [ ] 服务类继承自 `BaseService`
- [ ] 使用统一 `ApiResponse<T>` 响应
- [ ] 异常统一使用 `ServiceException`
- [ ] 日志使用统一 `Logger` 服务
- [ ] Provider 命名遵循规范（xxxProvider）

### 功能检查
- [ ] GET/POST/PUT/DELETE 使用正确方法
- [ ] 请求包含必要的认证头
- [ ] 超时正确重试
- [ ] 缓存策略一致

### 文档检查
- [ ] API 文档已更新
- [ ] 错误码文档已维护
- [ ] 变更日志已记录
- [ ] 示例代码已同步

---

## WebSocket 连接规范

### 连接生命周期

```dart
class WebSocketService {
  final SocketIO socket;
  final Logger logger;
  bool _isConnected = false;

  WebSocketService(this.url, this.logger);

  /// 建立连接
  Future<void> connect() async {
    try {
      socket = await IO.io(url);
      _isConnected = true;
      socket.onConnect((_) {
        logger.info('WebSocket connected');
      });
      socket.onDisconnect((_) {
        logger.warning('WebSocket disconnected');
        _isConnected = false;
      });
      socket.onError((error) {
        logger.error('WebSocket error', error);
      });
    } catch (e) {
      logger.error('WebSocket connection failed', e);
      throw ServiceException('Connection failed');
    }
  }

  /// 发送消息
  void emit(String event, dynamic data) {
    if (!_isConnected) {
      logger.warning('WebSocket not connected, queuing message');
      return;
    }
    socket.emit(event, data);
  }

  /// 接收消息
  void on(String event, Function(dynamic) handler) {
    socket.on(event, (data) {
      handler(data);
    });
  }

  /// 断开连接
  void disconnect() {
    socket.disconnect();
    _isConnected = false;
  }
}
```

### 消息格式规范

| 字段 | 类型 | 必填 | 说明 |
|------|------|--------|------|
| `event` | String | ✅ | 事件名称 |
| `data` | dynamic | ✅ | 消息数据 |
| `sessionId` | String | ✅ | 会话标识 |
| `timestamp` | int | ✅ | 时间戳 |
| `userId` | String | ✅ | 用户标识 |
| `messageId` | String | - | 消息 ID（可选） |

### 事件类型

```dart
/// 事件类型
enum SocketEvent {
  connect,           // 连接建立
  disconnect,        // 连接断开
  message,          // 消息
  typing,           // 正在输入
  status,          // 状态更新
  error,            // 错误
  toolCall,         // 工具调用
  toolResponse,     // 工具响应
}
```

### 重连策略

```dart
/// 重连配置
class ReconnectConfig {
  final int maxRetries;        // 最大重试次数
  final Duration retryDelay;  // 重试延迟
  final Duration timeout;      // 连接超时
  final bool enableAutoReconnect; // 是否自动重连

  const ReconnectConfig({
    this.maxRetries = 5,
    this.retryDelay = const Duration(seconds: 2),
    this.timeout = const Duration(seconds: 10),
    this.enableAutoReconnect = true,
  });
}

/// 带重连的 WebSocket 服务
class ReconnectableWebSocketService extends WebSocketService {
  int _retryCount = 0;

  @override
  Future<void> connect() async {
    return super.connect().catchError((e) async {
      if (_retryCount < config.maxRetries && config.enableAutoReconnect) {
        _retryCount++;
        logger.info('Reconnecting... (${_retryCount}/${config.maxRetries})');
        await Future.delayed(config.retryDelay);
        return super.connect();
      }
      _retryCount = 0;
      throw e; // 重试失败
    });
  }
}
```
### 文档检查
- [ ] API 文档已更新
- [ ] 错误码文档已维护
- [ ] 变更日志已记录
- [ ] 示例代码已同步

---

## 工具函数

```dart
/// 服务工具类
class ServiceUtils {
  /// 检查网络连接
  static Future<bool> hasNetworkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// 格式化错误消息
  static String formatErrorMessage(dynamic error) {
    if (error is ServiceException) {
      return error.message;
    }
    // 其他处理
    return 'Unknown error';
  }

  /// 获取认证 Token
  static Future<String?> getAuthToken() async {
    final secureStorage = await SecureStorage();
    return await secureStorage.read(key: 'auth_token');
  }

  /// 保存认证 Token
  static Future<void> saveAuthToken(String token) async {
    final secureStorage = await SecureStorage();
    await secureStorage.write(key: 'auth_token', value: token);
  }
}
```

---

## 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| 1.0.0 | 2026-03-04 | 初始版本 |
| 1.1.0 | - | 添加 WebSocket 连接规范 |

---

**文档版本**: 1.1.0
**最后更新**: 2026-03-04
**维护者**: Happy Coder Team
