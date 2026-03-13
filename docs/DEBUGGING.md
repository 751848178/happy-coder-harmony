# Happy Coder Flutter 项目调试文档

> **项目名称**: happy-coder-flutter
> **生成日期**: 2026-03-04
> **Flutter 版本**: 3.x (稳定版)

---

## 一、项目概述

### 1.1 项目结构

```
lib/
├── app/
│   ├── core/              # 核心功能（主题、配置等）
│   ├── features/          # 功能模块
│   │   ├── artifacts/       # 工件管理
│   │   ├── chat/           # 聊天
│   │   ├── encryption/      # 加密功能
│   │   ├── file_viewer/    # 文件查看器
│   │   ├── friends/         # 好友功能
│   │   ├── kv/             # KV 存储
│   │   ├── profiles/        # AI 配置管理
│   │   ├── settings/       # 设置页面
│   │   ├── session/         # 会话管理
│   │   │   ├── socketio/       # Socket.IO 连接
│   │   └── tools/           # 工具集
│   │   └── widgets/        # 共享组件
│   │   └── domain/          # 领域模型
│   ├── providers/          # 状态管理器
│   └── services/         # 服务层
│   └── app/            # 应用级配置
│   └── routes/          # 路由配置
└── main.dart            # 应用入口
```

### 1.2 架构设计

**Clean Architecture 模式**：
- Domain: 业务逻辑和模型
- Data: 数据访问层（Repository + API）
- Presentation: UI 组件层
- Providers: 状态管理器
- Services: 公共服务

**关键设计模式**：
- 使用 Riverpod 进行状态管理
- 使用 GoRouter 进行导航
- 使用 Dio 进行网络请求
- 使用 json_annotation 进行序列化
- 使用 Repository 模式抽象数据访问

---

## 二、已实现功能列表

### 2.1 Artifact 工件管理系统 (CRUD + 版本控制)

**功能描述**: 管理工件的创建、读取、更新、删除，支持 header 和 body 分离版本控制

**相关文件**:
- `lib/features/artifacts/domain/artifact_models.dart`
- `lib/features/artifacts/data/artifact_repository.dart`
- `lib/features/artifacts/screens/artifacts_list_screen.dart`
- `lib/features/artifacts/screens/artifact_detail_screen.dart`
- `lib/features/artifacts/screens/new_artifact_screen.dart`

**数据模型**:
```dart
@JsonSerializable()
class Artifact {
  final String id;
  final String? title;
  final String? header;
  final int? headerVersion;
  final String? body;
  final int? bodyVersion;
  final String? dataEncryptionKey;
  // ... 完整字段
}
```

**API 端点点**:
- `POST /v1/account/artifacts` - 创建工件
- `GET /v1/account/artifacts` - 列出工件
- `GET /v1/account/artifacts/{id}` - 获取工件详情
- `PUT /v1/account/artifacts/{id}` - 更新工件
- `DELETE /v1/account/artifacts/{id}` - 删除工件

---

### 2.2 KV 存储系统

**功能描述**: 键值对存储，支持批量操作、版本控制

**相关文件**:
- `lib/features/kv/domain/kv_models.dart`
- `lib/features/kv/data/kv_storage_repository.dart`
- `lib/features/kv/data/kv_storage_provider.dart`

**数据模型**:
```dart
@JsonSerializable()
class KVItem {
  final String key;
  final String value;
  final int? version;
}
```

**API 端键点**:
- `GET /v1/account/kv` - 获取所有键值
- `POST /v1/account/kv` - 创建键值
- `DELETE /v1/account/kv/{key}` - 删除键值

---

### 2.3 AI Backend Profile 管理

**功能描述**: 管理多个 AI 提供商配置，支持环境变量映射

**相关文件**:
- `lib/features/profiles/domain/profile_models.dart`
- `lib/features/profiles/data/profiles_repository.dart`
- `lib/features/profiles/data/profiles_provider.dart`
- `lib/features/profile/screens/profile_list_screen.dart`
- `lib/features/profile/screens/profile_detail_screen.dart`

**支持配置**:
- Anthropic (baseUrl, authToken, model)
- OpenAI (apiKey, baseUrl, model)
- Azure OpenAI (apiKey, endpoint, apiVersion, deploymentName)
- Together AI (apiKey, model)
- Tmux 配置 (sessionName, tmpDir, updateEnvironment)
- 环境变量 (支持 ${VAR} 模板)

**API 端键点**:
- `GET /v1/account/profiles` - 列出配置
- `POST /v1/account/profiles` - 创建配置
- `POST /v1/account/profiles/{id}` - 更新配置
- `DELETE /v1/account/profiles/{id}` - 删除配置

