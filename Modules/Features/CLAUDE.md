# Features Layer

## 책임

- TCA Reducer + SwiftUI View 결합
- Feature별 DependencyClient 정의 및 조립 (Repository + UseCase)
- Analytics / CrashReporting 이벤트 전송 (인터페이스만, 구현은 App layer)
- Platform 분기 처리 (iOS / macOS)

---

## 폴더 구조 표준

```
Features/Sources/Xxx/
  ├── XxxFeature.swift          # Reducer
  ├── XxxScene.swift            # 진입점 — platform 분기만, 비즈니스 로직 없음
  ├── iOS/
  │   ├── XxxView.swift
  │   └── XxxSubView.swift
  ├── macOS/
  │   └── XxxMacView.swift
  └── Dependencies/
      └── XxxClient.swift       # DependencyKey + Client struct

Features/Sources/Shared/
  ├── Analytics/
  │   └── AppEvent.swift        # 전체 이벤트 정의
  └── Dependencies/
      ├── AnalyticsClientDependency.swift
      └── CrashReportingClientDependency.swift
```

---

## TCA Reducer 구조

```swift
@Reducer
public struct XxxFeature {
    @ObservableState
    public struct State: Equatable { ... }

    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        case task                              // 라이프사이클
        case userDidTapSomething               // 사용자 액션
        case _loadResponse(Result<T, Error>)   // 내부 effect 결과
        case delegate(Delegate)                // 상위 전파

        public enum Delegate: Sendable {
            case someEvent(param: String)
        }
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in ... }
    }
}
```

---

## Action 네이밍 규칙

| 목적 | 패턴 | 예시 |
|------|------|------|
| 사용자 액션 | 동사+명사 | `categorySelected`, `refreshRequested` |
| Effect 결과 (내부) | `_xxxResponse(Result<T, E>)` | `_loadResponse` |
| 상위로 전파 | `delegate(Delegate)` | `delegate(.selectConcept(...))` |
| 라이프사이클 | `task` | `task` |

`_` prefix action은 Feature 외부에서 send 금지.

---

## Delegate Action 패턴

Feature 간 통신은 콜백 클로저 대신 delegate action 사용.

```swift
// 자식 Feature: delegate는 .none 반환 (부모가 처리)
case .delegate:
    return .none

// 부모 (AppFeature): Scope 이후 캐치
case .saved(.delegate(.selectConcept(let categoryID, let conceptID))):
    state.homeNavigationRequest = HomeNavigationRequest(...)
    state.selectedTab = .home
    return .none
```

---

## DependencyClient 정의 패턴

```swift
// Features/Xxx/Dependencies/XxxClient.swift
struct XxxClient {
    var fetch: () async throws -> [SomeEntity]
}

private enum XxxClientKey: DependencyKey {
    static let liveValue: XxxClient = {
        let repository = XxxConcreteRepository()
        let useCase = FetchXxxUseCase(repository: repository)
        return XxxClient(fetch: { try await useCase.execute() })
    }()
}

extension DependencyValues {
    var xxxClient: XxxClient {
        get { self[XxxClientKey.self] }
        set { self[XxxClientKey.self] = newValue }
    }
}
```

Analytics / CrashReporting은 `liveValue = .noop`. 실제 구현은 App layer에서 `withDependencies`로 주입.

---

## Effect 패턴

```swift
// 비동기 작업
return .run { send in
    do {
        let result = try await client.fetch()
        await send(._loadResponse(.success(result)))
    } catch {
        await send(._loadResponse(.failure(error)))
    }
}
```

상태 변경 + 이벤트 추적을 같이 처리할 때 `.merge` 금지. 상태 변경은 동기, 추적은 별도 `.run`:

```swift
case .someAction:
    state.value = newValue          // 동기 상태 변경
    return .run { _ in
        await analyticsClient.track(.someAction)   // 비동기 추적
    }
```

---

## Analytics 이벤트 표준

모든 이벤트는 `Features/Sources/Shared/Analytics/AppEvent.swift` 에 정의.

```swift
public enum AppEvent {
    case app_opened
    case tab_selected(tab: String)
    case concept_viewed(category_id: String, concept_id: String)

    public var name: String { ... }
    public var properties: [String: AnalyticsValue] { ... }
}

extension AnalyticsClient {
    func track(_ event: AppEvent) async {
        await track(AnalyticsEvent(name: event.name, properties: event.properties))
    }
}
```

이벤트 이름은 Firebase 규칙에 따라 snake_case 사용.

---

## Scene 패턴

Scene은 store를 받아 platform 분기만 처리. 비즈니스 로직 없음.

```swift
public struct XxxScene: View {
    let store: StoreOf<XxxFeature>

    public var body: some View {
        #if os(iOS)
        XxxIOSView(store: store)
        #else
        XxxMacView(store: store)
        #endif
    }
}
```

---

## 네비게이션 아키텍처

| 레벨 | 구현 | 소유자 |
|------|------|--------|
| 탭 전환 | `TabView(selection: $store.selectedTab)` | AppFeature |
| 스택 네비게이션 | `NavigationStack(path: $path)` + `XxxRoute` enum | XxxIOSCoordinator |
| 모달/시트 | `.navigationDestination(isPresented:)` | 각 Feature View |

크로스탭 이동이 필요하면 `delegate` action → `AppFeature` 캐치 → `navigationRequest` state 업데이트 → Coordinator 반응.

---

## SwiftData 규칙

- `@Model` 클래스는 해당 Feature의 `Models/` 폴더에 정의
- `modelContainer` 설정은 App layer (`DailyDeviOSApp.body`)
- View에서 `@Query`로 읽기, `@Environment(\.modelContext)`로 쓰기
- TCA State에 SwiftData 모델 저장 금지 — View 레이어에서만 소유
