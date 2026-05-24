# Design System

> **참조 에이전트:** Artisan (정본)
> 이 문서는 Artisan 에이전트의 성경이다. UI 구현 전 반드시 참조.
> 시각 디테일(색상 Hex, 폰트 규격, 아이콘 매핑)의 정본은 `brand-assets/README.md`이며, 이 문서는 "어떻게 적용하는가"에 집중한다.

---

## 1. Brand Identity

| 속성 | 값 |
|------|-----|
| **브랜드명** | WhipUp (윕업) |
| **핵심 감성** | 따뜻함 · 즐거움 · 창의성 |
| **금지 어조** | 잔소리, 강요, 복잡함 |
| **주방 맥락** | 젖은 손, 작은 화면, 소음 속 사용 |

---

## 2. Color System

> **정본:** `brand-assets/README.md §2`에 모든 Hex 값이 정의되어 있다.
> 이 섹션은 색상의 **적용 규칙**을 기술한다.

### 2.1. Core Colors 적용

| Token | 용도 | 적용 위치 |
|-------|------|----------|
| `primary` | 주요 액션, 긍정적 피드백 | CTA 버튼, FAB, AppBar, 선택 상태 |
| `secondary` | 보조 강조, 포인트 | 뱃지, 보조 버튼, 카드 하이라이트 |
| `surface` | 컨테이너 배경 | 카드, 바텀시트, 다이얼로그 |
| `error` | 부정적 피드백 | 폼 에러, 시스템 장애 |

### 2.2. Semantic Colors 적용

| Token | 적용 규칙 |
|-------|----------|
| `freshGreen` | 유통기한 3일 초과 남은 재고 |
| `warningAmber` | 유통기한 3일 이내 재고 |
| `dangerRed` | 유통기한 초과 재고, 삭제 확인 |
| `info` | 팁, 안내 메시지, science_note |

### 2.3. Recipe Type Badge

- 각 `recipe_type`에 고유 배경색+텍스트색 → `brand-assets §2.4` 참조
- 뱃지는 `labelSmall` 스타일 + `AppSpacing.xs` 패딩 + 4dp border radius

### 2.4. FlexColorScheme 설정

```dart
// app_theme.dart
// Light: FlexScheme.green 기반, seedColor brand-assets §2.1 primary
// Dark: FlexScheme.green 기반, seedColor brand-assets §2.1 primary (dark)
// fontFamily: 'Pretendard'
// useMaterial3: true
// Semantic Colors → ThemeExtension으로 확장
```

---

## 3. Typography

> **정본:** `brand-assets/README.md §3`에 전체 Type Scale이 정의되어 있다.
> 이 섹션은 타이포그래피의 **적용 규칙**을 기술한다.

### 3.1. 서체

- **Primary:** Pretendard (한국어+라틴, OFL 1.1)
- **Fallback:** Apple SD Gothic Neo (iOS), Roboto (Android)
- **파일:** `app/assets/fonts/Pretendard-*.otf`

### 3.2. 적용 규칙

| 상황 | TextStyle | 비고 |
|------|-----------|------|
| 화면 제목 | `titleLarge` (22sp, SemiBold) | AppBar title |
| 섹션 헤더 | `titleMedium` (18sp, SemiBold) | 카드 내 그룹 헤더 |
| 조리 단계 | `bodyLarge` (16sp, Regular) | 충분한 가독성 확보 |
| 일반 본문 | `bodyMedium` (14sp, Regular) | 기본 텍스트 |
| 버튼 | `labelLarge` (14sp, Medium) | CTA, 텍스트 버튼 |
| 태그/뱃지 | `labelSmall` (11sp, Medium) | recipe_type, 카테고리 |
| 히어로 숫자 | `displayMedium` (28sp, Bold) | 재고 수량, 타이머 |

### 3.3. 금지 사항

- 10sp 미만 텍스트 사용 금지 (주방 가독성)
- 이탤릭체 금지 (한국어 부적합)
- 시스템 폰트 직접 지정 금지 (항상 TextTheme 경유)
- ALL CAPS 영문은 라벨/뱃지에만 허용

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

| 사용처 | 값 |
|--------|-----|
| 카드 내부 패딩 | `md` (16) |
| 리스트 아이템 간격 | `sm` (8) |
| 섹션 사이 간격 | `lg` (24) |
| 화면 좌우 여백 | `md` (16) |
| 아이콘-텍스트 간격 | `sm` (8) |
| 칩 내부 패딩 | `xs` (4) 수직, `sm` (8) 수평 |

---

## 5. Interaction Principles

### 5.1. 주방 친화적 UI 원칙

