# Entity Layer

## 책임

순수 도메인 모델 정의. 외부 의존성 없음.

---

## 모델 정의 규칙

```swift
public struct SomeEntity: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
}
```

- `Codable` — 직렬화 (SwiftData 저장 또는 테스트 fixture)
- `Equatable` — TCA State에서 비교 가능
- `Sendable` — actor 경계 전달 가능
- `Identifiable` — List 렌더링, ForEach

에러 타입은 `userMessage` (사용자 노출 메시지), `isRetriable` 계산 프로퍼티 포함.

---

## 규칙

- 외부 SDK / 프레임워크 import 금지
- 비즈니스 로직 포함 금지 — 순수 데이터 구조만
- 클래스 타입 금지 — 반드시 `struct` 또는 `enum`
