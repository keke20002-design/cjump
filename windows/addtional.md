🗺️ 전체 콘텐츠 확장 플랜
시스템 구조 먼저 잡기
스킨 시스템은 단독으로 존재하면 의미 없고, 코인 → 업적 → 스킨 → 재플레이 동기 순환 루프가 핵심이에요.
플레이 → 점수/업적/코인 획득 → 스킨 해금 → "이 스킨으로 더 하고 싶다" → 재플레이

📝 Claude Code 추가 프롬프트
기존 프롬프트 뒤에 이어붙이거나 별도 태스크로 사용하세요.
## 🎨 EXPANSION: Skin & Unlock System

Add a complete skin, achievement, and coin economy system to the existing
Anti-Gravity Doodle Jump game. This system must integrate with the existing
score manager and game loop without breaking current functionality.

---

### 1. Data Models

#### Skin Model
```dart
enum SkinCategory { basic, effect, theme }
enum UnlockType { score, achievement, coin, free }

class CharacterSkin {
  final String id;              // e.g., 'green_core'
  final String displayName;
  final SkinCategory category;
  final UnlockType unlockType;
  final int unlockValue;        // score threshold / coin cost / achievement id ref
  final bool isDefault;
  bool isUnlocked;
  
  // Visual config
  final Color coreColor;
  final Color? glowColor;
  final TrailType? trailEffect;   // null = no trail
  final ParticleType? particleEffect;
}

enum TrailType { none, lightning, starDust, flame, ice, blackHole }
enum ParticleType { none, spark, star, ember, snowflake, glitch }
```

#### Achievement Model
```dart
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final AchievementCondition condition;
  final int targetValue;
  bool isCompleted;
  int currentProgress;
  
  // Reward
  final String? rewardSkinId;   // null = no skin reward
  final int rewardCoins;
}

enum AchievementCondition {
  totalScore,           // 누적 최고점수
  gravityFlipCount,     // 중력 뒤집기 횟수 (누적)
  consecutivePlatforms, // 연속 플랫폼 성공 횟수
  totalGamesPlayed,     // 총 플레이 횟수
  totalCoinsCollected,  // 누적 코인 수집
  singleRunScore,       // 단일 게임 점수
  gravityPadBounces,    // 중력패드 위에서 바운스 횟수
}
```

---

### 2. Skin Catalog (전체 목록 구현)

#### 🟢 Basic Category (기본 해금, 수량 확보용)
ID: green_core

Default skin, free
Color: #00E676, glow: none, trail: none

ID: red_core

Unlock: score 300점
Color: #FF1744, glow: #FF6B6B, trail: none

ID: neon_core

Unlock: score 700점
Color: #00FFFF, glow: #00FFFF, trail: none
글로우 펄스 애니메이션 추가 (0.8s cycle)

ID: shadow_core

Unlock: coin 150개
Color: #424242, glow: #7C4DFF, trail: none
캐릭터 주변 흐릿한 그림자 효과


#### 🌟 Effect Category (트레일 이펙트, "와" 소리)
ID: lightning_trail

Unlock: achievement 'gravity_master' (중력 50번 뒤집기)
Color: #FFD600, glow: #FFFF00
Trail: lightning (지그재그 전기 선, 잔상 5개)
이동 시 스파크 파티클 발생

ID: stardust_trail

Unlock: coin 300개
Color: #E040FB, glow: #CE93D8
Trail: starDust (별 모양 파티클 20개, 중력에 따라 위/아래로 흩어짐)

ID: flame_core

Unlock: achievement 'high_scorer' (단일 게임 1500점)
Color: #FF6D00, glow: #FFAB40
Trail: flame (위쪽으로 불꽃 파티클, 중력 반전 시 아래로)
Core 자체가 흔들리는 불꽃 shape

ID: ice_core

Unlock: score 2000점 + coin 200개 (복합 조건)
Color: #40C4FF, glow: #B3E5FC
Trail: ice (육각형 눈결정 파티클)
플랫폼 착지 시 얼음 균열 이펙트


