# 使用 flutter_harmonyos 实战指南

> 华为官方维护的 Flutter 到鸿蒙转换单元 `flutter_harmonyos`，可让现有 Flutter 项目运行在鸿蒙设备上。这是**华为官方推荐的方案**，不是纯 ArkTS 重写。

---

## 一、方案概述

### 1.1 什么是 flutter_harmonyos？

| 特性 | 说明 |
|------|------|
| 官方方案 | ✅ 华为维护的开源项目 |
| 代码复用 | ✅ Flutter 代码大部分可直接复用 |
| 转换层 | 自动处理 Dart 到 ArkTS 的转换 |
| 开发效率 | ✅ 相比重写更快 |

### 1.2 相关工具生态

| 工具 | 用途 | 状态 |
|------|------|
| `flutter_harmonyos` | Flutter → 鸿蒙基础转换单元 | ✅ 官方 |
| `flutterflow_cli` | 云端设计稿同步与代码生成 | ✅ 可选 |
| `nohos_flutter_hybrid` | 混合开发（Flutter UI + 鸿蒙原生）| 可选 |
| `nohos_ark_ui` | ArkUI 组件转换 | 可选 |

---

## 二、快速开始

### 2.1 环境准备

```bash
# 1. 安装 Flutter 3.24.0+ (如果未安装)
flutter --version

# 2. 安装 DevEco Studio 5.0+
# 下载: https://developer.huawei.com/consumer/cn/deveco-studio/

# 3. 安装 HarmonyOS SDK (API 12+)
# DevEco Studio: Settings > SDK Manager
# 推荐: HarmonyOS SDK API 12 (用于 flutter_harmonyos)
```

### 2.2 创建鸿蒙项目

```bash
# 在当前项目目录创建鸿蒙项目
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter

# 创建鸿蒙项目（会自动使用 flutter_harmonyos）
flutter create --platforms ohos happy_coder_harmony

# 新项目结构：
# happy_coder_harmony/
# ├── ohos/              # 鸿蒙原生代码
# ├── entry/             # 应用入口
# ├── lib/               # Flutter 代码（自动生成）
# └── oh-package.json5   # 鸿蒙配置
```

### 2.3 配置项目

```bash
# 进入鸿蒙项目目录
cd happy_coder_harmony

# 配置 pubspec.yaml（添加依赖）
```

```yaml
# pubspec.yaml - 添加鸿蒙依赖
name: happy_coder_harmony
description: Happy Coder HarmonyOS version

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter_harmonyos: ^0.3.0  # 华为官方转换单元
  # Flutter 依赖（可复用原项目的业务逻辑）
  # 这里不需要添加所有依赖，flutter_harmonyos 会自动处理

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

---

## 三、代码迁移

### 3.1 项目结构对比

| 原项目 | 鸿蒙项目 | 迁移策略 |
|------|----------|----------|
| `lib/features/` | `lib/` | 直接复制代码 |
| 状态管理 | 复用 | 复用 |
| UI 组件 | 需要适配 | 部分需要重新实现 |
| 路由 | go_router | 需要替换为鸿蒙路由 |

### 3.2 代码迁移步骤

```bash
# 方案 A：使用官方同步工具（推荐）
# 1. 将 lib/ 代码复制到鸿蒙项目
# 2. 在鸿蒙项目运行，由 flutter_harmonyos 自动转换

