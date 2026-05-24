# Brand Assets & Corporate Identity

> **최종 참조 문서:** 폰트, 색상, 아이콘, 로고 등 시각적 디테일에 대한 Single Source of Truth.
> 모든 에이전트는 시각 요소 결정 시 이 문서를 최우선 참조한다.

---

## 1. Logo & App Icon

### 1.1. 앱 아이콘 사양

| 속성 | 값 |
|------|-----|
| **형태** | Rounded Square (iOS Superellipse / Android Adaptive) |
| **배경색** | `#D75F28` (Hermes Orange) |
| **전경** | 화이트 미니멀 냄비 + 증기 아이콘 |
| **최소 크기** | 48x48dp (아이콘이 뭉개지지 않는 최소 크기) |

### 1.2. 로고 타입

| 속성 | 값 |
|------|-----|
| **영문** | **WhipUp** (W와 U만 대문자, CamelCase) |
| **한글** | 윕업 |
| **조합** | 아이콘 + 텍스트 수평 배치 (기본), 수직 배치 (제한 공간) |
| **최소 여백** | 아이콘 높이의 50% 이상 사방 확보 |
| **금지 사항** | 로고 색상 임의 변경, 비율 변형, 그림자 추가 |

### 1.3. 파일 규격

```
docs/brand-assets/
├── logo/
│   ├── whipup_icon.svg          # 벡터 원본 (마스터)
│   ├── whipup_icon_1024.png     # iOS App Store (1024x1024)
│   ├── whipup_icon_512.png      # Android Play Store (512x512)
│   ├── whipup_logo_horizontal.svg
│   └── whipup_logo_vertical.svg
├── colors/
│   └── palette.md               # 이 문서 Section 2 참조
├── typography/
│   └── font_guide.md            # 이 문서 Section 3 참조
└── illustrations/
    ├── onboarding/              # 온보딩 일러스트
    └── empty_states/            # 빈 상태 일러스트
```

---

## 2. Color Palette

> FlexColorScheme 기반. 모든 색상값은 이 문서가 정본이며, `design_system.md`의 Color 섹션은 이 문서를 참조한다.

### 2.1. Core Brand Colors

| Token | Hex (Light) | Hex (Dark) | 용도 |
|-------|-------------|------------|------|
| `primary` (Hermes Orange) | `#D75F28` | `#E8845A` | CTA 버튼, 주요 액션, 앱 바, FAB |
| `onPrimary` | `#FFFFFF` | `#3E1A08` | primary 위 텍스트/아이콘 |
| `primaryContainer` | `#FDDCC8` | `#8B3A14` | 선택된 상태, 칩 배경 |
| `secondary` (Warm Amber) | `#FFC107` | `#FFD54F` | 포인트 강조, 뱃지, 보조 CTA |
| `onSecondary` | `#3E2723` | `#3E2723` | secondary 위 텍스트/아이콘 |
| `secondaryContainer` | `#FFF0C2` | `#7B5800` | 강조 카드 배경 |

### 2.2. Surface & Background

| Token | Hex (Light) | Hex (Dark) | Midnight Kitchen | 용도 |
|-------|-------------|------------|-----------------|------|
| `surface` | `#FFF8F0` | `#1E1E1E` | `#141210` | 카드, 바텀시트, 다이얼로그 |
| `onSurface` | `#2C2C2C` | `#E8E8E8` | `#D4C8BC` | surface 위 본문 텍스트 |
| `surfaceVariant` | `#F5F0E8` | `#2A2A2A` | `#1C1916` | 구분이 필요한 보조 영역 |
| `background` | `#FFF8F0` | `#121212` | `#0E0C0A` | 스캐폴드 배경 (Clean Off-White) |
| `onBackground` | `#1C1C1C` | `#F0F0F0` | `#C8BEB4` | 배경 위 텍스트 |

### 2.3. Semantic Colors (기능 색상)

| Token | Hex (Light) | Hex (Dark) | 용도 |
|-------|-------------|------------|------|
| `freshGreen` | `#66BB6A` | `#A5D6A7` | 신선도 양호 표시 |
| `warningAmber` | `#FFA726` | `#FFB74D` | 유통기한 임박 (3일 이내), Burning 효과 |
| `dangerRed` | `#EF5350` | `#E57373` | 유통기한 초과, 삭제 확인, Burning 강화 |
| `error` | `#D32F2F` | `#EF9A9A` | 시스템 에러, 폼 검증 실패 |
| `info` | `#42A5F5` | `#90CAF9` | 안내, 팁 메시지, Call-out Box (The Kick) |

### 2.4. Recipe Type Badge Colors

| recipe_type | 배경색 (Light) | 텍스트색 |
|-------------|---------------|---------|
| `main` | `#E8F5E9` | `#2E7D32` |
| `side` | `#FFF3E0` | `#E65100` |
| `soup` | `#E3F2FD` | `#1565C0` |
| `dessert` | `#FCE4EC` | `#C62828` |
| `snack` | `#FFF8E1` | `#F57F17` |
| `drink` | `#E0F7FA` | `#00838F` |
| `sauce` | `#F3E5F5` | `#6A1B9A` |

