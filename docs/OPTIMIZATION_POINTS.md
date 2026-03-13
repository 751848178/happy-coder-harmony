# Happy Coder Flutter 优化点文档

> 本文档整理了 Happy Coder Flutter 项目的所有优化点及解决方案，包括性能、功能、UI/UX 三个维度。

---

## 📋 目录

- [一、性能体验优化](#一性能体验优化)
- [二、功能增强](#二功能增强)
- [三、UI/UX 优化](#三uiux-优化)
- [四、优先级汇总](#四优先级汇总)
- [五、关键代码位置索引](#五关键代码位置索引)
- [六、服务器优化说明](#六服务器优化说明)

---

## 一、性能体验优化

### 1. 中间态展示优化

**问题描述：**
- 发消息、连接设备、加载会话列表的中间态持续短
- 中间态结束后还有一段时间无响应
- 用户不清楚当前操作的真实状态

**问题根因：**

```dart
// socket_repository.dart:92-100
enum SocketState { disconnected, connected } // 缺少中间状态

// session_service.dart:656-717
// 发送消息缺少持续的状态展示

// session_service.dart:206-357
// loading 状态只在无缓存时设置
```

**解决方案：**

```dart
// 1. 扩展 Socket 连接状态
enum SocketConnectionState {
  disconnected,
  connecting,      // 正在连接
  connected,
  reconnecting,
  authenticating,   // 认证中
  ready,          // 完全就绪
  error,
}

// 2. 消息发送状态管理
enum MessageSendingState {
  pending,      // 待发送
  sending,      // 发送中
  sent,         // 已发送
  failed,       // 发送失败
}

// 3. UI 状态指示器
Widget _buildMessageStatus(MessageSendingState state) {
  switch (state) {
    case MessageSendingState.sending:
      return const SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    case MessageSendingState.failed:
      return const Icon(Icons.error_outline, size: 16, color: Colors.red);
    case MessageSendingState.sent:
      return const Icon(Icons.done_all, size: 16, color: Colors.grey);
    default:
      return const SizedBox.shrink();
  }
}
```

---

### 2. 设备连接速度优化

**问题描述：**
- 打开后连接设备慢，响应时间长（13-35秒）

**问题根因分析：**

| 环节 | 耗时 | 原因 |
|------|------|------|
| Socket 建立 | 2-5s | 网络延迟 + TLS 握手 |
| Socket 认证 | 1-3s | 服务器验证 token |
| 加载会话列表 | 3-8s | HTTP 请求 + 多次解密 |
| 加载机器列表 | 2-4s | 额外 HTTP 请求 |
| 预热消息 | 5-15s | 每个会话分页加载 |
| **总计** | **13-35s** | **串行执行** |

```dart
// terminal_connect_screen.dart:178-192 - 串行执行问题
await ref.read(socketStateProvider.notifier).initialize(...);
await ref.read(sessionStateProvider.notifier).loadSessions();
```

**解决方案：**

```dart
// 1. 并行执行连接后初始化
Future<void> _prepareConnectedState() async {
  final results = await Future.wait([
    ref.read(socketStateProvider.notifier).initialize(...),
  ]);

  // 连接完成后并行加载
  await Future.wait([
    ref.read(sessionStateProvider.notifier).loadSessions(),
    ref.read(sessionStateProvider.notifier).loadMachines(),
  ]);
}

// 2. 减少预热会话数量
Future<void> _warmSessionPreviewData(List<Session> sessions) async {
  final previewSessions = sessions.take(3); // 从 8 减到 3
  for (final session in previewSessions) {
    await loadSessionMessages(session.id);
  }
}

// 3. 缓存优先策略
Future<void> loadSessions({bool force = false}) async {
  // 先显示缓存
  final cachedSessions = await _restoreCachedSessions();
  _repository.applySessions(cachedSessions);
  _emitReadyState(); // 先显示

  // 后台刷新
  unawaited(_refreshSessionsInBackground());
}

// 4. 使用 Worker Isolate 进行解密
Future<List<Session>> _decryptSessionsInIsolate(
  List<Map<String, dynamic>> encryptedItems,
) async {
  return await compute(_decryptSessionsWorker, encryptedItems);
}
```

**优化后预期：**
- 连接时间：13-35s → **5-10s**
- 用户感知：先显示缓存内容，后台刷新

---

### 3. 服务器地域优化

**问题描述：**
- 连接慢可能与服务器地域有关

**分析结果：**

| 配置项 | 值 | 位置 |
|--------|-----|------|
| 默认 API 服务器 | `https://api.cluster-fluster.com` | 海外 |
| LiveKit (语音) | `wss://livekit.happy.engineering` | 海外 |
| 中国大陆预期延迟 | **200-500ms** | - |
| 香港/新加坡预期延迟 | **50-150ms** | - |

**解决方案：**

**选项 1: 使用自部署服务器（推荐）**
- 在国内或香港、新加坡部署 Happy Server
- 参见 [六、服务器部署说明](#六服务器部署说明)

**选项 2: 优化客户端超时配置**
```dart
// app_config.dart
static const int socketTimeout = 15000;  // 从 30s 减到 15s
static const int connectTimeout = 10000;  // 添加连接超时
```

**选项 3: 添加 CDN 加速**
- 在 Cloudflare 配置 DNS 加速
- 启用自动地理路由

---

## 二、功能增强

### 4. 多设备连接支持

**问题描述：**
- 当前仅支持单个设备连接
- 无法在多台设备间切换查看

**问题根因：**

```dart
// socket_repository.dart:41-43
static final SocketRepository instance = SocketRepository._();
io.Socket? _socket;      // 单一 Socket
String? _token;           // 单 token

// session_repository.dart:15-22
final Map<String, Session> _sessions = {};      // 单一 Map
```

**解决方案：**

```dart
// 1. 扩展凭证存储
class MultiDeviceCredentials {
  final Map<String, DeviceCredential> devices;  // machineId -> Credential
  final String? currentDeviceId;
}

class DeviceCredential {
  final String machineId;
  final String token;
  final String name;
  final bool isOnline;
  final DateTime lastConnectedAt;
}

// 2. 多 Socket 管理器
class MultiSocketManager {
  final Map<String, io.Socket> _sockets = {};
  final Map<String, DeviceConnectionState> _states = {};

  Future<void> connectDevice(String machineId, String token) async {
    if (_sockets.containsKey(machineId)) {
      return; // 已连接
    }
    // 创建新的 Socket 连接
    _sockets[machineId] = io.io(
      AppConfig.socketUrl,
      OptionBuilder()
        .setPath(AppConfig.socketPath)
        .setTransports(AppConfig.socketTransports)
        .setAuth({
          'token': token,
        })
        .build(),
    );
  }

  void disconnectDevice(String machineId) {
    _sockets[machineId]?.disconnect();
    _sockets.remove(machineId);
  }

  io.Socket? getSocket(String machineId) => _sockets[machineId];
  bool isConnected(String machineId) => _sockets.containsKey(machineId);
}

// 3. 会话按设备分组
class GroupedSessionRepository {
  final Map<String, Map<String, Session>> _sessionsByDevice = {};

  List<Session> getSessionsForDevice(String deviceId) {
    return _sessionsByDevice[deviceId]?.values.toList() ?? [];
  }

  void addSession(String deviceId, Session session) {
    _sessionsByDevice.putIfAbsent(deviceId, () => {});
    _sessionsByDevice[deviceId]![session.id] = session;
  }
}

// 4. UI 改造
// ┌─────────────────────────────────────────┐
// │  我的设备 [+ 添加设备]                │
// ├─────────────────────────────────────────┤
// │  🟢 MacBook Pro        活跃           │
// │     ├─ Project A (5 消息)            │
// │     └─ Project B (12 消息)           │
// ├─────────────────────────────────────────┤
// │  🔴 Ubuntu Server      离线            │
// │     ├─ Database Fix (上次: 2天前)      │
// │     └─ API Upgrade (上次: 1周前)       │
// └─────────────────────────────────────────┘
```

**工作评估：** 高（需要架构改造）

---

### 5. 历史对话修复

**问题描述：**
- 历史对话闪一下就只剩下当前连接设备的对话
- 其他设备的对话被错误删除

**问题根因：**

```dart
// session_service.dart:318-323 - 错误的删除逻辑
final staleSessionIds = _repository.sessionsMap.keys
    .where((sessionId) => !sessionsMap.containsKey(sessionId))
    .toList();
for (final staleSessionId in staleSessionIds) {
  await _purgeLocalSession(staleSessionId);  // 直接删除！
}
```

服务器只返回当前设备关联的会话，代码将服务器返回作为"最新会话"，删除了本地存在但服务器不返回的会话（其他设备的历史会话）。

**解决方案：**

```dart
// 1. 添加设备标签到会话 metadata
final metadata = <String, dynamic>{
  'machineId': currentDeviceId,
  'deviceName': deviceName,
  'path': directory,
  // ...
};

// 2. 只删除当前设备的会话
for (final staleId in staleSessionIds) {
  final existing = _repository.getSession(staleId);
  // 只删除属于当前设备的会话
  if (existing?.metadata?['machineId'] == currentDeviceId) {
    await _purgeLocalSession(staleId);
  }
}
```

**文件位置：** `lib/features/session/data/session_repository.dart:318-323`

---

### 6. 消息队列功能

**问题描述：**
- AI 产出过程中用户无法发送新消息
- 发送按钮被禁用

**问题根因：**

```dart
// session_screen.dart:989
onPressed: _isSending ? null : _sendMessage,  // 禁用发送按钮
```

**解决方案：**

```dart
// 1. 创建消息队列服务
class MessageQueue {
  static final MessageQueue instance = MessageQueue._();
  final List<QueuedMessage> _queue = [];
  bool _isProcessing = false;

  bool get canSend => !_isProcessing || _allowQueuing;

  Future<void> enqueue(String sessionId, String content) async {
    if (_isProcessing) {
      _queue.add(QueuedMessage(
        sessionId: sessionId,
        content: content,
        timestamp: DateTime.now(),
      ));
      _showQueuedIndicator();
      return;
    }

    await _processMessage(sessionId, content);
  }

  Future<void> _processMessage(String sessionId, String content) async {
    _isProcessing = true;
    try {
      await sessionService.sendMessage(
        sessionId: sessionId,
        content: content,
      );
    } finally {
      _isProcessing = false;
      _processNext();
    }
  }

  void _processNext() {
    if (_queue.isEmpty) return;
    final next = _queue.removeAt(0);
    _processMessage(next.sessionId, next.content);
  }

  List<QueuedMessage> get queuedMessages => List.unmodifiable(_queue);
}

class QueuedMessage {
  final String sessionId;
  final String content;
  final DateTime timestamp;
}

// 2. 检测 AI 是否在回复
// 在 SessionService 或 Repository 中检测最后一条消息的状态
bool get isAiResponding {
  final lastMessage = _messages.lastOrNull;
  return lastMessage?.metadata?['outputType'] == 'thinking' ||
         lastMessage?.metadata?['outputType'] == 'generating';
}

// 3. UI 显示待发送消息
Widget _buildQueuedMessagesIndicator() {
  final queued = MessageQueue.instance.queuedMessages;
  if (queued.isEmpty) return const SizedBox.shrink();

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.warningColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(
          '${queued.length} 条消息等待发送',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

// 4. 发送消息时使用队列
Future<void> _sendMessage() async {
  final text = _messageController.text.trim();
  if (text.isEmpty) return;

  if (isAiResponding) {
    // 加入队列
    MessageQueue.instance.enqueue(widget.sessionId, text);
  } else {
    // 直接发送
    await ref.read(sessionStateProvider.notifier).sendMessage(
      sessionId: widget.sessionId,
      content: text,
    );
  }

  _messageController.clear();
}
```

---

### 7. 输入模板快捷功能

**问题描述：**
- 缺少常用输入的快速选择
- 重复输入相同的请求格式

**解决方案：**

```dart
// 触发字符：^ (脱字符，不与 AI 编辑器冲突)

// 常用模板定义
const List<InputTemplate> defaultInputTemplates = [
  // 请求类
  InputTemplate(
    id: 'explain_code',
    label: '解释这段代码',
    content: '请解释这段代码的功能和实现方式',
    icon: Icons.lightbulb_outline,
    category: TemplateCategory.explanation,
  ),
  InputTemplate(
    id: 'add_comments',
    label: '添加注释',
    content: '请为这段代码添加清晰的注释',
    icon: Icons.comment_outlined,
    category: TemplateCategory.explanation,
  ),
  // 调试类
  InputTemplate(
    id: 'find_bug',
    label: '查找 Bug',
    content: '请帮我查找这段代码中可能存在的问题',
    icon: Icons.bug_report_outlined,
    category: TemplateCategory.debugging,
  ),
  InputTemplate(
    id: 'explain_error',
    label: '解释错误',
    content: '请帮我分析这个错误的原因和解决方法：\n[粘贴错误信息]',
    icon: Icons.error_outline,
    category: TemplateCategory.debugging,
  ),
  // 重构类
  InputTemplate(
    id: 'optimize',
    label: '性能优化',
    content: '请分析这段代码的性能瓶颈并提供优化建议',
    icon: Icons.speed_outlined,
    category: TemplateCategory.refactoring,
  ),
  InputTemplate(
    id: 'refactor',
    label: '重构代码',
    content: '请帮助我重构这段代码，使其更易读和维护',
    icon: Icons.transform_outlined,
    category: TemplateCategory.refactoring,
  ),
  InputTemplate(
    id: 'suggest_improvement',
    label: '改进建议',
    content: '请对这段代码提供改进建议，包括但不限于结构、命名、逻辑等方面',
    icon: Icons.auto_awesome_outlined,
    category: TemplateCategory.refactoring,
  ),
  // 审查类
  InputTemplate(
    id: 'review_pr',
    label: 'Code Review',
    content: '请帮我进行代码审查，关注：\n1. 潜在 Bug\n2. 性能问题\n3. 最佳实践\n4. 安全问题',
    icon: Icons.rate_review_outlined,
    category: TemplateCategory.review,
  ),
  InputTemplate(
    id: 'write_tests',
    label: '编写测试',
    content: '请为这段代码编写单元测试，覆盖主要场景',
    icon: Icons.science_outlined,
    category: TemplateCategory.review,
  ),
];

enum TemplateCategory {
  request,      // 请求类
  explanation,  // 解释类
  debugging,    // 调试类
  review,       // 审查类
  refactoring,   // 重构类
}

// 使用方式：输入 ^ 唤起模板菜单
```

**UI 效果：**

```
用户输入: ^
          ↓
显示模板菜单:
┌─────────────────────────────────────────────┐
│ 📝 解释这段代码                  ^       │
│    请解释这段代码的功能和实现方式          │
├─────────────────────────────────────────────┤
│ 💬 添加注释                     ^       │
│    请为这段代码添加清晰的注释              │
├─────────────────────────────────────────────┤
│ 🐛 查找 Bug                    ^       │
│    请帮我查找这段代码中可能存在的问题      │
├─────────────────────────────────────────────┤
│ 🚀 性能优化                    ^       │
│    请分析这段代码的性能瓶颈并提供优化建议  │
└─────────────────────────────────────────────┘
```

---

## 三、UI/UX 优化

### 8. 消息滚动行为优化

**问题描述：**
- 用户滚动查看历史消息时，新消息会强制滚动到底部
- 用户体验差，无法安心查看历史内容

**问题根因：**

```dart
// session_screen.dart:113-121
messageReceived: (message) {
  _scheduleMessageRefresh();
  _scrollToBottom();  // 总是滚动到底部！
}
```

**解决方案：**

```dart
// 1. 添加用户滚动追踪
class _SessionScreenState extends ConsumerState<SessionScreen> {
  // 现有变量...
  bool _isUserScrolling = false;
  DateTime? _lastUserScrollTime;

  void _handleScrollMetricsChanged() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final isNearBottom = (position.maxScrollExtent - position.pixels) < 50;

    // 检测用户是否手动滚动
    if (!isNearBottom && position.userScrollDirection != null) {
      _isUserScrolling = true;
      _lastUserScrollTime = DateTime.now();
    }

    if (isNearBottom) {
      _isUserScrolling = false;
    }

    // 原有代码...
  }

  // 2. 修改消息接收处理
  messageReceived: (message) {
    if (message.sessionId == widget.sessionId) {
      _scheduleMessageRefresh();
      // 只在用户未滚动时自动滚动
      if (!_isUserScrolling) {
        _scrollToBottom();
      }
    }
  },

  // 3. 显示"有新消息"提示
  Widget _buildNewMessageIndicator() {
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: ElevatedButton.icon(
        onPressed: _scrollToBottom,
        icon: const Icon(Icons.arrow_downward, size: 16),
        label: const Text('有新消息'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brandColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
```

---

### 9. 展开/收起状态保持

**问题描述：**
- 展开/收起状态在页面刷新后丢失
- 用户需要重新折叠所有内容

**问题根因：**

```dart
// sessions_screen.dart:36-37
final Set<String> _collapsedDefaultGroups = <String>{};  // 仅内存

// session_screen.dart:39-42
final Set<String> _expandedTurnIds = <String>{};      // 仅内存
```

**解决方案：**

```dart
// 1. 扩展 SessionGroupingState
class SessionGroupingState {
  const SessionGroupingState({
    this.useCustomGroups = false,
    this.groups = const <SessionGroup>[],
    this.ungroupedCollapsed = false,
    this.collapsedDefaultGroups = const <String>{}, // 新增
  });

  final bool useCustomGroups;
  final List<SessionGroup> groups;
  final bool ungroupedCollapsed;
  final Set<String> collapsedDefaultGroups; // 新增

  Map<String, dynamic> toJson() {
    return {
      'useCustomGroups': useCustomGroups,
      'groups': groups.map((group) => group.toJson()).toList(),
      'ungroupedCollapsed': ungroupedCollapsed,
      'collapsedDefaultGroups': collapsedDefaultGroups.toList(),
    };
  }

  factory SessionGroupingState.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'];
    final groups = rawGroups is List
        ? rawGroups.map((value) => SessionGroup.fromJson(value)).toList()
        : const <SessionGroup>[];
    return SessionGroupingState(
      useCustomGroups: json['useCustomGroups'] == true,
      groups: groups,
      ungroupedCollapsed: json['ungroupedCollapsed'] == true,
      collapsedDefaultGroups: (json['collapsedDefaultGroups'] as List?)
              ?.cast<String>()
              .toSet() ??
          const <String>{},
    );
  }
}

// 2. 在 SessionGroupingService 中添加方法
Future<SessionGroupingState> toggleDefaultGroupCollapsed(String label) async {
  final state = await load();
  final nextCollapsed = Set<String>.from(state.collapsedDefaultGroups);
  if (nextCollapsed.contains(label)) {
    nextCollapsed.remove(label);
  } else {
    nextCollapsed.add(label);
  }
  final next = state.copyWith(collapsedDefaultGroups: nextCollapsed);
  await _persist(next);
  return next;
}

// 3. SessionsScreen 使用持久化状态
final Set<String> _collapsedDefaultGroups = <String>{};

@override
void initState() {
  super.initState();
  _loadGroupingState().then((state) {
    setState(() {
      _groupingState = state;
      _collapsedDefaultGroups = state.collapsedDefaultGroups;
    });
  });
}

// 4. 会话内折叠状态使用 Hive 持久化
// lib/features/storage/domain/storage_service.dart 添加
Future<void> saveExpandedTurns(String sessionId, Set<String> expandedTurnIds) async {
  final box = await Hive.openBox('session_ui_state');
  await box.put('expanded_turns_$sessionId', expandedTurnIds.toList());
}

Future<Set<String>> loadExpandedTurns(String sessionId) async {
  final box = await Hive.openBox('session_ui_state');
  final list = await box.get('expanded_turns_$sessionId') as List?;
  return list?.cast<String>()?.toSet() ?? <String>{};
}
```

---

### 10. 输入框高度限制

**问题描述：**
- 输入框高度无限制
- 内容过多时占据过多屏幕空间

**问题根因：**

```dart
// session_screen.dart:963
TextField(maxLines: null)  // 无限制
```

**解决方案：**

```dart
// 方案：设置最大行数，超出后滚动
TextField(
  controller: _messageController,
  maxLines: 5,  // 最多 5 行
  minLines: 1,
  scrollPhysics: const ClampingScrollPhysics(),
  decoration: InputDecoration(
    hintText: '向$flavor发送消息...',
    filled: true,
    fillColor: AppTheme.neutral100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppTheme.spacingMd,
      vertical: AppTheme.spacingSm,
    ),
  ),
  keyboardType: TextInputType.multiline,
  textInputAction: settings.agentInputEnterToSend
      ? TextInputAction.send
      : TextInputAction.newline,
  onSubmitted: settings.agentInputEnterToSend
      ? (_) => _sendMessage()
      : null,
)
```

---

### 11. 分组工具栏样式优化

**问题描述：**
- 分组工具栏占位过大
- 在没有会话时也显示

**问题根因：**

```dart
// sessions_screen.dart:203-256
Container(
  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
  child: Wrap(
    children: [
      ChoiceChip(label: const Text('默认分组')),
      ChoiceChip(label: const Text('自定义分组')),
      TextButton.icon(...),
      Text('长按会话可移动到分组'),
    ],
  ),
)
```

**解决方案：**

```dart
// 方案 1: 可折叠的紧凑工具栏
Widget _buildGroupingToolbar(bool hasSessions) {
  if (!hasSessions && !_groupingState.useCustomGroups) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        // 紧凑的分组切换
        _buildGroupingToggle(),
        const Spacer(),
        // 更多选项下拉
        _buildGroupingOptionsButton(),
      ],
    ),
  );
}

Widget _buildGroupingToggle() {
  return PopupMenuButton<String>(
    icon: Icon(
      _groupingState.useCustomGroups ? Icons.view_module : Icons.list,
    ),
    onSelected: (value) {
      if (value == 'default') {
        _updateGroupingState(
          () => _groupingService.setUseCustomGroups(false),
        );
      } else if (value == 'custom') {
        _updateGroupingState(
          () => _groupingService.setUseCustomGroups(true),
        );
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: 'default',
        child: Row(
          children: [
            Icon(Icons.list),
            SizedBox(width: 8),
            Text('默认分组'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'custom',
        child: Row(
          children: [
            Icon(Icons.view_module),
            SizedBox(width: 8),
            Text('自定义分组'),
          ],
        ),
      ),
      if (_groupingState.useCustomGroups)
        const PopupMenuDivider(),
      if (_groupingState.useCustomGroups)
        const PopupMenuItem(
          value: 'create',
          child: Row(
            children: [
              Icon(Icons.create_new_folder),
              SizedBox(width: 8),
              Text('新建分组'),
            ],
          ),
        ),
    ],
  );
}
```

---

## 四、优先级汇总

| 优先级 | 优化点 | 工作量 | 影响范围 | 依赖 |
|--------|--------|--------|----------|------|
| **高** | 历史对话修复 | 中 | 数据丢失风险 | 无 |
| **高** | 设备连接速度 | 中-高 | 首次体验 | 无 |
| **高** | 输入框高度限制 | 低 | 高频使用 | 无 |
| **高** | 消息滚动行为 | 中 | 阅读体验 | 无 |
| **中** | 中间态展示 | 低 | 体验优化 | 无 |
| **中** | 展开/收起状态保持 | 中 | 用户体验 | 无 |
| **中** | 分组工具栏优化 | 低 | UI 改进 | 无 |
| **中** | 输入模板功能 | 中 | 效率提升 | 无 |
| **低** | 消息队列功能 | 高 | 特殊场景 | 无 |
| **低** | 多设备连接 | 高 | 新功能 | 架构改造 |
| **低** | 服务器地域优化 | 高 | 性能提升 | 服务器部署 |

---

## 五、关键代码位置索引

| 功能 | 文件路径 | 行号 |
|------|----------|------|
| Socket 连接状态 | `lib/features/socketio/data/socket_repository.dart` | 92-100 |
| Socket 超时配置 | `lib/core/config/app_config.dart` | 40-44 |
| 消息发送 | `lib/features/session/screens/session_screen.dart` | 1422-1453 |
| 会话加载过滤 | `lib/features/session/data/session_repository.dart` | 318-323 |
| 设备连接流程 | `lib/features/auth/presentation/terminal_connect_screen.dart` | 178-192 |
| 消息滚动处理 | `lib/features/session/screens/session_screen.dart` | 113-121, 165-193 |
| 分组状态服务 | `lib/features/session/data/session_grouping_service.dart` | 228-241 |
| 默认分组折叠 | `lib/features/session/screens/sessions_screen.dart` | 36-37, 303-319 |
| 输入框 | `lib/features/session/screens/session_screen.dart` | 960-985 |
| 斜杠命令 | `lib/features/session/screens/session_screen.dart` | 1196-1313 |
| 分组工具栏 | `lib/features/session/screens/sessions_screen.dart` | 203-256 |
| 服务器配置服务 | `lib/core/config/server_config_service.dart` | 全部 |
| API 服务 | `lib/app/services/api_service.dart` | 全部 |

---

## 六、服务器部署说明

### 6.1 官方服务器信息

| 配置项 | 值 |
|--------|-----|
| 默认 API 服务器 | `https://api.cluster-fluster.com` |
| LiveKit (语音) | `wss://livekit.happy.engineering` |
| 连接超时 | 30 秒 |

**服务器地域：** 海外（非中国境内）

### 6.2 自部署系统要求

| 资源 | 最小值 | 推荐值 |
|------|--------|--------|
| RAM | 512MB | 1GB |
| CPU | 1 核 | 2 核 |
| 存储 | 10GB | 50GB |
| 网络 | 100Mbps | 500Mbps |
| 操作系统 | Linux x86_64 | - |

### 6.3 部署方式

**方式 1: Docker Compose（推荐）**

```yaml
# docker-compose.yml
version: '3.8'
services:
  happy-server:
    image: sld3/happy-server:latest
    ports:
      - "3000:3000"      # HTTP API
      - "3001:3001"      # WebSocket
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/happy
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=happy
      - POSTGRES_USER=happy
      - POSTGRES_PASSWORD=your_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

**启动：**
```bash
docker-compose up -d
```

### 6.4 必需的环境变量

```bash
# .env 配置示例
NODE_ENV=production
PORT=3000

# 数据库
DATABASE_URL=postgresql://user:password@localhost:5432/happy

# Redis (用于缓存和会话)
REDIS_URL=redis://localhost:6379

# 加密密钥（用于 JWT 签名）
JWT_SECRET=your_random_secret_here

# 域名配置
BASE_URL=https://your-domain.com

# 可选：S3 存储配置
S3_BUCKET=your-bucket-name
S3_REGION=us-east-1
S3_ACCESS_KEY=your_access_key
S3_SECRET_KEY=your_secret_key

# 可选：推送通知
FCM_SERVER_KEY=your_fcm_key
```

### 6.5 客户端配置自部署服务器

```dart
// 通过设置页面配置
await ServerConfigService.instance.setCustomServerUrl(
  'https://your-domain.com'
);

// 或通过环境变量
flutter run --dart-define=HAPPY_SERVER_URL=https://your-domain.com
```

---

## 七、优化实施建议

### 7.1 第一阶段（高优先级）

预计工作量：2-3 天

1. 历史对话修复
2. 设备连接速度优化
3. 输入框高度限制
4. 消息滚动行为优化

### 7.2 第二阶段（中优先级）

预计工作量：3-5 天

1. 中间态展示优化
2. 展开/收起状态保持
3. 分组工具栏优化
4. 输入模板功能

### 7.3 第三阶段（低优先级，大改动）

预计工作量：5-10 天

1. 消息队列功能
2. 多设备连接支持
3. 服务器地域优化（自部署）

---

## 八、性能指标目标

| 指标 | 当前值 | 目标值 |
|------|--------|--------|
| 首次连接时间 | 13-35s | 5-10s |
| 消息发送延迟 | 不明显 | <1s |
| 会话加载时间 | 3-8s | <3s |
| 页面刷新后状态保持 | 不保持 | 100% |

---

*文档版本：v1.0*
*最后更新：2026-03-13*
*维护者：Happy Coder 团队*
