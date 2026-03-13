# Happy Coder Flutter 项目 - 运行和调试指南

## 项目概览

```
/Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── app/                      # 应用核心代码
│   │   ├── providers/           # Riverpod 状态管理
│   │   ├── routes/              # 路由配置
│   │   └── features/             # 功能模块
│   ├── features/                 # 功能模块
│   │   ├── auth/              # 认证模块
│   │   ├── chat/              # 聊天模块
│   │   └── settings/           # 设置模块
│   ├── core/                     # 核心配置
│   ├── shared/                   # 共享工具
│   └── harmony/                 # 鸿蒙原生端
├── harmony/                     # 鸿蒙原生端
│   └── entry/src/main/ets/       # ArkTS 代码
├── pubspec.yaml                # 依赖配置
└── docs/                       # 文档
```

---

## 一、环境准备

### 1. 安装项目依赖

```bash
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter
flutter pub get
```

### 2. 检查 Flutter 环境

```bash
flutter doctor
```

**预期输出：**
```
[✓] Flutter (Channel stable, 3.41.2)
[✓] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS and macOS
[✓] Chrome - develop for the web
[!] iOS 工具链... (如果需要)
```

---

## 二、macOS 调试（推荐）

### 方式 1: 命令行运行

```bash
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter

# macOS 调试
flutter run -d macos

# macOS Release 构建
flutter build macos --release

# 查看可用设备
flutter devices
```

### 方式 2: VS Code 调试（推荐）

#### 安装 Flutter 扩展

1. 打开 VS Code
2. 安装 Flutter 扩展
3. 打开项目文件夹

#### 快捷操作

| 操作 | 快捷键 |
|------|----------|
| 运行项目 | `F5` 或 `Cmd+R` |
| 调试 | `F5` 或 `Cmd+D` |
| 停止调试 | `Shift+F5` |
| 热重载 | `Cmd+Shift+P` |
| 打开终端 | `` `Cmd+`` ` `` |

#### 常用调试快捷键

| 快捷键 | 功能 |
|------|------|
| `Cmd+Shift+O` | 打开文件 |
| `Cmd+P` | 快速打开 |
| `Cmd+Shift+F` | 在文件中查找 |
| `Cmd+Shift+H` | 查找和替换 |

---

## 三、鸿蒙设备调试

### 前置条件

- ✅ DevEco Studio 已安装
- ✅ HarmonyOS SDK 已配置 (API 12+)
- ✅ 设备已连接（USB 或网络）

### 步骤 1: 安装鸿蒙 Flutter 支持

```bash
# 下载并安装 harmony_flutter
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter
flutter pub global activate harmony_flutter

# 或直接添加到 pubspec.yaml 后运行
flutter pub get
```

### 步骤 2: 在 DevEco Studio 中运行

1. **打开 DevEco Studio**

2. **打开项目**
   ```
   File → Open
   选择 /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter
   ```

3. **等待 Gradle 同步完成**

4. **选择设备或模拟器**
   - 在工具栏点击设备选择器
   - 选择 HarmonyOS 设备或模拟器

5. **运行应用**
   - 点击绿色三角形运行按钮
   - 或 `Run → Run 'happy_coder_flutter'`

### 步骤 3: 调试应用

#### DevEco Studio 调试

1. 设置断点：点击代码行号左侧添加断点
2. 启动调试：点击虫子图标
3. 查看日志：底部的 "Run" 面板

#### 日志过滤

```
tag:LiveKit         # 只显示 LiveKit 相关日志
tag:Auth            # 只显示认证相关日志
tag:Chat            # 只显示聊天相关日志
```

---

## 四、混合调试（鸿蒙 + Flutter）

### 场景：调试原生插件

1. **鸿蒙端调试**
   - 在 DevEco Studio 中设置断点
   - 在插件代码中调试

2. **Flutter 端调试**
   - 在 VS Code 中运行 `flutter run -d macos`
   - 设置 Flutter 断点

3. **查看日志**
   - 鸿蒙端：DevEco Studio "Run" 面板
   - Flutter 端：VS Code "Debug Console"

---

## 五、热重载

### Flutter 热重载

| 操作 | 快捷键 |
|------|----------|
| 保存文件 | `Cmd+S` |
| 热重载 | `r` 或 `Shift+R` |
| 热重载所有 | `R` |
| 重启应用 | `R` 或 `Shift+R` |