---

## 3. Typography

### 3.1. 서체 시스템

| 속성 | 값 |
|------|-----|
| **Primary Font** | **Pretendard** (한국어 + 라틴) |
| **Fallback** | Apple SD Gothic Neo (iOS), Roboto (Android) |
| **라이선스** | OFL 1.1 (오픈 소스, 상업 사용 가능) |
| **파일 위치** | `app/assets/fonts/Pretendard-*.otf` |

### 3.2. Font Weight 매핑

| Weight 이름 | Weight 값 | 역할 |
|-------------|----------|------|
| **Black** | `900` | 브랜드 앵커 — 홈 화면 "WhipUp" 로고 타이틀에만 사용 |
| **Bold** | `700` | 시선을 끄는 핵심 정보 — 단계 번호, 타이머, 히어로 |
| **SemiBold** | `600` | 구조를 잡는 뼈대 — 섹션 헤더, 카드 제목, CTA 버튼 |
| **Medium** | `500` | 조용한 안내자 — 폼 라벨, 네비게이션, 태그, 뱃지 |
| **Regular** | `400` | 편안한 읽기 — 본문, 조리 설명, 재료 목록 |
| **Light** | `300` | 숨은 보조 — 힌트, 플레이스홀더, 비활성 텍스트 |

### 3.3. Type Scale (Material 3 기준)

> 상세 적용 규칙과 화면별 매핑은 `design_system.md §1.2` 참조.

| Style | Size (sp) | Weight | Line Height | Letter Spacing | 용도 |
|-------|-----------|--------|-------------|----------------|------|
| `displayLarge` | 40 | Bold | 1.15 | -0.5 | 조리 단계 번호 (1m 거리 가독) |
| `displayMedium` | 32 | Bold | 1.15 | -0.25 | 타이머 카운트다운, 히어로 숫자 |
| `displaySmall` | 26 | SemiBold | 1.2 | 0 | 리워드 숫자, 통계, 재고 요약 |
| `headlineLarge` | 24 | Bold | 1.25 | -0.25 | 레시피 상세 히어로 제목 |
| `headlineMedium` | 22 | SemiBold | 1.25 | 0 | 온보딩 제목, 모달 제목 |
| `headlineSmall` | 20 | SemiBold | 1.3 | 0 | 바텀시트 제목, 칼럼 상세 제목 |
| `titleLarge` (홈) | 22 | Black | 1.25 | -0.25 | 홈 화면 "WhipUp" 브랜드 앵커 (홈 전용) |
| `titleLarge` (일반) | 20 | SemiBold | 1.3 | 0 | 홈 이외 AppBar 화면 제목 |
| `titleMedium` | 17 | SemiBold | 1.3 | 0.1 | 섹션 헤더, 카드 제목 |
| `titleSmall` | 15 | Medium | 1.3 | 0.1 | 폼 라벨, Phase 라벨, 서브 헤더 |
| `bodyLarge` | 16 | Regular | 1.5 | 0.25 | 조리 설명, 칼럼 본문 (주 읽기용) |
| `bodyMedium` | 14 | Regular | 1.5 | 0.25 | 재료 목록, 일반 본문, 보조 설명 |
| `bodySmall` | 12 | Regular | 1.4 | 0.4 | 타임스탬프, 출처, 부가 정보 |
| `labelLarge` | 14 | SemiBold | 1.2 | 0.1 | 버튼 텍스트, CTA |
| `labelMedium` | 12 | Medium | 1.2 | 0.5 | 바텀 네비 라벨, 탭 텍스트 |
| `labelSmall` | 11 | Medium | 1.1 | 0.5 | 태그, 뱃지, recipe_type 라벨 |

### 3.4. 폰트 사용 금지 사항

- 시스템 기본 폰트를 직접 지정하지 않음 (항상 Pretendard 사용)
- 10sp 미만의 텍스트 사용 금지 (주방 가독성)
- 이탤릭체 사용 금지 (한국어에 부적합)
- 전체 대문자(ALL CAPS) 영문은 라벨/뱃지에만 허용

---

## 4. Iconography

### 4.1. 아이콘 시스템

| 속성 | 값 |
|------|-----|
| **아이콘 셋** | Material Symbols Rounded |
| **기본 스타일** | `Rounded`, Weight 400, Optical Size 24 |
| **패키지** | `material_symbols_icons` (Flutter pub) |
| **보조** | 식재료 카테고리별 이모지 (시스템 이모지 사용) |

### 4.2. 핵심 아이콘 매핑

