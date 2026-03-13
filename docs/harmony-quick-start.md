# 鸿蒙开发环境快速配置

> ⚠️ **说明**：Flutter 项目目前**无法直接构建**为 HAP 包。本文档适用于已使用 flutter_harmonyos 等框架适配后的项目。如果只是标准 Flutter 项目，请先构建 Android 版本（可在华为手机运行）。

## 一、环境安装

### 1. DevEco Studio 安装

```bash
# 下载 DevEco Studio
# 访问: https://developer.huawei.com/consumer/cn/deveco-studio/

# 下载版本: DevEco Studio 5.0+ (API 9+)

# 安装要求
# - macOS: 10.15+
# - Windows: 10 或更高
# - 内存: 8GB+
# - 磁盘: 20GB+
```

### 2. HarmonyOS SDK 安装

```
DevEco Studio 启动后：
1. File > Settings > SDK
2. 选择 HarmonyOS SDK API 9 或更高
3. 点击 Download 等待安装完成
```

### 3. Node.js 安装

```bash
# macOS 使用 Homebrew
brew install node@18

# Windows 下载安装包
# 访问: https://nodejs.org/

# 验证安装
node --version  # 需要 >= 16.x
npm --version
```

---

## 二、项目导入

### 1. 导入 Flutter 项目

```
1. 打开 DevEco Studio
2. File > Open > 选择项目目录
3. 等待 Gradle 同步完成
```

### 2. 配置项目签名

```
1. Build > Generate Key and Certificate
2. 填写信息：
   - Key store path: 选择存储位置
   - Key store password: 设置密钥库密码
   - Key alias: 设置密钥别名
   - Key password: 设置密钥密码
3. 保存配置（请妥善保管密码！）
```

---

## 三、真机调试

### 1. 启用开发者模式

```
1. 打开手机"设置"
2. 进入"关于手机"
3. 连续点击"HarmonyOS版本" 7 次
4. 返回"系统和更新"
5. 进入"开发人员选项"
6. 开启"USB 调试"
```

### 2. 连接设备

```bash
# 安装 hdc 工具 (随 DevEco Studio 自动安装)
hdc list devices

# 输出示例：
# 设备 ID          类型
# 700100545392874893    phone
```

### 3. 安装到真机

```bash
# 构建 HAP 包
# DevEco Studio: Build > Build HAP(s)/APP(s)

# 安装
hdc install <hap文件路径>

# 示例:
hdc install harmony/entry/build/default/outputs/default/entry-default-signed.hap
```

---

## 四、日志查看

### 1. 实时日志

```bash
# 查看所有日志
hdc shell hilog

# 过滤应用日志
hdc shell hilog | grep happy_coder

# 清除日志
hdc shell hilog -r
```

### 2. 日志保存

```bash
# 保存到文件
hdc shell hilog > debug.log

# 持续监控并保存
hdc shell hilog -v time | tee debug.log
```

---

## 五、常用命令

### Flutter 相关

```bash
# 项目根目录执行
cd /Users/zhaoxingbo/Workspace/ai-driven/happy-coder-flutter

# 安装依赖
flutter pub get

# 代码分析
flutter analyze

# 代码格式化
dart format .

# 清理缓存
flutter clean
```

### HarmonyOS 相关

```bash
# 设备管理
hdc list devices              # 列出设备
hdc install hap包            # 安装应用
hdc uninstall 包名           # 卸载应用
hdc start 包名              # 启动应用
hdc stop 包名               # 停止应用

# 日志
hdc shell hilog             # 查看日志
hdc shell hilog -r         # 清除日志
hdc shell hilog -x 包名      # 仅查看指定应用日志

# 文件操作
hdc file send 本地文件 远程路径   # 发送文件到设备
hdc file recv 远程路径 本地路径   # 从设备获取文件
```

---

## 六、问题排查

### 问题 1: hdc 找不到设备

```bash
# 解决方案
1. 检查 USB 调试是否开启
2. 尝试重新插拔 USB 线
3. 重启 hdc 服务
   hdc kill
   hdc start
```

### 问题 2: 构建失败

```bash
# 解决方案
1. 清理项目
   Build > Clean Project
2. 删除 .gradle 缓存
   rm -rf ~/.gradle/caches/
3. 重新同步
   File > Sync Project with Gradle Files
```

### 问题 3: 签名错误

```bash
# 解决方案
1. 确认密码正确
2. 重新生成签名
   Build > Generate Key and Certificate
3. 在 module.json5 中更新签名配置
```

### 问题 4: 应用闪退

```bash
# 解决方案
1. 查看崩溃日志
   hdc shell hilog | grep -i "crash\|fatal"
2. 检查权限是否正确
3. 确认 MethodChannel 调用前检查可用性
```

---

## 七、资源链接

| 资源 | 链接 |
|------|------|
| DevEco Studio 下载 | https://developer.huawei.com/consumer/cn/deveco-studio/ |
| HarmonyOS SDK 文档 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ |
| 华为开发者社区 | https://developer.huawei.com/consumer/cn/forum/ |
| Flutter 鸿蒙支持 | https://docs.flutter.dev/platform-integration/harmonyos/overview |

---

**文档版本**: 1.0
**更新日期**: 2026-02-28
