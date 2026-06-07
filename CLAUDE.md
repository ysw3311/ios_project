# SpeakUp — iOS 발표 연습 앱

## 프로젝트 요약
발표 연습용 iOS 음성 분석 앱. 사용자가 대본을 입력하고 녹음하면
말하기 속도·침묵 구간·필러워드를 분석하고 대본 일치율을 점수로 피드백한다.

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
- **Storyboard** — ibtool이 iOS 플러그인을 로드하지 못하는 시스템 문제로 사용 불가. 모든 UI는 코드로 작성

### 사용 프레임워크
- **UIKit** — UI 구성 (코드 방식, Programmatic UI)
- **AVFoundation** — 녹음 및 파일 저장
- **NaturalLanguage** — 대본 텍스트 비교
- **CoreData** — 연습 기록 로컬 저장
- **STT** — 네이버 CLOVA Speech REST API (녹음 파일 → 업로드 방식, 언어: ko-KR)

### UI 작성 규칙 (Programmatic)
- 모든 뷰는 코드로 생성 — `loadView()` 또는 `viewDidLoad()` 에서 초기화
- AutoLayout은 `NSLayoutConstraint` 또는 `translatesAutoresizingMaskIntoConstraints = false` 사용
- 화면 전환은 `navigationController?.pushViewController(_:animated:)` 사용
- SceneDelegate에서 `UINavigationController(rootViewController: HomeViewController())` 로 루트 설정

---

## 현재 진행 상황 (2025-06-08 기준)

### 완료
- [x] Xcode 프로젝트 생성 (`Speakup.xcodeproj`)
- [x] 번들 ID, 배포 타겟, Swift 버전 설정 완료
- [x] `AppDelegate.swift`, `SceneDelegate.swift` 생성
- [x] `HomeViewController.swift` 생성
- [x] `Info.plist` 생성 (마이크 권한 포함, 스토리보드 참조 제거)
- [x] `Assets.xcassets` 생성
- [x] SceneDelegate에서 코드로 NavigationController + HomeViewController 연결
- [x] 스토리보드 빌드 제외 (ibtool 시스템 오류 우회)

### 진행 중
- [ ] 시뮬레이터 빌드 확인

### 미완성
- [ ] 4개 화면 UI 코드 구현 (Script / Recording / Result / History)
- [ ] Services 구현 (RecordingService, ClovaSTTService, SpeechAnalyzer)
- [ ] Models / CoreData 구성
- [ ] 점수 산출 로직

> **현황 요약:** 코드 기반 UI로 전환 완료. SceneDelegate → NavigationController → HomeViewController 구조. 빌드 확인 후 나머지 4개 화면 구현 시작.

---

## 파일 구조

```
Speakup/
│
├── AppDelegate.swift
├── SceneDelegate.swift              ← 여기서 루트 VC 코드로 설정
├── Info.plist
│
├── Screens/                         ← 화면별 ViewController
│   ├── HomeViewController.swift
│   ├── ScriptViewController.swift
│   ├── RecordingViewController.swift
│   ├── ResultViewController.swift
│   └── HistoryViewController.swift
│
├── Services/                        ← 비즈니스 로직 / 외부 연동
│   ├── RecordingService.swift       ← AVAudioRecorder 래핑
│   ├── ClovaSTTService.swift        ← 네이버 CLOVA REST API
│   └── SpeechAnalyzer.swift         ← WPM · 침묵 · 필러워드 분석
│
├── Models/
│   └── AnalysisResult.swift         ← 분석 결과 값 타입
│
├── CoreData/
│   └── SpeakUp.xcdatamodeld
│
└── Assets.xcassets
```

---

## 남은 작업 목록 (우선순위 순)

### 1단계 — 시뮬레이터 빌드 확인
- [ ] `git pull` 후 `Cmd+R` 빌드 성공 확인
- [ ] 홈 화면 (NavigationBar + "SpeakUp" 레이블) 뜨는지 확인

### 2단계 — 화면 UI 코드 구현

#### HomeViewController
- 앱 이름 "SpeakUp" 레이블
- 오늘 연습하기 버튼 → ScriptViewController push
- 최근 연습 점수 카드, 최고 점수 카드

