# 模拟器自动化测试方案

## 概述

本文档定义了 Happy Coder Flutter 应用的模拟器自动化测试方案，用于在 iOS/Android 模拟器环境中进行端到端的功能验证。

---

## 一、测试环境配置

### 1.1 模拟器准备

**iOS 模拟器配置:**
```yaml
# 使用 Xcode 命令启动
xcrun simctl boot

# 或使用 iOS Simulator 应用直接启动
# 推荐配置: iPhone 15 Pro, iOS 17.0+
```

**Android 模拟器配置:**
```yaml
# 使用 AVD 或 Android Studio Emulator
# 推荐配置: Pixel 6 Pro, Pixel 7 Pro, API 33+
# RAM: 至少 6GB
```

**测试前置条件:**
- ✅ 后端服务已启动并可访问
- ✅ 网络 DNS 配置正确
- ✅ 数据库已初始化
- ✅ 最小 SDK 版本检查通过

---

## 二、测试框架选择

### 2.1 推荐测试框架

| 框架 | 适用场景 | 推荐指数 |
|--------|----------|----------|
| Flutter Integration Test | 组件单元测试 | ⭐⭐⭐ |
| Flutter Driver (已弃用) | 端到端测试 | ⭐⭐ |
| Patrol | 高级 E2E 测试 | ⭐⭐⭐⭐⭐⭐ |
| integration_test | 官方集成测试 | ⭐⭐⭐⭐ |

**推荐选择: Patrol**

### 2.2 Patrol 配置

**pubspec.yaml 添加依赖:**
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  patrol:
    git:
      url: https://github.com/leancodeo/patrol.git
      path: packages/patrol
```

**初始化测试:**
```bash
# 安装 Patrol CLI
dart pub global activate patrol_cli

# 初始化测试
patrol init
```

---

## 三、测试用例结构

### 3.1 测试套件组织

```
test/
├── integration_test/          # 集成测试 (Patrol)
│   ├── authentication/       # 认证相关测试
│   ├── session/             # 会话管理测试
│   ├── chat/               # 聊天功能测试
│   ├── tools/              # AI 工具测试
│   ├── artifacts/           # 工件管理测试
│   ├── kv_storage/          # KV 存储测试
│   ├── settings/            # 设置功能测试
│   └── social/             # 社交功能测试
├── unit/                    # 单元测试
│   ├── repository/          # 数据仓库测试
│   ├── models/              # 模型测试
│   └── services/            # 服务测试
├── golden/                  # 截图对比测试
│   ├── screenshots/         # 预期 UI 截图
│   └── fixtures/           # 测试数据
└── mocks/                   # Mock 数据
    ├── api_responses/       # API 响应 Mock
    └── encrypted_data/       # 加密数据 Mock