| 규칙 | 기준 | 이유 |
|------|------|------|
| **터치 영역** | 최소 48x48dp | 젖은 손 고려 |
| **텍스트 크기** | 최소 14sp | 조리 중 가독성 |
| **색 대비** | WCAG AA 이상 | 주방 조명 변수 |
| **애니메이션** | 200~350ms | 빠른 응답감 |

### 5.2. 햅틱 피드백

| 시나리오 | 햅틱 타입 |
|----------|----------|
| 재료 추가 성공 | `HapticFeedback.lightImpact()` |
| 레시피 생성 완료 | `HapticFeedback.mediumImpact()` |
| 즐겨찾기 토글 | `HapticFeedback.lightImpact()` |
| 스와이프 삭제 실행 | `HapticFeedback.heavyImpact()` |
| 오류 발생 | `HapticFeedback.heavyImpact()` |

### 5.3. 전환 속도 토큰

| 토큰 | Duration | Curve | 용도 |
|------|----------|-------|------|
| `instant` | 100ms | `easeOut` | 탭 피드백, 색상 변경 |
| `fast` | 200ms | `easeInOut` | 페이드, 스케일, 탭 전환 |
| `normal` | 300ms | `easeInOutCubic` | 페이지 전환, 바텀시트 |
| `slow` | 500ms | `easeInOutCubic` | 온보딩, 히어로 애니메이션 |

### 5.4. Lottie 애니메이션

| 상황 | 파일 | 재생 |
|------|------|------|
| 레시피 로딩 | `assets/lottie/cooking.json` | 무한 반복 |
| 빈 재고 | `assets/lottie/empty_fridge.json` | 무한 반복 |
| 성공 | `assets/lottie/success.json` | 1회 재생 |

> 사양: 30fps, 100KB 이하, Brand Palette 색상만. 상세 → `brand-assets §6.2`

---

## 6. Component Guidelines

> 위젯의 **시각적 규칙**을 정의한다. 레이아웃 배치와 화면 구성은 `screen_layout.md` 참조.

### 6.1. 재료 카드 (IngredientCard)

- Leading: 카테고리 이모지 (`brand-assets §4.4`)
- Title: 재료명 (`titleSmall`)
- Subtitle: 수량 + 단위 (`bodyMedium`)
- Trailing: 유통기한 상태 뱃지 (Semantic Color 적용)
- 스와이프: 왼쪽 → 삭제 (`dangerRed` 배경, `HapticFeedback.heavyImpact`)

### 6.2. 레시피 카드 (RecipeCard)

- 썸네일: 이미지 또는 대표 이모지 (64dp)
- RecipeTypeBadge: 좌상단, `brand-assets §2.4` 색상
- Title: 레시피명 (`titleMedium`)
- Info Row: 조리시간 (`timer_rounded` + 분) + 난이도 인디케이터
- 탭: 레시피 상세 화면으로 이동

### 6.3. 조리 단계 위젯 (CookingStepItem)

- 단계 번호: `displayMedium`, `primary` 색상, 원형 배경
- Phase 라벨: `labelSmall`, `primaryContainer` 배경
- 설명: `bodyLarge` (가독성 최우선)
- 타이머 버튼: `duration_seconds`가 있을 경우만 표시 (`timer_rounded`)
- Tip 영역: `info` 색상 배경, `bodySmall`

### 6.4. 칼럼 카드 (ColumnCard)

- Leading: `thumbnailEmoji` (`displayLarge`)
- Title: 제목 (`titleMedium`)
- Subtitle: 부제 (`bodySmall`)
- Footer: 카테고리 칩 + 읽기 시간

### 6.5. 공용 위젯

| 위젯 | 역할 |
|------|------|
| `WhipUpButton` | Primary / Secondary / Text 3종 버튼 |
| `ExpiryBadge` | 유통기한 상태 표시 (fresh/warning/danger) |
| `CategoryChip` | 카테고리 필터 칩 (이모지 포함) |
| `ErrorStateWidget` | 에러 Lottie + 메시지 + 재시도 버튼 |
| `EmptyStateWidget` | 빈 상태 Lottie + 안내 메시지 |

---

## 7. Accessibility

| 규칙 | 기준 |
|------|------|
| 모든 아이콘/이미지에 `semanticLabel` | 필수 |
| 색상만으로 정보 전달 | 금지 (아이콘/텍스트 병행) |
| 최소 터치 영역 | 48x48dp |
| 다국어 | slang 패키지, 한국어 우선 |

---

## 8. Theme File Structure (Artisan)

```
app/lib/theme/
├── app_theme.dart          # ThemeData (Light/Dark) + FlexColorScheme
├── app_colors.dart         # Semantic Colors → ThemeExtension
├── app_typography.dart     # Type Scale 커스텀 (brand-assets §3.3 기준)
├── app_spacing.dart        # 8pt Grid 상수
└── app_shadows.dart        # Elevation 토큰
```
