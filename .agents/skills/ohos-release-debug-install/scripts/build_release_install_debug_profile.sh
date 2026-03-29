#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
LOCAL_PROPERTIES="$PROJECT_DIR/ohos/local.properties"
APP_SCOPE="$PROJECT_DIR/ohos/AppScope/app.json5"

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

echo "Project: $PROJECT_DIR"
echo "Device: $DEVICE_ID"
echo "Flutter: $FLUTTER_BIN"
echo "HDC: $HDC_BIN"
echo "Bundle: $BUNDLE_NAME"
echo "Step 1/3: build release package (bypass scripts/run.sh)"

"$FLUTTER_BIN" build app --release

ARTIFACT_PATH="$(find "$PROJECT_DIR/ohos/build/outputs/default" -maxdepth 1 -type f -name '*-all-signed.app' | head -n 1)"
if [[ -z "${ARTIFACT_PATH:-}" ]]; then
  echo "No *-all-signed.app artifact found under ohos/build/outputs/default" >&2
  exit 1
fi

echo "Step 2/3: install package"
"$HDC_BIN" -t "$DEVICE_ID" install -r "$ARTIFACT_PATH"

echo "Step 3/3: verify installed bundle"
"$HDC_BIN" -t "$DEVICE_ID" shell bm dump -n "$BUNDLE_NAME" | head -n 30

echo ""
echo "Done"
echo "Installed artifact: $ARTIFACT_PATH"
