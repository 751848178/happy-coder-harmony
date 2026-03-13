# Harmony Native Plugins

Happy Coder 鸿蒙原生插件集合，用于与 Flutter 项目配合使用。

## 概述

本目录包含从 `harmony/` 迁移出的手写鸿蒙插件，可配合 `flutter_harmonyos` 框架使用。

## 目录结构

```
harmony_native/
├── plugins/          # 插件实现
│   ├── DevicePlugin.ets      # 设备信息插件
│   ├── LiveKitPlugin.ets     # LiveKit 语音插件
│   ├── LibsodiumPlugin.ets   # 加密插件
│   ├── PushPlugin.ets        # 推送插件
│   ├── QRPlugin.ets          # QR 码插件
│   └── FilePlugin.ets        # 文件操作插件
├── utils/            # 工具类
│   ├── Conversion.ets        # 数据转换工具
│   └── Logger.ets            # 日志工具
├── index.ets         # 入口文件（导出所有插件）
├── module.json5      # 模块配置
├── build-profile.json5  # 构建配置
└── oh-package.json5  # 包管理配置
```

## 插件列表

| 插件 | Channel 名称 | 功能描述 |
|------|-------------|----------|
| DevicePlugin | `happy.device` | 获取设备信息 |
| LiveKitPlugin | `happy.livekit` | LiveKit 语音通话 |
| LibsodiumPlugin | `happy.libsodium` | 加密/解密 |
| PushPlugin | `happy.push` | 推送通知 |
| QRPlugin | `happy.qrcode` | QR 码生成/扫描 |
| FilePlugin | `happy.file` | 文件选择/保存 |

## 使用方式

### 方式 1：作为本地 HAP 模块

在 DevEco Studio 中将本模块作为 HAP 项目导入：

```bash
# 在 DevEco Studio 中导入
File > Open > 选择 harmony_native 目录
```

### 方式 2：作为 HAR 库

构建为 HAR 库供其他项目引用：

```bash
# DevEco Studio: Build > Make Project
# 输出: harmony_native/build/default/outputs/default/harmony_native.har
```

### 方式 3：与 flutter_harmonyos 配合使用

在 Flutter 项目中配置本地插件依赖：

```yaml
# pubspec.yaml
dependencies:
  flutter_harmonyos: ^0.3.0
```

然后在鸿蒙项目中引用本模块：

```json5
// oh-package.json5
{
  "dependencies": {
    "harmony_native": "file:../harmony_native"
  }
}
```

## MethodChannel 注册

所有插件使用标准的 Flutter MethodChannel 进行通信：

```typescript
// 示例：DevicePlugin 注册
const channel = new MethodChannel('happy.device', StandardMethodCodec());

channel.setMethodCallHandler((call, result) => {
  switch (call.method) {
    case 'getDeviceInfo':
      result.success(getDeviceInfo());
      break;
    default:
      result.notImplemented();
  }
});
```

## 迁移状态

| 插件 | 迁移状态 | 测试状态 |
|------|----------|----------|
| DevicePlugin | ✅ 已迁移 | ⬜ 待测试 |
| LiveKitPlugin | ✅ 已迁移 | ⬜ 待测试 |
| LibsodiumPlugin | ✅ 已迁移 | ⬜ 待测试 |
| PushPlugin | ✅ 已迁移 | ⬜ 待测试 |
| QRPlugin | ✅ 已迁移 | ⬜ 待测试 |
| FilePlugin | ✅ 已迁移 | ⬜ 待测试 |

## 开发说明

### 添加新插件

1. 在 `plugins/` 目录创建新插件文件
2. 实现 Flutter MethodCallHandler 接口
3. 在 `index.ets` 中导出新插件
4. 更新 `HarmonyPlugins` 注册表

### 调试

```bash
# 查看日志
hdc shell hilog | grep happy_coder

# 安装调试版本
hdc install build/default/outputs/default/entry-default-signed.hap
```

## 注意事项

1. 保持 MethodChannel 名称与 Flutter 端一致
2. 数据序列化使用 `StandardMethodCodec`
3. 所有异步操作需返回 Promise
4. 权限请求需在 `module.json5` 中声明

## 参考资料

- [flutter_harmonyos 官方仓库](https://github.com/openharmony-tpc/flutter_harmonyos)
- [HarmonyOS API 文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/)
- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)

---

**版本**: 1.0.0
**更新日期**: 2026-03-01
