# Happy Coder - 快速运行和调试指南

## 环境检查

```bash
# 检查 Flutter
flutter doctor

# 检查可用设备
flutter devices
```

---

## 快速开始

### 方式 1：VS Code + macOS

```bash
# 1. 用 VS Code 打开项目
code /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter

# 2. 在 VS Code 中:
#    - 按 F5 运行
#    - 或按 F5 → Debug → Start Debugging
#    - 设置断点后按 F5 继续
```

### 方式 2：命令行（推荐）

```bash
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter

# 如果依赖安装失败，先清理缓存
flutter clean

# 运行 macOS 应用
flutter run -d macos

# 或构建
flutter build macos
```

---

## 问题排查

### pubspec.yaml 解析错误

如果遇到 `Expected a key while parsing a block mapping` 错误：

**问题原因**: pubspec.yaml 中可能存在格式问题

**解决方案**:

1. 验证文件编码
```bash
file pubspec.yaml
# 应该显示 "ASCII text"
```

2. 手动测试解析
```bash
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter
flutter pub deps
# 只检查，不安装
```

3. 清理并重试
```bash
flutter clean
rm -rf .flutter-plugins .packages
flutter pub get
```

---

## 鸿蒙调试

### DevEco Studio 配置

1. **下载**: https://developer.huawei.com/consumer/cn/download/deveco-studio

2. **配置 SDK**:
   - SDK Manager → HarmonyOS NEXT (API 12+)

3. **连接设备**:
   - Tools → Device Manager
   - 选择真机或启动模拟器

### 运行步骤

1. 在 DevEco Studio 中打开项目
   ```
   File → Open
   选择 happy_coder_flutter 目录
   ```

2. 选择设备
   ```
   工具栏 → 设备选择器
   选择 HarmonyOS 设备或模拟器
   ```

3. 运行
   ```
   工具栏 → 运行按钮（绿色三角形）
   ```

---

## 调试技巧

### Flutter 端调试

1. **VS Code**
   - F5 - 运行
   - Shift+Cmd+D - 打开调试控制台
   - 红点断点 - 在代码行号左侧点击

2. **热重载**
   - `r` - 热重载（保存后）
   - `Shift+R` - 热重载（全部）
   - `R` - 重启应用

### 鸿蒙原生调试

1. **日志查看**
   - DevEco Studio → 底部 "Run" 窗口
   - 过滤日志: `tag:LiveKit`, `tag:Auth`

2. **断点调试**
   - 在插件文件中设置断点
   - 点击虫子图标进入调试模式

---

## 常用命令

```bash
# 项目根目录
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter

# 环境检查
flutter doctor
flutter devices

# 清理构建
flutter clean

# 获取依赖
flutter pub get

# 运行 macOS
flutter run -d macos

# 构建 macOS Release
flutter build macos --release

# 代码分析
flutter analyze

# 运行测试
flutter test
```

---

## VS Code 配置

### 推荐扩展

| 扩展 | 用途 |
|------|------|
| Flutter | Flutter 官方扩展 |
| Dart | Dart 语法支持 |
| Error Lens | 错误详情显示 |

### 快捷键配置

在 `.vscode/settings.json` 或通过 UI 设置中添加：

```json
{
  "[dart]": {
    "editor.formatOnSave": "always",
    "editor.defaultFormatter": "dart format"
  },
  "[flutter]": {
    "editor.codeActionsOnSave": "source.fixAll"
  }
}
```

---

## 权限问题

如果鸿蒙调试遇到权限问题：

1. **权限检查**: DevEco Studio → Run → 配置权限
2. **授权**: 在真机上确认权限

---

## 下一步

1. [ ] 修复 pubspec.yaml 解析问题
2. [ ] 运行 `flutter doctor` 确认环境
3. [ ] 尝试运行 `flutter run -d macos`
4. [ ] 安装 DevEco Studio
5. [ ] 在 DevEco Studio 中运行鸿蒙版本
