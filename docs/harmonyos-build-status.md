# HarmonyOS 构建状态

## ⚠️ 关键问题：SDK 版本不兼容

### 问题分析

| 项目 | SDK 类型 | 兼容性 |
|------|----------|---------|
| 你已安装 | HarmonyOS NEXT 6.0.2 | 纯血鸿蒙 NEXT |
| flutter_harmonyos 需要 | OpenHarmony API 20 | 鸿蒙开放版 |

### 不兼容原因

- flutter_harmonyos 3.27.5 是为 **OpenHarmony** 设计的
- 你安装的是 **HarmonyOS NEXT**（纯血鸿蒙）
- 两者**不兼容**，无法共用

### 解决方案

| 方案 | 说明 | 推荐度 |
|------|------|--------|
| **方案 A：使用 DevEco Studio 构建** | DevEco 同时支持 NEXT SDK | ⭐⭐⭐⭐⭐ |
| **方案 B：安装 OpenHarmony SDK** | 下载 OpenHarmony SDK，与 flutter_harmonyos 兼容 | ⭐⭐ |
| **方案 C：等待官方支持** | 等待 Flutter 官方支持 HarmonyOS NEXT | ⭐ |

### 方案 A 详细步骤（推荐）

使用已安装的 DevEco Studio 直接构建：

1. 打开 DevEco Studio
2. `File > Open >` 选择 `happy-coder-flutter/ohos/` 目录
3. 等待项目同步完成
4. `Build > Build HAP(s)/APP(s) > Build Release HAP(s)`
5. 等待构建完成

### 方案 B 详细步骤

下载 OpenHarmony SDK：

```bash
# OpenHarmony SDK 下载链接（需要华为账号）
https://developer.huawei.com/consumer/cn/download/

# 选择 API Level 12 (OpenHarmony 3.2 Release)
# 安装后，更新环境变量
export HOS_SDK_HOME=~/Library/OpenHarmony/Sdk

# 使用flutter_harmonyos构建
/Users/zhaoxingbo/Workspace/ai-driven/flutter_harmonyos/bin/flutter build app --release
```

## 已完成的工作（准备工作）

| 步骤 | 状态 | 说明 |
|------|------|------|
| 安装 HarmonyOS Flutter SDK | ✅ 完成 | 位于 `../flutter_harmonyos/` |
| 创建 `ohos/` 目录 | ✅ 完成 | HarmonyOS 原生代码目录 |
| 配置 `ohos/oh-package.json5` | ✅ 完成 | 已添加 `harmony_native` 依赖 |
| 配置 `entry/oh-package.json5` | ✅ 完成 | 已添加 `harmony_native` 依赖 |
| 配置 `app.json5` | ✅ 完成 | 包名 `cn.svton.happy` |
| 配置 `module.json5` | ✅ 完成 | 已添加所有必需权限 |
| 设备类型 | ✅ 完成 | 支持 phone 和 tablet |

## 项目结构（已完成配置）

```

| 步骤 | 状态 | 说明 |
|------|------|------|
| 安装 HarmonyOS Flutter SDK | ✅ 完成 | 位于 `../flutter_harmonyos/` |
| 创建 `ohos/` 目录 | ✅ 完成 | HarmonyOS 原生代码目录 |
| 配置 `ohos/oh-package.json5` | ✅ 完成 | 已添加 `harmony_native` 依赖 |
| 配置 `entry/oh-package.json5` | ✅ 完成 | 已添加 `harmony_native` 依赖 |
| 配置 `app.json5` | ✅ 完成 | 包名 `cn.svton.happy` |
| 配置 `module.json5` | ✅ 完成 | 已添加所有必需权限 |
| 设备类型 | ✅ 完成 | 支持 phone 和 tablet |

## 项目结构

```
happy-coder-flutter/
├── lib/                    # Flutter Dart 代码
├── ohos/                   # ✅ 已创建的鸿蒙原生层
│   ├── AppScope/            # 应用范围配置
│   ├── entry/               # 入口模块
│   ├── oh-package.json5      # ✅ 已配置依赖
│   └── build-profile.json5   # 构建配置
└── harmony_native/          # ✅ 已迁移的插件
    ├── plugins/             # 6 个插件文件
    ├── utils/               # 工具类
    └── index.ets           # 导出文件
