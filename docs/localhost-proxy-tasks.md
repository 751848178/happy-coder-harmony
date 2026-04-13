# 任务分解文档：APP 访问 PC 本地资源代理

## 项目信息

- **仓库**: happy-coder-flutter (Flutter APP)
- **关联仓库**: slopus/happy (Happy CLI)
- **分支策略**: 从 main 创建 `feat/localhost-proxy` 分支
- **相关文档**:
  - `docs/localhost-proxy-requirement.md` — 需求文档
  - `docs/localhost-proxy-technical-design.md` — 技术设计
  - `docs/http-proxy-handler-spec.md` — PC 端 handler 实现

---

## 阶段一：代理层核心（Flutter APP）

### Task 1.1：创建数据模型

**文件**: `lib/core/network/http_proxy_models.dart` (新建)

**内容**:
- `HttpRequestProxy` 类：method, path, targetPort, headers, body(base64)
  - `toJson()` / `fromJson()` 工厂方法
- `HttpProxyResponse` 类：success, statusCode, headers, body(base64), error
  - `fromJson()` 工厂方法
  - `bodyBytes` getter：base64 解码为 `List<int>`

**验证**: `dart analyze` 无错误

---

### Task 1.2：创建本地代理服务器

**文件**: `lib/core/network/local_proxy_server.dart` (新建)

**内容**:
- `LocalProxyServer` 单例类
- `start({sessionId, targetPort})` — `HttpServer.bind('127.0.0.1', 0)`
- `stop()` — `server.close(force: true)`
- `proxyUrl` getter — `http://127.0.0.1:{port}`
- `_handleRequest(HttpRequest)` — 收集请求参数，调用 `_forwardViaRpc`，写回响应
- `_forwardViaRpc(sessionId, request)` — 加密 → `sessionRpc` → 解密
- `_encryptPayload(sessionId, payload)` — 复用 `CryptoService` + `SessionDataKeyStore`
- `_decryptResult(sessionId, payload)` — 复用 `CryptoService`，尝试 AES-GCM → Legacy → JSON fallback
- `_collectBody(HttpRequest)` — `BytesBuilder` 收集请求体
- `_respondError(request, statusCode, message)` — 错误响应辅助方法

**依赖**: Task 1.1

**验证**: `dart analyze` 无错误；`LocalProxyServer.instance.start(sessionId: 'test', targetPort: 8080)` 不抛异常（需要有效 session）

---

### Task 1.3：集成 RPC 通道

**文件**:
- `lib/features/session/domain/session_service_http_proxy.dart` (新建, part file)
- `lib/features/session/domain/session_service.dart` (修改：添加 part 和 import)

**内容**:
- `SessionServiceHttpProxy` extension on `SessionServiceNotifier`
- `executeHttpProxy({sessionId, request})` — 调用 `_callSessionRpcDecoded(method: 'httpProxy')`
- 在 `session_service.dart` 中添加 `part 'session_service_http_proxy.dart'`
- 在 `session_service.dart` 中添加 `import '...core/network/http_proxy_models.dart'`

**依赖**: Task 1.1, Task 1.2

**验证**: `dart analyze` 无错误

---

### Task 1.4：端到端手动测试

**前置条件**:
1. Happy CLI 已实现 `httpProxy` handler（阶段二）
2. PC 上运行测试服务：`python3 -m http.server 8080`

**测试步骤**:
1. 启动 `happy daemon`，确认 `httpProxy` method 已注册
2. 在 APP 代码中调用：
   ```dart
   await LocalProxyServer.instance.start(sessionId: sid, targetPort: 8080);
   final url = LocalProxyServer.instance.proxyUrl;
   // 用设备浏览器或 curl 访问 url
   ```
3. 验证返回 PC 上的文件列表
4. 验证子资源（CSS、图片）能正常加载

**验证标准**:
- [ ] GET 请求返回 200 + 正确内容
- [ ] 404 路径返回 404
- [ ] 目标端口未开放时返回 502
- [ ] APP 其他功能不受影响

---

## 阶段二：PC 端 Handler（Happy CLI — slopus/happy）

### Task 2.1：创建 httpProxy RPC handler

**文件**: `packages/happy-cli/src/modules/proxy/httpProxyHandler.ts` (新建)

**内容**:
- `HttpProxyRequest` / `HttpProxyResponse` 接口定义
- `registerHttpProxyHandler(rpcHandlerManager)` 函数
- handler 逻辑：
  1. 校验 targetPort (1024-65535)
  2. 构造 URL: `http://127.0.0.1:{port}{path}`
  3. `axios.request()` 执行 HTTP 请求
  4. 返回 `{success, statusCode, headers, body}` (body base64)
- 错误处理：ECONNREFUSED, ETIMEDOUT, 响应体超限

**验证**: `npx tsc --noEmit` 无错误

---

### Task 2.2：注册 handler

**文件**: `packages/happy-cli/src/modules/common/registerCommonHandlers.ts` (修改)

**内容**:
- 添加 `import { registerHttpProxyHandler } from '../proxy/httpProxyHandler'`
- 在 `registerCommonHandlers()` 函数末尾调用 `registerHttpProxyHandler(rpcHandlerManager)`

**依赖**: Task 2.1

**验证**: 启动 `happy daemon`，日志中出现 `rpc-register` 事件包含 `httpProxy` method

---

## 阶段三：WebView 集成（后续迭代，不在本次范围）

### Task 3.1：添加 WebView 依赖
- `pubspec.yaml` 添加 `webview_flutter` (HarmonyOS 适配版)
- 验证 ohos 平台编译通过

### Task 3.2：创建 WebView 页面
- 新建 `lib/features/session/screens/session_webview_screen.dart`
- 地址栏、导航按钮、WebView 组件
- 加载 `LocalProxyServer.instance.proxyUrl`

### Task 3.3：入口集成
- 在 session 详情页或工具面板中添加 "打开本地服务" 入口
- 选择端口号 → 启动代理 → 打开 WebView

---

## 任务依赖关系

```
Task 1.1 ──→ Task 1.2 ──→ Task 1.3 ──→ Task 1.4 (手动测试)
                                              ↕
Task 2.1 ──→ Task 2.2 ───────────────────→ Task 1.4
```

## 当前状态

- [x] Task 1.1 — 数据模型已实现
- [x] Task 1.2 — 本地代理服务器已实现
- [x] Task 1.3 — RPC 通道集成已实现
- [ ] Task 1.4 — 等待 PC 端完成
- [ ] Task 2.1 — 待在 slopus/happy 仓库实现
- [ ] Task 2.2 — 待在 slopus/happy 仓库实现
- [ ] Task 3.x — 后续迭代
