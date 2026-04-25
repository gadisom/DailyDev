# Swift Sendable 정리

## 1. Sendable은 왜 쓰는가?

`Sendable`은 Swift 동시성에서 **값을 다른 실행 컨텍스트(다른 스레드/태스크)**로 전달해도 **데이터 레이스 없이 안전**하다는 보장을 명시하는 프로토콜입니다.

Swift Concurrency(`async/await`, `Task`, actor, actor hopping)은 컴파일러가 타입을 분석해서, 서로 다른 실행 컨텍스트로 넘어가는 값이 안전한지 확인합니다. 안전하지 않으면 경고/에러를 냅니다.

---

## 2. 왜 TCA에서 더 자주 만나게 되나?

TCA는 상태/이펙트가 비동기 태스크 안에서 움직입니다.

- `Reducer.run { send in ... }` 내부는 본질적으로 비동기 작업을 시작
- `@Dependency`로 주입된 객체나 useCase가 그 안으로 캡처되어 동작
- 결과를 다시 `send`로 전달

이 과정에서 값이 actor 간, 컨텍스트 간 이동할 수 있으므로 해당 값들이 `Sendable`이어야 합니다.

즉, “TCA를 쓴다”가 목적이라기보다, TCA가 만드는 **비동기 경계**가 이 검사를 촉발합니다.

---

## 3. 우리가 겪는 구간에서의 구체적 적용

현재 도메인 구조에서 이런 흐름이 있습니다.

- `FetchCSCategoriesUseCase: Sendable`
- 내부 저장값 `repository: any CSContentRepository`
- `QuizDataClient`/`HomeContentClient`에서 useCase를 주입해 비동기 실행

여기서 프로토콜이 `CSContentRepository: Sendable`가 아니면, `Sendable` 요구 조건이 전달되어

1) 컴파일러가 안전성 검증을 실패하거나
2) 설계상 보장이 약해져서 동시성에서의 데이터 레이스 위험

을 남길 수 있습니다.

그래서 레이어 경계를 기준으로 아래처럼 쓰는 게 정합적입니다.
- Repository 프로토콜: `: Sendable`
- UseCase 객체: `Sendable` 유지
- 가능하면 구현체는 `actor` 또는 내부 상태가 immutable/value-safe 하게 유지

---

## 4. 언제 꼭 필요하지 않을 수 있나?

모든 코드가 절대 다른 스레드로 이동하지 않고, 단일 실행 컨텍스트에서만 사용되는 아주 제한적 상황이면 엄격히 필요 없는 경우도 있습니다.

하지만 실제 앱은
- 네트워크 요청
- reducer effect
- 캐시/싱글톤/저장소 접근
- 화면 이동 경로
을 통해 자연스럽게 비동기 경계를 넘습니다.

그래서 보수적으로는 Repository/UseCase 레이어를 `Sendable` 기준으로 맞춰 두는 게 유지보수/컴파일/리뷰 모두에 유리합니다.

---

## 5. 정리 원칙 (우리 레이어 구조 기준)

- Domain
  - Repository protocol: `Sendable`
  - UseCase: `Sendable`
- Data
  - actor/동시성 안전 구현체 선호
- Features
  - `@Dependency` 클라이언트 내부 비동기 클로저에서 캡처되는 값은 Sendable 규칙 통과


이 규칙을 따르면 나중에 `@MainActor`, `Task.detached`, actor hopping이 늘어나더라도
새로운 오류를 줄이고, 코드를 추적하기 쉬워집니다.

---

## 6. 실전 체크리스트

- `UseCase`에 `Sendable`을 붙였는가?
- 그 안에 들어가는 프로퍼티 타입이 전부 `Sendable`인가?
- Repository 프로토콜이 `Sendable`인가?
- 구현체가 class인 경우 공유 가변 상태를 캡처하지 않거나 actor로 감쌌는가?
- `Task {}` 또는 TCA `run`에서 넘기는 클로저가 `@Sendable` 제약을 만족하는가?