```

### 3.2 核心功能测试覆盖

#### 认证功能测试

| 测试用例 | 优先级 | 覆盖点 |
|----------|--------|--------|
| QR 码登录成功流程 | P0 | `auth/qr_login_success_test.dart` |
| QR 码登录失败流程 | P0 | `auth/qr_login_failure_test.dart` |
| 密钥备份生成 | P0 | `auth/key_backup_test.dart` |
| 密钥恢复验证 | P0 | `auth/key_restore_test.dart` |
| 账户关联功能 | P1 | `auth/link_account_test.dart` |
| 会话初始化时加载缓存 | P1 | `auth/session_cache_test.dart` |

#### 会话管理测试

| 测试用例 | 优先级 | 覆盖点 |
|----------|--------|--------|
| 创建新会话 | P0 | `session/create_session_test.dart` |
| 加载会话列表 | P0 | `session/list_sessions_test.dart` |
| 删除会话 | P1 | `session/delete_session_test.dart` |
| 会话详情加载 | P1 | `session/session_detail_test.dart` |
| 搜索会话 | P2 | `session/search_sessions_test.dart` |
| 会话排序 | P2 | `session/session_sort_test.dart` |
| 分页加载 | P2 | `session/pagination_test.dart` |

#### 聊天功能测试

| 测试用例 | 优先级 | 覆盖点 |
|----------|--------|--------|
| 发送文本消息 | P0 | `chat/send_text_message_test.dart` |
| 发送带附件的消息 | P1 | `chat/send_attachment_message_test.dart` |
| 消息列表滚动性能 | P1 | `chat/message_scroll_test.dart` |
| 消息气泡渲染 | P1 | `chat/message_bubble_render_test.dart` |
| 输入状态持久化 | P1 | `chat/input_persistence_test.dart` |
| 实时消息接收 | P1 | `chat/realtime_message_test.dart` |

#### 工具功能测试

| 测试用例 | 优先级 | 覆盖点 |
|----------|--------|--------|
| Bash 工具执行 | P0 | `tools/bash_tool_test.dart` |
| Edit 工具语法高亮 | P1 | `tools/edit_tool_test.dart` |
| Write 工具字数统计 | P1 | `tools/write_tool_test.dart` |
| Todo 工具状态切换 | P1 | `tools/todo_tool_test.dart` |
| MCP 工具连接 | P2 | `tools/mcp_tool_test.dart` |

#### 工件管理测试

| 测试用例 | 优先级 | 覆盖点 |
|----------|--------|--------|
| 工件列表加载 | P0 | `artifacts/list_artifacts_test.dart` |
| 创建新工件 | P0 | `artifacts/create_artifact_test.dart` |
| 工件详情查看 | P0 | `artifacts/artifact_detail_test.dart` |
| 编辑工件 | P1 | `artifacts/edit_artifact_test.dart` |
| 删除工件 | P1 | `artifacts/delete_artifact_test.dart` |
| 工件类型筛选 | P2 | `artifacts/filter_artifacts_test.dart` |

#### KV 存储测试

| 测试用例 | 优先级 | 覆盖点 |
|----------|--------|--------|
| 设置键值 | P0 | `kv/set_kv_test.dart` |
| 获取键值 | P0 | `kv/get_kv_test.dart` |
| 删除键值 | P0 | `kv/delete_kv_test.dart` |
| 批量更新 | P0 | `kv/batch_update_test.dart` |
| 前缀列表查询 | P1 | `kv/prefix_list_test.dart` |
| 值版本控制 | P1 | `kv/version_control_test.dart` |
| 本地缓存持久化 | P1 | `kv/cache_persistence_test.dart` |

#### 设置功能测试

| 测试用例 | 优先级 | 覆盖点 |
|----------|--------|--------|
| 切换主题 | P1 | `settings/theme_switch_test.dart` |
| 修改通知设置 | P2 | `settings/notification_settings_test.dart` |
| 安全设置修改 | P1 | `settings/security_settings_test.dart` |
| AI 配置文件管理 | P0 | `settings/profile_management_test.dart` |
| 语言切换 | P2 | `settings/language_switch_test.dart` |
| 使用统计显示 | P2 | `settings/usage_display_test.dart` |

#### 社交功能测试

| 测试用例 | 优先级 | 覆盖点 |
|----------|--------|--------|
| 好友列表加载 | P1 | `social/friends_list_test.dart` |
| 添加好友 | P1 | `social/add_friend_test.dart` |
| 好友状态更新 | P2 | `social/friend_status_update_test.dart` |
| 收件箱加载 | P1 | `social/inbox_list_test.dart` |
| 好友请求处理 | P1 | `social/friend_request_test.dart` |

---

## 四、Mock 策略

### 4.1 API Mock 层

```dart
// test/mocks/mock_api_service.dart
class MockApiService extends Mock implements ApiService {
  @override
  Future<T> get<T>(...) => mockData;

  @override
  Future<T> post<T>(...) => mockResponse;
}

// Mock 数据
const mockSessionList = [
  Session(
    id: 'test-session-1',
    title: 'Test Session 1',
    active: true,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    messages: [],
  ),
  Session(
    id: 'test-session-2',
    title: 'Test Session 2',
    active: false,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 2),
    messages: [],
  ),
];

const mockArtifacts = [
  Artifact(
    id: 'test-artifact-1',
    title: 'Test Code',
    type: 'code',
    body: 'function test() { return true; }',
    createdAt: DateTime.now().millisecondsSinceEpoch,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
    seq: 1,
  ),
];
```

---

## 五、测试执行

### 5.1 本地测试命令

```bash
# 运行所有集成测试
patrol test

# 运行特定测试套件
patrol test test/integration_test/authentication/

# 生成测试覆盖率报告
patrol test coverage

