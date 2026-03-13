# 鸿蒙原生端实现总结 (使用真实 HarmonyOS API)

## 概述

本文档总结了 Happy Coder Flutter 项目的鸿蒙原生端实现，所有插件均已使用真实的 HarmonyOS API 更新。

## 项目结构

```
harmony/entry/src/main/ets/
├── entryability/
│   └── EntryAbility.ets          # 应用入口，集成所有插件
├── plugins/
│   ├── LiveKitPlugin.ets         # 实时语音通话插件
│   ├── LibsodiumPlugin.ets       # 加密插件 (使用 @kit.CryptoArchitectureKit)
│   ├── PushPlugin.ets            # 推送通知插件 (使用 @ohos.push)
│   ├── QRPlugin.ets              # QR 码生成与扫描插件 (使用 @ohos.multimedia.scanBarcode)
│   ├── FilePlugin.ets            # 文件操作插件 (使用 @ohos.file.picker & @ohos.file.fs)
│   └── DevicePlugin.ets          # 设备信息和权限插件 (使用多个系统 API)
└── utils/
    ├── Logger.ets                # 日志工具
    └── Conversion.ets            # 数据转换工具
```

## 插件详情及使用的 API

### 1. LiveKit 插件 (`LiveKitPlugin.ets`)

**使用的 HarmonyOS API:**
- `@kit.NetworkKit` - `webSocket` 用于建立 WebSocket 连接
- `@ohos.net.http` - HTTP 请求（备用）

**功能：**
- WebSocket 连接到 LiveKit 服务器
- 音频数据发送/接收（框架已实现，需集成 @ohos.multimedia.media）
- 麦克风静音控制
- 自动重连机制

**主要方法:**
| 方法 | 参数 | 返回值 |
|------|------|--------|
| `connectSession` | token: string | Promise\<boolean\> |
| `disconnect` | - | Promise\<void\> |
| `sendAudio` | data: ArrayBuffer | Promise\<void\> |
| `toggleMute` | - | Promise\<boolean\> |
| `startRecording` | - | Promise\<boolean\> |
| `stopRecording` | - | Promise\<void\> |

**MethodChannel:** `happy.livekit`

---

### 2. Libsodium 插件 (`LibsodiumPlugin.ets`)

**使用的 HarmonyOS API:**
- `@kit.CryptoArchitectureKit` - `cryptoFramework`
  - AES-256-GCM 加密/解密
  - SHA-256/SHA-512 哈希计算
  - HMAC 计算
  - 随机数生成
  - RSA 密钥生成和加密

**功能：**
- AES-256-GCM 对称加密/解密
- RSA-2048 非对称加密/解密
- SHA-256/SHA-512 哈希计算
- HMAC-SHA256 计算
- 密钥生成（对称密钥、密钥对）
- 安全的随机数生成

**主要方法:**
| 方法 | 参数 | 返回值 |
|------|------|--------|
| `generateKey` | - | Promise\<string\> |
| `generateKeyPair` | - | Promise\<KeyPair\> |
| `generateRandom` | size: number | Promise\<string\> |
| `encrypt` | data, key | Promise\<string\> |
| `decrypt` | encrypted, key | Promise\<string\> |
| `encryptForPublicKey` | data, publicKey | Promise\<string\> |
| `decryptFromPublicKey` | encrypted, secretKey | Promise\<string\> |
| `hash` | data | Promise\<string\> |
| `hash512` | data | Promise\<string\> |
| `hmac` | data, key | Promise\<string\> |

**MethodChannel:** `happy.libsodium`

---

### 3. Push 插件 (`PushPlugin.ets`)

**使用的 HarmonyOS API:**
- `@ohos.push` - `pushService`
  - 推送服务初始化
  - Token 获取和刷新
  - 消息接收
  - 通知渠道管理

**功能：**
- 初始化推送服务 (Push Kit)
- 请求推送权限
- 获取推送 Token
- 接收推送消息
- 处理消息点击
- 显示本地通知
- 管理通知渠道

**主要方法:**
| 方法 | 参数 | 返回值 |
|------|------|--------|
| `initialize` | appId: string | Promise\<boolean\> |
| `requestPermissions` | - | Promise\<boolean\> |
| `getInitialMessage` | - | Promise\<string \| null\> |
| `getToken` | - | Promise\<string\> |
| `refreshToken` | - | Promise\<string \| null\> |
| `showLocalNotification` | title, content, extras | Promise\<boolean\> |
| `clearAllNotifications` | - | Promise\<boolean\> |
| `setNotificationChannel` | config | Promise\<boolean\> |

**MethodChannel:** `happy.push`
**EventChannel:** `happy.push/events`

---

### 4. QR 插件 (`QRPlugin.ets`)

**使用的 HarmonyOS API:**
- `@ohos.multimedia.scanBarcode` - `scanBarcode`
  - QR 码扫描
  - 相册图片扫描
  - 闪光灯控制

- `@ohos.multimedia.image` - `image`
  - 图片处理
  - QR 码图片生成（需集成第三方库）

