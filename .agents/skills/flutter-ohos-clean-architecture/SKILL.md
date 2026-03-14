---
name: flutter-ohos-clean-architecture
description: Audit and refactor Flutter plus OHOS bridge code for modularity, atomic widgets, separation of concerns, decoupled platform channels, and mainstream repository/provider layering. Use when reviewing or fixing architecture in Flutter projects with HarmonyOS or OpenHarmony bridge code.
---

# Flutter OHOS Clean Architecture

Use this skill when a Flutter project needs a structural audit or refactor, especially when Flutter UI, Riverpod state, repositories, and OHOS bridge code have become mixed together.

## Quick Workflow

1. Run `flutter analyze` and sort files by size with `find lib -name '*.dart' -print0 | xargs -0 wc -l | sort -nr`.
2. Flag direct violations before style nits:
   - UI widgets calling `MethodChannel`, `Dio`, storage, or encryption directly
   - repositories owning UI state
   - duplicated domain models across features
   - bridge code that mixes multiple native capabilities in one file
   - authored code files that exceed 200 lines without a strong reason
   - files with more than one reason to change
3. Fix in this order:
   - compile/runtime blockers
   - boundary violations between widget, notifier, repository, service, and bridge
   - duplication and naming drift
   - local warnings inside touched files
4. Re-run `flutter analyze` and targeted tests.

## Flutter Rules

- Widgets and screens assemble UI only. They may read providers and emit intents, but must not own networking, persistence, crypto, or platform-channel orchestration.
- Riverpod notifiers or controllers manage view state and user intents only. They do not know `BuildContext`, `MethodChannel`, or raw HTTP details.
- Repositories are data-facing orchestration boundaries. They combine API, local storage, and bridge-backed services, but they do not expose widget concepts.
- Services wrap one external system or capability. Keep them stateless where possible and injectable.
- Domain models live once per concept. If two features represent the same entity, consolidate or make one a compatibility adapter.

## Atomicity Rules

- Split files when they carry more than one axis of change.
- Authored code files should normally stay at or below 200 lines. If a file must exceed that, document the reason in code comments and prefer splitting by state, models, widgets, routes, or bridge capability first.
- A bridge file should expose one capability family only, such as `qr`, `push`, `crypto`, `device`, or `file`.
- A notifier should manage one slice of state only.
- Shared widgets should be leaf components or small compositions, not mini pages.

## OHOS Bridge Rules

- Keep all channel names centralized. Do not scatter raw channel strings through feature code.
- Do not call `MethodChannel` outside the bridge layer.
- Expose typed methods and typed streams from bridge services; callers should not parse loose maps unless the native SDK truly requires it.
- One native plugin or bridge service per capability. Avoid a single “god bridge”.
- Catch `MissingPluginException` and `PlatformException` inside the bridge and return domain-safe failures.
- Keep event channel lifecycle close to the owning feature and surface cancellable streams.
- When the contract is stable and shared by Dart plus OHOS, prefer generated bindings such as Pigeon over handwritten stringly-typed payloads.

## Verification Gates

- `flutter analyze` must be clean of new errors.
- Excluding generated code and necessary registrants, authored code should not accumulate files above 200 lines unless the exception is deliberate and justified.
- Every touched boundary should have one obvious owner:
  - screen
  - notifier/provider
  - repository
  - external service
  - OHOS bridge
- New code should reduce file size or responsibility spread, not move the same coupling elsewhere.

## References

- Load [references/standards.md](references/standards.md) when you need the fuller checklist, anti-pattern examples, or source links.
