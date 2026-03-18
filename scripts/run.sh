#!/bin/bash
#
# Happy Coder 项目运行脚本
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCAL_PROPERTIES="$PROJECT_DIR/ohos/local.properties"
BUILD_PROFILE="$PROJECT_DIR/ohos/build-profile.json5"

cd "$PROJECT_DIR"

if [[ ! -f "$LOCAL_PROPERTIES" ]]; then
  echo "✗ 缺少 $LOCAL_PROPERTIES"
  exit 1
fi

FLUTTER_ROOT="$(grep '^flutter.sdk=' "$LOCAL_PROPERTIES" | cut -d'=' -f2-)"
if [[ -z "${FLUTTER_ROOT:-}" ]]; then
  echo "✗ 未在 $LOCAL_PROPERTIES 中找到 flutter.sdk"
  exit 1
fi

FLUTTER_BIN="$FLUTTER_ROOT/bin/flutter"
if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "✗ Flutter 不可执行: $FLUTTER_BIN"
  exit 1
fi

HWSDK_DIR="$(grep '^hwsdk.dir=' "$LOCAL_PROPERTIES" | cut -d'=' -f2-)"
if [[ -n "${HWSDK_DIR:-}" ]]; then
  export HOS_SDK_HOME="$HWSDK_DIR"
  export OHOS_SDK_HOME="$HWSDK_DIR"
  if [[ -d "$HWSDK_DIR/default" ]]; then
    export DEVECO_SDK_HOME="$HWSDK_DIR"
  fi
fi

HDC_CANDIDATES=(
  "$HOS_SDK_HOME/default/openharmony/toolchains"
  "$HOS_SDK_HOME/default/toolchains"
  "$HOS_SDK_HOME/20/toolchains"
  "/Users/zhaoxingbo/Library/OpenHarmony/Sdk/20/toolchains"
)

for candidate in "${HDC_CANDIDATES[@]}"; do
  if [[ -x "$candidate/hdc" ]]; then
    export PATH="$candidate:$PATH"
    break
  fi
done

extract_device_id() {
  local previous=""
  for arg in "$@"; do
    if [[ "$previous" == "-d" || "$previous" == "--device-id" ]]; then
      printf '%s\n' "$arg"
      return 0
    fi
    previous="$arg"
  done
  return 1
}

format_epoch_local() {
  python3 - <<'PY' "$1"
import datetime
import sys

if not sys.argv[1]:
    raise SystemExit(0)

print(datetime.datetime.fromtimestamp(int(sys.argv[1])).astimezone().strftime("%Y-%m-%d %H:%M:%S %Z"))
PY
}

preflight_real_device_profile() {
  local device_id="$1"
  shift
  local hdc_bin
  hdc_bin="$(command -v hdc || true)"
  if [[ -z "$hdc_bin" ]]; then
    return 0
  fi

  local model
  model="$("$hdc_bin" -t "$device_id" shell param get const.product.model 2>/dev/null | tr -d '\r' | tail -n 1)"
  if [[ -z "$model" || "$model" == "emulator" ]]; then
    return 0
  fi

  local udid
  udid="$("$hdc_bin" -t "$device_id" shell bm get --udid 2>/dev/null | tr -d '\r' | tail -n 1)"
  if [[ -z "$udid" ]]; then
    echo "✗ 无法读取设备 UDID，跳过 profile 检查。"
    return 0
  fi

  if [[ ! -f "$BUILD_PROFILE" ]]; then
    echo "✗ 缺少 $BUILD_PROFILE"
    exit 1
  fi

  local profile_path
  profile_path="$(python3 - <<'PY' "$BUILD_PROFILE"
import json, sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as handle:
    data = json.load(handle)
configs = data.get('app', {}).get('signingConfigs', [])
material = configs[0].get('material', {}) if configs else {}
print(material.get('profile', ''))
PY
)"

  if [[ -z "$profile_path" || ! -f "$profile_path" ]]; then
    echo "✗ 当前签名配置里的 profile 不存在: ${profile_path:-<empty>}"
    exit 1
  fi

  local hap_sign_tool
  hap_sign_tool="$HOS_SDK_HOME/default/openharmony/toolchains/lib/hap-sign-tool.jar"
  if [[ ! -f "$hap_sign_tool" ]]; then
    echo "✗ 找不到 hap-sign-tool: $hap_sign_tool"
    exit 1
  fi

  local verify_file
  verify_file="$(mktemp "${TMPDIR:-/tmp}/happy_profile_verify.XXXXXX.json")"
  java -jar "$hap_sign_tool" verify-profile -inFile "$profile_path" -outFile "$verify_file" >/dev/null

  local bundle_name
  bundle_name="$(python3 - <<'PY' "$verify_file"