**功能：**
- 扫描 QR 码
- 从相册选择图片扫描
- 生成 QR 码图片
- 闪光灯控制
- 相机权限管理

**主要方法:**
| 方法 | 参数 | 返回值 |
|------|------|--------|
| `generate` | data, options | Promise\<PixelMap\> |
| `generateBase64` | data, options | Promise\<string\> |
| `startScanning` | options | QRScanEvent[] |
| `stopScanning` | - | void |
| `scanFromGallery` | - | Promise\<QRScanResult\> |
| `scanImage` | uri | Promise\<QRScanResult\> |
| `checkCameraPermission` | - | Promise\<boolean\> |
| `requestCameraPermission` | - | Promise\<boolean\> |
| `toggleFlash` | enable | Promise\<boolean\> |

**MethodChannel:** `happy.qrcode`
**EventChannel:** `happy.qrcode/events`

---

### 5. File 插件 (`FilePlugin.ets`)

**使用的 HarmonyOS API:**
- `@ohos.file.picker` - `picker`
  - 文件选择 (DocumentViewPicker)
  - 图片选择 (PhotoViewPicker)
  - 视频选择
  - 保存文件

- `@ohos.file.fs` - `fs`
  - 文件信息获取
  - 文件读写
  - 目录操作
  - 文件复制/移动/删除

**功能：**
- 文件选择（支持多选、MIME 类型过滤）
- 图片选择
- 视频选择
- 保存文件
- 文件信息获取
- 文件读写（文本/二进制）
- 目录操作
- 文件存在性检查

**主要方法:**
| 方法 | 参数 | 返回值 |
|------|------|--------|
| `selectFiles` | mimeTypes, multiple | Promise\<string[] \| null\> |
| `selectImage` | options | Promise\<string \| null\> |
| `selectImages` | maxCount, options | Promise\<string[] \| null\> |
| `selectVideos` | maxCount | Promise\<string[] \| null\> |
| `saveFile` | content, options | Promise\<string \| null\> |
| `getFileInfo` | uri | Promise\<FileInfo \| null\> |
| `getDirectoryInfo` | uri | Promise\<DirectoryInfo \| null\> |
| `readFile` | uri | Promise\<string \| null\> |
| `readFileBinary` | uri, offset, length | Promise\<ArrayBuffer \| null\> |
| `writeFile` | uri, content | Promise\<number \| null\> |
| `writeFileBinary` | uri, data | Promise\<number \| null\> |
| `copyFile` | sourceUri, targetUri | Promise\<boolean\> |
| `moveFile` | sourceUri, targetUri | Promise\<boolean\> |
| `deleteFile` | uri | Promise\<boolean\> |
| `fileExists` | uri | Promise\<boolean\> |
| `createDirectory` | uri, recursive | Promise\<boolean\> |

**MethodChannel:** `happy.file`

---

### 6. Device 插件 (`DevicePlugin.ets`)

**使用的 HarmonyOS API:**
- `@ohos.deviceInfo` - 设备信息
- `@ohos.net.connection` - 网络状态
- `@ohos.batteryInfo` - 电池信息
- `@ohos.abilityAccessCtrl` - 权限管理
- `@ohos.pasteboard` - 剪贴板
- `@ohos.geoLocationManager` - 位置服务

**功能：**
- 获取设备信息
- 获取网络状态
- 获取电池信息
- 请求系统权限
- 剪贴板操作
- 位置服务
- 打开应用设置

**主要方法:**
| 方法 | 参数 | 返回值 |
|------|------|--------|
| `getDeviceInfo` | - | Promise\<DeviceInfo\> |
| `getNetworkStatus` | - | Promise\<NetworkStatus\> |
| `getBatteryInfo` | - | Promise\<BatteryInfo\> |
| `requestCameraPermission` | - | Promise\<boolean\> |
| `requestMicrophonePermission` | - | Promise\<boolean\> |
| `requestStoragePermission` | - | Promise\<boolean\> |
| `requestLocationPermission` | - | Promise\<boolean\> |
| `requestMultiplePermissions` | permissions | Promise\<Map\> |
| `checkPermission` | permission | Promise\<PermissionStatus\> |
| `setClipboard` | text | Promise\<boolean\> |
| `getClipboard` | - | Promise\<string \| null\> |
| `clearClipboard` | - | Promise\<boolean\> |
| `openAppSettings` | - | Promise\<void\> |
| `getCurrentLocation` | config | Promise\<LocationInfo\> |
| `enableLocationUpdates` | config, callback | Promise\<number\> |
| `disableLocationUpdates` | callbackId | void |

**MethodChannel:** `happy.device`

---

## 工具类

### Logger (`Logger.ets`)

统一的日志输出工具，支持不同级别的日志：
- `debug()` - 调试日志
- `info()` - 信息日志
- `warn()` - 警告日志
- `error()` - 错误日志

### Conversion (`Conversion.ets`)

数据转换工具：
- ArrayBuffer / Base64 互转
- Uint8Array / Base64 互转
- ArrayBuffer / Hex 互转
- 字符串编解码
- 数据合并比较

