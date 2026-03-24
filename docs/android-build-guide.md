# Android 构建与发布指南

> Android 版本可以在华为手机上运行，是当前最可行的发布方案。

## 快速构建

### 1. 构建 APK

```bash
# 项目根目录
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter

# 构建 Debug APK（用于测试）
flutter build apk --debug

# 构建 Release APK（用于分发）
flutter build apk --release
```

### 2. 构建 App Bundle（推荐 Google Play）

```bash
# 构建 App Bundle（更小的包大小）
flutter build appbundle --release

# 输出位置
# build/app/outputs/bundle/release/app-release.aab
```

### 3. 构建 Split APK（按架构）

```bash
# 分别构建不同架构的 APK（更小体积）
flutter build apk --split-per-abi --release

# 输出
# build/app/outputs/flutter-apk/
# ├── app-armeabi-v7a-release.apk
# ├── app-arm64-v8a-release.apk
# ├── app-x86_64-release.apk
# └── app-release.apk（通用版）
```

---

## 构建输出

| 文件 | 用途 | 位置 |
|------|------|------|
| app-release.apk | 通用安装包 | build/app/outputs/flutter-apk/ |
| app-arm64-v8a-release.apk | 64位 ARM | build/app/outputs/flutter-apk/ |
| app-release.aab | Google Play 专用 | build/app/outputs/bundle/release/ |

---

## 真机安装测试

### 1. ADB 连接

```bash
# 检查设备连接
adb devices

# 安装 APK
adb install build/app/outputs/flutter-apk/app-release.apk

# 卸载
adb uninstall cn.svton.happy

# 启动
adb shell am start -n cn.svton.happy/.MainActivity
```

### 2. 华为手机特殊设置

```
如果遇到安装问题：
1. 进入设置 > 安全和隐私
2. 关闭"从非官方来源安装应用"的检查
```

---

## 应用签名（发布必需）

### 1. 生成签名密钥

```bash
# 使用 keytool 生成
keytool -genkey -v -keystore happy-coder.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias happy-coder-key

# 输入信息：
# 密钥库密码：__________________
# 密钥密码：__________________
# 姓名：__________________
# 组织单位：__________________
# 城市：__________________
# 省份：__________________
# 国家代码：CN
```

### 2. 配置签名（build.gradle）

在 `android/app/build.gradle` 中：

```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 3. keystore.properties 文件

创建 `android/key.properties`：

```
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=happy-coder-key
storeFile=../keystore/happy-coder.jks
```

---

## 应用商店发布

### 1. Google Play

```
1. 访问 Google Play Console
2. 创建应用
3. 上传 app-release.aab
4. 填写商店信息
5. 提交审核（1-3 天）
```

### 2. 华为应用市场（Android 版本）

```
1. 访问 https://developer.huawei.com/consumer/cn/
2. 登录 AppGallery Connect
3. 创建应用（选择"Android"类型）
4. 上传 app-release.aab 或 app-release.apk
5. 填写信息并提交审核
```

**说明**：虽然这不是鸿蒙原生应用，但 Android 版本可以在 HarmonyOS 4.0+ 的华为手机上通过兼容层运行。

---

## 包大小优化

### 检查当前包大小

```bash
# 查看 APK 大小
ls -lh build/app/outputs/flutter-apk/app-release.apk

# 分析内容
unzip -l build/app/outputs/flutter-apk/app-release.apk
```

### 优化建议

| 优化项 | 预期效果 |
|--------|----------|
| 启用 ProGuard | 减少 10-20% |
| 启用混淆 | 保护代码 |
| 移除未使用资源 | 减少 5-10% |
| 启用 App Bundle | 用户下载更小 |

### ProGuard 配置

在 `android/app/build.gradle`：

```gradle
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-rules.pro')
        }
    }
}
```

---

## 版本号管理

### pubspec.yaml

```yaml
version: 1.0.0+1  # 1.0.0 版本，构建号 1
```

### 自动增加构建号

```bash
# 使用版本管理工具
# 安装
pub global activate version

# 自动增加版本
pub run version:minor  # 1.1.0
pub run version:patch  # 1.0.1
```

---

## 常见问题

### 问题 1: 构建失败

```bash
# 清理后重试
flutter clean
flutter pub get
flutter build apk --release
```

### 问题 2: 签名错误

```
确认：
- keystore 路径正确
- 密码匹配
- alias 名称一致
```

### 问题 3: 安装失败

```
华为手机：
- 检查"允许安装未知来源"设置
- 确认 Android 版本兼容

通用：
- adb uninstall 卸载旧版本
- 删除数据后重装
```

---

## 发布检查清单

- [ ] 测试所有核心功能
- [ ] 检查权限声明
- [ ] 验证签名配置
- [ ] 测试在不同 Android 版本（8, 10, 12, 13, 14）
- [ ] 测试在不同屏幕尺寸
- [ ] 准备应用图标（512x512）
- [ ] 准备截图（至少 5 张）
- [ ] 准备隐私政策链接
- [ ] 准备更新日志

---

**文档版本**: 1.0
**更新日期**: 2026-02-28
