# Design System: Visual Standard

> **참조 에이전트:** Artisan (정본)
> Artisan 에이전트가 참조할 시각적 표준과 인터랙션 규칙.
> 색상 Hex, 폰트 규격, 아이콘 매핑 등 시각 디테일의 정본은 `brand-assets/README.md`이다.

---

## 0. Creed

에이전트는 모든 UI Component를 설계할 때 아래의 신조를 준수해야 한다.
특히 **'데이터는 보이지 않게, 즐거움은 눈에 띄게'** 원칙에 따라, 복잡한 설정창보다는 직관적인 제스처를 우선 순위에 둬야 한다.

1. **데이터는 보이지 않게, 즐거움은 눈에 띄게** — 복잡한 계산, AI 분석 과정 등은 조용히 처리하고 유저는 직관적인 카드와 눈을 즐겁게 하는 애니메이션만 볼 수 있도록 설계.
2. **레시피는 정답이 아니라, 영감을 위한 악보일 뿐** — 재료의 대체 가능성이나 변주를 제안하여 유저의 창의성을 자극하는 방향으로 설계. 하지만 너무 근본없는 레시피는 화성학을 고려하지 않은 악보와도 같으니 주의할 것.
3. **가벼운 인터랙션을 지향** — 복잡한 탭이나 텍스트 입력 대신 던지기, 자석처럼 붙이기 등 최소한의 힘과 인지 부하가 드는 인터랙션을 구현.
4. **모든 기능은 주방의 동선을 닮도록** — 준비된 재료의 배치(미장플라스)부터 완성까지 앱의 화면 흐름이 실제 요리사의 움직임 및 요리 순서와 일치하도록 설계.
5. **주방의 소음 속에서도 명확한 전달이 되도록** — 주방의 어수선한 환경을 가정하고 폰트 크기, 고대비 UI, 햅틱, 사운드 알림 등 다각적인 피드백을 통해 유저가 정보를 놓치지 않도록 설계.

---

## 1. Brand Theme

### 1.1. Colors

| Token | 값 | 용도 |
|-------|-----|------|
| **Flame Orange** | `#F04E23` | Primary — CTA 버튼, FAB, 앱 바, 핵심 액센트 |
| **Warm Amber** | `#FFC107` | Secondary — 포인트 강조, 뱃지, 보조 액션 |
| **Clean Off-White** | `#FFF8F0` | Background — 스캐폴드 배경, 전체 기조 |

> 전체 Color Palette (Core, Semantic, Badge별 Light/Dark Hex)는 `brand-assets §2` 참조.
> 하드코딩 금지 — 반드시 `Theme.of(context)` 또는 FlexColorScheme 시멘틱 컬러 사용.

### 1.2. Typography

#### 1.2.1. 서체 기본

| 속성 | 값 |
|------|-----|
| **Primary Font** | Pretendard (한국어+라틴) |
| **Fallback** | Apple SD Gothic Neo (iOS), Roboto (Android) |
| **라이선스** | OFL 1.1 (오픈 소스, 상업 사용 가능) |
| **파일** | `app/assets/fonts/Pretendard-*.otf` |

**사용하는 Weight:**

| Weight | 값 | 역할 |
|--------|-----|------|
| **Black** | `900` | 브랜드 앵커 — 홈 화면 "WhipUp" 로고 타이틀에만 사용 |
| **Bold** | `700` | 시선을 끄는 핵심 정보 — 단계 번호, 타이머, 히어로 제목 |
| **SemiBold** | `600` | 구조를 잡는 뼈대 — 섹션 헤더, 카드 제목, CTA 버튼 |
| **Medium** | `500` | 조용한 안내자 — 폼 라벨, 네비게이션, 태그, 뱃지 |
| **Regular** | `400` | 편안한 읽기 — 본문, 조리 설명, 재료 목록 |
| **Light** | `300` | 숨은 보조 — 힌트, 플레이스홀더, 비활성 텍스트 |

#### 1.2.2. Type Scale

> **설계 원리:** 주방에서 폰을 손에 들고 보는 **탐색 모드**(~30cm)와
> 조리대 위에 세워두고 요리하는 **조리 모드**(~80cm)를 모두 만족시켜야 한다.
> Display 계열은 조리 모드에서 1m 거리에서도 읽히는 크기로 설정한다.