import json, sys
verify_path = sys.argv[1]
with open(verify_path, 'r', encoding='utf-8') as handle:
    data = json.load(handle)
content = data.get('content', {})
print(content.get('bundle-info', {}).get('bundle-name', ''))
PY
)"

  local profile_not_before
  profile_not_before="$(python3 - <<'PY' "$verify_file"
import json, sys
verify_path = sys.argv[1]
with open(verify_path, 'r', encoding='utf-8') as handle:
    data = json.load(handle)
print(data.get('content', {}).get('validity', {}).get('not-before', ''))
PY
)"

  local profile_not_after
  profile_not_after="$(python3 - <<'PY' "$verify_file"
import json, sys
verify_path = sys.argv[1]
with open(verify_path, 'r', encoding='utf-8') as handle:
    data = json.load(handle)
print(data.get('content', {}).get('validity', {}).get('not-after', ''))
PY
)"

  local profile_devices_file
  profile_devices_file="$(mktemp "${TMPDIR:-/tmp}/happy_profile_devices.XXXXXX.txt")"
  python3 - <<'PY' "$verify_file" "$profile_devices_file"
import json, sys
verify_path, output_path = sys.argv[1], sys.argv[2]
with open(verify_path, 'r', encoding='utf-8') as handle:
    data = json.load(handle)
device_ids = data.get('content', {}).get('debug-info', {}).get('device-ids', [])
with open(output_path, 'w', encoding='utf-8') as handle:
    for item in device_ids:
        handle.write(f"{item}\n")
PY

  local dev_cert_file
  dev_cert_file="$(mktemp "${TMPDIR:-/tmp}/happy_profile_dev_cert.XXXXXX.pem")"
  python3 - <<'PY' "$verify_file" "$dev_cert_file"
import json, sys
verify_path, output_path = sys.argv[1], sys.argv[2]
with open(verify_path, 'r', encoding='utf-8') as handle:
    data = json.load(handle)
cert = data.get('content', {}).get('bundle-info', {}).get('development-certificate', '')
with open(output_path, 'w', encoding='utf-8') as handle:
    handle.write(cert)