#### 👽 Theme Category (보상 전용, 희소성 높음)
ID: blackhole_core

Unlock: achievement 'legend' (누적 10000점)
Color: #000000, glow: #AA00FF
Trail: blackHole (주변 빛을 빨아들이는 렌즈 왜곡 효과)
중력 뒤집기 시 주변 파티클이 안으로 빨려들어오는 연출

ID: virus_core

Unlock: achievement 'survivor' (총 100게임 플레이)
Color: #76FF03, glow: #CCFF90
Particle: glitch (화면 글리치 효과, 픽셀 노이즈)
이동 시 디지털 노이즈 트레일

ID: gold_core

Unlock: coin 1000개 (프리미엄 구매)
Color: #FFD700, glow: #FFF176
Trail: starDust (골드 색상)
착지 시 금화 파티클 폭발
코인 획득량 1.5x 보너스 (기능적 보상)

ID: robot_core

Unlock: achievement 'platformer' (연속 플랫폼 30개 성공)
Color: #90A4AE, glow: #CFD8DC
캐릭터가 로봇 형태 (네모난 바디, 안테나)
이동 시 기계음 SFX


---

### 3. Achievement System (업적 12개)
```dart
final List<Achievement> achievements = [

  // 🎯 점수 관련
  Achievement(
    id: 'first_flight',
    title: '첫 비행',
    description: '500점 달성',
    iconEmoji: '🚀',
    condition: AchievementCondition.singleRunScore,
    targetValue: 500,
    rewardCoins: 50,
  ),
  Achievement(
    id: 'high_scorer',
    title: '고득점자',
    description: '단일 게임에서 1500점 달성',
    iconEmoji: '🔥',
    condition: AchievementCondition.singleRunScore,
    targetValue: 1500,
    rewardSkinId: 'flame_core',
    rewardCoins: 100,
  ),
  Achievement(
    id: 'legend',
    title: '전설',
    description: '누적 총점 10000점 돌파',
    iconEmoji: '👑',
    condition: AchievementCondition.totalScore,
    targetValue: 10000,
    rewardSkinId: 'blackhole_core',
    rewardCoins: 200,
  ),

  // 🔄 중력 관련
  Achievement(
    id: 'gravity_curious',
    title: '중력 탐험가',
    description: '중력 10번 뒤집기',
    iconEmoji: '🔃',
    condition: AchievementCondition.gravityFlipCount,
    targetValue: 10,
    rewardCoins: 30,
  ),
  Achievement(
    id: 'gravity_master',
    title: '중력 마스터',
    description: '중력 50번 뒤집기',
    iconEmoji: '⚡',
    condition: AchievementCondition.gravityFlipCount,
    targetValue: 50,
    rewardSkinId: 'lightning_trail',
    rewardCoins: 80,
  ),
  Achievement(
    id: 'gravity_god',
    title: '중력의 신',
    description: '중력 200번 뒤집기',
    iconEmoji: '🌀',
    condition: AchievementCondition.gravityFlipCount,
    targetValue: 200,
    rewardCoins: 150,
  ),

  // 🏃 플레이 스타일 관련
  Achievement(
    id: 'platformer',
    title: '플랫폼 달인',
    description: '연속 플랫폼 30개 성공',
    iconEmoji: '🤖',
    condition: AchievementCondition.consecutivePlatforms,
    targetValue: 30,
    rewardSkinId: 'robot_core',
    rewardCoins: 80,
  ),
  Achievement(
    id: 'survivor',
    title: '생존자',
    description: '총 100번 플레이',
    iconEmoji: '🦠',
    condition: AchievementCondition.totalGamesPlayed,
    targetValue: 100,
    rewardSkinId: 'virus_core',
    rewardCoins: 100,
  ),

  // 💰 코인 관련
  Achievement(
    id: 'coin_collector',
    title: '수집가',
    description: '코인 500개 모으기',
    iconEmoji: '💰',
    condition: AchievementCondition.totalCoinsCollected,
    targetValue: 500,
    rewardCoins: 50,
  ),
];
```