| Style | Size | Weight | Height | Spacing | 용도 |
|-------|------|--------|--------|---------|------|
| `displayLarge` | 40sp | Bold | 1.15 | -0.5 | 조리 단계 번호 — 1m 거리 가독성 |
| `displayMedium` | 32sp | Bold | 1.15 | -0.25 | 타이머 카운트다운, 히어로 숫자 |
| `displaySmall` | 26sp | SemiBold | 1.2 | 0 | 리워드 숫자, 연속 기록 |
| `headlineLarge` | 24sp | Bold | 1.25 | -0.25 | 레시피 상세 제목 (히어로) |
| `headlineMedium` | 22sp | SemiBold | 1.25 | 0 | 온보딩 제목, 모달 제목 |
| `headlineSmall` | 20sp | SemiBold | 1.3 | 0 | 바텀시트 제목, 칼럼 제목 |
| `titleLarge` | 22sp | Black | 1.25 | -0.25 | **홈 화면 전용** — "WhipUp" 브랜드 앵커 |
| `titleLarge` (일반) | 20sp | SemiBold | 1.3 | 0 | 홈 이외 AppBar 화면 제목 |
| `titleMedium` | 17sp | SemiBold | 1.3 | 0.1 | 섹션 헤더, 카드 제목 |
| `titleSmall` | 15sp | Medium | 1.3 | 0.1 | 폼 라벨, 서브 헤더, Phase 라벨 |
| `bodyLarge` | 16sp | Regular | 1.5 | 0.25 | 조리 설명, 칼럼 본문 (주 읽기용) |
| `bodyMedium` | 14sp | Regular | 1.5 | 0.25 | 재료 목록, 일반 본문, 보조 설명 |
| `bodySmall` | 12sp | Regular | 1.4 | 0.4 | 타임스탬프, 출처, 부가 정보 |
| `labelLarge` | 14sp | SemiBold | 1.2 | 0.1 | 버튼 텍스트, CTA |
| `labelMedium` | 12sp | Medium | 1.2 | 0.5 | 바텀 네비 라벨, 탭 텍스트 |
| `labelSmall` | 11sp | Medium | 1.1 | 0.5 | 태그, 뱃지, recipe_type |

#### 1.2.3. 자주 쓰는 스타일 vs 가끔 쓰는 스타일

화면을 만들 때 아래 **8가지 Primary 스타일**로 90% 이상을 커버한다.
나머지는 특수 상황에서만 꺼내 쓴다.

**Primary (일상적으로 사용):**

| 스타일 | 한줄 요약 |
|--------|----------|
| `titleLarge` | 홈: 22sp Black 브랜드 앵커 / 나머지: 20sp SemiBold |
| `titleMedium` | 카드 제목, 섹션 헤더 |
| `bodyLarge` | 사용자가 '읽어야 하는' 핵심 본문 |
| `bodyMedium` | 사용자가 '훑어보는' 보조 정보 |
| `labelLarge` | 버튼 위의 텍스트 |
| `labelSmall` | 뱃지, 태그 |
| `displayLarge` | 조리 단계 번호 (조리 모드 전용) |
| `displayMedium` | 타이머 표시 (조리 모드 전용) |

**Supporting (특수 상황에서 사용):**

| 스타일 | 언제 쓰는가 |
|--------|-----------|
| `displaySmall` | 리워드 화면의 연속 기록 숫자, 통계 숫자 |
| `headlineLarge` | 레시피 상세 화면의 레시피명 (한 화면에 하나) |
| `headlineMedium` | 온보딩 각 페이지의 대제목 |
| `headlineSmall` | 바텀시트/다이얼로그 제목, 칼럼 상세 제목 |
| `titleSmall` | 폼 라벨, CookingPhase 라벨, 서브 헤더 |
| `bodySmall` | 타임스탬프, 등록일, 출처 텍스트, 칼럼 읽기 시간 |
| `labelMedium` | 바텀 네비게이션 라벨, 탭 바 텍스트 |

#### 1.2.4. 화면별 타이포그래피 매핑

> **규칙:** 같은 역할의 텍스트는 어떤 화면에서든 같은 스타일을 쓴다.
> 아래 매핑을 벗어나는 예외를 만들지 않는다.

