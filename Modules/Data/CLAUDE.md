# Data Layer

## 책임

- Domain layer의 Repository 프로토콜 구현
- 네트워킹 (Supabase, URLSession)
- DTO → Entity 변환

---

## 폴더 구조

```
Data/Sources/
  ├── XxxRepository.swift          # Repository 구현체 (actor)
  ├── Networking/
  │   ├── SupabaseClient.swift     # Supabase 클라이언트 래퍼
  │   └── HTTPClient.swift         # URLSession 래퍼
  └── Models/
      └── XxxDTO.swift             # 네트워크 응답 DTO (Codable)
```

---

## Repository 구현체 패턴

```swift
actor XxxConcreteRepository: XxxRepository {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient = .shared) {
        self.supabase = supabase
    }

    func fetchSomething() async throws -> [SomeEntity] {
        let dtos: [SomeDTO] = try await supabase.fetch(from: "table_name")
        return dtos.map { $0.toEntity() }
    }
}
```

- 반드시 `actor`로 선언 (Sendable + 데이터 경쟁 방지)
- DTO → Entity 변환은 `DTO+Mapping.swift` 또는 DTO 내부 `toEntity()` 메서드로 처리

---

## DTO 패턴

```swift
struct SomeDTO: Codable {
    let id: String
    let title: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt = "created_at"
    }

    func toEntity() -> SomeEntity {
        SomeEntity(id: id, title: title)
    }
}
```

DTO는 네트워크 응답 구조에 맞게 정의. Entity 타입은 Data layer에서 직접 생성 금지 — DTO 변환으로만.

---

## 규칙

- Repository 구현체는 Features에서 직접 import 금지 — DependencyClient 통해서만 접근
- DTO는 Data layer 내부에서만 사용. Entity를 절대 DTO로 대체 사용 금지