---

### 4. Coin Economy

#### 코인 수급 설계
인게임 코인 획득:

플랫폼 착지마다: +1 코인
Gravity Pad 플랫폼 사용: +3 코인
100점마다: +5 보너스 코인
게임 오버 후 부활 광고 시청: +20 코인 (AdMob optional)
업적 달성 보상: 30~200 코인 (위 목록 참고)

코인 소비:

shadow_core: 150코인
stardust_trail: 300코인
ice_core: 200코인 (+ 2000점 조건)
gold_core: 1000코인


#### Coin Component (게임 중 수집 아이템)
```dart
// 플랫폼 위에 랜덤하게 코인 스폰
// 캐릭터가 지나가면 자동 흡수 (magnet 범위: 30px)
// 화면에 최대 8개까지만 존재
// 금색 원형, 회전 애니메이션, 수집 시 +1 텍스트 팝업
```

---

### 5. 신규 파일 구조
lib/
├── skins/
│   ├── skin_catalog.dart          # 전체 스킨 데이터 정의
│   ├── skin_renderer.dart         # 스킨별 CustomPainter 로직
│   └── trail_painter.dart         # 트레일 이펙트 렌더링
├── achievements/
│   ├── achievement_catalog.dart   # 전체 업적 데이터
│   ├── achievement_manager.dart   # 진행도 추적 & 완료 처리
│   └── achievement_popup.dart     # 업적 달성 알림 위젯 (슬라이드 인)
├── economy/
│   ├── coin_manager.dart          # 코인 잔액, 수급/소비 처리
│   └── coin_component.dart        # 인게임 코인 아이템
├── screens/
│   ├── skin_shop_screen.dart      # 스킨 상점 & 선택 화면
│   └── achievement_screen.dart   # 업적 목록 화면
└── utils/
└── persistence_manager.dart   # shared_preferences 통합 저장

---

### 6. Persistence (저장 데이터)
```dart
// persistence_manager.dart가 관리할 키 목록
class PersistenceKeys {
  // 경제
  static const String coins = 'coins';
  
  // 스킨
  static const String unlockedSkins = 'unlocked_skins';   // List<String>
  static const String selectedSkin = 'selected_skin';     // String
  
  // 업적
  static const String achievementProgress = 'achievement_progress'; // Map<String,int>
  static const String completedAchievements = 'completed_achievements'; // List<String>
  
  // 통계 (업적 조건 계산용)
  static const String totalScore = 'stat_total_score';
  static const String highScore = 'stat_high_score';
  static const String totalGames = 'stat_total_games';
  static const String totalFlips = 'stat_total_flips';
  static const String totalCoinsEver = 'stat_total_coins';
}
```

---

### 7. UI 명세

#### Skin Shop Screen
레이아웃:

상단: 현재 코인 잔액 (코인 아이콘 + 숫자)
탭: [기본형] [이펙트형] [테마형]
그리드: 2열, 각 카드에

스킨 미리보기 (작은 애니메이션 캐릭터)
스킨 이름
해금 조건 or "선택" 버튼 or 잠금 아이콘
코인 구매 스킨은 [구매 N코인] 버튼


하단: 현재 선택된 스킨 큰 미리보기 + "게임 시작" 버튼

해금 상태별 카드 스타일:

잠김: 회색 처리, 자물쇠 아이콘, 조건 텍스트
해금됨: 풀컬러, "선택" 버튼
선택됨: 테두리 강조, 체크 표시


#### Achievement Popup (인게임)
업적 달성 시:

화면 상단에서 카드가 슬라이드 다운 (2초 후 사라짐)
카드 내용: 이모지 + 업적 이름 + 보상 (코인 or 스킨)
스킨 해금 업적은 스킨 미리보기 썸네일 포함
여러 개 동시 달성 시 큐로 순차 표시


---