---

## 依赖项清单

### 系统模块依赖

```json
{
  "dependencies": {
    "@ohos.abilityAccessCtrl": {},
    "@ohos.app.ability.common": {},
    "@ohos.batteryInfo": {},
    "@ohos.deviceInfo": {},
    "@ohos.file.fs": {},
    "@ohos.file.picker": {},
    "@ohos.geoLocationManager": {},
    "@ohos.multimedia.image": {},
    "@ohos.multimedia.media": {},
    "@ohos.multimedia.scanBarcode": {},
    "@ohos.net.connection": {},
    "@ohos.net.http": {},
    "@ohos.pasteboard": {},
    "@ohos.push": {},
    "kit.CryptoArchitectureKit": {},
    "kit.NetworkKit": {}
  }
}
```

### 第三方依赖

当前实现需要以下第三方库（未包含在 HarmonyOS SDK 中）：

1. **QR 码生成库** - 用于生成 QR 码图片
   - 建议使用 `qrcode` 的 HarmonyOS 移植版本

2. **LiveKit SDK** - 用于完整的 WebRTC 音频通话
   - 需要等待官方 HarmonyOS SDK 或使用社区移植版本

3. **Flutter HarmonyOS Bridge** - Flutter 与 HarmonyOS 通信的桥接库
   - 需要根据项目选择的 Bridge 框架进行集成

---

## 权限配置

在 `module.json5` 中需要添加以下权限：

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:internet_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      },
      {
        "name": "ohos.permission.CAMERA",
        "reason": "$string:camera_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.MICROPHONE",
        "reason": "$string:microphone_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.READ_MEDIA_IMAGE",
        "reason": "$string:read_media_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.READ_MEDIA_VIDEO",
        "reason": "$string:read_media_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.APPROXIMATELY_LOCATION",
        "reason": "$string:location_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.NOTIFICATION_CONTROLLER"
      }
    ]
  }
}
```

---

## 代码统计

| 文件 | 行数 | 使用的 API |
|------|------|-------------|
| Logger.ets | ~100 | - |
| Conversion.ets | ~180 | - |
| LiveKitPlugin.ets | ~600 | @kit.NetworkKit (webSocket) |
| LibsodiumPlugin.ets | ~520 | @kit.CryptoArchitectureKit |
| PushPlugin.ets | ~540 | @ohos.push |
| QRPlugin.ets | ~620 | @ohos.multimedia.scanBarcode, @ohos.multimedia.image |
| FilePlugin.ets | ~680 | @ohos.file.picker, @ohos.file.fs |
| DevicePlugin.ets | ~780 | @ohos.deviceInfo, @ohos.net.connection, @ohos.batteryInfo, @ohos.abilityAccessCtrl, @ohos.pasteboard, @ohos.geoLocationManager |
| EntryAbility.ets | ~450 | - |
| **总计** | **~4,470 行** | 8+ 个系统模块 |

---

## API 对照表

| Flutter 端方法 | HarmonyOS API | 插件文件 |
|----------------|---------------|----------|
| LiveKit | @kit.NetworkKit:webSocket | LiveKitPlugin.ets |
| Libsodium | @kit.CryptoArchitectureKit:cryptoFramework | LibsodiumPlugin.ets |
| Push | @ohos.push:pushService | PushPlugin.ets |
| QR Scan | @ohos.multimedia.scanBarcode:scanBarcode | QRPlugin.ets |
| QR Generate | 需第三方库 | QRPlugin.ets |
| File Select | @ohos.file.picker:picker | FilePlugin.ets |
| File IO | @ohos.file.fs:fs | FilePlugin.ets |
| Device Info | @ohos.deviceInfo:deviceInfo | DevicePlugin.ets |
| Network | @ohos.net.connection:connection | DevicePlugin.ets |
| Battery | @ohos.batteryInfo:batteryInfo | DevicePlugin.ets |
| Permissions | @ohos.abilityAccessCtrl:abilityAccessCtrl | DevicePlugin.ets |
| Clipboard | @ohos.pasteboard:pasteboard | DevicePlugin.ets |
| Location | @ohos.geoLocationManager:geoLocationManager | DevicePlugin.ets |

---

## 下一步

### 已完成

- ✅ 使用真实 HarmonyOS API 替换所有模拟实现
- ✅ 所有插件支持 Context 注入
- ✅ 完善的错误处理和日志记录
- ✅ 插件资源清理（dispose 方法）

### 待集成

1. **Flutter HarmonyOS Bridge** - 需要集成具体的 Bridge 框架
2. **LiveKit SDK** - 需要等待官方 HarmonyOS SDK 或使用 WebRTC
3. **QR 码生成库** - 需要集成第三方 QR 码生成库
4. **音频录制/播放** - 需要集成 @ohos.multimedia.media

### 测试清单

- [ ] 单元测试
- [ ] 插件集成测试
- [ ] 真机测试
- [ ] 性能测试
- [ ] 内存泄漏测试
