# 需求文档：APP 访问 PC 本地资源代理

## 1. 背景与动机

用户在 PC 上运行本地开发服务（如 Vite dev server、React dev preview、API mock server 等），希望在手机 APP 上实时预览和操作这些服务。但 APP 和 PC 通常不在同一局域网，无法直接访问 `localhost`。

现有架构中，APP 和 PC 都通过 Socket.IO 连接到 Happy Server，已有完整的加密 RPC 通道（用于 bash、readFile 等操作）。本需求复用该通道，将 HTTP 请求从 APP 代理到 PC 的 localhost。

## 2. 目标用户

- 使用 Happy Coder APP 的开发者
- PC 上运行 `happy daemon` 的用户

## 3. 功能需求

### FR-01：启动/停止本地代理服务

- APP 内可启动一个本地 HTTP Server，监听 `127.0.0.1` 随机端口
- 可指定目标 PC session 和目标端口号
- 可停止代理服务并释放端口
- 同一时间仅运行一个代理实例

### FR-02：HTTP 请求代理转发

- APP 内的 HTTP 客户端（WebView 或其他）访问 `http://127.0.0.1:{localPort}/path`
- 代理服务器自动将请求通过 RPC 加密通道转发到 PC
- PC 在 `127.0.0.1:{targetPort}` 上执行真实 HTTP 请求
- 响应原路返回到 APP 的 HTTP 客户端
- 支持所有 HTTP 方法：GET、POST、PUT、DELETE、PATCH、OPTIONS
- 支持请求头、请求体、响应头、响应体的完整透传

### FR-03：预设端口 + 路径导航

- 用户预先配置目标端口号（如 8080、3000、5173）
- 配置完成后，WebView 中所有路径导航（`/`、`/api/data`、`/page?query=value`）自动代理到 PC 的对应端口
- 不需要每次手动输入完整 URL

### FR-04：WebView 页面（后续迭代）

- 提供 WebView 页面加载代理地址
- 含地址栏显示当前 URL、前进/后退/刷新按钮
- **本迭代不实现**，仅预留接口

## 4. 非功能需求

### NFR-01：安全性

- PC 端只允许访问 `127.0.0.1`，禁止访问外部网络（SSRF 防护）
- 目标端口范围限制：1024-65535
- 所有传输数据端到端加密（复用现有 AES-GCM / Legacy 加密）
- 响应体大小限制：10MB
- 请求超时：30 秒

### NFR-02：性能

- 单次代理请求额外延迟 < 200ms（局域网场景）
- 支持并发请求（多个资源同时加载）
- 不影响现有 Socket.IO 连接和 RPC 通道的正常功能

### NFR-03：可靠性

- RPC 超时或 PC 断连时，返回明确的错误码（502/504）
- 代理服务异常不崩溃 APP
- 端口冲突时自动使用随机端口
- APP 切后台时代理服务继续运行

### NFR-04：兼容性

- 支持 HarmonyOS（ohos）平台
- `dart:io` HttpServer 在 HarmonyOS Flutter 上可用（已验证）
- 不引入新的平台原生依赖

## 5. 约束

- Happy Server 不做任何改动（纯 RPC 中继）
- 不引入新的第三方依赖（使用 `dart:io` 原生 HttpServer）
- 不影响现有 session、message、RPC 等功能

## 6. 验收标准

1. PC 启动 `python3 -m http.server 8080`，APP 启动代理，设备浏览器访问 `http://127.0.0.1:{localPort}/` 能看到文件列表
2. 代理传输的数据在 Server 端不可读（加密验证）
3. 访问不存在的端口返回 502 错误
4. 代理运行时，APP 的其他功能（消息、session 列表等）正常工作
5. 停止代理后端口被正确释放