#### ScriptViewController
- UITextView 대본 입력
- 글자 수 카운터 (현재 / 2000자)
- 녹음 시작 버튼 → RecordingViewController push

#### RecordingViewController
- 경과 시간 타이머
- 음성 파형 애니메이션 (AVAudioRecorder metering 활용)
- 원형 녹음 중지 버튼
- 중지 시 → 분석 후 ResultViewController push

#### ResultViewController
- 종합 점수 원형 게이지
- 항목별 점수 바 차트 (4개 항목)
- 누락 문장 하이라이트
- 히스토리 보기 버튼 → HistoryViewController push

#### HistoryViewController
- 날짜별 연습 기록 리스트 (CoreData)
- 점수 변화 선 그래프

### 3단계 — 핵심 로직 구현

#### 녹음 (AVFoundation)
- `AVAudioRecorder`로 `.m4a` 파일 저장
- 실시간 음량 레벨 polling (metering)

#### STT — 네이버 CLOVA Speech API
- 녹음 완료 후 파일을 REST API로 multipart 업로드
- 응답 JSON에서 인식 텍스트 파싱
- completion handler 방식만 사용 (async/await 금지)

#### 분석 엔진
- **말하기 속도** — 인식된 단어 수 ÷ 녹음 시간(분) → WPM, 적정 범위 120~150
- **침묵 구간** — 오디오 레벨 기반 2초 이상 침묵 감지 및 횟수 집계
- **필러워드** — "음", "어", "그" 감지 및 횟수 집계
- **대본 일치율** — NaturalLanguage 또는 단순 문자열 비교로 입력 대본 vs 인식 텍스트 비교

#### 점수 산출
| 항목 | 배점 |
|------|------|
| 대본 일치율 | 40점 |
| 말하기 속도 | 20점 |
| 침묵 구간 | 20점 |
| 필러워드 | 20점 |

#### CoreData
- Entity: `PracticeRecord` (날짜, 종합점수, 항목별 점수, 스크립트, STT 결과)
- CRUD: 저장 / 조회 / (필요 시) 삭제

### 4단계 — 마무리
- [ ] 시뮬레이터에서 전체 플로우 테스트 (홈 → 대본 → 녹음 → 결과 → 히스토리)
- [ ] 엣지 케이스 처리 (빈 대본, 네트워크 실패, 권한 거부)
- [ ] UI 완성도 점검

---

## 화면 전환 구조

```
SceneDelegate
  └─ UINavigationController
        └─ HomeViewController
              └─(오늘 연습하기)─▶ ScriptViewController
                                      └─(녹음 시작)─▶ RecordingViewController
                                                            └─(중지)─▶ ResultViewController
                                                                            └─(히스토리)─▶ HistoryViewController
```
모두 `navigationController?.pushViewController` 로 전환.

---

## STT API 참고

- 서비스: 네이버 CLOVA Speech (CSR)
- 엔드포인트: `https://clovaspeech-gw.ncloud.com/recog/v1/stt`
- 방식: multipart/form-data POST
- 언어 코드: `Kor`
- 인증: `X-CLOVASPEECH-API-KEY` 헤더
- 응답 필드: `text` (인식된 전체 텍스트)

---

## 주의사항 및 알려진 제약

1. **시뮬레이터 마이크** — 시뮬레이터에서 실제 마이크 녹음이 제한될 수 있으므로 테스트용 더미 오디오 파일 경로를 준비해둘 것.
2. **CLOVA API 키** — `Info.plist` 또는 별도 Config 파일에 저장, 소스에 하드코딩 금지. `.gitignore`에 키 파일 추가 필수.
3. **iOS 14 호환** — `@available` 가드 없이 iOS 15+ API 호출 금지.
4. **URLSession** — `dataTask(with:completionHandler:)` 패턴만 사용.
5. **Storyboard 사용 금지** — 이 Mac의 ibtool이 iOS 플러그인을 로드하지 못함 (`Unknown target runtime "AppleCocoa Touch"`). 원인은 Big Sur 11.0.1 + Xcode 12.5 환경 문제로 추정. 스토리보드 파일은 프로젝트에 존재하지만 빌드에서 제외됨.
