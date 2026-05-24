# Design System

> **Artisan Agent 신조(Creed):** 이 문서는 Artisan 에이전트의 성경이다. UI 구현 전 반드시 참조. (CLAUDE.md §4.2)

---

## 1. Brand Identity

| 속성 | 값 |
|------|-----|
| **브랜드명** | WhipUp (윕업) |
| **핵심 감성** | 따뜻함 · 즐거움 · 창의성 |
| **금지 어조** | 잔소리, 강요, 복잡함 |
| **주방 맥락** | 젖은 손, 작은 화면, 소음 속 사용 |

---

## 2. Color Palette

> **정본:** `docs/brand-assets/README.md §2`에 모든 색상 Hex 값이 정의되어 있다.
> FlexColorScheme의 `FlexScheme.green`을 베이스로 하며, 정확한 Hex 코드는 brand-assets를 참조한다.

| Token | Light | Dark | 용도 |
|-------|-------|------|------|
| `primary` | `#4CAF50` | `#81C784` | CTA, 주요 액션 |
| `secondary` | `#D4A373` | `#E0C097` | 포인트, 강조 |
| `surface` | `#FFF8F0` | `#1E1E1E` | 카드, 바텀시트 |
| `error` | `#D32F2F` | `#EF9A9A` | 경고, 오류 |

### 2.1. Custom Semantic Colors
> 상세 정의: `brand-assets §2.3` (freshGreen, warningAmber, dangerRed, info)
> Recipe Type Badge 색상: `brand-assets §2.4`

---

## 3. Typography

> **정본:** `docs/brand-assets/README.md §3`에 전체 Type Scale (Size, Weight, Line Height, Letter Spacing)이 정의되어 있다.

| 스타일 | Size | Weight | 용도 |
|--------|------|--------|------|
| `displayLarge` | 34sp | Bold | 이모지, 히어로 텍스트 |
| `displayMedium` | 28sp | Bold | 메인 숫자 (재고 수량) |
| `titleLarge` | 22sp | SemiBold | 화면 제목, 레시피명 |
| `titleMedium` | 18sp | SemiBold | 섹션 헤더 |
| `titleSmall` | 15sp | Medium | 서브 헤더 |
| `bodyLarge` | 16sp | Regular | 조리 단계 설명 |
| `bodyMedium` | 14sp | Regular | 일반 본문 |
| `bodySmall` | 12sp | Regular | 부가 정보, 타임스탬프 |
| `labelLarge` | 14sp | Medium | 버튼 텍스트 |
| `labelMedium` | 12sp | Medium | 탭 라벨, 네비게이션 |
| `labelSmall` | 11sp | Medium | 태그, 뱃지 |

> **폰트:** Pretendard (한국어 최적화, OFL 1.1 라이선스). `app/assets/fonts/Pretendard-*.otf` 배치.
> **Font Weight 상세:** `brand-assets §3.2` 참조. **폰트 사용 금지사항:** `brand-assets §3.4` 참조.

---

## 4. Spacing & Sizing

```dart
// 8pt 그리드 시스템
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
```

---

## 5. Interaction Principles

### 5.1. 주방 친화적 UI 원칙
- **터치 영역:** 최소 48x48dp (젖은 손 고려)
- **텍스트 크기:** 최소 14sp (조리 중 가독성)
- **색 대비:** WCAG AA 이상 (주방 조명 변수)
- **애니메이션:** 200~350ms (빠른 응답감)

### 5.2. 햅틱 피드백
| 시나리오 | 햅틱 타입 |
|----------|----------|
| 재료 추가 성공 | `HapticFeedback.lightImpact()` |
| 레시피 생성 완료 | `HapticFeedback.mediumImpact()` |
| 오류 발생 | `HapticFeedback.heavyImpact()` |

### 5.3. Lottie 애니메이션 가이드
| 상황 | 파일 | 설명 |
|------|------|------|
| 레시피 로딩 | `assets/lottie/cooking.json` | 요리 중 애니메이션 |
| 빈 재고 | `assets/lottie/empty_fridge.json` | 빈 냉장고 |
| 성공 | `assets/lottie/success.json` | 완료 도파민 보상 |

---

## 6. Component Guidelines

### 6.1. 재료 카드 (IngredientCard)
- 재료명 + 수량 + 유통기한 색상 표시
- 스와이프로 삭제 (HapticFeedback 동반)

### 6.2. 레시피 카드 (RecipeCard)
- 썸네일 이미지 (또는 이모지 대체)
- recipe_type 뱃지 (색상 코딩)
- 조리시간 + 난이도 인디케이터

### 6.3. 조리 단계 위젯 (CookingStepItem)
- 단계 번호 (크고 굵게)
- phase 레이블 + 설명
- 타이머 버튼 (duration_seconds가 있을 경우)
