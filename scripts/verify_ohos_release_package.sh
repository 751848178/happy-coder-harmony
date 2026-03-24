#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_PATH="${1:-}"
BUILD_PROFILE_PATH="${2:-$PROJECT_DIR/ohos/build-profile.json5}"
LOCAL_PROPERTIES_PATH="${3:-$PROJECT_DIR/ohos/local.properties}"
APP_SCOPE_PATH="${4:-$PROJECT_DIR/ohos/AppScope/app.json5}"

if [[ -z "$APP_PATH" ]]; then
  echo "usage: $0 <signed-app-path> [build-profile] [local-properties] [app-scope]"
  exit 1
fi

if [[ ! -f "$APP_PATH" ]]; then
  echo "✗ signed app not found: $APP_PATH"
  exit 1
fi

if [[ ! -f "$BUILD_PROFILE_PATH" ]]; then
  echo "✗ build profile not found: $BUILD_PROFILE_PATH"
  exit 1
fi

if [[ ! -f "$LOCAL_PROPERTIES_PATH" ]]; then
  echo "✗ local.properties not found: $LOCAL_PROPERTIES_PATH"
  exit 1
fi

if [[ ! -f "$APP_SCOPE_PATH" ]]; then
  echo "✗ AppScope config not found: $APP_SCOPE_PATH"
  exit 1
fi

HOS_SDK_HOME_VALUE="$(grep '^hwsdk.dir=' "$LOCAL_PROPERTIES_PATH" | cut -d'=' -f2-)"
if [[ -z "${HOS_SDK_HOME_VALUE:-}" ]]; then
  echo "✗ hwsdk.dir missing in $LOCAL_PROPERTIES_PATH"
  exit 1
fi

HAP_SIGN_TOOL="$HOS_SDK_HOME_VALUE/default/openharmony/toolchains/lib/hap-sign-tool.jar"
if [[ ! -f "$HAP_SIGN_TOOL" ]]; then
  echo "✗ hap-sign-tool.jar not found: $HAP_SIGN_TOOL"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

EMBEDDED_CERT="$TMP_DIR/app-cert.cer"
EMBEDDED_PROFILE="$TMP_DIR/app-profile.p7b"

java -jar "$HAP_SIGN_TOOL" verify-app \
  -inFile "$APP_PATH" \
  -inForm zip \
  -outCertChain "$EMBEDDED_CERT" \
  -outProfile "$EMBEDDED_PROFILE" >/dev/null

SELECTED_PROFILE_PATH="$(
  python3 - "$BUILD_PROFILE_PATH" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
print(data['app']['signingConfigs'][0]['material']['profile'])
PY
)"

if [[ ! -f "$SELECTED_PROFILE_PATH" ]]; then
  echo "✗ selected profile missing: $SELECTED_PROFILE_PATH"
  exit 1
fi

python3 - "$APP_PATH" "$SELECTED_PROFILE_PATH" "$EMBEDDED_PROFILE" "$LOCAL_PROPERTIES_PATH" "$APP_SCOPE_PATH" <<'PY'
import json
import subprocess
import sys
from pathlib import Path
from zipfile import ZipFile

app_path = Path(sys.argv[1])
selected_profile_path = Path(sys.argv[2])
embedded_profile_path = Path(sys.argv[3])
local_properties_path = Path(sys.argv[4])
app_scope_path = Path(sys.argv[5])

def load_profile(path: Path) -> dict:
    output = subprocess.check_output(
        ["security", "cms", "-D", "-i", str(path)],
        text=True,
    )
    return json.loads(output)

def load_local_properties(path: Path) -> dict:
    values = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" not in line or line.strip().startswith("#"):
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values

selected_profile = load_profile(selected_profile_path)
embedded_profile = load_profile(embedded_profile_path)
local_properties = load_local_properties(local_properties_path)
app_scope = json.loads(app_scope_path.read_text(encoding="utf-8"))

with ZipFile(app_path) as app_zip:
    pack_info = json.loads(app_zip.read("pack.info").decode("utf-8"))

selected_bundle = selected_profile["bundle-info"]["bundle-name"]
selected_app_identifier = selected_profile["bundle-info"]["app-identifier"]
selected_version_name = selected_profile["version-name"]
selected_version_code = int(selected_profile["version-code"])
selected_uuid = selected_profile["uuid"]

embedded_bundle = embedded_profile["bundle-info"]["bundle-name"]
embedded_app_identifier = embedded_profile["bundle-info"]["app-identifier"]
embedded_version_name = embedded_profile["version-name"]
embedded_version_code = int(embedded_profile["version-code"])
embedded_uuid = embedded_profile["uuid"]

pack_bundle = pack_info["summary"]["app"]["bundleName"]
pack_version_name = pack_info["summary"]["app"]["version"]["name"]
pack_version_code = int(pack_info["summary"]["app"]["version"]["code"])

scope_bundle = app_scope["app"]["bundleName"]
scope_version_name = app_scope["app"]["versionName"]
scope_version_code = int(app_scope["app"]["versionCode"])

local_version_name = local_properties.get("flutter.versionName")
local_version_code = int(local_properties.get("flutter.versionCode", "1"))

errors = []
if selected_profile["type"] != "release":
    errors.append(f"selected profile type is {selected_profile['type']}, expected release")
if selected_bundle != embedded_bundle:
    errors.append(f"profile bundle mismatch: selected={selected_bundle}, embedded={embedded_bundle}")
if selected_app_identifier != embedded_app_identifier:
    errors.append(
        "profile app-identifier mismatch: "
        f"selected={selected_app_identifier}, embedded={embedded_app_identifier}"
    )
if selected_uuid != embedded_uuid:
    errors.append(f"profile uuid mismatch: selected={selected_uuid}, embedded={embedded_uuid}")
if selected_version_name != embedded_version_name or selected_version_code != embedded_version_code:
    errors.append(
        "profile version mismatch: "
        f"selected={selected_version_name}+{selected_version_code}, "
        f"embedded={embedded_version_name}+{embedded_version_code}"
    )
if embedded_bundle != pack_bundle:
    errors.append(f"pack.info bundle mismatch: embedded={embedded_bundle}, pack={pack_bundle}")
if embedded_version_name != pack_version_name or embedded_version_code != pack_version_code:
    errors.append(
        "pack.info version mismatch: "
        f"embedded={embedded_version_name}+{embedded_version_code}, "
        f"pack={pack_version_name}+{pack_version_code}"
    )
if scope_bundle != pack_bundle:
    errors.append(f"AppScope bundle mismatch: scope={scope_bundle}, pack={pack_bundle}")
if scope_version_name != pack_version_name or scope_version_code != pack_version_code:
    errors.append(
        "AppScope version mismatch: "
        f"scope={scope_version_name}+{scope_version_code}, "
        f"pack={pack_version_name}+{pack_version_code}"
    )
if local_version_name != pack_version_name or local_version_code != pack_version_code:
    errors.append(
        "local.properties version mismatch: "
        f"local={local_version_name}+{local_version_code}, "
        f"pack={pack_version_name}+{pack_version_code}"
    )

print("OHOS release package verification")
print(f"  app: {app_path}")
print(f"  selected profile: {selected_profile_path}")
print(f"  profile uuid: {selected_uuid}")
print(f"  bundle: {pack_bundle}")
print(f"  version: {pack_version_name}+{pack_version_code}")
print(f"  app identifier: {selected_app_identifier}")

if errors:
    print("")
    print("verification failed:")
    for error in errors:
        print(f"  - {error}")
    sys.exit(1)

print("")
print("verification passed")
PY