# 查看测试报告
open patrol build/ios/patrol/report/index.html
```

### 5.2 CI/CD 集成

**GitHub Actions 配置示例:**

```yaml
name: Happy Coder Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action/setup-flutter@v2
        with:
          channel: 'stable'
          architecture: x64
          cache: true
      - run: flutter pub get
      - run: dart pub global activate patrol_cli
      - run: patrol test

  test-android:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
      - uses: subosito/flutter-action/setup-flutter@v2
        with:
          channel: 'stable'
          architecture: x64
          cache: true
      - run: flutter pub get
      - run: dart pub global activate patrol_cli
      - run: patrol test test/integration_test/
```

---

## 六、测试报告

### 6.1 报告指标

| 指标 | 目标值 | 说明 |
|--------|--------|------|
| 代码覆盖率 | > 80% | 关键代码路径覆盖率 |
| 测试通过率 | > 95% | 所有测试用例通过率 |
| 性能基准 | < 3s | 关键操作响应时间 |
| 内存泄漏 | 无 | 所有测试完成后无内存泄漏 |

### 6.2 报告输出

```bash
# 生成 HTML 报告
patrol test report

# 生成 JSON 报告 (用于 CI)
patrol test report --format json

# 生成覆盖率报告
patrol test coverage --coverage
```

---

## 七、测试最佳实践

### 7.1 编写测试用例原则

1. **可读性**: 测试名称清晰描述测试目的
2. **独立性**: 每个测试用例独立，可单独运行
3. **可重复性**: 测试可重复执行，结果一致
4. **快速执行**: 测试应在合理时间内完成 (< 5s 单个测试)
5. **清理**: 测试后清理状态，不影响其他测试

### 7.2 等待策略

```dart
// Patrol 推荐的等待模式
await tester.pumpAndSettle(timeout: Duration(seconds: 2));

// 等待元素出现
await tester.getUntilVisible(find.byKey('submit-button'));

// 等待网络请求完成
await tester.pump(Duration(milliseconds: 100));
```

---

## 八、持续测试计划

### 8.1 回归测试计划

每次发布前必须执行的完整测试:

| 测试模块 | 负责人 | 频率 |
|----------|--------|------|
| 认证功能 | @team-1 | 每次发布 |
| 会话管理 | @team-2 | 每次发布 |
| 聊天功能 | @team-2 | 每次发布 |
| 工具功能 | @team-3 | 每次发布 |
| 工件管理 | @team-4 | 每次发布 |
| KV 存储 | @team-4 | 每次发布 |
| 设置功能 | @team-1 | 每次发布 |
| 社交功能 | @team-2 | 每次发布 |

### 8.2 新功能测试流程

1. 新功能开发完成后，先编写测试用例
2. 在本地模拟器运行所有相关测试
3. 测试通过后，在真实设备验证
4. 记录发现的问题并修复
5. 回到步骤 1，直到所有测试通过

---

## 九、常见问题排查

### 9.1 测试环境问题

| 问题 | 可能原因 | 解决方案 |
|------|----------|--------|
| 模拟器启动失败 | Xcode/Android Studio 版本不兼容 | 更新开发工具 |
| 网络请求超时 | 模拟器网络配置问题 | 检查代理设置 |
| 加密解密失败 | Mock 数据不匹配 | 更新 Mock 数据 |
| 状态不同步 | 状态未正确清理 | 添加 teardown 方法 |
| 截图对比失败 | UI 有变化但未更新 | 增加截图稳定性等待 |

### 9.2 测试编写技巧

1. **使用 Page Object**: 对于复杂页面，封装为 Page 对象简化测试
2. **Key 优先级**: 优先使用 byKey 而非 byType 提高稳定性
3. **等待超时设置**: 避免无限等待，设置合理超时
4. **日志输出**: 关键步骤添加日志输出便于调试
5. **截图对比**: 使用 golden file 对比关键 UI 变化

---

## 十、总结

本测试方案确保：

1. ✅ 核心功能 100% 覆盖
2. ✅ 关键用户流程端到端测试
3. ✅ 性能指标持续监控
4. ✅ 自动化 CI/CD 集成
5. ✅ 可重复的测试套件
6. ✅ 完整的 Mock 策略

遵循此方案，可确保应用质量和稳定性达到生产标准。
