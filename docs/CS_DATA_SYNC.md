# CS Data Sync

`DailyDev`는 JSON 원본을 즉시 뷰에 바인딩하지 않고, `SwiftData`를 SSOT로 두는 흐름으로 운영합니다.

## 핵심 규칙
- 앱이 `Home`의 `.task`를 시작할 때 `CSContentClient.fetchManifest()`를 먼저 호출합니다.
- `fetchManifest()`는 `SyncCSContentUseCase.execute()`를 통해 다음을 수행합니다.
  - 원격 manifest 버전 체크
  - 버전이 올라가면 원격 categories/content JSON을 전체 갱신
  - 네트워크 실패 시 로컬 캐시(또는 번들 seed)로 fallback
- `fetchCategories()` / `fetchCategoryContent()`는 SwiftData 캐시만 읽습니다.
- 기존 앱 번들 JSON은 bootstrap 용도로만 사용하고, 기본 렌더링 경로는 로컬 DB입니다.

## 레이어 맵
- Data
  - `CSSwiftDataContentRepository`(`CSContentRepository`): manifest 동기화, SwiftData persist, 캐시 조회
  - `CSBundleRepository`: 번들 리소스 seed
  - `CSRemoteContentService`: Supabase manifest/categories/content fetch
- Domain
  - `SyncCSContentUseCase`: 동기화 트리거
  - `FetchCSManifestUseCase`: 로컬 manifest 조회
  - `FetchCSCategoriesUseCase`: 로컬 카테고리 조회
  - `FetchCSCategoryContentUseCase`: 로컬 카테고리 콘텐츠 조회
- Feature(Home)
  - `CSContentClient`: 의존성 브릿지, 위 use case를 통해 reducer에 제공

## 나중 확장 포인트 (iCloud)
- 현재는 `ModelContainer("DailyDevCS")`로 로컬 영구 저장소 사용
- 장기적으로 iCloud 공유가 필요하면 `ModelConfiguration`을 CloudKit 설정으로 교체하거나, 별도 migration 정책을 둡니다.