---

### 2.4 会话信息页面

**功能描述**: 显示会话的完整元数据，包括代理信息、机器信息、使用统计

**相关文件**:
- `lib/features/session/screens/session_info_screen.dart`

**数据模型**:
```dart
class Session {
  // 扩展字段
  final String? id;
  final String title;
  final List<dynamic> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final String? tag;
  final String? path;
  final Map<String, dynamic>? metadata;
  final String? permissionMode;
  final String? draft;
  final Map<String, dynamic>? agentState;
}
```

---

### 2.5 会话文件管理

**功能描述**: 显示会话关联的所有文件，支持文件列表、上传、删除、操作历史

**相关文件**:
- `lib/features/session/domain/session_files_models.dart`
- `lib/features/session/data/session_files_repository.dart`
- `lib/features/session/data/session_files_provider.dart`
- `lib/features/session/screens/session_files_screen.dart`

**数据模型**:
```dart
class SessionFile {
  final String id;
  final String sessionId;
  final String filePath;
  final String fileName;
  final int? size;
  final String? mimeType;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class FileOperation {
  final String id;
  final String sessionId;
  final FileOperationType operation;
  final String? filePath;
  final DateTime timestamp;
  final int? duration;
  final String? errorMessage;
}
```

**API 端键点**:
- `GET /v1/sessions/{id}/files` - 列出文件
- `POST /v1/sessions/{id}/files` - 上传文件
- `GET /v1/sessions/{id}/files/operations` - 获取操作历史
- `DELETE /v1/sessions/{id}/files/{fileId}` - 删除文件

---

### 2.6 文件查看器

**功能描述**: 查看不同类型的文件内容，支持语法高亮显示

**相关文件**:
- `lib/features/file_viewer/file_viewer_screen.dart`

**支持的文件类型**:
- 代码文件 - 语法高亮
- 文本文件 - 纯文本显示
- Markdown - Markdown 渲染
- JSON - 格式化显示
- 图片 - 图片预览
- PDF - PDF 查看器

---

### 2.7 工具视图

**功能描述**: 文件搜索和目录浏览工具

**相关文件**:
- `lib/features/tools/glob_tool_screen.dart` - 文件模式匹配
- `lib/features/tools/grep_tool_screen.dart` - 内容搜索（支持正则表达式）
- `lib/features/tools/ls_tool_screen.dart` - 目录浏览

---

### 2.8 设置功能增强

**功能描述**: 使用统计和语言设置

**相关文件**:
- `lib/features/settings/domain/usage_models.dart`
- `lib/features/settings/screens/usage_statistics_screen.dart`
- `lib/features/settings/screens/language_settings_screen.dart`

---

### 2.9 实时功能增强

**功能描述**: 在线状态、思考状态、使用统计

**相关文件**:
- `lib/features/session/domain/session_models.dart` - 扩展的会话模型
- `lib/features/session/widgets/presence_indicator.dart` - 实时状态指示器

**新增字段**:
```dart
final PresenceStatus? presence;    // 在线状态
final bool? thinking;              // 思考状态
final DateTime? thinkingAt;      // 思考时间
final LatestUsage? latestUsage;     // 最新使用统计
```

---

### 2.10 增强的会话创建向导

**功能描述**: 3 步骤创建向导，支持机器选择、路径选择、配置文件编辑

**相关文件**:
- `lib/features/session/screens/enhanced_new_session_screen.dart`

**步骤**:
1. 基本信息 - 模板选择、标题、描述
2. 环境配置 - 机器选择、工作路径选择
3. 高级配置 - 配置文件、权限模式、模型模式

---

## 三、路由配置

### 3.1 新增路由

```dart
// 工件相关
/artifacts                - 工件列表
/artifacts/:id            - 工件详情
/artifacts/new             - 新建工件
/artifacts/edit/:id        - 编辑工件

// 会话相关
/sessions                - 会话列表
/session/:id            - 会话详情
/session/new              - 新建会话
/session/files             - 会话文件列表
/session/info             - 会话信息
/session/files             - 会话文件（重复，需要修复）

// 文件查看
/file/view              - 文件查看器

// 工具
/tools/bash              - Bash 工具
/tools/edit             - 编辑工具
/tools/write             - 写入工具
/tools/todo              - Todo 工具
/tools/mcp               - MCP 工具
/tools/glob              - Glob 工具
/tools/grep              - Grep 工具
/tools/ls                - LS 工具

// 设置
/settings              - 设置首页
/settings/account         - 账户设置
/settings/notifications - 通知设置
/settings/appearance     - 外观设置
/settings/security       - 安全设置
/settings/about          - 关于
/settings/usage          - 使用统计
/settings/language         - 语言设置

// 个人资料
/profiles                - 配置文件列表
/profile/detail           - 配置详情

// 增强的会话创建
/session/new-wizard      - 增强创建向导（新增）

```

