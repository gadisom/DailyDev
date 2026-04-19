# DailyDev Agent Guide

This workspace uses TCA as the primary feature architecture.

When editing TCA code in this repository, follow these rules by default.

## TCA rules

1. Follow the architecture notes in [docs/TCA_ARCHITECTURE.md](/Users/kim-jeongwon/Desktop/DailyDev/docs/TCA_ARCHITECTURE.md).
2. Use `/Users/kim-jeongwon/Desktop/crypto-book-iOS` as the reference style for TCA dependency keys and feature composition.
3. For CS JSON sync behavior, follow [docs/CS_DATA_SYNC.md](/Users/kim-jeongwon/Desktop/DailyDev/docs/CS_DATA_SYNC.md).
4. Put screen-level features under `Modules/Features/<FeatureName>`.
4. Keep reducer/state/action in `*Feature.swift`.
5. Keep SwiftUI view files separate from reducer files.
6. Prefer feature-local `Dependencies/` folders for feature-specific TCA clients.
7. Shared TCA dependencies should be promoted to shared modules instead of duplicated across features.
8. Use `DependencyKey` and `DependencyValues` for TCA dependency wiring.
9. Use `@Dependency` inside reducers instead of constructing repositories/services directly.
10. Compose child features with `Scope`, `ifLet`, `forEach`, and TCA navigation tools when appropriate.

## Avoid

- Do not scatter `DependencyKey` implementations randomly across unrelated files.
- Do not put business logic directly in SwiftUI views.
- Do not mix multiple TCA styles in the same feature unless there is a strong reason.
- Do not bypass TCA dependencies with ad-hoc singletons inside reducers.

## Practical note

TCA uses Swift macros in this workspace.
If builds fail in Xcode after package changes, macro approval may be required in the IDE.