| 기능 | 아이콘 이름 | 비고 |
|------|-----------|------|
| 홈 | `home_rounded` | 바텀 네비게이션 |
| 재고 | `kitchen_rounded` | 바텀 네비게이션 |
| 레시피 | `restaurant_menu_rounded` | 바텀 네비게이션 |
| 마이 | `person_rounded` | 바텀 네비게이션 |
| 설정 | `settings_rounded` | 마이 페이지 / 앱바 |
| 재료 추가 | `add_circle_rounded` | FAB |
| 카메라 | `photo_camera_rounded` | OCR 진입점 |
| 마이크 | `mic_rounded` | 음성 입력 |
| 검색 | `search_rounded` | 검색 바 |
| 삭제 | `delete_rounded` | 스와이프 액션 |
| 즐겨찾기 | `favorite_rounded` | 레시피 저장 |
| 타이머 | `timer_rounded` | 조리 단계 |
| 알림 | `notifications_rounded` | 유통기한 알림 |

### 4.3. 아이콘 크기 규격

| 사용처 | 크기 (dp) |
|--------|----------|
| 바텀 네비게이션 | 24 |
| 앱 바 액션 | 24 |
| FAB 내부 | 28 |
| 리스트 아이템 Leading | 24 |
| 빈 상태 중앙 | 64 |
| 인라인 텍스트 옆 | 18 |

### 4.4. 식재료 카테고리 이모지

| 카테고리 | 이모지 | 영문 키 |
|---------|--------|---------|
| 채소 | 🥬 | `vegetable` |
| 과일 | 🍎 | `fruit` |
| 육류 | 🥩 | `meat` |
| 해산물 | 🐟 | `seafood` |
| 유제품 | 🧀 | `dairy` |
| 곡물 | 🌾 | `grain` |
| 양념/소스 | 🧂 | `seasoning` |
| 음료 | 🥤 | `beverage` |
| 냉동식품 | 🧊 | `frozen` |
| 기타 | 🍽️ | `other` |

---

## 5. Illustration & Empty State

### 5.1. 일러스트 스타일 가이드

| 속성 | 값 |
|------|-----|
| **스타일** | Flat illustration, 부드러운 라운딩 |
| **색상** | Brand Palette 내 색상만 사용 |
| **선 굵기** | 2~3px (SVG 기준) |
| **무드** | 따뜻함, 친근함, 유머러스 (잔소리 금지) |
| **포맷** | SVG (원본), Lottie JSON (애니메이션) |

### 5.2. 필수 일러스트 목록

| 상황 | 파일명 | 설명 |
|------|--------|------|
| 빈 냉장고 | `empty_fridge` | 재고 0개 상태 |
| 첫 레시피 | `first_recipe` | 레시피 탭 첫 진입 |
| 로딩 | `cooking_loading` | AI 레시피 생성 대기 |
| 성공 | `recipe_complete` | 레시피 추천 완료 도파민 |
| 에러 | `oops_spill` | 네트워크/시스템 에러 |
| 온보딩 1 | `onboard_welcome` | 환영 화면 |
| 온보딩 2 | `onboard_fridge` | 냉장고 등록 안내 |
| 온보딩 3 | `onboard_recipe` | 레시피 추천 안내 |

---

## 6. Motion & Animation

### 6.1. 전환 속도 토큰

| 토큰 | Duration | Curve | 용도 |
|------|----------|-------|------|
| `instant` | 100ms | `easeOut` | 탭 피드백, 색상 변경 |
| `fast` | 200ms | `easeInOut` | 페이드, 스케일 전환 |
| `normal` | 300ms | `easeInOutCubic` | 페이지 전환, 바텀시트 |
| `slow` | 500ms | `easeInOutCubic` | 온보딩, 히어로 애니메이션 |

### 6.2. Lottie 애니메이션 사양

| 항목 | 규격 |
|------|------|
| **프레임 레이트** | 30fps |
| **최대 파일 크기** | 100KB |
| **색상** | Brand Palette 내 색상만 |
| **반복** | 로딩: 무한 반복, 성공: 1회 재생, Burning: 무한 반복 |
| **파일 경로** | `app/assets/lottie/` |
| **사운드 경로** | `app/assets/sounds/` |

---

## 7. 에셋 관리 규칙

| 규칙 | 설명 |
|------|------|
| **원본 관리** | 모든 원본은 `docs/brand-assets/` 하위에서 관리 |
| **앱 배포용** | `app/assets/`로 복사하여 사용 (원본 수정 금지) |
| **이미지 최적화** | PNG 8-bit, WebP 권장, 2x/3x 해상도 제공 |
| **네이밍** | `snake_case`, 기능 접두사 (`ic_`, `img_`, `bg_`) |
| **사운드 포맷** | WAV (원본), MP3 (앱 번들용), 3초 이내 |
| **변경 이력** | 에셋 변경 시 커밋 메시지에 `[brand]` 접두사 |

### 7.1. 사운드 에셋 목록

| 이벤트 | 파일명 | 특성 |
|--------|--------|------|
| 타이머 완료 | `timer_done.wav` | 맑은 벨, 따뜻한 톤 |
| 레시피 완성 | `recipe_complete.wav` | 경쾌한 성공 효과음 |
| 유통기한 경보 | `expiry_alert.wav` | 부드러운 경고음 |
