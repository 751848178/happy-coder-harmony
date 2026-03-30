#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
LOCAL_PROPERTIES="$PROJECT_DIR/ohos/local.properties"
APP_SCOPE="$PROJECT_DIR/ohos/AppScope/app.json5"
BUILD_PROFILE="$PROJECT_DIR/ohos/build-profile.json5"

DEVICE_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device-id)
      DEVICE_ID="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--device-id <id>]" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$LOCAL_PROPERTIES" ]]; then
  echo "Missing file: $LOCAL_PROPERTIES" >&2
  exit 1
fi

if [[ ! -f "$APP_SCOPE" ]]; then
  echo "Missing file: $APP_SCOPE" >&2
  exit 1
fi

if [[ ! -f "$BUILD_PROFILE" ]]; then
  echo "Missing file: $BUILD_PROFILE" >&2
  exit 1
fi

FLUTTER_SDK="$(grep '^flutter.sdk=' "$LOCAL_PROPERTIES" | cut -d'=' -f2-)"
HOS_SDK="$(grep '^hwsdk.dir=' "$LOCAL_PROPERTIES" | cut -d'=' -f2-)"

if [[ -z "${FLUTTER_SDK:-}" || -z "${HOS_SDK:-}" ]]; then
  echo "local.properties must contain flutter.sdk and hwsdk.dir" >&2
  exit 1
fi

FLUTTER_BIN="$FLUTTER_SDK/bin/flutter"
HDC_BIN="$HOS_SDK/default/openharmony/toolchains/hdc"

if [[ ! -x "$FLUTTER_BIN" ]]; then
  echo "Flutter binary not executable: $FLUTTER_BIN" >&2
  exit 1
fi

if [[ ! -x "$HDC_BIN" ]]; then
  echo "HDC binary not executable: $HDC_BIN" >&2
  exit 1
fi

export HOS_SDK_HOME="$HOS_SDK"
export OHOS_SDK_HOME="$HOS_SDK"
export DEVECO_SDK_HOME="$HOS_SDK"

find_newer_ohos_source() {
  local built_artifact="$1"

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
    if [[ -f "$candidate" && "$candidate" -nt "$built_artifact" ]]; then
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
    -newer "$built_artifact" 2>/dev/null | head -n 1
}

preflight_release_build_cache() {
  local existing_artifact
  existing_artifact="$(ls -t "$PROJECT_DIR"/ohos/build/outputs/default/*-all-signed.app 2>/dev/null | head -n 1 || true)"
  if [[ -z "${existing_artifact:-}" || ! -f "$existing_artifact" ]]; then
    return 0
  fi

  local newer_source
  newer_source="$(find_newer_ohos_source "$existing_artifact" || true)"
  if [[ -z "$newer_source" ]]; then
    return 0
  fi

  echo "⚠️ 检测到 OHOS Release 产物可能陈旧。"
  echo "  产物: $existing_artifact"
  echo "  较新的源码: $newer_source"
  echo "  正在执行 flutter clean，避免继续复用旧的 Release UI / 签名产物..."
  "$FLUTTER_BIN" clean
}

clear_previous_release_outputs() {
  rm -f "$PROJECT_DIR"/ohos/build/outputs/default/*.app
  rm -f "$PROJECT_DIR"/build/ohos/app/*.app
}

stop_running_bundle_if_needed() {
  "$HDC_BIN" -t "$DEVICE_ID" shell aa force-stop "$BUNDLE_NAME" >/dev/null 2>&1 || true
}

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$("$FLUTTER_BIN" devices | awk -F '•' '/ohos-arm64/ {gsub(/ /, "", $2); print $2; exit}')"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "No OHOS real device detected. Pass --device-id explicitly." >&2
  exit 1
fi

BUNDLE_NAME="$(python3 - <<'PY' "$APP_SCOPE"
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    app_scope = json.load(fh)
print(app_scope['app']['bundleName'])
PY
)"

SIGNING_INFO="$(python3 - <<'PY' "$BUILD_PROFILE"
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    profile = json.load(fh)

material = profile['app']['signingConfigs'][0]['material']
print(material.get('profile', ''))
print(material.get('certpath', ''))
print(material.get('storeFile', ''))
PY
)"

PROFILE_PATH="$(printf '%s\n' "$SIGNING_INFO" | sed -n '1p')"
CERT_PATH="$(printf '%s\n' "$SIGNING_INFO" | sed -n '2p')"
STORE_FILE="$(printf '%s\n' "$SIGNING_INFO" | sed -n '3p')"

preflight_release_build_cache
clear_previous_release_outputs

echo "Project: $PROJECT_DIR"
echo "Device: $DEVICE_ID"
echo "Flutter: $FLUTTER_BIN"
echo "HDC: $HDC_BIN"
echo "Bundle: $BUNDLE_NAME"
echo "Profile: ${PROFILE_PATH:-<empty>}"
echo "Cert: ${CERT_PATH:-<empty>}"
echo "Store: ${STORE_FILE:-<empty>}"
echo "Step 1/4: build release package with current build-profile signing materials"

"$FLUTTER_BIN" build app --release

ARTIFACT_PATH="$(find "$PROJECT_DIR/ohos/build/outputs/default" -maxdepth 1 -type f -name '*-all-signed.app' | head -n 1)"
if [[ -z "${ARTIFACT_PATH:-}" ]]; then
  echo "No *-all-signed.app artifact found under ohos/build/outputs/default" >&2
  exit 1
fi

echo "Step 2/4: stop running bundle before install"
stop_running_bundle_if_needed

echo "Step 3/4: install package"
"$HDC_BIN" -t "$DEVICE_ID" install -r "$ARTIFACT_PATH"

echo "Step 4/4: verify installed bundle"
"$HDC_BIN" -t "$DEVICE_ID" shell bm dump -n "$BUNDLE_NAME" | head -n 30

echo ""
echo "Done"
echo "Installed artifact: $ARTIFACT_PATH"
