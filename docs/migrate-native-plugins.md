# 迁移手写鸿蒙插件到外部目录指南

> 将现有的 `harmony/` 插件代码迁移到独立目录，然后在 Flutter 项目中使用 flutter_harmonyos 引用。这样可以继续使用手写的鸿蒙代码，同时利用官方框架。

---

## 一、方案说明

### 1.1 为什么需要迁移？

| 问题 | 说明 |
|------|------|
| `harmony/` 在项目中 | 手写的鸿蒙插件代码 |
| flutter_harmonyos | 华为官方方案 | 会自动生成自己的桥接层 |
| 冲突风险 | ⚠️ 两个方案功能可能重复 |

### 1.2 迁移后的结构

```
happy-coder-flutter/
├── lib/                      # Flutter 代码
├── harmony_native/              # ✅ 迁移后的原生插件
│   ├── entry/
│   │   └── src/main/ets/
│   │   │   ├── plugins/              # 插件实现
│   │   │   │   ├── DevicePlugin.ets
│   │   │   ├── LiveKitPlugin.ets
│   │   │   ├── LibsodiumPlugin.ets
│   │   │   ├── PushPlugin.ets
│   │   │   ├── QRPlugin.ets
│   │   │   ├── FilePlugin.ets
│   │   │   └── DevicePlugin.ets
│   └── oh-package.json5
│   └── pubspec.yaml           # 声明使用新插件
└── harmony/                      # 保留原位置（备用）
```

---

## 二、迁移步骤

### 2.1 备份当前项目

```bash
# 创建备份
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter
cp -r happy-coder-flutter happy-coder-flutter-backup
```

### 2.2 创建迁移目录

```bash
# 创建独立的原生插件目录
mkdir -p harmony_native
```

### 2.3 迁移插件代码

#### 2.3.1 DevicePlugin.ets

**迁移前**（harmony/entry/src/main/ets/plugins/DevicePlugin.ets）：
```typescript
import { MethodChannel, MethodCall } from '@package:flutter/services.dart';
import { EventChannel } from '@package:flutter/services.dart';

export default class DevicePlugin {
  static const MethodChannel _channel =
    MethodChannel('happy.device', const MethodCodec('StandardMethodCodec'));

  /// 获取设备信息
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    // ... 实现代码
  }
}
```

**迁移后**（harmony_native/entry/src/main/ets/plugins/DevicePlugin.ets）：
```typescript
import { MethodChannel, MethodCall } from '@package:flutter/services.dart';
import { DeviceInfo } from '@ohos/deviceInfo';
import plugin_platform_interface from 'plugin_platform_interface';

// 保持与原插件相同的 Channel 名称
export default class HarmonyDevicePlugin extends DeviceInfo {
  private _channel = MethodChannel('happy.device');

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    // 调用鸿蒙原生获取设备信息
    return await _channel.invokeMethod('getDeviceInfo');
  }
}
```

#### 2.3.2 LiveKitPlugin.ets

**迁移前**：
```typescript
import { MethodChannel } from '@package:flutter/services.dart';

export default class LiveKitPlugin {
  static const _channel =
    MethodChannel('happy.livekit', const MethodCodec('StandardMethodCodec'));

  static Future<void> connectSession(String token) async {
    await _channel.invokeMethod('connectSession', {'token': token});
  }

  // ... 其他方法
}
```

**迁移后**（harmony_native/entry/src/main/ets/plugins/LiveKitPlugin.ets）：
```typescript
import { MethodChannel } from '@package:flutter/services.dart';
import plugin_platform_interface from 'plugin_platform_interface';

export default class HarmonyLiveKitPlugin {
  private _channel = MethodChannel('happy.livekit');

  @override
  Future<void> connectSession(String token) async {
    return await _channel.invokeMethod('connectSession', {'token': token});
  }

  // ... 其他方法保持相同
}
```

### 2.4 更新 pubspec.yaml

```yaml
# pubspec.yaml - 引用迁移后的插件
name: happy_coder_harmony
description: Happy Coder with harmony_native plugins
version: 1.0.0

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # Flutter 依赖（复用）
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  socket_io_client: ^2.0.0
  dio: ^5.4.0
  sodium: ^2.0.0

  # 添加鸿蒙原生插件依赖
  harmony_native_device:
    path: harmony_native/
  harmony_native_livekit:
    path: harmony_native/
```

### 2.5 创建鸿蒙项目的 oh-package.json5

```json5
{
  "name": "happy_coder_harmony",
  "version": "1.0.0",
  "type": "entry",

  "module": {
    "name": "entry",
    "srcPath": "./entry/src/main/ets",
    "targets": [
      {
        "name": "default"
      }
    ]
  },

  "dependencies": {
    "name": "harmony_native",
    "version": "1.0.0",
    "module": {
      "name": "harmony_native",
      "srcPath": "./harmony_native/src/main/ets",
      "targets": [
        {
          "name": "default"
        }
      ]
    }
  }
}
```

---

## 三、关键注意事项

### 3.1 MethodChannel 冲突解决

| 冲突 | 解决方案 |
|------|------|
| 原插件和新插件使用相同 Channel 名 | 新插件改用不同名称 |
| 或者统一使用官方 `plugin_platform_interface` 契约 | 推荐方式 |

### 3.2 插件生命周期管理

迁移后的插件需要正确实现以下方法：

```typescript
interface HarmonyPlugin {
  onAttachedToEngine(binding: PluginBinding): void;
  onDetachedFromEngine(binding: PluginBinding): void;
  dispose(): void;
}
```

### 3.3 测试清单

| 模块 | 测试项 |
|------|------|
| DevicePlugin | [ ] 设备信息获取 [ ] 权限检查 [ ] |
| LiveKitPlugin | [ ] 连接会话 [ ] 音频发送 [ ] 静音控制 [ ] |
| LibsodiumPlugin | [ ] 密钥生成 [ ] 加密解密 [ ] |
| PushPlugin | [ ] 推送初始化 [ ] 消息接收 [ ] |
| QRPlugin | [ ] 生成 QR [ ] 扫描 QR [ ] |
| FilePlugin | [ ] 文件选择 [ ] 保存读取 [ ] |

---

## 四、推荐迁移顺序

1. **第一阶段**：基础插件优先
   - DevicePlugin（设备信息）
   - LibsodiumPlugin（加密）

2. **第二阶段**：核心功能插件
   - LiveKitPlugin（语音）
   - PushPlugin（推送）

3. **第三阶段**：UI 相关插件
   - QRPlugin
   - FilePlugin

4. **第四阶段**：测试和验证

---

## 五、快捷命令

```bash
# 创建迁移目录
mkdir -p harmony_native

# 复制第一个插件（示例）
cp -r harmony/entry/src/main/ets/plugins/DevicePlugin.ets harmony_native/plugins/

# 运行 flutter analyze 检查
flutter analyze
```

---

## 六、参考资料

| 资源 | 链接 |
|------|------|
| flutter_harmonyos 仓库 | https://github.com/openharmony-tpc/flutter_harmonyos |
| plugin_platform_interface | flutter_harmonyos 包内含 |
| 华为开发者文档 | https://developer.huawei.com/consumer/cn/ |
| 鸿蒙开发者论坛 | https://developer.huawei.com/consumer/cn/forum/ |

---

**文档版本**: 1.0
**更新日期**: 2026-03-01