### 8. Integration Points (기존 코드 수정 부분)
```dart
// game_screen.dart 수정
onGravityFlip: () {
  achievementManager.increment(AchievementCondition.gravityFlipCount);
}

// score_manager.dart 수정  
onScoreUpdate: (int score) {
  achievementManager.checkScore(score);
  coinManager.addFromScore(score);
}

// platform collision 수정
onPlatformLand: (PlatformType type) {
  coinManager.add(type == PlatformType.gravityPad ? 3 : 1);
  achievementManager.incrementConsecutive();
}

// game_over 수정
onGameOver: () {
  achievementManager.resetConsecutive();
  achievementManager.increment(AchievementCondition.totalGamesPlayed);
  persistenceManager.save();
}
```

---

### Implementation Order for This Expansion
1. `persistence_manager.dart` 구현 (기반 인프라)
2. `coin_manager.dart` + 인게임 코인 아이템
3. `skin_catalog.dart` 데이터 정의 + 기본형 4개 렌더링
4. `skin_shop_screen.dart` UI
5. `achievement_catalog.dart` + `achievement_manager.dart`
6. `achievement_popup.dart` 위젯
7. 이펙트형 트레일 렌더링 (`trail_painter.dart`)
8. 테마형 스킨 특수 효과
9. 전체 통합 테스트 및 밸런싱

⚖️ 경제 밸런싱 가이드
콘텐츠가 너무 빨리 소진되면 재플레이 동기가 사라져요. 아래 기준으로 조정하세요.
코인 수급 속도 — 평균 게임 1회에 약 30~50코인 획득이 적당해요. 그러면 shadow_core(150코인)는 3~5판, gold_core(1000코인)는 20~30판 걸려서 적절한 긴장감을 만들어요.
업적 난이도 피라미드 — 전체 12개 중 처음 3~4개는 5판 이내에 자연스럽게 달성되도록 설계해야 "업적 시스템이 있구나" 를 플레이어가 인지해요. 마지막 2~3개(legend, gravity_god)는 장기 목표로 두세요.
스킨 희소성 유지 — gold_core와 blackhole_core는 절대 쉽게 풀지 마세요. 희귀 스킨을 가진 플레이어가 자랑할 수 있는 구조가 재플레이 루프의 핵심이에요.

---

## 🆕 EXPANSION v2: 추가 콘텐츠 레이어 설계

> 기존 플랜(스킨/업적/코인)이 "수집 루프" 중심이라면, v2는 게임플레이 깊이 + 장기 리텐션을 담당한다.

---

### 레이어 1: 콤보 & 멀티플라이어 시스템

연속 플랫폼 착지 시 콤보 카운터 증가, 착지 실패 시 리셋.

```
콤보 x5  → 점수 1.2배
콤보 x10 → 점수 1.5배 + 화면 파티클 황금 링
콤보 x20 → 점수 2.0배 + 특수 이펙트 + 코인 2배
```

**파일:** `lib/game/combo_manager.dart`
**기존 수정:** `antigravity_game.dart` onPlatformLand 훅, HudOverlay 콤보 표시

**Why:** 현재 고득점은 그냥 오래 살아남기만 하면 됨. 콤보가 있어야 "잘 하는 것"에 보상이 생기고, 단일 점수 1500 업적 달성에 전략이 필요해짐.

---

### 레이어 2: 데일리 미션 시스템

업적은 장기 목표 → 매일 단기 피드백 루프 제공.

```dart
class DailyMission {
  final String id;
  final String description;      // "오늘 중력 20번 뒤집기"
  final AchievementCondition condition;
  final int targetValue;
  final int rewardCoins;         // 20~50코인 (업적보다 낮음)
  final MissionDifficulty difficulty; // easy / medium / hard
  int currentProgress;
  bool isCompleted;
  DateTime expiresAt;            // 당일 자정
}

enum MissionDifficulty { easy, medium, hard }
```

매일 미션 풀(30개)에서 3개 랜덤 선택, 자정에 갱신.

