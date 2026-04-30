# Core Layer

## 책임

앱 전반에 걸쳐 사용되는 크로스커팅 인터페이스 정의. 외부 SDK 없이 순수 Swift로만 구성.

---

## 제공하는 인터페이스

| 타입 | 역할 |
|------|------|
| `AnalyticsClient` | 이벤트 추적 인터페이스 |
| `AnalyticsEvent` | 이벤트 이름 + 프로퍼티 값 타입 |
| `AnalyticsValue` | Analytics 프로퍼티 값 (string/int/double/bool/array/object/null) |
| `CrashReportingClient` | 크래시 리포팅 인터페이스 |
| `AppEnvironment` | 플랫폼 설정 (iOS / macOS 분기) |

---

## 절대 금지

- Firebase, Amplitude, 기타 외부 SDK import 금지
- 구현 로직 포함 금지 — 인터페이스(`struct`, `protocol`, `enum`)만 정의
- `liveValue` 정의 금지 — live 구현은 App layer에서만

---

## AnalyticsClient 구조

```swift
// Core에서: 인터페이스만
public struct AnalyticsClient {
    public var track: (AnalyticsEvent) async -> Void
    public var setUserID: (String?) async -> Void

    public static let noop = AnalyticsClient(
        track: { _ in },
        setUserID: { _ in }
    )
}
```

구현(`FirebaseAnalyticsService`)은 `App/iOS/Sources/Analytics/`에 위치.

---

## CrashReportingClient 구조

```swift
public struct CrashReportingClient {
    public var recordError: (Error) async -> Void
    public var setUserID: (String?) async -> Void

    public static let noop = CrashReportingClient(
        recordError: { _ in },
        setUserID: { _ in }
    )
}
```

구현(`FirebaseCrashlyticsService`)은 `App/iOS/Sources/CrashReporting/`에 위치.