**홈 화면 (`/home`)**

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` **(22sp Black)** | "WhipUp" ← 홈 화면만 예외 |
| 대시보드 카드 제목 | `titleMedium` | "우리집 냉장고 현황" |
| 대시보드 보유 숫자 | `displaySmall` | "24" |
| 대시보드 위치별 수량 | `bodySmall` | "🧊12 ❄️5 📦4 🧂3" |
| 대시보드 임박 경고 | `bodyMedium` | "유통기한 임박 3개" |
| 섹션 헤더 | `titleMedium` | "빠른 레시피 추천", "콘텐츠" |
| 레시피 슬라이더 제목 | `titleSmall` | "소고기 배추 전골" |
| 레시피 슬라이더 메타 | `bodySmall` | "30분 · 보통" |
| 콘텐츠 카드 제목 | `titleSmall` | "당근은 왜 기름과?" |
| 콘텐츠 카드 요약 | `bodySmall` | "지용성 비타민의 비밀" |

**재고 목록 (`/stock`)**

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "냉장고" |
| 카테고리 필터 칩 | `labelLarge` | "🥬 채소" |
| 정렬 드롭다운 | `bodyMedium` | "유통기한순" |
| IngredientCard 재료명 | `titleSmall` | "소고기" |
| IngredientCard 수량 | `bodyMedium` | "300g" |
| IngredientCard 유통기한 | `labelSmall` | "D-2" |
| 빈 상태 메시지 | `bodyLarge` | "냉장고가 텅 비었어요" |
| 빈 상태 버튼 | `labelLarge` | "재료 추가하기" |

**재고 추가/수정 (`/stock/add`, `/stock/edit/:id`)**

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "재료 추가" |
| 폼 라벨 | `titleSmall` | "재료명 *" |
| 입력 텍스트 | `bodyLarge` | 사용자 입력값 |
| 힌트 텍스트 | `bodyMedium` + Light | "예: 양파" |
| 드롭다운 선택값 | `bodyMedium` | "🥬 채소" |
| 유효성 에러 | `bodySmall` + error 색상 | "필수 항목입니다" |
| 저장 버튼 | `labelLarge` | "저장하기" |

**레시피 추천 (`/recipe`)**

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "레시피" |
| 섹션 헤더 | `titleMedium` | "재료 선택" |
| 카테고리 라벨 | `bodySmall` + SemiBold | "🥬 채소" |
| 재료 칩 (선택됨) | `bodySmall` + Medium | "배추 500g" (primary 배경) |
| 재료 칩 (해제됨) | `bodySmall` + Medium | "배추 500g" (surfaceVariant 배경) |
| 모두 선택/해제 | `labelSmall` | "모두 선택", "모두 해제" |
| 옵션 라벨 | `titleSmall` | "recipe_type" |
| 옵션 드롭다운 | `bodyMedium` | "전체" |
| CTA 버튼 | `labelLarge` | "레시피 추천 받기" |
| 로딩 메시지 | `bodyLarge` | "맛있는 레시피를 찾고 있어요" |
| RecipeCard 제목 | `titleMedium` | "소고기 배추 전골" |
| RecipeCard 보조 | `bodySmall` | "30분 · 보통 · 2인분" |
| RecipeTypeBadge | `labelSmall` | "SOUP" |

**레시피 상세 (`/recipe/:id`) — 조리 모드 진입점**

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "소고기 배추 전골" |
| 히어로 레시피명 | `headlineLarge` | "소고기 배추 전골" |
| RecipeTypeBadge | `labelSmall` | "SOUP" |
| 메타 정보 | `bodyMedium` | "30분 · 보통 · 2인분" |
| 섹션 헤더 | `titleMedium` | "맛 프로필", "재료", "조리 순서" |
| FlavorRadar 라벨 | `labelSmall` | "감칠맛", "단맛" |
| 재료 이름 | `bodyMedium` | "소고기 300g" |
| **단계 번호** | **`displayLarge`** | **"1"** |
| Phase 라벨 | `titleSmall` + primary | "prep 재료 손질" |
| 단계 설명 | `bodyLarge` | "배추를 한 잎씩 떼어 흐르는..." |
| 단계 팁 (The Kick) | `bodyMedium` + Call-out Box | "배추는 심지부터 떼면 깔끔해요" |
| 타이머 | `displayMedium` | "05:00" |
| science_note | `bodyMedium` + Call-out Box | "마이야르 반응이..." |

**칼럼 목록 (`/column`)**

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "칼럼" |
| 카테고리 필터 칩 | `labelLarge` | "과학" |
| ColumnCard 이모지 | 시스템 이모지 28sp | "🥕" |
| ColumnCard 제목 | `titleMedium` | "당근의 재발견" |
| ColumnCard 부제+시간 | `bodySmall` | "지용성 비타민의 비밀 · 3분" |
| 카테고리 뱃지 | `labelSmall` | "SCIENCE" |

**칼럼 상세 (`/column/:id`)**

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "칼럼" |
| 칼럼 제목 | `headlineSmall` | "당근의 재발견: 왜 기름과 함께..." |
| 칼럼 부제 | `titleSmall` + onSurface 60% | "지용성 비타민의 비밀" |
| 본문 | `bodyLarge` | 칼럼 본문 텍스트 |
| 출처 칩 | `bodySmall` | "K. Miglio et al., 2008" |
| 태그 | `labelSmall` | "당근", "베타카로틴" |

**리워드 (`/reward`)**

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "나의 기록" |
| 연속 기록 숫자 | `displaySmall` | "7" |
| 연속 기록 라벨 | `bodyMedium` | "일 연속 요리!" |
| 통계 숫자 | `displaySmall` | "12" |
| 통계 라벨 | `bodySmall` | "총 요리" |
| 업적 이름 | `titleSmall` | "첫 요리사" |
| 업적 설명 | `bodySmall` | "레시피 완료 1회" |

**설정 (`/settings`)**

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "설정" |
| 섹션 헤더 | `titleMedium` | "테마" |
| 옵션 라벨 | `bodyLarge` | "유통기한 알림" |
| 옵션 보조 설명 | `bodySmall` | "알림 기준일" |
| 버전 정보 | `bodySmall` | "버전 1.0.0" |

**온보딩 (`/onboarding`)**

| 요소 | 스타일 | 예시 |
|------|--------|------|
| 이모지 일러스트 | 80sp | 🧊→📦→🧂 순환 애니메이션 (2.5초 간격) |
| 대제목 | `headlineMedium` | "냉장고 속 재료로 근사한 한 끼" |
| 설명 | `bodyLarge` | "재료를 등록하면 AI가..." |
| 건너뛰기 | `labelLarge` + onSurface 60% | "건너뛰기" → 기본 구성 + 토스트 → 홈 |
| 다음/시작 버튼 | `labelLarge` | "시작하기" → 재고함 설정 화면 |
| 페이지 인디케이터 | — (도트, 텍스트 없음) | |

**재고함 설정 (`/storage-setup`)**

| 요소 | 스타일 | 예시 |
|------|--------|------|
| AppBar 제목 | `titleLarge` (20sp SemiBold) | "재고함 설정" |
| 안내 메시지 | `bodyLarge` | "사용하는 재고함을 추가해 주세요." |
| 보조 메시지 | `bodyMedium` + onSurface 60% | "나중에 설정에서 변경할 수 있어요." |
| 재고함 이름 | `bodyLarge` + SemiBold | "냉장고", "냉동고" |
| 재고함 설명 | `bodySmall` | "냉장 보관 식재료" |
| 카운터 숫자 | `titleMedium` + primary | "1" |
| 완료 버튼 | `labelLarge` | "완료" |

#### 1.2.5. 조리 모드 특별 규칙

> Creed §5 "주방의 소음 속에서도 명확한 전달" 원칙의 구체적 구현.

조리 단계 화면(`/recipe/:id`)에서 사용자가 Step-by-Step 가이드에 진입하면, 텍스트 크기를 일반 탐색 모드보다 한 단계 올려 **조리 모드**로 전환한다.

| 요소 | 탐색 모드 | 조리 모드 | 이유 |
|------|----------|----------|------|
| 단계 번호 | `displayLarge` (40sp) | 동일 | 이미 최대 크기 |
| 타이머 | `displayMedium` (32sp) | 동일 | 이미 원거리 가독 |
| Phase 라벨 | `titleSmall` (15sp) | `titleMedium` (17sp) | 현재 단계 명칭 강조 |
| 단계 설명 | `bodyLarge` (16sp) | `titleSmall` (15sp→17sp 비율 유지) | 원거리 가독성 확보 |
| 이전/다음 버튼 | `labelLarge` (14sp) | `titleSmall` (15sp) + 56dp 영역 | 젖은 손 대응 |

- 조리 모드 전환은 Step-by-Step 뷰 진입 시 자동.
- Landscape에서는 조리 모드가 기본.

#### 1.2.6. 통일 규칙 및 금지 사항

**반드시 지킬 것:**
1. **같은 역할 = 같은 스타일:** "섹션 헤더"는 어떤 화면에서든 `titleMedium`.
2. **TextTheme 경유 필수:** `Text('...', style: Theme.of(context).textTheme.titleMedium)`.
3. **최소 11sp:** 뱃지/태그의 `labelSmall`(11sp)이 가장 작은 텍스트.
4. **Weight 5종만 사용:** Bold, SemiBold, Medium, Regular, Light 외 다른 Weight 금지.
5. **색상 오버라이드 시 Theme 기반:** `style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)`.

**금지 사항:**
- `fontSize: 16` 같은 하드코딩 (반드시 TextTheme의 스타일명으로 참조)
- 10sp 미만 텍스트 사용 (주방 가독성 최저 기준 위반)
- 이탤릭체 (한국어에 부적합)
- `fontWeight: FontWeight.w800` (ExtraBold는 사용하지 않음)
- `FontWeight.w900`(Black)은 홈 화면 "WhipUp" 타이틀 전용 — 다른 화면에 사용 금지
- 한 화면에 6개 이상의 서로 다른 스타일 사용 (시각 혼란 — Primary 8종 내에서 해결)
- 한 카드 안에 3개 이상의 서로 다른 Weight 사용 (계층이 흐려짐)

### 1.3. Iconography

- **아이콘 셋:** Material Symbols Rounded
- **보조:** 식재료 카테고리별 이모지 — **Twemoji (Twitter Emoji)** SVG 렌더링
- **이모지 일관성:** 시스템 이모지 대신 Twemoji를 사용하여 iOS/Android/Web 간 동일한 형태를 보장. 플랫폼별 이모지 디자인 차이를 방지.
- **Flutter 적용:** `flutter_twemoji` 패키지 또는 Twemoji SVG 에셋 번들 (`app/assets/emoji/`)
- **커스텀 전환 대비:** 이모지 렌더링을 `EmojiWidget` 단일 컴포넌트로 추상화. 정식 출시 시 커스텀 에셋으로 교체할 때 경로만 변경하면 전환 가능하도록 설계.

> 아이콘 매핑표, 이모지 매핑, 크기 규격은 `brand-assets §4` 참조.

---

## 2. Interaction Rules

### 2.1. Input Strategy

- 텍스트 입력 최소화 — **'필터형 칩'** 중심의 선택형 인터랙션 지향.
- 카테고리, recipe_type, 난이도 등은 모두 칩/드롭다운으로 선택.
- 재료명만 텍스트 입력 허용 (자동완성 지원).

### 2.2. Haptic & Animation

| 시나리오 | 햅틱 | 비고 |
|----------|------|------|
| 재료 추가 성공 | `lightImpact` | 칩 선택/해제에도 적용 |
| 레시피 생성 완료 | `mediumImpact` | Lottie 보상 애니메이션 동반 |
| 즐겨찾기 토글 | `lightImpact` | |
| 스와이프 삭제 | `heavyImpact` | |
| 타이머 완료 | `heavyImpact` | 커스텀 사운드 동반 |
| 에러 발생 | `heavyImpact` | |

- Lottie 기반 보상 애니메이션 및 햅틱 피드백 **필수 적용**.
- Lottie 사양: 30fps, 100KB 이하, Brand Palette 색상만.

### 2.3. Magnetic Snapping

- 카드를 컨테이너로 이동 시 **자석처럼 붙는 효과** 적용.
- 재료 카드 → 레시피 재료 슬롯으로 드래그 시, 근접하면 스냅 애니메이션 발동.
- 스냅 시 `lightImpact` 햅틱.

### 2.4. Visual Cues

| 상태 | 이펙트 | 적용 대상 |
|------|--------|----------|
| 유통기한 임박 (3일 이내) | **Burning 효과** — 카드 테두리에 미세한 불꽃/글로우 | IngredientCard |
| 유통기한 초과 | dangerRed 배경 + Burning 강화 | IngredientCard |
| 신규 입고 재료 (24h 이내) | **테두리 강조** — primary 색상 펄스 애니메이션 | IngredientCard |
| AI 레시피 생성 중 | cooking Lottie 로딩 | RecipeScreen |

---

## 3. States UI

### 3.1. Empty State

- **비주얼:** '텅 빈 냉장고' 일러스트 (`empty_fridge` Lottie)
- **메시지:** 따뜻한 톤 ("냉장고가 텅 비었어요. 장 보고 온 영수증을 찍어볼까요?")
- **액션 버튼:** 영수증 스캔(Phase 1.2), 직접 추가(Phase 1.0) 강조.
- **금지:** "재고가 없습니다" 같은 기계적 문구 사용 금지.

### 3.2. Loading State

- 프로젝트 테마를 반영한 **스켈레톤 UI** 적용.
- AI 레시피 생성은 cooking Lottie 애니메이션 (무한 반복).
- 스켈레톤 색상: `surfaceVariant` 기반 shimmer 효과.

### 3.3. Error State

- **비주얼:** 'oops_spill' Lottie (무언가 엎질러진 이미지)
- **메시지:** 따뜻한 톤 ("앗, 뭔가 엎질렀어요. 다시 시도해 볼까요?")
- **액션:** [다시 시도] 버튼, 필요시 [오프라인 모드] 안내.

---

## 4. Context-Aware Interaction

### 4.1. Hands-Free Accessibility

- 요리 중에는 화면 터치가 어려움.
- 모든 조리 가이드 단계에는 음성 명령(다음, 이전) 외에도 시각적으로 멀리서도 잘 보이는 **'High-Contrast Step-Indicator'** 를 적용.
- Step-Indicator: 현재 단계를 크고 굵은 숫자(`displayLarge`)로 표시, 완료 단계는 primary 색상으로 채움.

### 4.2. Touch-Target Optimization

- 모든 버튼과 인터랙션 영역은 젖은 손이나 장갑 낀 손으로도 조작하기 쉽도록 **최소 48x48dp** 이상의 터치 영역을 확보.
- 조리 가이드 화면에서는 [이전]/[다음] 버튼을 더 크게 확대 (최소 56x56dp).

### 4.3. Screen Awake Policy

- 조리 가이드(Step-by-Step) 화면 진입 시, 사용자의 별도 설정 없이도 시스템 화면 꺼짐을 자동으로 방지 (**Wakelock**).
- 조리 가이드 화면에서 벗어나면 Wakelock 자동 해제.
- `wakelock` Flutter 패키지 활용.

---

## 5. Visual Hierarchy & Information Architecture

### 5.1. Dynamic Font Scaling

- 조리 단계 화면에서는 **텍스트보다 이미지를 강조**하되, 가독성이 필요한 텍스트 정보(분량, 시간)는 이미지 위에 오버레이 하지 않고 **독립적인 영역**을 확보.
- 분량/시간 정보: `displayMedium` (32sp, Bold) — 한눈에 파악 가능한 크기.
- 조리 설명: `bodyLarge` (16sp, Regular) — 충분한 가독성.

### 5.2. Grid-based Vatting View

- 조리 전 '손질(Prep)' 단계에서는 필요한 재료가 한눈에 들어오도록 **'Grid-based Vatting View'** 를 제공.
- 2~3열 그리드, 각 셀에 재료 이모지 + 이름 + 분량.
- 보유 재료: 체크 표시 + 원래 색상 / 미보유 재료: 흐리게 + "대체 가능" 힌트.

### 5.3. The Kick (Highlight)

- 조리 원리 설명(science_note, tip)은 일반 텍스트와 명확히 구분되는 **'Call-out Box'** 로 표현.
- Call-out Box 스타일: `info` 색상 배경 + 좌측 4dp 보더 + 전구 아이콘 (`lightbulb_rounded`).
- 사용자가 놓치지 않게 시각적 포인트를 주되, 본문 흐름을 끊지 않는 인라인 카드 형태.

---

## 6. Micro-Interactions for Motivation

### 6.1. Progressive Rewards

- 조리 단계를 완료할 때마다 상단 진행 바에 미세한 **불꽃 애니메이션**이나 색상 변화를 주어 성취감을 고취.
- 진행 바: Hermes Orange 그라데이션, 단계 완료 시 `fast` (200ms) 스케일 펄스.
- 전체 완료 시: `success` Lottie + `mediumImpact` 햅틱.

### 6.2. Ingredient Vanishing Effect

- 재료 소진 제스처(화면 밖으로 던지기) 시, 단순 삭제가 아니라 **'먼지가 되어 사라지는(Dust Effect)'** 애니메이션을 적용하여 '해치웠다'는 쾌감을 극대화.
- Dust Effect: 카드가 파티클로 분해되며 사라짐 (300ms, easeInOutCubic).
- 던지기 제스처: 위 또는 좌우로 빠른 스와이프 → 속도 임계값 초과 시 Dust Effect 발동.
- 되돌리기: Snackbar 5초 (Undo).

### 6.2.5. Step Media (조리 단계 미디어)

- 각 조리 단계 텍스트 아래에 해당 단계를 시각적으로 보여주는 **미디어 영역**을 배치.
- 미디어 타입: YouTube 임베드 클립 (16:9 비율) 또는 이미지 (3:2 비율).
- 미디어 컨테이너: `border-radius: 12dp`, 화면 너비 - 좌우 `md` * 2 - step-num 영역.
- 영상 클립: 자동 재생 금지, 음소거 기본, 탭하면 재생. 조리 모드에서는 전체 화면 재생 지원.
- 이미지: 해당 단계의 완성 상태 또는 핵심 동작을 보여주는 사진.
- 미디어가 없는 단계는 영역을 표시하지 않음 (조건부 렌더링).
- 데이터 모델: `RecipeStep`에 `mediaUrl: String?` 및 `mediaType: image | video` 필드 추가 → `product_map.md §2.1` 연동.

### 6.3. Sound Identity

- 중요한 알림(타이머 완료, 유통기한 경보) 시에는 브랜드 테마와 어울리는 **경쾌하고 따뜻한 톤의 커스텀 사운드** 를 사용.
- 사운드 파일: `app/assets/sounds/` 에 배치.
- 볼륨: 시스템 알림 볼륨에 연동.

| 이벤트 | 사운드 특성 | 파일 |
|--------|-----------|------|
| 타이머 완료 | 맑은 벨 소리, 따뜻한 톤 | `timer_done.wav` |
| 레시피 완성 | 경쾌한 성공 효과음 | `recipe_complete.wav` |
| 유통기한 경보 | 부드러운 경고음 | `expiry_alert.wav` |

---

## 7. Responsive & Layout Rules

### 7.1. Breakpoints

| 카테고리 | 너비 | 레이아웃 |
|---------|------|----------|
| 소형 폰 | < 360dp | 1열 리스트, 축소 카드 |
| 일반 폰 | 360~414dp | **기본 디자인 기준** (Portrait) |
| 대형 폰 | 414~600dp | 레시피 카드 2열 그리드 |
| 태블릿 | > 600dp | 2패널 레이아웃 (목록 + 상세) |

### 7.2. Landscape Optimization

- 주방에서 태블릿을 가로로 거치하고 요리하는 사용자를 위해, 모든 조리 가이드는 **가로 모드(Landscape) 전용 레이아웃**을 반드시 포함.
- Landscape 레이아웃: 좌측에 재료 목록/Vatting View, 우측에 현재 조리 단계.
- Step-Indicator는 가로 모드에서도 대형 폰트로 표시.

### 7.3. Midnight Kitchen Mode

- 밤늦은 시간 야식을 만들거나 어두운 조명 아래에서 요리하는 사용자를 위해, 눈의 피로를 낮추는 **'Midnight Kitchen Mode'** 를 지원.
- 일반 Dark Mode보다 더 낮은 명도 + 따뜻한 색온도(blue light 감소).
- 테마 설정: 시스템 / 라이트 / 다크 / **Midnight Kitchen** 4종.
- Midnight Kitchen 전용 색상은 `brand-assets §2` 에서 정의.

### 7.4. Spacing & Grid

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

---

## 8. Common UI Atoms

### 8.0. Recipe Dual-Select

- 레시피 추천 결과에서 최대 **2개의 레시피를 동시 선택**하여 비교할 수 있다.
- 선택 시 RecipeCard 좌측에 체크박스 표시, 선택된 카드는 `primaryContainer` 배경.
- 2개 선택 시 하단에 **"선택한 2개 동시에 보기"** CTA 버튼이 슬라이드업으로 나타남.
- 비교 화면: 2개 레시피를 좌우 또는 상하로 나란히 표시 (재료 겹침 하이라이트).

### 8.1. Ingredient Card

- 상태(신선도), 수량, 카테고리 이모지를 포함한 일관된 카드 규격.
- Burning 효과 (유통기한 임박), 테두리 강조 (신규 입고) 적용.
- 스와이프 삭제 → Dust Effect 또는 일반 슬라이드.
- 스타일 상세 → `design_system.md §2.4` Visual Cues 참조.

### 8.2. Action Chip

- 선택/취소 시의 모션: `fast` (200ms) Scale up/down.
- 선택 상태: primary 색상 배경 + `onPrimary` 텍스트.
- 미선택 상태: `surfaceVariant` 배경 + `onSurface` 텍스트.
- 선택 시 `lightImpact` 햅틱.

### 8.3. Primary Button

- **Flame Orange** (`#F04E23`)를 사용.
- 'whipup' 다운 역동적인 라운드 값: **border radius 16dp**.
- 최소 높이: 48dp, 최소 너비: 화면 너비 - 좌우 `md` * 2 (Full-width 기본).
- **내부 여백:** 좌우 `lg` (24dp), 상하 `md` (16dp) — 텍스트가 윤곽에 꽉 차지 않도록 충분한 breathing room 확보.
- 텍스트: `labelLarge` (14sp, SemiBold), `onPrimary` 색상.
- Press 효과: `instant` (100ms) 살짝 어두워짐 + `lightImpact`.

