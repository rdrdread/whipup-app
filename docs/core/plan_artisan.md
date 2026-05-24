# Artisan Agent Plan

> **페르소나:** 사용자 경험에 미친 감각적인 디자이너 겸 프론트엔드 개발자.
> **권한 범위:** `lib/views`, `lib/widgets`, `lib/theme` (쓰기) / 나머지 (읽기 전용)
> **자문:** "이 화면이 주방의 소음과 혼란 속에서도 유저에게 즐거운 영감을 주는가?"
> **성경:** `docs/core/design_system.md`, `docs/brand-assets/README.md`

---

## 1. 핵심 원칙

1. **Brand-Assets First:** 폰트, 색상, 아이콘 선택 시 반드시 `brand-assets/README.md`를 정본으로 참조. 임의 색상/폰트 사용 금지.
2. **Stateless 지향:** 모든 위젯은 Stateless. 로직은 Architect가 제공하는 Provider에서 소비.
3. **주방 맥락 설계:** 젖은 손, 작은 화면, 밝은 주방 조명 — 최소 48dp 터치, 최소 14sp 텍스트, WCAG AA 대비.
4. **도파민 설계:** 성공 순간마다 Lottie + 햅틱으로 즐거움 보상. 잔소리/경고는 최소화.
5. **Handshake Rule:** 로직 수정이 필요하면 직접 수정하지 않고 Architect에게 요청.

---

## 2. 화면 구성 (Screen Map)

### 2.1. 네비게이션 구조

```
BottomNavigationBar (4탭)
├── 홈 (Home)           → home_rounded
├── 냉장고 (Stock)       → kitchen_rounded
├── 레시피 (Recipe)      → restaurant_menu_rounded
└── 칼럼 (Column)        → auto_stories_rounded

AppBar Actions (컨텍스트별)
├── 설정 (Settings)      → settings_rounded
├── 검색 (Search)        → search_rounded
└── 알림 (Notification)  → notifications_rounded
```

> 아이콘은 `brand-assets §4.2` 매핑표 준수. Material Symbols Rounded 사용.

### 2.2. 화면 목록

| 화면 | Route | Phase | 설명 |
|------|-------|-------|------|
| 스플래시 | `/splash` | 1.0 | 앱 아이콘 + 브랜드 로고 페이드인 |
| 온보딩 | `/onboarding` | 1.0 | 3단계 소개 (PageView) |
| 홈 | `/home` | 1.0 | 대시보드: 재고 요약 + 유통기한 임박 + 빠른 레시피 |
| 재고 목록 | `/stock` | 1.0 | 전체 재고 리스트 + 필터/정렬 |
| 재고 추가/수정 | `/stock/edit` | 1.0 | form_builder 기반 입력 폼 |
| 레시피 추천 | `/recipe` | 1.1 | 재료 선택 → AI 추천 결과 |
| 레시피 상세 | `/recipe/:id` | 1.1 | 7단계 조리 가이드 + 타이머 |
| 카메라 OCR | `/camera` | 1.2 | 영수증 촬영 → 재료 자동 입력 |
| 음성 입력 | `/voice` | 1.3 | 음성 → 재료 변환 |
| 칼럼 목록 | `/column` | 2.6 | Weekly Column 피드 |
| 칼럼 상세 | `/column/:id` | 2.6 | 칼럼 본문 읽기 |
| 설정 | `/settings` | 1.0 | 테마, 언어, 알림 설정 |

---

## 3. 테마 시스템 구현

### 3.1. 파일 구조

```
app/lib/theme/
├── app_theme.dart          # ThemeData 생성 (Light/Dark)
├── app_colors.dart         # Semantic Colors (brand-assets §2.3)
├── app_typography.dart     # Type Scale (brand-assets §3.3)
├── app_spacing.dart        # 8pt Grid (design_system §4)
└── app_shadows.dart        # Elevation 토큰
```

### 3.2. FlexColorScheme 설정

```dart
// app_theme.dart
// Light: FlexScheme.green 기반, seedColor #4CAF50
// Dark: FlexScheme.green 기반, seedColor #81C784
// fontFamily: 'Pretendard'
// useMaterial3: true
```

> 모든 색상값은 `brand-assets §2`에서 가져옴. 하드코딩 금지.

