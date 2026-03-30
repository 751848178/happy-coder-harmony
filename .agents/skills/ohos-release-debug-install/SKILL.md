---
name: ohos-release-debug-install
description: Build and install a HarmonyOS/OpenHarmony package to a real device in the current project. When the user says "install to real device" or similar without explicitly asking for a debug package, default to building and installing a release package that uses the profile and certificate currently configured in `ohos/build-profile.json5`. Only use a debug package when the user explicitly says `debug`, `调试包`, wants hot reload, or asks for a live debug run.
---

# Ohos Release Debug Install

## Overview

Use this skill whenever the user wants to install the app to a HarmonyOS/OpenHarmony real device.

Default behavior:
- If the user only says "安装到真机", "装到手机", "install to device", or similar, treat it as a release-package install.
- Use the profile and certificate that are currently configured in `ohos/build-profile.json5`.
- Do not silently swap signing materials unless the user explicitly asks for a different profile or certificate.

Only switch to a debug package when the user clearly asks for one, such as:
- `debug`
- `调试包`
- hot reload / breakpoint / attach debugger
- a live `flutter run` session

For release-package installs, prefer direct `flutter + hdc` commands or the bundled script instead of `scripts/run.sh`, because:
- the project may intentionally keep a debug signing profile in `ohos/build-profile.json5`
- `scripts/run.sh` may block on release-profile alignment checks that are irrelevant for this workflow

For explicit debug-package installs, use the normal debug run/install path such as `./scripts/run.sh run -d <device-id> --debug`.

Before building, always inspect `ohos/build-profile.json5` and report which `profile` and `certpath` are being used so the install result is easy to audit.

## Workflow

1. Determine install mode from the request.
Rules:
- Default to `release` for real-device install.
- Use `debug` only when the user explicitly asks for a debug package or live debugging.

2. Confirm the project root and required files exist.
Required files:
- `ohos/local.properties`
- `ohos/build-profile.json5`
- `ohos/AppScope/app.json5`

3. Read the current signing material from `ohos/build-profile.json5`.
Always capture:
- `material.profile`
- `material.certpath`
- `material.storeFile`

4. Read SDK locations from `ohos/local.properties`.
Required keys:
- `flutter.sdk`
- `hwsdk.dir`

5. Discover the target device.
Preferred command:
```bash
./scripts/run.sh devices
```
When the user did not specify a device id, auto-select the first connected `ohos-arm64` real device.

6. Run the correct install path.

Release package path:
- Build a release package using the current `ohos/build-profile.json5` signing materials.
- Prefer the bundled script for deterministic execution.
- Before building, apply the same anti-stale strategy that `scripts/run.sh` uses for debug:
  - inspect whether the latest signed release `.app` is older than project source/config files
  - if stale, run `flutter clean`
  - clear old `ohos/build/outputs/default/*.app` and `build/ohos/app/*.app` artifacts before the next build
  - stop the running app process on device before reinstalling, so the user does not keep seeing an old process after overwrite install

Command shape:
```bash
bash .agents/skills/ohos-release-debug-install/scripts/build_release_install_debug_profile.sh --device-id <device-id>
```

Explicit debug package path:
- Use the normal debug run/install workflow.

Command shape:
```bash
./scripts/run.sh run -d <device-id> --debug
```

7. If you use direct commands instead of the bundled script for release, export OHOS build environment and run direct Flutter build.
Command shape:
```bash
"$FLUTTER_BIN" build app --release
```

8. Install the freshly built release package to the target device with `hdc`.
Preferred artifact:
- `ohos/build/outputs/default/*-all-signed.app`
Install command shape:
```bash
"$HDC" -t <device-id> install -r "<artifact-path>"
```

9. Verify the installed bundle.
Use bundle name from `ohos/AppScope/app.json5`.
Command shape:
```bash
"$HDC" -t <device-id> shell bm dump -n <bundle-name>
```

10. Report concise results.
Always include:
- used device id
- resolved install mode: `release` or `debug`
- used profile full path
- used cert full path
- build command and exit status
- installed artifact full path
- install result and key diagnostics if failed

## Script

For default release-package installs, run the bundled script for deterministic execution:
```bash
bash .agents/skills/ohos-release-debug-install/scripts/build_release_install_debug_profile.sh --device-id <device-id>
```

When `--device-id` is omitted, the script auto-selects the first connected `ohos-arm64` device from `flutter devices`.
The script builds a release package and installs it using the profile and certificate currently configured in `ohos/build-profile.json5`.
It now also checks for stale release artifacts, performs `flutter clean` when needed, clears old signed `.app` outputs, and force-stops the installed app before reinstalling.
