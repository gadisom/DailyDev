# DailyDev Architecture

## 레이어 구조

```
App (iOS)
  └─ Features
       └─ Core / Entity / Domain / Data / DesignSystem
```

의존성은 단방향. 상위 레이어만 하위 레이어를 알고, 역방향 참조 금지.

```
App
 ├── Features      ← TCA Reducer + View
 ├── Core          ← 크로스커팅 관심사 (Analytics 인터페이스, AppEnvironment)
 ├── DesignSystem  ← 디자인 토큰 + UI 기초 컴포넌트
 └── (transitive)
      ├── Domain   ← Repository 프로토콜 + UseCase
      ├── Data     ← 네트워크 구현체 (Supabase, REST)
      └── Entity   ← 순수 도메인 모델
```

---

## 각 레이어 책임

### App/iOS
- 앱 진입점 (`DailyDeviOSApp`)
- 루트 TCA Store 생성 및 dependency 주입 (`withDependencies`)
- TabView 컨테이너 (`AppFeature`)
- SDK 초기화 (Amplitude 등) — **SDK import는 App layer에만**

### Features
- TCA Reducer + SwiftUI View 결합
- Feature별 DependencyClient 정의 (`CSContentClient`, `PostContentClient`, `QuizDataClient`)
- Analytics 이벤트 정의 (`AmplitudeEvent`) 및 AnalyticsClient DependencyKey
- Platform 분기 처리 (iOS/macOS)

### Core
- SDK 미포함 순수 인터페이스만 (`AnalyticsClient` struct, `AnalyticsEvent`, `AnalyticsValue`)
- `AppEnvironment` (플랫폼 설정)
- **AmplitudeSwift import 금지** — 구현은 App layer에

### Domain
- Repository 프로토콜 정의
- UseCase: 단일 Repository 메서드 호출 래핑

### Data
- Repository 구현체 (모두 `actor`)
- DTO → Entity 변환
- 네트워킹 (Supabase, URLSession)

### Entity
- 순수 데이터 모델 (`Codable`, `Equatable`, `Sendable`, `Identifiable`)
- 에러 타입 (`userMessage`, `isRetriable` 계산 프로퍼티)
- 외부 의존성 없음

### DesignSystem
- 디자인 토큰: `BrandPalette`, `Spacing`, `Radius`, `Animation`
- 재사용 UI 컴포넌트
- Core만 import 허용

---

## TCA 패턴 표준

### Reducer 구조

```swift
@Reducer
public struct XxxFeature {
    @ObservableState
    public struct State: Equatable { ... }

    public enum Action: BindableAction, Sendable {
        case binding(BindingAction<State>)
        // 사용자 액션
        // 내부 effect 결과: _xxxResponse(Result<T, Error>)
        // 크로스 feature 통신: delegate(Delegate)
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in ... }
    }
}
```

### Action 네이밍 규칙

| 목적 | 패턴 | 예시 |
|------|------|------|
| 사용자 액션 | 동사+명사 | `categorySelected`, `refreshRequested` |
| Effect 결과 (내부) | `_xxx(Result<T, E>)` | `_loadResponse` |
| 상위로 전파 | `delegate(Delegate)` | `delegate(.selectConcept(...))` |
| 라이프사이클 | `task` | `task` |

`_` prefix는 Feature 외부에서 직접 send 금지.

### Delegate Action 패턴

Feature 간 통신은 콜백 클로저 대신 delegate action 사용.

```swift
public enum Action: BindableAction, Sendable {
    ...
    case delegate(Delegate)

    public enum Delegate: Sendable {
        case selectConcept(categoryID: String, conceptID: String)
    }
}

// Reducer에서: delegate action은 .none 반환 (부모가 처리)
case .delegate:
    return .none
```

부모 Reducer(`AppFeature`)에서 `Scope` 이후 캐치:
```swift
case .saved(.delegate(.selectConcept(let categoryID, let conceptID))):
    state.homeNavigationRequest = HomeNavigationRequest(...)
    state.selectedTab = .home
    return .none
```

### DependencyKey 정의 위치

- Feature별 클라이언트는 해당 Feature의 `Dependencies/` 폴더에 정의
- `liveValue`에서 Repository + UseCase 직접 조립
- `AnalyticsClient`는 `Features/Shared/Dependencies/`에 정의, `liveValue = .noop`
- 실제 live 구현은 App layer에서 `withDependencies`로 주입

```swift
// Features/Shared/Dependencies/AnalyticsClientDependency.swift
private enum AnalyticsClientKey: DependencyKey {
    static let liveValue = AnalyticsClient.noop  // App이 주입
    static let testValue = AnalyticsClient.noop
}

// App/iOS/Sources/DailyDeviOSApp.swift
Store(initialState: AppFeature.State()) {
    AppFeature()
} withDependencies: {
    $0.analyticsClient = .live()
}
```

### Effect 패턴

```swift
// 비동기 작업
return .run { send in
    do {
        let result = try await client.fetch()
        await send(.loaded(.success(result)))
    } catch {
        await send(.loaded(.failure(error)))
    }
}

// 다중 effect 동시 실행
return .merge(
    .run { _ in await analyticsClient.track(...) },
    .send(._load(reset: true))
)
```

---

## 네비게이션 아키텍처

### 계층