### 3.3. Semantic Color Extension

```dart
// app_colors.dart — brand-assets §2.3 연동
// freshGreen, warningAmber, dangerRed → ThemeExtension으로 구현
// Recipe Type Badge 색상 → brand-assets §2.4 매핑
```

---

## 4. 핵심 위젯 컴포넌트

### 4.1. 재고 관련

| 위젯 | 파일 | 설명 | 참조 |
|------|------|------|------|
| `IngredientCard` | `lib/widgets/stock/ingredient_card.dart` | 재료 카드: 이모지 + 이름 + 수량 + 유통기한 색상 | `design_system §6.1` |
| `StockListTile` | `lib/widgets/stock/stock_list_tile.dart` | 리스트 모드 재고 항목 | — |
| `CategoryChip` | `lib/widgets/stock/category_chip.dart` | 카테고리 필터 칩 (이모지 포함) | `brand-assets §4.4` |
| `ExpiryBadge` | `lib/widgets/stock/expiry_badge.dart` | 유통기한 상태 뱃지 (fresh/warning/danger) | `brand-assets §2.3` |
| `StockEmptyState` | `lib/widgets/stock/stock_empty_state.dart` | 빈 냉장고 Lottie + 안내 | `brand-assets §5.2` |

### 4.2. 레시피 관련

| 위젯 | 파일 | 설명 | 참조 |
|------|------|------|------|
| `RecipeCard` | `lib/widgets/recipe/recipe_card.dart` | 레시피 카드: 썸네일 + 타입뱃지 + 시간/난이도 | `design_system §6.2` |
| `RecipeTypeBadge` | `lib/widgets/recipe/recipe_type_badge.dart` | recipe_type 색상 코딩 뱃지 | `brand-assets §2.4` |
| `CookingStepItem` | `lib/widgets/recipe/cooking_step_item.dart` | 조리 단계: 번호 + phase + 설명 + 타이머 | `design_system §6.3` |
| `FlavorRadar` | `lib/widgets/recipe/flavor_radar.dart` | 맛 프로필 레이더 차트 (5축) | — |
| `IngredientCheckList` | `lib/widgets/recipe/ingredient_check_list.dart` | 재료 체크리스트 (보유/미보유 표시) | — |
| `RecipeLoadingState` | `lib/widgets/recipe/recipe_loading_state.dart` | AI 생성 대기 Lottie | `brand-assets §5.2` |

### 4.3. 칼럼 관련

| 위젯 | 파일 | 설명 |
|------|------|------|
| `ColumnCard` | `lib/widgets/column/column_card.dart` | 칼럼 카드: 이모지 썸네일 + 제목 + 요약 |
| `ColumnBody` | `lib/widgets/column/column_body.dart` | 칼럼 본문 렌더링 (마크다운 or 구조화) |
| `SourceChip` | `lib/widgets/column/source_chip.dart` | 출처 표시 칩 (탭 시 링크) |

### 4.4. 공용 위젯

| 위젯 | 파일 | 설명 |
|------|------|------|
| `WhipUpAppBar` | `lib/widgets/common/whipup_app_bar.dart` | 통일된 앱바 |
| `WhipUpBottomNav` | `lib/widgets/common/whipup_bottom_nav.dart` | 바텀 네비게이션 (4탭) |
| `WhipUpButton` | `lib/widgets/common/whipup_button.dart` | Primary/Secondary/Text 버튼 |
| `WhipUpSearchBar` | `lib/widgets/common/whipup_search_bar.dart` | 검색 입력 바 |
| `ErrorStateWidget` | `lib/widgets/common/error_state_widget.dart` | 에러 상태 + 재시도 |
| `LoadingOverlay` | `lib/widgets/common/loading_overlay.dart` | 전체 화면 로딩 |

---

## 5. 인터랙션 & 애니메이션

### 5.1. 햅틱 피드백 (design_system §5.2 준수)

| 시나리오 | 타입 | 트리거 |
|----------|------|--------|
| 재료 추가 성공 | `lightImpact` | StockItem 저장 완료 콜백 |
| 레시피 생성 완료 | `mediumImpact` | AI 응답 수신 |
| 즐겨찾기 토글 | `lightImpact` | 하트 아이콘 탭 |
| 삭제 확인 | `heavyImpact` | 스와이프 삭제 실행 |
| 에러 발생 | `heavyImpact` | 네트워크/파싱 에러 |

