# 鸿蒙应用验证与上线指南

> ⚠️ **重要说明**：Flutter 官方尚未正式支持 HarmonyOS 作为构建目标。当前项目是标准 Flutter 项目，可直接构建 Android/iOS/macOS/Windows/Web 版本。要发布鸿蒙版本，需要使用第三方桥架或等待官方支持。详见本文档"鸿蒙支持现状"章节。

---

## 目录
- [环境准备](#环境准备)
- [本地测试](#本地测试)
- [真机调试](#真机调试)
- [构建发布包](#构建发布包)
- [上线材料清单](#上线材料清单)
- [华为应用市场发布流程](#华为应用市场发布流程)

---

## 鸿蒙支持现状

### 当前项目支持的平台

| 平台 | 构建命令 | 状态 |
|------|----------|------|
| Android | `flutter build apk` | ✅ 完全支持 |
| iOS | `flutter build ios` | ✅ 完全支持 |
| macOS | `flutter build macos` | ✅ 完全支持 |
| Windows | `flutter build windows` | ✅ 完全支持 |
| Web | `flutter build web` | ✅ 完全支持 |
| HarmonyOS | - | ⚠️ 需要额外处理 |

### 为什么不能直接构建 HAP 包？

1. **Flutter 官方支持状态**
   - Flutter SDK 暂未将 HarmonyOS 作为一级构建目标
   - 目前仅支持：Android、iOS、Linux、macOS、Windows、Web

2. **项目当前结构**
   - `lib/` - 标准 Flutter 代码
   - `harmony/` - 仅包含 MethodChannel 插件，不是完整应用
   - 缺少 Flutter-to-HarmonyOS 转换层

### 发布鸿蒙的可选方案

| 方案 | 工作量 | 时间 | 推荐度 |
|------|--------|------|----------|
| **A: 先发布 Android 版本** | 最小 | 1-2 天 | ⭐⭐⭐⭐⭐⭐ |
| **B: 使用 flutter_harmonyos 框架** | 中 | 2-4 周 | ⭐⭐⭐ |
| **C: 重写为纯鸿蒙应用** | 大 | 2-3 月 | ⭐⭐ |
| **D: 等待 Flutter 官方支持** | 无 | 未知 | ⭐ |

### 方案详解

#### 方案 A：先发布 Android 版本（推荐）

**优势**：
- 可立即发布，获得用户反馈
- Android 版本可以在华为手机上运行
- 开发成本最低

**操作**：
```bash
# 构建 Android Release 包
flutter build apk --release

# 构建 App Bundle（推荐 Google Play）
flutter build appbundle --release
```

#### 方案 B：使用 flutter_harmonyos 框架

**开源项目**：
- https://github.com/OpenHarmony-TPC/flutter_harmonyos
- https://gitee.com/openharmony-sig/flutter_flutter

**操作**：
```yaml
# pubspec.yaml
dependencies:
  flutter_harmonyos: ^0.3.0
```

```bash
# 运行迁移脚本
flutter_harmonyos_tools pub get
flutter_harmonyos_tools migrate
```

#### 方案 C：重写为纯鸿蒙应用

**技术栈**：
- ArkUI（鸿蒙原生 UI）
- ArkTS（编程语言）
- @ohos 系统模块

**策略**：
- 复用业务逻辑层（domain 层）
- 重写 UI 层（presentation 层）
- 重新实现状态管理

#### 方案 D：等待官方支持

**进度追踪**：
- https://github.com/flutter/flutter/issues?q=harmonyos
- Flutter 官方 Roadmap 包含 HarmonyOS 支持

---

## 环境准备

### 1. 开发环境安装

```bash
# 安装 DevEco Studio
# 下载地址: https://developer.huawei.com/consumer/cn/deveco-studio/

# 安装 HarmonyOS SDK
# 在 DevEco Studio 中通过 SDK Manager 安装
# 推荐版本: HarmonyOS SDK API 9+ (基于 ArkTS)

# 配置 Node.js (用于 Flutter HarmonyOS Bridge)
node --version  # 需要 >= 16.x
```

### 2. 项目配置检查

确认以下配置文件正确：

| 文件 | 用途 | 检查项 |
|------|------|----------|
| `harmony/app.json` | 应用基本信息 | name, version, package |
| `harmony/module.json5` | 模块配置 | permissions, abilities |
| `pubspec.yaml` | Flutter 依赖 | 所有依赖已添加 |
| `analysis_options.yaml` | 代码分析 | lint 规则配置 |

### 3. 签名配置

```bash
# 创建签名密钥
# DevEco Studio: Build > Generate Key and Certificate

# 需要的信息：
# - 密钥库密码 (.jks/.p12)
# - 密钥密码
# - 密钥别名
# - 发布有效期
```

---

## 本地测试

### 1. 单元测试

```bash
# 运行 Flutter 单元测试
flutter test

# 运行特定测试文件
flutter test test/features/auth/
```

### 2. 插件功能测试

测试所有 MethodChannel 方法：

| 插件 | 测试方法 | 预期结果 |
|------|----------|----------|
| LiveKit | connectSession, disconnect, sendAudio | 成功连接/断开 |
| Libsodium | generateKey, encrypt, decrypt | 成功加密/解密 |
| Push | initialize, requestPermissions | 成功初始化/获取权限 |
| QR | generate, startScanning | 成功生成/扫描 |
| File | selectFiles, saveFile | 成功选择/保存文件 |
| Device | getDeviceInfo, requestCameraPermission | 成功获取信息/权限 |

### 3. 集成测试

```bash
# 使用模拟器测试
# DevEco Studio: Tools > Device Manager

# 推荐测试设备:
# - Huawei P40 (API 9)
# - Huawei Mate 60 Pro (API 10)
# - 荣耀系列手机
```

---

## 真机调试

### 1. 启用开发者模式

```
设置 > 关于手机 > 连续点击"HarmonyOS版本" 7次
> 进入开发者模式
> 打开 USB 调试
```

### 2. 配置 ADB 连接

```bash
# 检查设备连接
hdc list devices

# 安装到真机
hdc install hap包路径

# 查看日志
hdc shell hilog | grep happy_coder
```

### 3. 真机测试清单

- [ ] 应用安装成功
- [ ] 启动无闪退
- [ ] 认证功能正常
- [ ] Socket.IO 连接正常
- [ ] 消息收发正常
- [ ] 音频通话功能正常
- [ ] 推送通知接收正常
- [ ] QR 码扫描/生成正常
- [ ] 文件选择/保存正常
- [ ] 权限请求正常
- [ ] 网络请求正常
- [ ] 加密/解密功能正常
- [ ] 设置页面正常
- [ ] 退出登录正常
- [ ] 深色/浅色主题切换正常

---

## 构建发布包

### 1. 构建 HAP 包

```bash
# 方法1: 使用 DevEco Studio
# 1. 打开项目
# 2. Build > Build HAP(s)/APP(s) > Build HAP(s)
# 3. 选择 Release 模式
# 4. 等待构建完成

# 方法2: 使用命令行 (需要 hvigorw)
hvigorw assembleHap --mode module -p module=entry@default -p product=default
```

### 2. 构建结果

构建成功后会生成：

```
harmony/entry/build/default/outputs/default/
├── entry-default-signed.hap    # 签名后的发布包
└── entry-default-unsigned.hap   # 未签名版本（仅用于测试）
```

### 3. 验证 HAP 包

```bash
# 检查包信息
hdc shell bm dump -n com.happy.coder.harmony

# 安装测试
hdc install entry-default-signed.hap
```

---

## 上线材料清单

### 必备材料

| 材料类型 | 文件格式 | 说明 | 状态 |
|----------|----------|------|------|
| 应用图标 | PNG (512x512) | 无圆角、透明背景 | ⬜ 待准备 |
| 应用截图 | PNG/JPG (至少 5 张) | 展示核心功能 | ⬜ 待准备 |
| 应用视频 | MP4 (15-30 秒) | 演示主要功能 | ⬜ 待准备 |
| 软著证书 | JPG/PDF | 证明版权归属 | ⬜ 待准备 |
| ICP 备案 | 图片 + 文字 | 大陆开发者必需 | ⬜ 待准备 |
| 隐私政策 | URL | 隐私政策页面 | ⬜ 待准备 |
| 用户协议 | URL | 用户服务协议 | ⬜ 待准备 |
| 应用签名 | .p12 或 .jks | 发布签名 | ⬜ 待准备 |

### 图标规格

| 用途 | 尺寸 | 格式 | 备注 |
|------|------|------|------|
| 应用市场图标 | 512x512 | PNG | 无圆角 |
| 启动图 | 1080x1920 | PNG | 带品牌元素 |
| 小图标 | 24x24, 36x36, 48x48, 72x72, 96x96 | PNG | 通知栏等 |

### 截图要求

- **至少 5 张截图**，尺寸：1080 x 1920 或更高
- **场景建议**：
  1. 登录/认证界面
  2. 会话列表界面
  3. 聊天界面（包含消息输入）
  4. 代码编辑/Diff 视图
  5. 设置/个人中心

### 应用描述

**简短描述**（100 字以内）：
> Happy Coder - AI 驱动的编程助手，支持 Claude AI，提供实时语音对话和代码协作。

**详细描述**（5000 字以内）：
```
Happy Coder 是一款基于 Claude AI 的智能编程助手应用，专为开发者打造。

核心功能：
- 智能代码生成：基于 Claude AI 的代码补全和生成
- 实时语音对话：支持语音输入和实时对话
- 多会话管理：同时进行多个编程项目对话
- 代码协作：内置 Diff 视图，支持代码对比和合并
- 工具调用：支持文件操作、Git 管理、代码执行等工具
- 端到端加密：采用 Libsodium 加密，保护隐私安全
- 跨平台同步：支持桌面、移动端数据同步

适用人群：
- 软件开发者
- 学习编程的学生
- 需要 AI 辅助编程的程序员

技术特点：
- 基于 Flutter 跨平台框架
- 采用 Clean Architecture 设计模式
- 集成 LiveKit 实时语音
- 支持 Socket.IO 实时通信
```

### 关键词（Tags）

```
编程助手,AI编程,Claude,代码生成,实时对话,代码协作,
开发者工具,IDE,ChatGPT替代,代码补全,语音对话
```

### 分类选择

华为应用市场分类建议：
- **一级分类**：工具
- **二级分类**：效率

---

## 华为应用市场发布流程

### 1. 注册开发者账号

```
访问: https://developer.huawei.com/consumer/cn/
步骤:
1. 注册华为账号
2. 完成实名认证
3. 注册成为开发者
4. 等待审核（通常 1-3 天）
```

### 2. 创建应用

```
1. 登录 AppGallery Connect
2. 选择"我的应用" > "添加应用"
3. 填写应用信息
4. 上传应用截图
5. 配置应用分类和标签
6. 提交审核
```

### 3. 上传 HAP 包

```
1. 在应用详情页面选择"版本管理"
2. 点击"上传新版本"
3. 上传 entry-default-signed.hap
4. 填写版本更新说明
5. 提交审核
```

### 4. 审核时间

| 审核类型 | 预计时间 | 备注 |
|----------|----------|------|
| 新应用审核 | 3-7 个工作日 | 首次上架时间较长 |
| 版本更新 | 1-3 个工作日 | 功能更新通常较快 |
| 紧急修复 | 24 小时内 | 需特殊申请 |

### 5. 常见审核问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 权限说明不足 | 权限用途描述不清楚 | 补充详细的使用场景 |
| 隐私政策缺失 | 未提供隐私政策 | 上线隐私政策页面 URL |
| 图标不规范 | 有圆角或背景 | 使用无圆角图标 |
| 截图不符 | 尺寸或内容不符 | 按要求重新制作 |
| 功能描述不完整 | 关键功能未展示 | 补充完整描述 |

---

## 技术支持联系方式

| 问题类型 | 联系方式 |
|----------|----------|
| 开发问题 | 开发者社区论坛 |
| 审核问题 | AppGallery Connect 客服 |
| 技术咨询 | 华为开发者支持 |

---

## 附录：快捷命令参考

```bash
# 项目根目录快捷命令
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter

# Flutter 相关
flutter pub get          # 安装依赖
flutter analyze          # 代码分析
flutter build apk       # 构建 Android
flutter clean           # 清理缓存

# HarmonyOS 相关 (需要 DevEco Studio 环境)
hdc list devices      # 列出连接的设备
hdc install hap包    # 安装 HAP
hdc shell hilog      # 查看日志
hdc uninstall 包名   # 卸载应用

# 代码格式化
dart format .
dart fix --apply
```

---

**文档版本**: 1.0
**更新日期**: 2026-02-28