PY

  local now_epoch
  now_epoch="$(date +%s)"

  if [[ -n "$profile_not_before" && "$now_epoch" -lt "$profile_not_before" ]]; then
    echo "✗ 当前真机无法安装。原因不是代码编译，而是签名 profile 还未生效。"
    echo "  设备: $device_id ($model)"
    echo "  profile: $profile_path"
    if [[ -n "$bundle_name" ]]; then
      echo "  bundle: $bundle_name"
    fi
    echo "  profile 生效时间: $(format_epoch_local "$profile_not_before")"
    echo ""
    echo "  处理方式:"
    echo "  1. 等 profile 生效后再安装"
    echo "  2. 或在 AppGallery Connect / DevEco Studio 重新生成立即生效的 profile"
    rm -f "$verify_file" "$profile_devices_file" "$dev_cert_file"
    exit 1
  fi

  if [[ -n "$profile_not_after" && "$now_epoch" -gt "$profile_not_after" ]]; then
    echo "✗ 当前真机无法安装。原因不是代码编译，而是签名 profile 已过期。"
    echo "  设备: $device_id ($model)"
    echo "  profile: $profile_path"
    if [[ -n "$bundle_name" ]]; then
      echo "  bundle: $bundle_name"
    fi
    echo "  profile 到期: $(format_epoch_local "$profile_not_after")"
    echo ""
    echo "  处理方式:"
    echo "  1. 在 AppGallery Connect / DevEco Studio 重新生成新的 debug profile"
    echo "  2. 用新 profile 覆盖当前 $profile_path"
    echo "  3. 再执行 ./scripts/run.sh $*"
    rm -f "$verify_file" "$profile_devices_file" "$dev_cert_file"
    exit 1
  fi

  if [[ -s "$dev_cert_file" ]] && ! openssl x509 -in "$dev_cert_file" -checkend 0 -noout >/dev/null 2>&1; then
    local dev_cert_not_after
    dev_cert_not_after="$(openssl x509 -in "$dev_cert_file" -noout -enddate 2>/dev/null | cut -d'=' -f2-)"
    echo "✗ 当前真机无法安装。原因不是代码编译，而是签名证书已过期。"
    echo "  设备: $device_id ($model)"
    echo "  profile: $profile_path"
    if [[ -n "$bundle_name" ]]; then
      echo "  bundle: $bundle_name"
    fi
    if [[ -n "$dev_cert_not_after" ]]; then
      echo "  证书到期: $dev_cert_not_after"
    fi
    echo ""
    echo "  处理方式:"
    echo "  1. 在 AppGallery Connect / DevEco Studio 重新生成新的 development certificate"
    echo "  2. 同步更新 cert、p12、profile 这套签名材料"
    echo "  3. 再执行 ./scripts/run.sh $*"
    rm -f "$verify_file" "$profile_devices_file" "$dev_cert_file"
    exit 1
  fi

  if ! grep -Fxq "$udid" "$profile_devices_file"; then
    local profile_devices
    profile_devices="$(cat "$profile_devices_file")"
    echo "✗ 当前真机无法安装。原因不是代码编译，而是调试 profile 未授权这台设备。"
    echo "  设备: $device_id ($model)"
    echo "  UDID: $udid"
    echo "  profile: $profile_path"
    if [[ -n "$bundle_name" ]]; then
      echo "  bundle: $bundle_name"
    fi
    if [[ -n "$profile_devices" ]]; then
      echo "  profile 已授权设备:"
      printf '    %s\n' $profile_devices
    else
      echo "  profile 未包含任何 device-ids。"
    fi
    echo ""
    echo "  处理方式:"
    echo "  1. 在 DevEco Studio / AppGallery Connect 重新生成包含该 UDID 的 debug profile"
    echo "  2. 用新 profile 覆盖当前 $profile_path"
    echo "  3. 再执行 ./scripts/run.sh $*"
    rm -f "$verify_file" "$profile_devices_file" "$dev_cert_file"
    exit 1
  fi

  rm -f "$verify_file" "$profile_devices_file" "$dev_cert_file"
}

echo "=================================="
echo "Happy Coder Flutter Project"
echo "Project: $PROJECT_DIR"
echo "Flutter: $FLUTTER_BIN"
if [[ -n "${HOS_SDK_HOME:-}" ]]; then
  echo "HOS SDK: $HOS_SDK_HOME"
fi
echo "=================================="
"$FLUTTER_BIN" --version | head -1

if [[ $# -gt 0 ]]; then
  if [[ "$1" == "run" ]]; then
    device_id="$(extract_device_id "$@" || true)"
    if [[ -n "${device_id:-}" ]]; then
      preflight_real_device_profile "$device_id" "$@"
    fi
  fi
  exec "$FLUTTER_BIN" "$@"
fi

echo ""
echo "推荐命令:"
echo "  ./scripts/run.sh devices"
echo "  ./scripts/run.sh run -d 127.0.0.1:5555 --debug"
echo "  ./scripts/run.sh build hap --target-platform ohos-arm64 --debug"
echo ""
echo "注意:"
echo "  1. 这个项目没有 android/，不要用系统 stable Flutter 直接跑 Android 命令。"
echo "  2. 设备锁屏时，OHOS 会报 10106102，需先手动解锁设备。"
