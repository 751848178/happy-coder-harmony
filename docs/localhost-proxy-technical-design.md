# 技术设计文档：APP 访问 PC 本地资源代理

## 1. 架构总览

```
┌──────────────── Flutter APP ────────────────┐
│                                              │
│  WebView / HTTP 客户端                        │
│       │ http://127.0.0.1:{localPort}/path    │
│       ▼                                      │
│  LocalProxyServer (dart:io HttpServer)       │
│       │ 打包为 HttpRequestProxy              │
│       │ 加密 (AES-GCM / Legacy)              │
│       ▼                                      │
│  SocketRepository.sessionRpc()               │
│       │ emitWithAck('rpc-call', {            │
│       │   method: "$sessionId:httpProxy",    │
│       │   params: "<encrypted>"              │
│       │ })                                    │
└───────┼──────────────────────────────────────┘
        │  Socket.IO (TLS)
        ▼
┌─── Happy Server ────────────────────────────┐
│  rpcHandler.ts                               │
│  rpcListeners.get("$sessionId:httpProxy")    │
│  → targetSocket.emitWithAck('rpc-request')   │
│  ← ack callback → 返回给调用方               │
│                                              │
│  ⚠ Server 不解密 payload，纯中继             │
└───────┼──────────────────────────────────────┘
        │  Socket.IO (TLS)
        ▼
┌─── Happy CLI (PC) ──────────────────────────┐
│  ApiSessionClient / ApiMachineClient         │
│  RpcHandlerManager                           │
│  handler: "httpProxy"                        │
│  → decrypt(params)                           │
│  → validateUrl (仅允许 127.0.0.1)            │
│  → axios.request(url)                        │
│  → encrypt(response)                         │
│  → return via ack                            │
└──────────────────────────────────────────────┘
```

## 2. 数据协议

### 2.1 请求格式 (APP → PC, 加密传输)

```json
{
  "method": "GET",
  "path": "/api/data?query=value",
  "targetPort": 8080,
  "headers": {
    "accept": "text/html",
    "content-type": "application/json"
  },
  "body": null
}
```

- `method`: HTTP 方法名，大写
- `path`: URL 路径 + query string（不含 host 和 port）
- `targetPort`: PC 上要访问的目标端口 (1024-65535)
- `headers`: 请求头 map（已移除 host、connection、transfer-encoding）
- `body`: 请求体的 base64 编码，无 body 时为 null

### 2.2 响应格式 (PC → APP, 加密传输)

```json
{
  "success": true,
  "statusCode": 200,
  "headers": {
    "content-type": "text/html; charset=utf-8",
    "content-length": "1234"
  },
  "body": "PGh0bWw+..."
}
```

- `success`: 请求是否成功到达 PC 并获得响应
- `statusCode`: HTTP 状态码 (成功时)
- `headers`: 响应头 map（已移除 hop-by-hop 头）
- `body`: 响应体的 base64 编码 (成功时)
- `error`: 错误信息 (失败时)

### 2.3 错误码映射

| PC 端错误 | APP 端 HTTP 状态码 |
|---|---|
| 端口无效 (不在 1024-65535) | 403 Forbidden |
| 连接被拒 (端口未监听) | 502 Bad Gateway |
| 请求超时 (30s) | 504 Gateway Timeout |
| RPC 通道断开 | 503 Service Unavailable |
| 响应体超过 10MB | 502 Bad Gateway |
| RPC 加密/解密失败 | 502 Bad Gateway |

## 3. 加密方案

复用现有 RPC 加密通道，不引入新的加密逻辑。

### 3.1 请求加密流程

```
原始 payload (JSON)
    ↓
尝试 AES-GCM (per-session dataEncryptionKey)
    ↓ 失败
回退 NaCl Legacy (account secretKey)
    ↓
base64 编码的加密字符串 → 作为 rpc-call 的 params
```

### 3.2 密钥来源

- **AES-GCM 密钥**: `SessionDataKeyStore.instance.sessionKeyFor(sessionId)`
  - 来源：session 加载时从服务器获取加密的 dataEncryptionKey，用 account master secret 解密
- **Legacy 密钥**: `TokenStorageService.instance.getSecretKey()`
  - 来源：账户注册时生成，持久化存储

## 4. Flutter APP 模块设计

### 4.1 模块结构

```
lib/core/network/
├── http_proxy_models.dart          # 数据模型
└── local_proxy_server.dart         # 本地 HTTP 代理服务器

lib/features/session/domain/
└── session_service_http_proxy.dart # RPC 调用扩展 (part file)
```

### 4.2 LocalProxyServer

