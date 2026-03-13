# Happy Coder 开发环境配置总结

## 已安装组件

| 组件 | 版本 | 状态 | 路径 |
|------|--------|------|------|
| Flutter | 3.41.2 | ✅ | `/opt/homebrew/bin/flutter` |
| Dart | 3.11.0 | ✅ | 内置于 Flutter |
| Node.js | v22.17.0 | ✅ | `/Users/zhaoxingbo/.nvm/versions/node/v22.17.0/bin/node` |
| Homebrew | 5.0.15 | ✅ | `/opt/homebrew/bin/brew` |

---

## 环境变量

```bash
# Flutter
export PATH="/opt/homebrew/bin:$PATH"
export FLUTTER_ROOT="/opt/homebrew/share/flutter"

# Node.js (通过 NVM)
export PATH="$HOME/.nvm/versions/node/v22.17.0/bin:$PATH"
```

---

## 项目目录

```
/Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter/
├── lib/                      # Dart 源代码
├── harmony/                   # 鸿蒙原生端代码
│   ├── entry/src/main/ets/
│   │   ├── entryability/
│   │   ├── plugins/
│   │   └── utils/
│   └── module.json5
├── apps/                     # Flutter 应用
├── packages/                  # 共享包
└── docs/                     # 文档
```

---

## 鸿蒙 DevEco Studio 安装

### 下载地址
https://developer.huawei.com/consumer/cn/download/deveco-studio

### 推荐版本
- **DevEco Studio 5.0.0+** (支持 HarmonyOS NEXT / API 12+)

### 安装步骤

1. 下载 DMG 文件
2. 打开并拖动到 `/Applications/` 文件夹
3. 首次启动同意许可协议

### 首次启动配置

1. 配置 **Node.js** 路径:
   ```
   /Users/zhaoxingbo/.nvm/versions/node/v22.17.0/bin/node
   ```

2. 配置 **JDK**:
   - DevEco Studio 内置 JDK 17
   - 确认使用默认设置

3. 安装 **HarmonyOS SDK** 和 **NDK**:
   - SDK Manager → 安装 SDK
   - 选择 HarmonyOS NEXT (API 12) 或更高版本

4. 安装 **HarmonyOS Previewer**:
   - 用于预览和调试鸿蒙应用

---

## Flutter HarmonyOS 开发

### 1. 安装 Flutter 鸿蒙插件

```bash
# 在项目根目录
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter

# 安装依赖
flutter pub get
```

### 2. 配置 DevEco Studio

1. 打开 DevEco Studio
2. 选择 **File → Open** 打开项目
3. 等待 Gradle 同步完成

### 3. 运行项目

#### macOS 调试:
```bash
cd apps/admin
flutter run -d macos
```

#### 鸿蒙设备/模拟器:
```bash
# 方式 1: 在 DevEco Studio 中直接运行
# 方式 2: 使用 Flutter 命令（需要配置）
flutter build harmony --debug
```

---

## 常用命令

```bash
# Flutter 常用命令
flutter doctor              # 检查环境
flutter pub get             # 获取依赖
flutter upgrade             # 升级 Flutter
flutter clean              # 清理构建缓存
flutter build macos        # 构建 macOS 应用
flutter build harmony       # 构建鸿蒙应用

# 鸿蒙常用命令
# 在 DevEco Studio 中操作
```

---

## 开发环境检查

### Flutter Doctor 输出示例

```bash
$ flutter doctor
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.41.2, on macOS 26.1 15.0 Darwin arm64, locale zh_CN.UTF-8)
[✓] Android toolchain - develop for Android devices. (Android SDK version 34.0.0)
[✓] Xcode - develop for iOS and macOS (Xcode 16.0)
[✓] Chrome - develop for the web
[!] Android Studio (not installed)
[!] VS Code (not installed)
```

---

## 已创建的鸿蒙原生插件

| 插件 | 文件 | 使用的 HarmonyOS API |
|------|------|---------------------|
| LiveKit | `harmony/entry/src/main/ets/plugins/LiveKitPlugin.ets` | `@kit.NetworkKit:webSocket` |
| Libsodium | `harmony/entry/src/main/ets/plugins/LibsodiumPlugin.ets` | `@kit.CryptoArchitectureKit:cryptoFramework` |
| Push | `harmony/entry/src/main/ets/plugins/PushPlugin.ets` | `@ohos.push:pushService` |
| QR | `harmony/entry/src/main/ets/plugins/QRPlugin.ets` | `@ohos.multimedia.scanBarcode:scanBarcode` |
| File | `harmony/entry/src/main/ets/plugins/FilePlugin.ets` | `@ohos.file.picker`, `@ohos.file.fs` |
| Device | `harmony/entry/src/main/ets/plugins/DevicePlugin.ets` | `@ohos.deviceInfo`, `@ohos.net.connection`, `@ohos.batteryInfo`, `@ohos.abilityAccessCtrl`, `@ohos.pasteboard`, `@ohos.geoLocationManager` |

---

## 下一步

### 立即操作

1. [ ] 安装 DevEco Studio
2. [ ] 运行 `flutter doctor` 确认环境
3. [ ] 在 DevEco Studio 中配置 HarmonyOS SDK
4. [ ] 运行 `flutter pub get` 安装项目依赖

### 可选优化

1. [ ] 安装 VS Code (可选编辑器)
2. [ ] 安装 Android Studio (Android 调试)
3. [ ] 配置真机调试设备

---

## 故障排除

### Flutter 问题

| 问题 | 解决方案 |
|------|----------|
| `command not found: flutter` | 运行 `source ~/.zshrc` 或重启终端 |
| Dart 版本不匹配 | 运行 `brew reinstall --cask flutter` |
| 构建失败 | 运行 `flutter clean` 后重试 |
| 下载缓慢 | 使用 Flutter 中国镜像 (`export PUB_HOSTED_URL=https://pub.flutter-io.cn`) |

### 鸿蒙开发问题

| 问题 | 解决方案 |
|------|----------|
| DevEco Studio 无法启动 | 检查 JDK 版本，尝试重新安装 |
| SDK 下载失败 | 检查网络连接，使用 VPN 或镜像 |
| 构建失败 | 清理项目 (`Build → Clean`) 后重试 |
| 设备无法连接 | 检查 USB 连接，确保已开启开发者模式 |

---

## 参考链接

- [Flutter 官方文档](https://docs.flutter.dev)
- [Flutter 鸿蒙插件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/flutter-harmonyos-V5-overview)
- [DevEco Studio 下载](https://developer.huawei.com/consumer/cn/download/deveco-studio)
- [HarmonyOS 文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5)
