---
name: ohos-release-debug-install
description: 覆盖安装 HarmonyOS APP 到真机。触发词 — 安装、装到手机、install、deploy、hdc、真机。永远使用 hdc 全路径覆盖安装（-r），绝不卸载，保护用户数据。
---

# OHOS 真机覆盖安装

## 绝对规则

1. **永远使用 `hdc install -r`（覆盖安装）**，保留应用数据。
2. **绝不执行 `hdc uninstall`**，卸载会清除全部本地数据（Hive 数据库、Token、加密密钥、PC 连接状态）。
3. **永远使用 hdc 全路径**（从 `ohos/local.properties` → `hwsdk.dir` 解析），不依赖系统 PATH 中的 hdc。
4. 安装前先 `aa force-stop` 停止运行中的 app，避免覆盖后残留旧进程。

## 触发条件

以下表述均触发此 skill：
- 安装、装到手机、装到真机、安装到设备
- install、deploy、push to device
- hdc、hdc install
- 覆盖安装、更新 app
- 真机调试（非 hot reload 场景）

## 两种安装方式

### 方式 A：使用项目脚本（推荐）

一键构建 + 覆盖安装：

```bash
bash .agents/skills/ohos-release-debug-install/scripts/build_release_install_debug_profile.sh --device-id <device-id>
```

脚本内部会：
1. 从 `ohos/local.properties` 读取 `hwsdk.dir`，解析 hdc 全路径
2. 检测陈旧产物，必要时 `flutter clean`
3. 清除旧的 signed `.app` 产物
4. `flutter build app --release`
5. `aa force-stop` 停止运行中的 app
6. **`hdc -t <device-id> install -r <artifact>`** — 覆盖安装
7. `bm dump` 验证安装结果

### 方式 B：使用 ./scripts/run.sh

```bash
./scripts/run.sh run -d <device-id>
```

适用于 debug 模式安装或需要 `scripts/run.sh` 提供的额外预检流程时。

### 方式 C：手动 hdc 全路径覆盖安装

当 release 产物已存在且未过期时，可跳过构建直接安装：

```bash
# 1. 从 local.properties 解析 hdc 全路径
HDC_BIN="$(grep 'hwsdk.dir' ohos/local.properties | cut -d'=' -f2-)/default/openharmony/toolchains/hdc"

# 2. 找到 signed artifact
ARTIFACT="$(ls -t ohos/build/outputs/default/*-all-signed.app | head -1)"

# 3. 停止 app
"$HDC_BIN" -t <device-id> shell aa force-stop cn.svton.happy

# 4. 覆盖安装（注意 -r 标志）
"$HDC_BIN" -t <device-id> install -r "$ARTIFACT"
```

## 选择逻辑

| 用户意图 | 方式 |
|---------|------|
| "安装到真机"、"覆盖安装"、"install" | **A（脚本）** |
| "debug 安装"、"调试模式安装" | **B（run.sh --debug）** |
| "只安装不构建"、产物已存在 | **C（手动 hdc）** |
| 用户明确指定用 run.sh | **B** |

## 输出

安装完成后报告：
- 设备 ID
- hdc 全路径
- 安装模式：release / debug
- 签名 profile 全路径
- 签名 cert 全路径
- 安装产物全路径
- 安装结果（成功/失败 + 诊断信息）