**미션 예시:**
- 오늘 5판 플레이 (+20코인, easy)
- 오늘 단일 게임 500점 (+30코인, medium)
- 오늘 중력 20번 뒤집기 (+25코인, medium)
- 오늘 플랫폼 15개 연속 착지 (+35코인, medium)
- 오늘 코인 50개 수집 (+20코인, easy)
- 오늘 1000점 달성 (+50코인, hard)

**파일:** `lib/missions/daily_mission_model.dart`, `lib/missions/daily_mission_manager.dart`, `lib/screens/mission_screen.dart`

---

### 레이어 3: 로컬 리더보드 (명예의 전당)

Firebase 없이 기기 내 상위 10점 기록 저장.

```dart
class LeaderboardEntry {
  final int score;
  final DateTime date;
  final String skinId;   // 해당 게임에서 사용한 스킨
  final int totalFlips;  // 중력 뒤집기 횟수
}
```

공유 기능: "내 점수 공유하기" → 텍스트 클립보드 복사
`"AntiGravity Jump 최고점 2,340점! ⚡ #AntiGravityJump"`

나중에 Firebase 연동 시 온라인 리더보드 업그레이드 가능.

**파일:** `lib/economy/local_leaderboard.dart`

---

### 레이어 4: 추가 스킨 5개 (v2 전용)

| ID | 해금 조건 | 특징 |
|----|----------|------|
| `aurora_core` | 데일리 미션 30일 완주 | 오로라 트레일, 무지개 글로우 |
| `pixel_core` | 콤보 x20 첫 달성 | 8비트 픽셀 사각형 스타일 |
| `ghost_core` | 총 50판 플레이 | 반투명 50%, 잔상 이펙트 |
| `neon_glitch` | 단일 점수 2500점 | 글리치 + 네온 혼합 |
| `rainbow_core` | 데일리 미션 총 50개 달성 | 무지개 사이클 컬러 변환 |

---

### 레이어 5: 코인 인플레이션 방지 — 추가 소비처

데일리 미션으로 매일 ~80코인 추가 수급 → 소비처 다양화 필수.

| 소비처 | 비용 | 효과 |
|--------|------|------|
| 2배 코인 게임 (1판) | 50코인 | 해당 게임 코인 획득 2배 |
| 계속 달리기 (부활) | 30코인 | 게임오버 1회 무효화 |
| 미션 리롤 | 15코인 | 마음에 안 드는 미션 1개 교체 |

**파일:** 기존 `coin_manager.dart`에 소비 메서드 추가, `game_over_screen.dart`에 부활 버튼 추가

---

### 레이어 6: 튜토리얼 & 온보딩

첫 3판 가이드 + 스타트 부스트.

```
1판: 기본 점프 + 중력 뒤집기 안내 (화살표 힌트 오버레이)
2판: 코인 수집 안내 (코인에 "수집하세요!" 버블)
3판: 첫 업적 달성 의도적 연출 (낮은 조건 first_flight 유도)
→ 온보딩 완료: 코인 100개 지급
```

**파일:** `lib/screens/tutorial_overlay.dart`
첫 실행 여부는 `PersistenceKeys.isFirstRun` (bool)으로 관리.

---

### 📋 업데이트된 구현 순서 (v1 + v2 통합)

```
기존 1~9단계 유지 (스킨/업적/코인 기반)
+
10. combo_manager.dart — 콤보 & 배율 (점수 공식 수정)
11. daily_mission_manager.dart + mission_screen.dart
12. local_leaderboard.dart + 공유 기능
13. 추가 스킨 5개 (aurora, pixel, ghost, neon_glitch, rainbow)
14. tutorial_overlay.dart — 첫 실행 감지 → 온보딩
15. 소비처 확장 (부활 버튼, 미션 리롤, 코인 부스터)
```

⚖️ v2 밸런싱 가이드
데일리 미션 → 매일 ~60~80코인 추가 수급 예상. 부활(30코인) + 리롤(15코인) 소비처가 자연스럽게 흡수. 콤보 시스템은 초보자에게는 보너스, 숙련자에게는 핵심 전략이 되도록 x5 임계값을 낮게 유지.
