---
name: ohos-release-debug-install
description: Build and install a HarmonyOS/OpenHarmony release package to a real device while intentionally using the existing debug signing profile and bypassing scripts/run.sh checks. Use when users explicitly request "release build + real-device install" in the current project and require direct flutter + hdc commands instead of run.sh preflight alignment.
---

# Ohos Release Debug Install

## Overview

Use this skill to produce and install the latest OHOS release artifact on a real device when the project intentionally keeps a debug signing profile in `ohos/build-profile.json5`.
Avoid `scripts/run.sh` for this workflow, because the request explicitly requires bypassing release-profile alignment checks.

## Workflow

1. Confirm the project root and required files exist.
Required files:
- `ohos/local.properties`
- `ohos/build-profile.json5`
- `ohos/AppScope/app.json5`

2. Read SDK locations from `ohos/local.properties`.
Required keys:
- `flutter.sdk`
- `hwsdk.dir`

3. Export OHOS build environment and run direct Flutter build.
Command shape:
```bash
"$FLUTTER_BIN" build app --release
```
Do not call `scripts/run.sh`.

4. Install the freshly built package to the target device with `hdc`.
Preferred artifact:
- `ohos/build/outputs/default/*-all-signed.app`
Install command shape:
```bash
"$HDC" -t <device-id> install -r "<artifact-path>"
```

5. Verify the installed bundle.
Use bundle name from `ohos/AppScope/app.json5`.
Command shape:
```bash
"$HDC" -t <device-id> shell bm dump -n <bundle-name>
```

6. Report concise results.
Always include:
- used device id
- build command and exit status
- installed artifact full path
- install result and key diagnostics if failed

## Script

Run the bundled script for deterministic execution:
```bash
bash .agents/skills/ohos-release-debug-install/scripts/build_release_install_debug_profile.sh --device-id <device-id>
```

When `--device-id` is omitted, the script auto-selects the first connected `ohos-arm64` device from `flutter devices`.