### 8.4. Recipe Type Badge

- 각 `recipe_type`에 고유 배경색+텍스트색 → `brand-assets §2.4` 참조.
- 스타일: `labelSmall` + `xs` 수직 / `sm` 수평 패딩 + 4dp border radius.

### 8.5. Call-out Box (The Kick)

- 배경: `info` 색상 10% opacity.
- 좌측 보더: 4dp, `info` 색상 100%.
- 아이콘: `lightbulb_rounded`, 18dp.
- 텍스트: `bodyMedium`.

### 8.6. Horizontal Overflow Prevention

- 모든 카드, 리스트, 텍스트 컨테이너는 **화면 너비를 초과하지 않도록** `max-width: 100%` + `overflow: hidden` 적용.
- 조리 단계(`CookingStepItem`)의 설명 텍스트는 좌우 `md` (16dp) 패딩 내에서 줄바꿈 처리. 가로 스크롤 금지.
- FlavorRadar, IngredientCheckList 등 내부 콘텐츠는 부모 컨테이너 너비(화면 - 좌우 `md` * 2 = 화면 - 32dp) 내에서 렌더링.
- 긴 재료명, 레시피명은 `TextOverflow.ellipsis` + `maxLines: 2` 적용.

---

## 9. Developer Experience

### 9.1. Widget Splitting

