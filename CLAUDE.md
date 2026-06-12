# SpeakUp — iOS 발표 연습 앱

## 프로젝트 요약
발표 연습용 iOS 음성 분석 앱. 발표별 워크스페이스를 만들어 대본을 저장하고,
녹음(또는 미리 준비한 오디오 파일)을 CLOVA STT로 분석해
말하기 속도·침묵 구간·필러워드·대본 일치율을 점수로 피드백한다.

**제출 마감: 2025년 6월 14일**

---

## 개발 환경 & 제약사항

| 항목 | 값 |
|------|-----|
| Xcode | 12.5 |
| Swift | 5.4 |
| iOS Deployment Target | 14.5 |
| macOS | Big Sur 11.0.1 |
| 실행 환경 | 시뮬레이터 (실기기 연결 불가) |

### 절대 사용 금지
- SwiftUI
- Speech Framework
- iOS 15 이상 전용 API (`@available(iOS 15, *)` 포함)
- `async/await` — URLSession은 반드시 completion handler 방식만 사용
- **Storyboard** — ibtool이 iOS 플러그인을 로드하지 못하는 시스템 문제로 사용 불가

### 사용 프레임워크
- **UIKit** — UI 구성 (코드 방식, Programmatic UI)
- **AVFoundation** — 녹음 및 파일 저장
- **NaturalLanguage** — 대본 텍스트 비교 (대본 일치율 계산)
- **UserDefaults + Codable** — 데이터 영속성 (CoreData 대신 선택, 구현 단순화)
- **STT** — 네이버 CLOVA Speech REST API (파일 업로드 방식, 언어: Kor)

### UI 작성 규칙 (Programmatic)
- 모든 뷰는 코드로 생성 — `viewDidLoad()` 에서 초기화
- AutoLayout은 `NSLayoutConstraint.activate([...])` + `translatesAutoresizingMaskIntoConstraints = false`
- 화면 전환은 `navigationController?.pushViewController(_:animated:)` 사용
- SceneDelegate에서 `UINavigationController(rootViewController: WorkspaceListViewController())` 로 루트 설정

---

## 현재 진행 상황 (2026-06-12 기준)

### 완료
- [x] Xcode 프로젝트 생성 및 환경 설정 (번들 ID, 배포 타겟, Swift 버전)
- [x] `AppDelegate.swift`, `SceneDelegate.swift`
- [x] `Info.plist` (마이크 권한 포함, 스토리보드 참조 제거)
- [x] `Assets.xcassets`
- [x] 스토리보드 빌드 제외 (ibtool 시스템 오류 우회)
- [x] **UI 전면 구현 — 워크스페이스 방식으로 설계**
  - [x] `WorkspaceListViewController` — 발표 카드 리스트 (홈)
  - [x] `WorkspaceCreateViewController` — 새 발표 만들기 (formSheet 모달)
  - [x] `WorkspaceDetailViewController` — 발표별 상세 (대본 미리보기, 통계, 점수 그래프, 기록 리스트)
  - [x] `ScriptViewController` — 대본 편집 전용, WorkspaceStore에 저장
  - [x] `RecordingViewController` — 타이머, 파형 애니메이션 (더미), workspaceId 전달
  - [x] `ResultViewController` — 점수 표시(현재 더미), WorkspaceStore에 기록 저장
- [x] `Models/Workspace.swift` — Workspace, PracticeRecord 데이터 모델
- [x] `Models/WorkspaceStore.swift` — UserDefaults + Codable 기반 싱글턴 저장소
- [x] `project.pbxproj` 에 신규 파일 모두 등록

### 미완성 (다음 작업)
- [ ] `Services/RecordingService.swift` — AVAudioRecorder 래핑, 시뮬레이터에서는 번들 파일 사용
- [ ] `Services/ClovaSTTService.swift` — CLOVA REST API 멀티파트 업로드
- [ ] `Services/SpeechAnalyzer.swift` — WPM / 침묵 / 필러워드 / 대본 일치율 분석
- [ ] `RecordingViewController` — 실제 AVAudioRecorder 연동 (현재 타이머/파형만 있음)
- [ ] `ResultViewController` — 더미 점수 → 실제 분석 결과로 교체
- [ ] 시연용 `.m4a` 파일 번들 추가 (시뮬레이터 마이크 불안정 대비)
- [ ] CLOVA API 키 설정 (`Config.plist` 분리, `.gitignore` 추가)
- [ ] 엣지 케이스 처리 (빈 대본, 네트워크 실패, 권한 거부)
- [ ] 전체 플로우 시뮬레이터 테스트

---

## 파일 구조

```
Speakup/
│
├── AppDelegate.swift
├── SceneDelegate.swift              ← root: WorkspaceListViewController
├── HomeViewController.swift         ← class WorkspaceListViewController (파일명 유지)
├── Info.plist
│
├── Models/
│   ├── Workspace.swift              ← Workspace, PracticeRecord (Codable)
│   └── WorkspaceStore.swift         ← UserDefaults 기반 싱글턴
│
├── Screens/
│   ├── WorkspaceCreateViewController.swift  ← 새 발표 만들기 모달
│   ├── WorkspaceDetailViewController.swift  ← 발표별 상세 화면
│   ├── ScriptViewController.swift           ← 대본 편집 (저장 후 pop)
│   ├── RecordingViewController.swift        ← 녹음 화면
│   ├── ResultViewController.swift           ← 분석 결과
│   └── HistoryViewController.swift          ← 미사용 (legacy)
│
├── Services/                        ← 미구현
│   ├── RecordingService.swift       ← AVAudioRecorder 래핑
│   ├── ClovaSTTService.swift        ← 네이버 CLOVA REST API
│   └── SpeechAnalyzer.swift         ← 분석 엔진
│
└── Assets.xcassets
```