| 레벨 | 구현 | 소유자 |
|------|------|--------|
| 탭 전환 | `TabView(selection: $store.selectedTab)` | AppFeature |
| 스택 네비게이션 | `NavigationStack(path: $path)` + `HomeRoute` enum | HomeIOSCoordinator |
| 모달/시트 | `.navigationDestination(isPresented:)` | 각 Feature View |

### 크로스 탭 네비게이션

SavedFeature → HomeFeature 이동 흐름:

```
SavedView 클릭
  → store.send(.delegate(.selectConcept(...)))
  → AppFeature가 캐치
  → state.homeNavigationRequest = HomeNavigationRequest(...)
  → state.selectedTab = .home
  → HomeIOSCoordinator의 .onChange(of: navigationRequest) 반응
  → path 업데이트 + navigationRequest = nil
```

### Route 정의

```swift
public enum HomeRoute: Hashable {
    case category(String)
    case lesson(categoryID: String, subcategoryID: String)
}
```

새 Feature의 딥링크/크로스탭 이동이 필요하면 동일하게 `XxxRoute` enum + `AppFeature`에 `xxxxxNavigationRequest` state 추가.

---

## Feature 구조 표준

새 Feature를 추가할 때 따라야 할 폴더 구조:

```
Features/Sources/Xxx/
  ├── XxxFeature.swift          # Reducer
  ├── XxxScene.swift            # 진입점 (store 수신, platform 분기)
  ├── iOS/
  │   ├── XxxView.swift         # 메인 뷰
  │   └── XxxSubView.swift      # 하위 뷰
  ├── macOS/                    # macOS 지원 시
  │   └── XxxMacView.swift
  └── Dependencies/
      └── XxxClient.swift       # DependencyKey + Client struct
```

**Scene의 역할**: store를 받아 platform 분기만 처리. 비즈니스 로직 없음.

```swift
public struct XxxScene: View {
    private let store: StoreOf<XxxFeature>

    public init(store: StoreOf<XxxFeature>) {
        self.store = store
    }

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

## Analytics 표준

### 이벤트 정의 위치

`Features/Sources/Shared/Analytics/AmplitudeEvent.swift`에 모든 이벤트 정의.

```swift
public enum AmplitudeEvent {
    case appOpened
    case tabSelected(tab: String)
    case xxxAction(param: String)

    public var name: String { ... }
    public var properties: [String: AnalyticsValue] { ... }
}
```

`AnalyticsEvent`로 변환하는 extension도 같은 파일에:
```swift
extension AnalyticsClient {
    func track(_ event: AmplitudeEvent) async {
        await track(AnalyticsEvent(name: event.name, properties: event.properties))
    }
}
```

### Reducer에서 추적

```swift
case .someAction:
    state.something = newValue
    return .run { _ in
        await analyticsClient.track(.someAction(param: value))
    }
```

상태 변경과 추적을 같이 처리할 때 `.merge` 금지 — 상태 변경은 동기, 추적은 `.run`으로 분리.

---

## Repository / UseCase 패턴

### Repository 프로토콜 (Domain)

```swift
public protocol XxxRepository: Sendable {
    func fetchSomething() async throws -> SomeEntity
}
```

### Repository 구현체 (Data)

```swift
actor XxxConcreteRepository: XxxRepository {
    func fetchSomething() async throws -> SomeEntity {
        // 네트워크 호출 → DTO → Entity 변환
    }
}
```

### UseCase (Domain)

```swift
public struct FetchXxxUseCase {
    private let repository: XxxRepository

    public init(repository: XxxRepository) {
        self.repository = repository
    }

    public func execute(...) async throws -> SomeEntity {
        try await repository.fetchSomething()
    }
}
```

### DependencyClient에서 조립 (Features)

```swift
private enum XxxClientKey: DependencyKey {
    static let liveValue: XxxClient = {
        let repository = XxxConcreteRepository()
        let useCase = FetchXxxUseCase(repository: repository)
        return XxxClient(
            fetch: { try await useCase.execute() }
        )
    }()
}
```

---

## SwiftData

- `@Model` 클래스는 `Features/Saved/Models/`에 정의
- `modelContainer` 설정은 App layer (`DailyDeviOSApp.body`)
- Feature View에서 `@Query`로 직접 읽기, `@Environment(\.modelContext)`로 쓰기
- TCA State에 SwiftData 모델 저장 금지 — View 레이어에서만 소유

---

## 플랫폼 분기

컴파일 타임 분기보다 런타임 분기 선호 (공유 코드 최대화):

```swift
// 선호: 런타임
switch store.platform {
case .iOS: IOSView(store: store)
case .macOS: MacView(store: store)
}

// 허용: 컴파일 타임 (iOS 전용 SDK 사용 시)
#if os(iOS)
import UIKit
#endif
```

iOS 전용 Feature는 파일 상단에 `#if os(iOS)` 래핑.

---

## 금지 사항

- Feature 간 직접 import 금지 (HomeFeature → QuizFeature 등)
- App layer 이외에서 SDK(Amplitude 등) 직접 import 금지
- TCA State에 클래스 타입 저장 금지 (`Equatable` 준수 불가)
- `_` prefix action을 Feature 외부에서 send 금지
- Reducer 내에서 UI 작업 직접 수행 금지 (View의 책임)
- Repository를 Feature에서 직접 import 금지 (DependencyClient 통해서만)
