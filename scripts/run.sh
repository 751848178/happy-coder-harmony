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

sync_ohos_flutter_version_properties() {
  local pubspec_file="$PROJECT_DIR/pubspec.yaml"
  if [[ ! -f "$pubspec_file" ]]; then
    return 0
  fi

  local raw_version
  raw_version="$(sed -n 's/^version:[[:space:]]*//p' "$pubspec_file" | head -n 1 | tr -d '\r')"
  if [[ -z "${raw_version:-}" ]]; then
    return 0
  fi

  local version_name="$raw_version"
  local version_code="1"
  if [[ "$raw_version" == *"+"* ]]; then
    version_name="${raw_version%%+*}"
    version_code="${raw_version##*+}"
  fi

  local current_name=""
  local current_code=""
  current_name="$(grep '^flutter.versionName=' "$LOCAL_PROPERTIES" | cut -d'=' -f2- || true)"
  current_code="$(grep '^flutter.versionCode=' "$LOCAL_PROPERTIES" | cut -d'=' -f2- || true)"

  if [[ "$current_name" == "$version_name" && "$current_code" == "$version_code" ]]; then
    return 0
  fi

  local tmp_file
  tmp_file="$(mktemp)"
  grep -vE '^flutter\.version(Name|Code)=' "$LOCAL_PROPERTIES" > "$tmp_file" || true
  printf 'flutter.versionName=%s\n' "$version_name" >> "$tmp_file"
  printf 'flutter.versionCode=%s\n' "$version_code" >> "$tmp_file"
  mv "$tmp_file" "$LOCAL_PROPERTIES"

  echo "✓ 已同步 OHOS 版本到 local.properties: versionName=$version_name, versionCode=$version_code"
}

sync_ohos_flutter_version_properties

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

extract_flavor() {
  local previous=""
  for arg in "$@"; do
    if [[ "$previous" == "--flavor" ]]; then
      printf '%s\n' "$arg"
      return 0
    fi
    case "$arg" in
      --flavor=*)
        printf '%s\n' "${arg#--flavor=}"
        return 0
        ;;
    esac
    previous="$arg"
  done
  return 1
}