---

## 화면 전환 구조

```
SceneDelegate
  └─ UINavigationController
        └─ WorkspaceListViewController (홈)
              ├─ [+] ──────────────────▶ WorkspaceCreateViewController (modal)
              └─ [카드 탭] ────────────▶ WorkspaceDetailViewController
                                              ├─ [대본 편집] ──▶ ScriptViewController
                                              │                      └─ (저장) ──▶ pop
                                              └─ [연습 시작] ──▶ RecordingViewController
                                                                     └─ (중지) ──▶ ResultViewController
                                                                                     └─ (발표로 돌아가기) ──▶ pop to WorkspaceDetailVC
```
모두 `navigationController?.pushViewController` 로 전환.

---

## 남은 작업 — 핵심 기능 구현

### 1단계 — 시연 전략 확정
- 시뮬레이터 마이크는 불안정하므로 **번들에 미리 준비한 `.m4a` 파일을 사용**하는 방식으로 시연
- `RecordingViewController` 중지 시 → 번들 파일 경로를 ClovaSTTService에 전달
- 실기기에서는 실제 녹음 파일 사용 (RecordingService가 처리)

### 2단계 — RecordingService
```swift
// Services/RecordingService.swift
// - AVAudioRecorder로 .m4a 저장 (실기기)
// - 시뮬레이터에서는 Bundle.main의 demo.m4a 경로 반환
// - 실시간 음량 레벨 polling (metering) → WaveformView에 반영
```

### 3단계 — ClovaSTTService
```swift
// Services/ClovaSTTService.swift
// - 오디오 파일 URL → multipart/form-data POST
// - 엔드포인트: https://clovaspeech-gw.ncloud.com/recog/v1/stt
// - 헤더: X-CLOVASPEECH-API-KEY
// - 언어: Kor
// - 응답 JSON { "text": "..." } 파싱
// - completion handler 방식 (async/await 금지)
```

### 4단계 — SpeechAnalyzer
```swift
// Services/SpeechAnalyzer.swift
// 입력: sttText(인식 텍스트), script(원본 대본), duration(녹음 시간 초)
// 출력: AnalysisResult (4개 항목 점수)

// 말하기 속도 (20점)
//   - 단어 수 ÷ duration(분) = WPM
//   - 적정 범위 120~150 WPM → 20점, 벗어날수록 감점

// 침묵 구간 (20점)
//   - RecordingService에서 metering 레벨 배열 수신
//   - 연속 2초 이상 -40dB 이하 구간 = 침묵
//   - 침묵 횟수 0→20점, 많을수록 감점

// 필러워드 (20점)
//   - sttText에서 "음", "어", "그", "저" 등 감지
//   - 횟수 0→20점, 많을수록 감점

// 대본 일치율 (40점)
//   - NaturalLanguage 또는 단순 tokenize 후 교집합/합집합 비율
//   - 일치율 × 40점
```

### 5단계 — ResultViewController 연동
- 더미 `computeDummyScores()` → `SpeechAnalyzer` 실제 결과로 교체
- `RecordingViewController`에서 `(audioFileURL, silenceLevels, duration)` 을 `ResultViewController`로 전달

### 6단계 — API 키 관리
- `Speakup/Config.plist` 파일 생성 (gitignore 추가)
- `ClovaAPIKey` 키에 값 저장
- 코드에서 `Bundle.main.infoDictionary` 로 읽기

---

## STT API 참고

- 서비스: 네이버 CLOVA Speech (CSR)
- 엔드포인트: `https://clovaspeech-gw.ncloud.com/recog/v1/stt`
- 방식: multipart/form-data POST
- 언어 코드: `Kor`
- 인증: `X-CLOVASPEECH-API-KEY` 헤더
- 응답 필드: `text` (인식된 전체 텍스트)

---

## 점수 산출 기준

| 항목 | 배점 | 기준 |
|------|------|------|
| 대본 일치율 | 40점 | 토큰 기반 유사도 × 40 |
| 말하기 속도 | 20점 | 120~150 WPM 적정, 벗어날수록 감점 |
| 침묵 구간 | 20점 | 2초↑ 침묵 횟수, 많을수록 감점 |
| 필러워드 | 20점 | 음/어/그/저 감지 횟수, 많을수록 감점 |

---

## 주의사항 및 알려진 제약

1. **시뮬레이터 마이크** — Big Sur + Xcode 12.5 환경에서 불안정. 시연은 번들 `.m4a` 파일 사용.
2. **CLOVA API 키** — `Config.plist`에 저장, 소스 하드코딩 금지. `.gitignore`에 추가 필수.
3. **iOS 14 호환** — `@available` 가드 없이 iOS 15+ API 호출 금지.
4. **URLSession** — `dataTask(with:completionHandler:)` 패턴만 사용. async/await 금지.
5. **Storyboard 사용 금지** — ibtool 오류 (`Unknown target runtime "AppleCocoa Touch"`). Big Sur 11.0.1 + Xcode 12.5 환경 문제.
6. **CoreData 미사용** — `UserDefaults + Codable` (WorkspaceStore)로 대체. 구현 단순화 목적.