### 鸿蒙原生热重载

鸿蒙原生代码不支持热重载，修改后需要：
1. 停止应用
2. 点击 "Run" 重新运行

---

## 六、常见问题解决

### 问题 1: `flutter doctor` 报错

| 错误 | 解决方案 |
|------|----------|
| "No devices found" | 检查设备连接或使用模拟器 |
| "CocoaPods not installed" | `sudo gem install cocoapods` |
| "Xcode not installed" | 从 App Store 安装 Xcode |

### 问题 2: 依赖安装失败

```bash
# 清理缓存后重试
flutter clean
flutter pub get

# 使用国内镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
flutter pub get
```

### 问题 3: DevEco Studio 无法识别项目

1. 检查 `pubspec.yaml` 是否存在
2. 运行 `flutter pub get` 确保依赖已安装
3. 在 DevEco Studio 中重新打开项目

### 问题 4: 原生方法调用失败

1. 检查 `harmony/` 目录是否正确配置
2. 查看 `EntryAbility.ets` 中的 MethodChannel 名称
3. 确保插件文件都在正确位置

---

## 七、日志和调试工具

### Flutter 日志

```bash
# 查看实时日志
flutter logs

# 清理日志
flutter clean
```

### DevEco Studio 日志位置

```
~/Library/Logs/Huawei/DevEcoStudio/     # macOS
%LOCALAPPDATA%/Huawei/DevEcoStudio/  # Windows
```

---

## 八、构建发布版本

### macOS Release

```bash
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter

# 构建 Release
flutter build macos --release

# 输出位置
# build/macos/Build/Products/Release/happy_coder_flutter.app
```

### 鸿蒙 HAP（鸿蒙应用包）

1. 在 DevEco Studio 中
2. `Build → Build Hap(s)/APP(s) → Build Hap(s)`
3. 或使用命令行 `hvigorw assembleHap`

---

## 九、推荐工具和配置

### VS Code 推荐扩展

| 扩展 | 用途 |
|------|------|
| Flutter | Flutter 官方支持 |
| Dart | Dart 语法高亮 |
| Error Lens | 显示错误详情 |
| GitLens | Git 增强功能 |

### 推荐设置

```json
{
  "dart.lineLength": 100,
  "dart.insertSpacesAndTabs": true,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit"
  }
}
```

---

## 十、快速命令参考

```bash
# ========== 项目操作 ==========
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter

flutter pub get              # 安装依赖
flutter clean              # 清理构建
flutter upgrade             # 升级 Flutter
flutter doctor              # 检查环境

# ========== 运行 ==========
flutter run -d macos        # macOS 调试
flutter run -d chrome       # Chrome 调试
flutter run -d harmony      # 鸿蒙调试（需配置）

# ========== 构建 ==========
flutter build macos         # 构建 macOS Debug
flutter build macos --release # 构建 macOS Release
flutter build harmony       # 构建鸿蒙应用

# ========== 测试 ==========
flutter test               # 运行单元测试
flutter analyze           # 代码分析
```

---

## 十一、调试技巧

### 1. 使用 print 输出调试信息

```dart
void main() {
  debugPrint("Debug: App starting");

  runApp(MyApp());
}

void myFunction() {
  debugPrint("Debug: myFunction called");

  // 条件输出
  if (kDebugMode) {
    print("Debug mode only output");
  }
}
```

### 2. 使用 Flutter DevTools

```bash
flutter pub global activate devtools
flutter devtools
```

然后在 Chrome 中打开 DevTools (自动提示地址)

### 3. 性能分析

```bash
flutter run --profile
# 运行后分析性能
flutter analyze
# 静态分析
```

---

## 十二、团队协作

### Git 工作流

```bash
# 创建功能分支
git checkout -b feature/your-feature-name

# 提交代码
git add .
git commit -m "Add new feature"

# 推送到远程
git push origin feature/your-feature-name
```

---

## 参考链接

- [Flutter 官方文档](https://docs.flutter.dev)
- [鸿蒙 Flutter 开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/flutter-harmonyos-V5-overview)
- [DevEco Studio 下载](https://developer.huawei.com/consumer/cn/download/deveco-studio)
- [Flutter Riverpod 文档](https://riverpod.dev/docs/introduction/getting_started)