- 하나의 파일에 모든 UI를 작성하지 말 것.
- `widgets/` 폴더 내에 기능 단위로 위젯을 잘게 분리하여 가독성과 재사용성을 높여야 함.
- 한 위젯 파일의 최대 권장 라인: 200줄.

### 9.2. Lottie Pre-loading

- 보상 애니메이션은 실제 트리거 시점에 지연이 없도록 미리 로드하거나 캐싱 전략을 고려하여 코드를 작성할 것.
- `Lottie.asset()` 대신 `LottieBuilder`의 `frameBuilder` 활용 또는 Provider에서 사전 로드.

### 9.3. Strict Theme Binding

- `Colors.orange` 같은 하드코딩 대신 반드시 `Theme.of(context).colorScheme.primary` 또는 FlexColorScheme에 정의된 시멘틱 컬러를 참조할 것.
- 커스텀 시멘틱 컬러는 `ThemeExtension`으로 정의 (`lib/theme/app_colors.dart`).

### 9.4. Animation Constants

- 모든 Duration/Curve 값은 상수로 정의하여 일관성 유지.

```dart
// lib/theme/app_motion.dart
abstract final class AppMotion {
  static const instant = Duration(milliseconds: 100);  // easeOut
  static const fast    = Duration(milliseconds: 200);  // easeInOut
  static const normal  = Duration(milliseconds: 300);  // easeInOutCubic
  static const slow    = Duration(milliseconds: 500);  // easeInOutCubic
}
```