is_ohos_debug_command() {
  if [[ $# -eq 0 ]]; then
    return 1
  fi

  local primary="$1"
  shift

  case "$primary" in
    run)
      for arg in "$@"; do
        case "$arg" in
          --release|--profile)
            return 1
            ;;
        esac
      done
      return 0
      ;;
    build)
      if [[ "${1:-}" != "hap" ]]; then
        return 1
      fi
      shift
      for arg in "$@"; do
        case "$arg" in
          --release|--profile)
            return 1
            ;;
        esac
      done
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_ohos_app_build_command() {
  [[ $# -ge 2 && "$1" == "build" && "$2" == "app" ]]
}

find_newer_ohos_debug_source() {
  local kernel_blob="$1"

  local direct_candidates=(
    "$PROJECT_DIR/pubspec.yaml"
    "$PROJECT_DIR/pubspec.lock"
    "$PROJECT_DIR/.dart_tool/package_config.json"
    "$PROJECT_DIR/ohos/oh-package.json5"
    "$PROJECT_DIR/ohos/hvigorfile.ts"
    "$PROJECT_DIR/ohos/hvigorconfig.ts"
    "$PROJECT_DIR/ohos/build-profile.json5"
    "$PROJECT_DIR/ohos/AppScope/app.json5"
    "$PROJECT_DIR/ohos/entry/src/main/module.json5"
    "$PROJECT_DIR/ohos/entry/oh-package.json5"
    "$PROJECT_DIR/ohos/entry/build-profile.json5"
    "$PROJECT_DIR/ohos/entry/hvigorfile.ts"
  )

  local candidate
  for candidate in "${direct_candidates[@]}"; do
    if [[ -f "$candidate" && "$candidate" -nt "$kernel_blob" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  find \
    "$PROJECT_DIR/lib" \
    "$PROJECT_DIR/ohos/AppScope/resources" \
    "$PROJECT_DIR/ohos/entry/src/main/ets" \
    "$PROJECT_DIR/ohos/entry/src/main/resources/base" \
    "$PROJECT_DIR/ohos/entry/src/main/resources/en_US" \
    "$PROJECT_DIR/ohos/entry/src/main/resources/zh_CN" \
    -type f \
    \( \
      -name '*.dart' -o \
      -name '*.ets' -o \
      -name '*.json' -o \
      -name '*.json5' -o \
      -name '*.yaml' -o \
      -name '*.yml' -o \
      -name '*.ts' \
    \) \
    -newer "$kernel_blob" 2>/dev/null | head -n 1
}

preflight_ohos_debug_cache() {
  if ! is_ohos_debug_command "$@"; then
    return 0
  fi

  local kernel_blob="$PROJECT_DIR/build/ohos/intermediates/flutter/defaultDebug/flutter_assets/kernel_blob.bin"
  if [[ ! -f "$kernel_blob" ]]; then
    return 0
  fi

  local newer_source
  newer_source="$(find_newer_ohos_debug_source "$kernel_blob" || true)"
  if [[ -z "$newer_source" ]]; then
    return 0
  fi

  echo "⚠️ 检测到 OHOS Debug Flutter 产物可能陈旧。"
  echo "  产物: $kernel_blob"
  echo "  较新的源码: $newer_source"
  echo "  正在执行 flutter clean，避免继续复用旧的 Dart UI 产物..."
  "$FLUTTER_BIN" clean
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

preflight_release_profile_alignment() {
  if ! is_ohos_app_build_command "$@"; then
    return 0
  fi

  if [[ ! -f "$BUILD_PROFILE" ]]; then
    echo "✗ 缺少 $BUILD_PROFILE"
    exit 1
  fi

  local profile_path
  profile_path="$(python3 - <<'PY' "$BUILD_PROFILE"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as handle:
    data = json.load(handle)
configs = data.get('app', {}).get('signingConfigs', [])
material = configs[0].get('material', {}) if configs else {}
print(material.get('profile', ''))
PY
)"

  if [[ -z "$profile_path" || ! -f "$profile_path" ]]; then
    echo "✗ 当前签名配置里的 release profile 不存在: ${profile_path:-<empty>}"
    exit 1
  fi

  python3 - <<'PY' "$profile_path" "$LOCAL_PROPERTIES" "$PROJECT_DIR/ohos/AppScope/app.json5"
import json
import subprocess
import sys
from pathlib import Path

profile_path = Path(sys.argv[1])
local_properties_path = Path(sys.argv[2])
app_scope_path = Path(sys.argv[3])

def load_profile(path: Path) -> dict:
    raw = subprocess.check_output(["security", "cms", "-D", "-i", str(path)], text=True)
    return json.loads(raw)

def load_local_properties(path: Path) -> dict:
    values = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" not in line or line.strip().startswith("#"):
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values

profile = load_profile(profile_path)
local_properties = load_local_properties(local_properties_path)
app_scope = json.loads(app_scope_path.read_text(encoding="utf-8"))

profile_bundle = profile["bundle-info"]["bundle-name"]
profile_version_name = profile["version-name"]
profile_version_code = int(profile["version-code"])
profile_type = profile["type"]
profile_uuid = profile["uuid"]

local_version_name = local_properties.get("flutter.versionName")
local_version_code = int(local_properties.get("flutter.versionCode", "1"))
scope_bundle = app_scope["app"]["bundleName"]
scope_version_name = app_scope["app"]["versionName"]
scope_version_code = int(app_scope["app"]["versionCode"])

errors = []
if profile_type != "release":
    errors.append(f"profile type is {profile_type}, expected release")
if profile_bundle != scope_bundle:
    errors.append(
        f"profile bundle mismatch: profile={profile_bundle}, AppScope={scope_bundle}"
    )
if profile_version_name != local_version_name or profile_version_code != local_version_code:
    errors.append(
        "profile/local.properties version mismatch: "
        f"profile={profile_version_name}+{profile_version_code}, "
        f"local={local_version_name}+{local_version_code}"
    )
if profile_version_name != scope_version_name or profile_version_code != scope_version_code:
    errors.append(
        "profile/AppScope version mismatch: "
        f"profile={profile_version_name}+{profile_version_code}, "
        f"AppScope={scope_version_name}+{scope_version_code}"
    )

if errors:
    print("✗ 当前 release profile 与工程版本不一致，继续构建会导致上传失败。")
    print(f"  profile: {profile_path}")
    print(f"  profile uuid: {profile_uuid}")
    print(f"  profile bundle: {profile_bundle}")
    print(f"  profile version: {profile_version_name}+{profile_version_code}")
    print(f"  local.properties version: {local_version_name}+{local_version_code}")
    print(f"  AppScope version: {scope_version_name}+{scope_version_code}")
    print("")
    print("  处理方式:")
    print("  1. 在 AppGallery Connect / DevEco Studio 重新生成版本一致的 release profile")
    print(f"  2. 下载后覆盖当前 profile: {profile_path}")
    print("  3. 再执行 ./scripts/run.sh build app --release")
    print("")
    print("  发现的问题:")
    for item in errors:
        print(f"  - {item}")
    sys.exit(1)

print("✓ 已确认 release profile 与工程版本一致")
print(f"  profile: {profile_path}")
print(f"  bundle: {profile_bundle}")
print(f"  version: {profile_version_name}+{profile_version_code}")
PY
}

postprocess_ohos_app_artifacts() {
  if ! is_ohos_app_build_command "$@"; then
    return 0
  fi

  local flavor
  flavor="$(extract_flavor "$@" || true)"
  if [[ -z "$flavor" ]]; then
    flavor="default"
  fi

  local project_output_dir="$PROJECT_DIR/ohos/build/outputs/$flavor"
  if [[ ! -d "$project_output_dir" ]]; then
    return 0
  fi

  local all_signed_app
  all_signed_app="$(find "$project_output_dir" -maxdepth 1 -type f -name '*-all-signed.app' | head -n 1)"
  if [[ -z "${all_signed_app:-}" ]]; then
    return 0
  fi

  local verify_script="$PROJECT_DIR/scripts/verify_ohos_release_package.sh"
  if [[ -x "$verify_script" ]]; then
    "$verify_script" "$all_signed_app" "$BUILD_PROFILE" "$LOCAL_PROPERTIES" "$PROJECT_DIR/ohos/AppScope/app.json5"
  fi

  local copied_output_dir="$PROJECT_DIR/build/ohos/app"
  mkdir -p "$copied_output_dir"

  local all_signed_name
  all_signed_name="$(basename "$all_signed_app")"
  local stable_name="${all_signed_name/-all-signed.app/-signed.app}"

  cp -f "$all_signed_app" "$copied_output_dir/$all_signed_name"
  cp -f "$all_signed_app" "$copied_output_dir/$stable_name"

  echo ""
  echo "✓ 已同步包内全签名的 .app 产物:"
  echo "  $copied_output_dir/$all_signed_name"
  if [[ "$stable_name" != "$all_signed_name" ]]; then
    echo "  $copied_output_dir/$stable_name"
  fi
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
    if [[ -n "${device_id:-}" ]] && is_ohos_debug_command "$@"; then
      preflight_real_device_profile "$device_id" "$@"
    fi
  fi
  preflight_ohos_debug_cache "$@"
  preflight_release_profile_alignment "$@"
  "$FLUTTER_BIN" "$@"
  postprocess_ohos_app_artifacts "$@"
  exit 0
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
