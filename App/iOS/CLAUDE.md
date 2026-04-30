# App/iOS Layer

## 책임

- 앱 진입점 (`DailyDeviOSApp`)
- Firebase SDK 초기화 (`FirebaseAppConfigurator`)
- 루트 TCA Store 생성 및 live dependency 주입
- TabView 컨테이너 (`AppFeature`)
- Push Notification 등록 (`AppDelegate`, `FCMService`)

---

## 폴더 구조

```
App/iOS/Sources/
  ├── DailyDeviOSApp.swift          # @main, 루트 Store, AppDelegate 연결
  ├── AppCoordinator.swift          # AppFeature Reducer (탭 전환, 크로스탭 네비게이션)
  ├── Analytics/
  │   ├── FirebaseAnalyticsService.swift   # Firebase Analytics 구현
  │   └── AnalyticsClient+Live.swift       # live() 팩토리
  ├── CrashReporting/
  │   ├── FirebaseAppConfigurator.swift    # FirebaseApp.configure()
  │   ├── FirebaseCrashlyticsService.swift # Crashlytics 구현
  │   └── CrashReportingClient+Live.swift  # live() 팩토리
  └── Notifications/
      ├── AppDelegate.swift          # APNs 등록, UNUserNotificationCenterDelegate
      └── FCMService.swift           # FCM 토큰 관리, MessagingDelegate
```

---

## 루트 Store 생성 패턴

```swift
@main
struct DailyDeviOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
    } withDependencies: {
        $0.analyticsClient = .live()
        $0.crashReportingClient = .live()
    }

    init() {
        FirebaseAppConfigurator.configureIfPossible()
    }
}
```

`liveValue = .noop`으로 등록된 클라이언트는 반드시 여기서 실제 구현으로 덮어쓴다.

---

## Analytics / CrashReporting Live 구현 패턴

Firebase SDK는 이 레이어에서만 import. Core 인터페이스를 구현하는 service actor를 만들고, `+Live.swift`에서 팩토리 메서드로 래핑한다.

```swift
// FirebaseAnalyticsService.swift
import FirebaseAnalytics
actor FirebaseAnalyticsService {
    func track(_ event: AnalyticsEvent) { ... }
    func setUserID(_ userID: String?) { ... }
}

// AnalyticsClient+Live.swift
import Core
extension AnalyticsClient {
    static func live() -> AnalyticsClient {
        let service = FirebaseAnalyticsService()
        return AnalyticsClient(
            track: { await service.track($0) },
            setUserID: { await service.setUserID($0) }
        )
    }
}
```

CrashReportingClient도 동일한 패턴.

---

## Push Notifications (FCM)

APNs 토큰은 `AppDelegate`에서 수신해 `FCMService`로 전달. FCM 등록 토큰은 `NotificationCenter`로 브로드캐스트.

```swift
// AppDelegate
func application(_ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    FCMService.shared.setAPNSToken(deviceToken)
}

// FCMService
func setAPNSToken(_ token: Data) {
    Messaging.messaging().apnsToken = token
}
```

FCM 토큰이 필요하면 `await FCMService.shared.currentToken()` 으로 가져온다.

---

## 규칙

- Firebase / 외부 SDK import는 이 폴더 내부로만 한정
- `AppFeature`는 TCA Reducer. UI 로직 직접 수행 금지
- `withDependencies` 주입 없이 `.noop` 상태로 배포 금지