```dart
class LocalProxyServer {
  static final instance = LocalProxyServer._();

  // 公开 API
  Future<void> start({required String sessionId, int targetPort = 8080});
  Future<void> stop();
  String get proxyUrl;              // http://127.0.0.1:{port}
  bool get isRunning;
  int? get localPort;
  int get targetPort;

  // 内部
  Future<void> _handleRequest(HttpRequest);
  Future<HttpProxyResponse> _forwardViaRpc(String sessionId, HttpRequestProxy);
  Future<String> _encryptPayload(String sessionId, Map<String, dynamic>);
  Future<dynamic> _decryptResult(String sessionId, dynamic);
}
```

### 4.3 请求处理流程

```
1. HttpServer 收到请求
2. 读取 method, path, headers, body
3. body → BytesBuilder collect → base64Encode
4. 移除 hop-by-hop headers (host, connection, transfer-encoding)
5. 构造 HttpRequestProxy
6. _encryptPayload(sessionId, request.toJson())
7. SocketRepository.instance.sessionRpc(sessionId, 'httpProxy', encrypted)
8. _decryptResult(sessionId, response['result'])
9. HttpProxyResponse.fromJson(decrypted)
10. 写回 HttpResponse: statusCode, headers, body(base64Decode)
```

### 4.4 与现有代码的集成点

| 集成点 | 文件 | 说明 |
|---|---|---|
| RPC 发送 | `socket_repository_rpc.dart` | 复用 `sessionRpc()` 方法 |
| 加密 | `crypto_service_payloads.dart` | 复用 `encryptHappyCoderAesGcmJson` / `encryptHappyCoderLegacyJson` |
| 密钥存储 | `session_data_key_store.dart` | 复用 `SessionDataKeyStore.instance` |
| 账户密钥 | `token_storage_service.dart` | 复用 `getSecretKey()` |
| RPC 解密 | `session_service_rpc.dart` | `_callSessionRpcDecoded` 的等价逻辑在 `local_proxy_server.dart` 中内联实现 |

## 5. Happy CLI (PC) 模块设计

### 5.1 新增文件

`packages/happy-cli/src/modules/proxy/httpProxyHandler.ts`

### 5.2 注册位置

`packages/happy-cli/src/modules/common/registerCommonHandlers.ts` 末尾调用 `registerHttpProxyHandler(rpcHandlerManager)`

### 5.3 处理流程

```
1. RpcHandlerManager 接收 rpc-request (method = "httpProxy")
2. 解密 params → HttpProxyRequest
3. 校验 targetPort ∈ [1024, 65535]
4. 构造 URL: http://127.0.0.1:{targetPort}{path}
5. axios.request({method, url, headers, data, timeout: 30s, responseType: arraybuffer})
6. 收集 statusCode, headers, body
7. body → Buffer → base64
8. 构造 HttpProxyResponse → 加密 → 返回
```

### 5.4 安全防护

- **SSRF**: 目标 host 硬编码 `127.0.0.1`，不接受请求中指定
- **端口范围**: 1024-65535，排除系统保留端口
- **响应大小**: 10MB 上限（axios maxContentLength / maxBodyLength）
- **超时**: 30 秒（与 RPC 超时一致）

详细实现代码见 `docs/http-proxy-handler-spec.md`。

## 6. Happy Server

**无需任何改动。** Server 的 `rpcHandler.ts` 已支持任意 method 名的注册和转发。新增的 `httpProxy` method 对 Server 完全透明。

## 7. 依赖分析

### 7.1 Flutter APP — 新增依赖

| 包名 | 用途 | 是否新增 |
|---|---|---|
| `dart:io` | HttpServer、HttpRequest | **否**，SDK 内置，HarmonyOS 已验证可用 |

无第三方包新增。

### 7.2 Happy CLI — 新增依赖

无。使用已有的 `axios`（已在 package.json 中）。

### 7.3 Happy Server

无。

## 8. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|---|---|---|
| dart:io HttpServer 在 HarmonyOS 上不稳定 | 代理服务不可用 | 已通过社区文档验证可用；备选方案：通过 PlatformView 实现 ArkUI 原生 HTTP Server |
| RPC 超时 (30s) 不够大文件传输 | 大文件加载失败 | 设置 10MB 响应体上限；后续可扩展分块传输 |
| WebView 子资源加载触发大量并发 RPC | 性能压力 | 代理服务器天然支持并发（每个 HttpRequest 独立处理）；RPC 通道已支持 multiplexing |
| 端口冲突（其他 APP 占用） | 代理启动失败 | 使用 `bind('127.0.0.1', 0)` 绑定随机端口，避免冲突 |
| 连接生命周期（APP 切后台） | 代理服务可能被系统杀掉 | 可在后续迭代中通过 `WidgetsBindingObserver` 管理 |
