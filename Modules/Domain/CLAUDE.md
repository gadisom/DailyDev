# Domain Layer

## 책임

- Repository 프로토콜 정의 (구현체는 Data layer)
- UseCase: 단일 Repository 메서드 호출을 래핑하는 값 타입

외부 의존성 없음. Entity만 import.

---

## Repository 프로토콜 패턴

```swift
public protocol XxxRepository: Sendable {
    func fetchSomething() async throws -> [SomeEntity]
    func fetchById(_ id: String) async throws -> SomeEntity
}
```

- 반드시 `Sendable` 준수
- 반환 타입은 Entity layer 타입만 사용
- 구현체는 Data layer의 `actor`로 작성

---

## UseCase 패턴

```swift
public struct FetchXxxUseCase {
    private let repository: XxxRepository

    public init(repository: XxxRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [SomeEntity] {
        try await repository.fetchSomething()
    }
}
```

UseCase는 단일 책임 원칙. 여러 Repository를 조합하거나 복잡한 비즈니스 로직이 필요하면 별도 UseCase로 분리.

---

## 현재 정의된 Repository / UseCase

| Repository | UseCase |
|-----------|---------|
| `CSContentRepository` | `FetchCSCategoriesUseCase`, `FetchCSCategoryContentUseCase` |
| `PostResourceRepository` | `FetchPostArticlesUseCase`, `FetchPostBlogSourcesUseCase` |
| `QuizRepository` | `FetchQuizBankUseCase` |