---

## 四、当前项目状态

### 4.1 Flutter 分析结果

```
分析完成，无阻塞错误
```

**警告（非阻塞）**：
- 使用了已弃用的 `withOpacity()` 方法，建议使用 `withValues()`

### 4.2 依赖状态

```
flutter_riverpod: 2.6.1 (3.2.1 available)
dio: 5.9.1 (5.9.2 available)
file_picker: 8.0.7 (10.3.10 available)
flutter_local_notifications: 17.2.4 (20.1.0 available)
go_router: 13.2.1 (14.5.1 available)
```

---

## 五、常用开发命令

### 5.1 清理和构建

```bash
# 清理构建缓存
flutter clean

# 运行分析
flutter analyze

# 重新生成 JSON 序列化文件
flutter pub get

# 运行应用
flutter run
```

### 5.2 检查语法错误

```bash
# 检查类型错误
flutter analyze
```

---

## 六、待实现功能

根据 `docs/happy-coder-analysis.md` 分析文档，以下功能仍需实现：

### 高优先级
- 会话消息详情页面
- 最近会话页面
- 机器选择页面
- 路径选择页面
- 配置文件编辑页面
- 机器详情页面
- 终端连接页面
- 终端审批页面
- 文本选择功能

### 中优先级
- 增强的会话创建（已实现简化版）
- 功能设置页面（标记）
- Git 状态显示
- 开发工具页面
- 更新日志页面

### 低优先级
- 文本选择功能（部分实现）
- 任务/子代理功能
- 退出计划模式
- 询问用户问题功能

---

## 七、故障排除

### 7.1 常见问题

**问题**: Flutter 分析报告显示多个 "Target of URI doesn't exist"

**原因**: JSON 序列化文件引用了不存在的包

**解决方法**:
1. 检查导入语句
2. 确认包名正确
3. 运行 `flutter pub get` 重新生成 `.g.dart` 文件

**命令**:
```bash
# 检查并修复导入
flutter analyze | grep -i "from.*material"
```

---

## 八、代码规范

### 8.1 遵循 Clean Architecture

- Domain 层只包含数据模型，不包含任何 UI
- Repository 层只负责 API 调用
- 所有异步方法都返回 Future 类型
- 错误处理统一使用 `Exception` 类型

### 8.2 状态管理规范

- 使用 `StateNotifier` 扩展 `StateNotifier`
- 状态类命名使用 `XxxState` 模式
- 所有状态都是不可变对象

---

## 九、调试技巧

### 9.1 热点断点

```dart
// 在关键位置添加调试打印
print('DEBUG: ${DateTime.now()} - ${widget.runtimeType}');

// 使用 debugPrint 代替 print 进行日志输出
import 'package:flutter/foundation.dart' show debugPrint;
```

### 9.2 网络调试

```dart
// 拦截和显示 API 请求
import 'package:dio/io.dart';

Dio dio = Dio()
  ..options.connectTimeout = const Duration(seconds: 30)
  ..options.receiveTimeout = const Duration(seconds: 30)
  ..options.headers = {
    'User-Agent': 'Happy-Coder-Flutter/1.0.0',
  };
  ..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // 打印请求信息
      debugPrint('API Request: ${options.method} ${options.path}');
      return handler.next(options);
    },
  );
```

### 9.3 状态调试

```dart
// 查看当前状态
final state = ref.watch(someProvider);
print('Current state: $state');
```

---

## 十、API 文档参考

### 10.1 后端 API 端点

参考文档位置**: 后端 API 文档

**基础端点**:
- 会话管理: `/v1/sessions`
- 文件管理: `/v1/sessions/{id}/files`
- 工件管理: `/v1/account/artifacts`
- KV 存储: `/v1/account/kv`
- 配置管理: `/v1/account/profiles`

**认证**: 使用 QR 码认证流程

**实时功能**: 使用 WebSocket 进行实时同步

---

**文档更新日期**: 2026-03-04

---

**维护说明**:
1. 所有新增页面都已在 `app/routes/app_routes.dart` 中注册
2. 所有新增模型都已在对应 `domain` 文件中定义
3. 使用 `StateNotifierProvider` 需要正确的类型参数
4. JSON 序列化文件修改后需要运行 `flutter pub get`
5. 修改模型后需要重新生成对应的 `.g.dart` 文件
