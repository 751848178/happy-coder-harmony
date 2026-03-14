# Standards

## Source-Informed Baseline

- Flutter app architecture guide: repositories/services should isolate data and side effects from UI.
  - https://docs.flutter.dev/app-architecture/guide
- Flutter platform channels guide: platform messaging should be isolated behind clear interfaces and codecs.
  - https://docs.flutter.dev/platform-integration/platform-channels
- Flutter plugin development guide: split platform implementations cleanly and keep plugin boundaries explicit.
  - https://docs.flutter.dev/packages-and-plugins/developing-packages
- OpenHarmony community packages show generated or scoped plugin bindings for OHOS instead of app-wide raw channel calls.
  - https://github.com/shinnytech/flutter_packages/tree/main/packages/pigeon
  - https://github.com/openharmony-tpc/flutter_harmonyos

## Structural Checklist

- Presentation
  - screens compose widgets and navigation only
  - no raw `Dio`, `MethodChannel`, filesystem, crypto, or JSON schema branching in widgets
- State
  - providers/notifiers own loading, success, error, and selection state
  - notifiers delegate side effects to repositories or services
- Data
  - repositories are the only place combining API plus local persistence plus bridge-backed services
  - repositories return typed models, not view-specific maps
- Bridge
  - one channel owner per capability
  - centralized channel constants
  - safe error mapping inside bridge
  - typed conversion helpers for `Map<dynamic, dynamic>`
- Domain
  - avoid duplicate models under similarly named features such as `profile` and `profiles`
  - use compatibility adapters if old namespaces must survive temporarily

## Anti-Patterns To Remove

- Monolithic files over several hundred lines that contain unrelated responsibilities
- Authored source files over 200 lines that can be split into models, notifiers, widgets, route sections, or bridge capability files
- A notifier class living in a repository file
- Multiple channel families inside one `harmony_bridge.dart`
- Platform checks sprinkled across screens instead of being hidden behind a feature API
- Native payload parsing duplicated in several callers
- Shared widgets that own business rules or storage mutations

## Refactor Heuristics

- If a file needs changes for both UI and data concerns, split immediately.
- Treat 200 lines as the normal upper bound for authored code. Generated files, registrants, and rare static catalogs can be exceptions, but only when the source of truth lives elsewhere or splitting would reduce clarity.
- If the same domain entity exists in two features, choose one canonical model and make the other a thin adapter.
- If a bridge API is used in more than one feature, add a feature service between the bridge and UI-facing code.
- If a channel contract has more than two methods and two payload shapes, consider generating bindings.

## Validation

- Run `flutter analyze`.
- For each touched feature, verify one import direction:
  - UI -> notifier/provider -> repository/service -> bridge/native
- Confirm bridge callers use typed methods, not raw channel strings.
