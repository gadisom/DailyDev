# DailyDev Architecture

## 레이어 구조

```
App (iOS / macOS)
  └─ Features
       └─ Core / DesignSystem
            └─ Domain
                 └─ Data / Entity
```

의존성은 단방향. 상위 레이어만 하위 레이어를 참조하며, 역방향 참조는 금지.

```
App
 ├── Features      ← TCA Reducer + View, DependencyClient 조립
 ├── Core          ← 크로스커팅 인터페이스 (Analytics, CrashReporting, AppEnvironment)
 ├── DesignSystem  ← 디자인 토큰 + 재사용 UI 컴포넌트
 └── (transitive)
      ├── Domain   ← Repository 프로토콜 + UseCase
      ├── Data     ← 네트워크 구현체 (Supabase, REST)
      └── Entity   ← 순수 도메인 모델
```

---

## 각 레이어 한 줄 책임

| 레이어 | 책임 | 세부 규칙 |
|--------|------|-----------|
| **App** | 진입점, SDK 초기화, 루트 Store 생성 | [App/iOS/CLAUDE.md](App/iOS/CLAUDE.md) |
| **Features** | TCA Reducer + View, DependencyClient | [Modules/Features/CLAUDE.md](Modules/Features/CLAUDE.md) |
| **Core** | SDK 없는 순수 인터페이스 | [Modules/Core/CLAUDE.md](Modules/Core/CLAUDE.md) |
| **DesignSystem** | 디자인 토큰, 기초 컴포넌트 | [Modules/DesignSystem/CLAUDE.md](Modules/DesignSystem/CLAUDE.md) |
| **Domain** | Repository 프로토콜, UseCase | [Modules/Domain/CLAUDE.md](Modules/Domain/CLAUDE.md) |
| **Data** | Repository 구현체, DTO→Entity | [Modules/Data/CLAUDE.md](Modules/Data/CLAUDE.md) |
| **Entity** | 순수 도메인 모델 | [Modules/Entity/CLAUDE.md](Modules/Entity/CLAUDE.md) |

---

## 전체 데이터 흐름

```
User Action
  → TCA Reducer (Features)
  → DependencyClient.fetch()
  → UseCase.execute() (Domain)
  → Repository.fetch() (Domain Protocol)
  → ConcreteRepository (Data) → Supabase / REST
  → DTO → Entity 변환
  → State 업데이트 → View 렌더링
```

---

## 크로스커팅 관심사 흐름

Analytics / CrashReporting은 구현과 인터페이스가 레이어 경계로 분리됨:

```
Core          : 인터페이스 정의 (AnalyticsClient, CrashReportingClient)
Features      : DependencyKey 등록, liveValue = .noop
App/iOS       : Firebase 기반 live 구현체 생성 + withDependencies로 주입
```

---

## 전체 금지 사항

- Feature 간 직접 import 금지 (HomeFeature → QuizFeature 등)
- App layer 이외에서 Firebase, 외부 SDK 직접 import 금지
- TCA State에 클래스 타입 저장 금지 (`Equatable` 준수 불가)
- `_` prefix action을 Feature 외부에서 send 금지
- Reducer 내에서 UI 작업 직접 수행 금지
- Feature에서 Repository 직접 import 금지 (DependencyClient 통해서만)
- Core에서 외부 SDK import 금지 (순수 Swift 인터페이스만)