### 5.2. Lottie 애니메이션 (brand-assets §6.2 준수)

- 30fps, 100KB 이하, Brand Palette 색상만 사용
- 로딩: 무한 반복 / 성공: 1회 재생
- 파일 경로: `app/assets/lottie/`

### 5.3. 페이지 전환 (brand-assets §6.1 준수)

- go_router의 `CustomTransitionPage` 활용
- 기본 전환: `normal` (300ms, easeInOutCubic)
- 모달/바텀시트: `normal` (300ms)
- 탭 전환: `fast` (200ms, easeInOut) 크로스페이드

---

## 6. 반응형 & 접근성

### 6.1. 반응형 브레이크포인트

| 카테고리 | 너비 | 레이아웃 |
|---------|------|----------|
| 소형 폰 | < 360dp | 1열 리스트, 축소 카드 |
| 일반 폰 | 360~414dp | 기본 레이아웃 (디자인 기준) |
| 대형 폰 | 414~600dp | 2열 그리드 (레시피 카드) |
| 태블릿 | > 600dp | Phase 2+ 대응 예정 |

### 6.2. 접근성

- 모든 아이콘/이미지에 `semanticLabel` 필수
- 색상만으로 정보 전달 금지 (아이콘/텍스트 병행)
- 최소 터치 영역 48x48dp 준수
- 다국어: slang 패키지 활용, 한국어 우선

---

## 7. 폴더 구조

```
app/lib/
├── views/                     # 화면 단위 (Artisan 전용)
│   ├── splash/
│   │   └── splash_screen.dart
│   ├── onboarding/
│   │   └── onboarding_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── stock/
│   │   ├── stock_list_screen.dart
│   │   └── stock_edit_screen.dart
│   ├── recipe/
│   │   ├── recipe_screen.dart
│   │   └── recipe_detail_screen.dart
│   ├── column/
│   │   ├── column_list_screen.dart
│   │   └── column_detail_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── widgets/                   # 재사용 위젯 (Artisan 전용)
│   ├── common/
│   ├── stock/
│   ├── recipe/
│   └── column/
├── theme/                     # 테마 시스템 (Artisan 전용)
│   ├── app_theme.dart
│   ├── app_colors.dart
│   ├── app_typography.dart
│   ├── app_spacing.dart
│   └── app_shadows.dart
└── router/                    # go_router 설정
    └── app_router.dart
```

---

## 8. 타 에이전트와의 계약

### Architect에게 의존

- Provider가 반환하는 `AsyncValue<T>`를 `ref.watch()`로 소비
- `when(data:, loading:, error:)` 패턴으로 3가지 상태 모두 처리
- Freezed 모델의 필드명을 UI 바인딩에 직접 사용

### Bridge와의 관계

- 직접 의존 없음 (Architect Provider를 통해 간접 소비)
- Bridge가 제공하는 로딩/에러 상태는 Provider의 `AsyncValue`로 전달됨

### Brand-Assets 참조

- 색상: `brand-assets §2` (Core, Semantic, Badge)
- 폰트: `brand-assets §3` (Pretendard, Type Scale)
- 아이콘: `brand-assets §4` (Material Symbols Rounded, 이모지)
- 애니메이션: `brand-assets §6` (속도 토큰, Lottie 사양)

---

## 9. Verification Checklist

매 PR 생성 전 자가 검증:

- [ ] 위젯이 모두 StatelessWidget 또는 ConsumerWidget
- [ ] 비즈니스 로직이 위젯 내부에 없음 (Provider 위임)
- [ ] 색상 하드코딩 없음 (Theme/Extension 참조)
- [ ] 폰트 직접 지정 없음 (TextTheme 활용)
- [ ] 터치 영역 48dp 이상, 텍스트 14sp 이상
- [ ] Lottie/햅틱 피드백이 design_system 및 brand-assets 규격 준수
- [ ] `lib/models`, `lib/repositories`, `lib/providers`, `lib/services` 수정 없음
- [ ] 아이콘이 `brand-assets §4.2` 매핑표와 일치
- [ ] 빈 상태/로딩/에러 상태 모두 처리