```

## 待完成工作

### 1. 安装 DevEco Studio

```bash
# 下载地址
https://developer.huawei.com/consumer/cn/deveco-studio/

# macOS 下载完成后，拖拽到 /Applications/ 安装
```

### 2. 安装 HarmonyOS SDK

1. 启动 DevEco Studio
2. Settings > SDK Manager
3. 选择 HarmonyOS SDK API 12 或更高版本
4. 点击 Download 等待安装完成

### 3. 配置环境变量

在 `~/.zshrc` 或 `~/.bash_profile` 中添加：

```bash
# HarmonyOS SDK 路径（根据实际安装路径调整）
export HOS_SDK_HOME=~/Library/Huawei/Sdk
export DEVECO_SDK_HOME=~/Library/Huawei/Sdk

# 或 DevEco Studio 的默认路径
export HOS_SDK_HOME=/Users/zhaoxingbo/Library/Huawei/Sdk
```

重新加载环境变量：
```bash
source ~/.zshrc
```

### 3. 已配置的权限

| 权限 | 用途 |
|------|------|
| `ohos.permission.INTERNET` | 网络访问 |
| `ohos.permission.CAMERA` | QR 码扫描 |
| `ohos.permission.MICROPHONE` | LiveKit 语音通话 |
| `ohos.permission.READ_IMAGEVIDEO` | 读取图片视频 |
| `ohos.permission.WRITE_IMAGEVIDEO` | 保存图片视频 |
| `ohos.permission.READ_MEDIA` | 读取媒体文件 |
| `ohos.permission.WRITE_MEDIA` | 写入媒体文件 |
| `ohos.permission.GET_NETWORK_INFO` | 获取网络信息 |
| `ohos.permission.NOTIFICATION_CONTROLLER` | 推送通知 |

### 4. 构建 HAP 包

```bash
# 使用 HarmonyOS Flutter SDK
/Users/zhaoxingbo/Workspace/ai-driven/flutter_harmonyos/bin/flutter build app --release

# 或在 DevEco Studio 中打开项目
File > Open > 选择 happy-coder-flutter/ohos/ 目录
Build > Build HAP(s)/APP(s) > Build Release HAP(s)
```

### 5. 输出位置

构建成功后，HAP 包位于：
```
happy-coder-flutter/ohos/build/outputs/default/
├── happy_coder_flutter-default-signed.hap       # 签名版本
└── happy_coder_flutter-default-unsigned.hap      # 未签名版本
```

## 鸿蒙 Flutter SDK 信息

| 项目 | 值 |
|------|-----|
| Flutter 版本 | 3.27.5-ohos-1.0.4 |
| Dart 版本 | 3.6.2 |
| SDK 位置 | `/Users/zhaoxingbo/Workspace/ai-driven/flutter_harmonyos/` |
| 支持平台 | ios, android, windows, linux, macos, web, ohos |

## 下一步操作

1. [ ] 安装 DevEco Studio
2. [ ] 在 DevEco Studio 中安装 HarmonyOS SDK (API 12+)
3. [ ] 配置 HOS_SDK_HOME 环境变量
4. [ ] 执行 `flutter build app --release` 构建 HAP
5. [ ] 在鸿蒙设备/模拟器上测试

## 备选方案

如果不想安装 DevEco Studio，可以考虑：

| 方案 | 说明 |
|------|------|
| **Android 版本** | 可直接在华为手机运行，推荐 |
| **云端构建** | 使用华为云端构建服务（需企业账号） |

---

**文档版本**: 1.0
**更新日期**: 2026-03-01
