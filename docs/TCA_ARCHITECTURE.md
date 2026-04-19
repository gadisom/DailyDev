# TCA Architecture Guide

`DailyDev` follows the same broad TCA direction used in `/Users/kim-jeongwon/Desktop/crypto-book-iOS`.

The goal is consistency:

- dependency keys are easy to find
- feature boundaries stay stable
- parent/child reducer composition stays predictable
- future TCA edits follow one pattern instead of mixing styles

## Core rules

1. Every screen-level feature lives under `Modules/Features/<FeatureName>`.
2. Each feature owns its own reducer, state, action, and view files.
3. TCA dependencies are exposed through `DependencyValues` keys, not ad-hoc singletons inside reducers.
4. Parent features compose child features with `Scope`, `ifLet`, or `forEach`.
5. Views talk to `StoreOf<Feature>` and do not own business logic.
6. Reducers depend on clients/use cases through `@Dependency`, not direct repository construction.

## Folder layout

For a feature named `Home`, prefer this structure:

```text
Modules/Features/Home/
├── Project.swift
├── Sources/
│   ├── HomeFeature.swift
│   ├── HomeView.swift
│   ├── HomePhoneView.swift
│   ├── HomePadView.swift
│   ├── HomeMacView.swift
│   ├── Models/
│   ├── Components/
│   └── Dependencies/
│       ├── HomeClient.swift
│       └── HomeDependencyKey.swift
└── Support/
```

Not every feature needs all files on day one.

The important part is keeping:

- reducer code in `*Feature.swift`
- view code in `*View.swift`
- TCA client/dependency definitions in `Dependencies/`

## Dependency pattern

Use `crypto-book-iOS/Targets/App/Sources/Dependencies/TCAKey.swift` as the mental model.

We will follow this shape in `DailyDev`:

1. Define a lightweight client type.
2. Define a `DependencyKey` for the live implementation.
3. Expose it via `DependencyValues`.
4. Inject it into reducers with `@Dependency`.

Example:

```swift
import ComposableArchitecture

struct ArticleClient {
    var fetchToday: @Sendable () async throws -> [Article]
}

private enum ArticleClientKey: DependencyKey {
    static let liveValue = ArticleClient(
        fetchToday: {
            []
        }
    )
}

extension DependencyValues {
    var articleClient: ArticleClient {
        get { self[ArticleClientKey.self] }
        set { self[ArticleClientKey.self] = newValue }
    }
}
```

Reducer usage:

```swift
@Reducer
struct HomeFeature {
    @Dependency(\.articleClient) var articleClient
}
```

## Where dependencies live

Use this rule of thumb:

- feature-specific client: `Modules/Features/<FeatureName>/Sources/Dependencies`
- shared cross-feature client: `Modules/Core` or a future shared `Modules/Domain` / `Modules/Data` dependency bridge

Do not scatter `DependencyKey` definitions randomly across unrelated files.

If a dependency is only used by `Home`, keep it in `Home`.
If multiple features use it, promote it to a shared module.

## Parent-child feature composition

When one feature owns another feature:

- parent state owns child state
- parent action wraps child action
- reducer composes child reducer with `Scope`

Like this:

```swift
@Reducer
struct RootFeature {
    @ObservableState
    struct State: Equatable {
        var home = HomeFeature.State()
    }

    enum Action {
        case home(HomeFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }

        Reduce { state, action in
            switch action {
            case .home:
                return .none
            }
        }
    }
}
```

For navigation stacks, follow the same pattern as `crypto-book-iOS`:

- nested `Path` reducer
- `StackState`
- `forEach(\.path, action: \.path)`

## View rules

Views should stay thin.

Good:

- bind UI to state
- send actions
- compose smaller view components
- branch by platform when necessary

Avoid:

- constructing repositories/services in views
- putting network logic directly in button handlers
- inventing local state that duplicates reducer state

Preferred shape:

```swift
struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        Text(store.title)
    }
}
```

## When editing TCA code

Whenever TCA code is changed in `DailyDev`, prefer this checklist:

1. Is this change inside the correct feature module?
2. If new async/business behavior is added, should it become a dependency client?
3. If a dependency is added, is it exposed through `DependencyKey` and `DependencyValues`?
4. If state/action grows, should it be split into child features or components?
5. If navigation is added, should it use TCA navigation tools instead of ad-hoc booleans?

## Current project direction

Right now `Home` is the first TCA feature.

As more features are added, follow the same naming and composition pattern:

- `Modules/Features/Home`
- `Modules/Features/Settings`
- `Modules/Features/Bookmarks`
- `Modules/Features/Feed`

If we later add shared domain/data modules, TCA reducers should still depend on those through client abstractions, not concrete implementations.

## Practical note for this workspace

TCA currently brings in Swift macros.
On a fresh machine or after package updates, Xcode may ask to approve package macros before the project builds normally in the IDE.

That is expected for this setup.