# 方案 B：手动迁移关键代码
# 只迁移需要适配的部分（权限、文件操作等）
```

### 3.3 关键代码适配

| 代码类型 | 说明 |
|------|------|
| HTTP 请求 (dio) | ✅ 可直接使用 |
| Socket.IO | ✅ 可直接使用 |
| LocalStorage (hive) | ⚠️ 需改用华为 `@ohos.data.preferences` |
| SecureStorage | ⚠️ 需改用华为加密方案 |
| Permissions | ⚠️ 需使用华为权限 API |

---

## 四、功能适配

### 4.1 保留功能

以下功能可直接使用，无需修改：

| 功能模块 | 原代码 | 鸿蒙支持 |
|----------|----------|----------|
| 认证 UI | ✅ 完全支持 | ✅ 完全支持 |
| 会话列表 | ✅ 完全支持 | ✅ 完全支持 |
| 聊天界面 | ✅ 完全支持 | ✅ 完全支持 |
| 消息输入 | ✅ 完全支持 | ✅ 完全支持 |
| Markdown 渲染 | ✅ 完全支持 | ✅ 完全支持 |
| 代码高亮 | ✅ 完全支持 | ✅ 完全支持 |
| 设置页面 | ✅ 完全支持 | ✅ 完全支持 |

### 4.2 需要适配的功能

| 功能模块 | 适配方式 |
|----------|----------|
| 推送通知 | 使用 `@ohos.push` |
| 文件操作 | 使用 `@ohos.file.picker` |
| 权限管理 | 使用 `@ohos.abilityAccessCtrl` |
| 设备信息 | 使用 `@ohos.deviceInfo` |
| 剪贴板 | 使用 `@ohos.pasteboard` |
| 加密功能 | 使用 `@kit.CryptoArchitectureKit` |

### 4.3 桥接方法

当前 `harmony/` 目录的 MethodChannel 可继续使用：

| MethodChannel | 用途 |
|-----------|------|
| `happy.livekit` | LiveKit 语音 |
| `happy.libsodium` | 加密功能 |
| `happy.push` | 推送通知 |
| `happy.qrcode` | QR 码 |
| `happy.file` | 文件操作 |
| `happy.device` | 设备信息 |

**优势**：这些桥接代码已经写好，可以直接复用！

---

## 五、构建与运行

### 5.1 构建项目

```bash
# 在鸿蒙项目目录
cd happy_coder_harmony

# 安装依赖
flutter pub get

# 构建 HAP 包（支持签名）
flutter build hap --release
```

### 5.2 在 DevEco Studio 中运行

```
1. File > Open > 打开鸿蒙项目
2. 选择设备（模拟器或真机）
3. 点击运行按钮
```

### 5.3 构建输出

```
happy_coder_harmony/build/outputs/default/
├── entry-default-signed.hap     # 签名后的发布包
└── entry-default-unsigned.hap    # 未签名版本（用于测试）
```

---

## 六、与纯鸿蒙开发对比

| 维度 | flutter_harmonyos | 纯 ArkTS 开发 |
|------|----------|--------------|
| 开发速度 | 快（代码复用率高）| 慢（需要全部重写）|
| 代码维护 | 低（单一代码库）| 中（需要维护两套）|
| 学习曲线 | 低（Flutter 开发者）| 高（需要学习 ArkTS）|
| 适用场景 | 现有 Flutter 项目适配 | 全新项目开发 |
| 官方支持 | ✅ 有官方维护和更新| 需要自己跟进 |
| 生态兼容性 | ✅ 与 Flutter 生态互通| 鸿蒙专属生态 |

---

## 七、常见问题

### Q1: 构建失败？

```bash
# 清理缓存
flutter clean
flutter pub get

# 重新构建
flutter build hap --release
```

### Q2: 某些依赖不支持？

flutter_harmonyos 会自动处理大部分 Flutter 依赖，但有部分需要替换为鸿蒙原生 API：

| 原依赖 | 鸿蒙替代 |
|----------|----------|
| `flutter_secure_storage` | `@ohos.data.preferences` |
| `path_provider` | `@ohos.file.fs` |
| `permission_handler` | `@ohos.abilityAccessCtrl` |

### Q3: 如何调试鸿蒙代码？

```bash
# 使用 DevEco Studio 的日志查看器
# 或使用 hdc 命令
hdc shell hilog | grep happy_coder
```

### Q4: 性能优化建议

1. 使用 `ListView.builder` 替代 `Column`
2. 使用 `const` 构造函数
3. 避免不必要的 `setState` 调用
4. 图片资源使用鸿蒙支持的格式

---

## 八、推荐学习资源

| 资源 | 链接 |
|------|------|
| 官方仓库 | https://github.com/openharmony-tpc/flutter_harmonyos |
| Flutter 鸿蒙生态 | https://openharmonycrossplatform.csdn.net |
| DevEco Studio 教程 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ |
| 鸿蒙开发者论坛 | https://developer.huawei.com/consumer/cn/forum/ |

---

## 九、行动建议

### 立即行动

```bash
# 1. 创建测试用的鸿蒙项目
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter
flutter create --platforms ohos happy_coder_test

# 2. 验证基础功能能否运行
```

### 本周完成

- [ ] 安装 DevEco Studio
- [ ] 运行 `flutter create --platforms ohos` 创建测试项目
- [ ] 验证核心功能（认证、会话列表、聊天界面）
- [ ] 记录适配过程中的问题

### 下周计划

- [ ] 完成关键功能的适配
- [ ] 性能测试
- [ ] 真机测试

---

**文档版本**: 1.0
**更新日期**: 2026-03-01
