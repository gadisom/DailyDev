# DesignSystem Layer

## 책임

디자인 토큰과 재사용 UI 컴포넌트 제공. Core만 import 허용.

---

## 제공하는 토큰

| 타입 | 역할 |
|------|------|
| `BrandPalette` | 브랜드 컬러 (green, background 등) |
| `Spacing` | 여백 기준값 |
| `Radius` | 모서리 반경 |
| `Animation` | 애니메이션 duration / curve |

---

## 규칙

- Core 이외 레이어 import 금지
- 비즈니스 로직 포함 금지
- 컴포넌트는 데이터를 직접 fetch하지 않음 — 값을 전달받아 렌더링만
