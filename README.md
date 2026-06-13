# SpeakUp
### 음성 분석과 AI 피드백을 활용한 iOS 발표 연습 애플리케이션

2171099 용승우

<br>

---

### 1. 프로젝트 수행 목적

#### 1.1 프로젝트 정의

* 사용자가 대본을 입력하고 발표를 녹음하면, 음성을 자동으로 분석하여 말하기 속도·침묵 구간·필러워드·대본 일치율을 점수로 피드백하는 iOS 발표 연습 앱

#### 1.2 프로젝트 배경

* 발표를 앞두고 혼자 연습할 때 스스로 어떤 점이 부족한지 파악하기 어렵다.
* 기존에는 영상을 직접 찍어 반복 시청하거나 타인의 평가에 의존해야 했다.
* 객관적인 지표(속도·침묵·필러워드)와 AI 피드백을 통해 혼자서도 발표 실력을 향상시킬 수 있는 도구가 필요하다고 판단하였다.

#### 1.3 프로젝트 목표

* **음성 녹음 및 STT** — AVFoundation으로 발표를 녹음하고 CLOVA Speech API로 텍스트로 변환
* **발표 분석** — 말하기 속도(WPM), 침묵 구간 횟수, 필러워드 빈도, 대본 일치율을 자동 산출
* **종합 점수 제공** — 4개 항목을 100점 만점으로 환산하여 원형 게이지와 바 차트로 시각화
* **AI 피드백** — Gemini 2.5 Flash 모델로 대본 vs 실제 발표를 비교 분석하여 구조화된 피드백 제공
* **기록 관리** — 워크스페이스별 연습 기록을 저장하고 점수 변화 그래프로 성장 추이 확인

---

### 2. 프로젝트 개요

#### 2.1 프로젝트 설명

* 사용자는 워크스페이스(발표 주제)를 생성하고 대본을 입력한 뒤 발표를 녹음한다.
* 녹음이 완료되면 CLOVA Speech 장문 인식 API로 음성을 텍스트로 변환한다.
* 변환된 텍스트와 원본 대본을 비교하여 대본 일치율, 말하기 속도, 침묵 구간, 필러워드를 분석하고 100점 만점의 종합 점수를 산출한다.
* Gemini 2.5 Flash API가 대본과 STT 결과를 비교하여 전반 평가·잘한 점·개선할 점·핵심 조언을 카드 형태로 제공한다.
* 연습 결과는 워크스페이스별로 저장되며 날짜별 기록 조회와 점수 변화 그래프를 제공한다.

#### 2.2 화면 구성

| 화면 | 설명 |
|------|------|
| 홈 화면 | 워크스페이스 목록, 최고 점수 및 평균 점수 확인 |
| 워크스페이스 상세 | 대본 미리보기, 연습 기록 리스트, 점수 그래프 |
| 녹음 화면 | 직접 녹음 / 파일 업로드 선택, 실시간 파형 애니메이션, 경과 타이머 |
| 결과 화면 | 종합 점수 원형 게이지, 항목별 바 차트, STT 인식 결과, 대본 대조 하이라이트, AI 피드백 카드 |
| 기록 화면 | 전체 연습 기록 날짜순 목록, 점수 변화 선 그래프 |

#### 2.3 화면 전환 구조

```
SceneDelegate
  └─ UINavigationController
        └─ HomeViewController (워크스페이스 목록)
              └─ WorkspaceDetailViewController (워크스페이스 상세)
                    └─ RecordingViewController (녹음)
                          └─ ResultViewController (분석 결과 + AI 피드백)
```

#### 2.4 점수 산출 기준

| 항목 | 배점 | 기준 |
|------|------|------|
| 대본 일치율 | 40점 | 대본 단어 중 실제로 말한 비율 |
| 말하기 속도 | 20점 | 적정 범위 120~150 WPM |
| 침묵 구간 | 20점 | 2초 이상 침묵 횟수 |
| 필러워드 | 20점 | "음", "어", "그" 감지 횟수 |

#### 2.5 AI 피드백 구조

Gemini 2.5 Flash에게 원본 대본과 STT 결과를 전달하면 다음 4개 항목을 카드 형식으로 반환한다.

```
┌─ 전반 평가 ──────────────────────┐
│ 전체적인 발표에 대한 1~2문장 평가   │
└──────────────────────────────────┘
┌─ 잘한 점 ──┐  ┌─ 개선할 점 ──────┐
│ • 항목 1   │  │ • 항목 1         │
│ • 항목 2   │  │ • 항목 2         │
└────────────┘  └──────────────────┘
┌─ 핵심 조언 ──────────────────────┐
│ 다음 연습을 위한 핵심 1문장        │
└──────────────────────────────────┘
```

---

### 3. 기대효과

* 발표 연습 결과를 객관적 수치로 확인할 수 있어 개선 방향을 스스로 파악할 수 있다.
* AI 피드백을 통해 타인의 평가 없이도 구체적인 개선점을 제공받을 수 있다.
* 연습 기록이 누적되어 장기적인 발표 실력 향상 추이를 시각적으로 확인할 수 있다.
* 파일 업로드 기능으로 실제 발표 현장 녹음도 분석할 수 있다.

---

### 4. 관련 기술

| 구분 | 설명 |
|------|------|
| Speech-To-Text | 사람이 말하는 음성 언어를 컴퓨터가 텍스트 데이터로 전환하는 기술. CLOVA Speech 장문 인식 API를 사용하여 발표 녹음 파일을 한국어 텍스트로 변환한다. |
| 자연어 처리 (NLP) | Apple NaturalLanguage 프레임워크로 대본과 STT 결과를 토크나이징하여 단어 단위 일치율을 산출한다. |
| 생성형 AI | Gemini 2.5 Flash 모델에 대본과 발표 내용을 전달하여 구조화된 JSON 형식의 피드백을 생성한다. |
| 오디오 처리 | AVFoundation을 사용하여 m4a 포맷으로 녹음하고, 실시간 음량 레벨 측정으로 파형 애니메이션을 구현한다. |
| 로컬 데이터 저장 | UserDefaults에 Codable 구조체를 직렬화하여 워크스페이스 및 연습 기록을 영구 저장한다. |

---

### 5. 개발 환경

| 항목 | 값 |
|------|-----|
| 언어 | Swift 5.4 |
| 프레임워크 | UIKit (Programmatic UI), AVFoundation, NaturalLanguage |
| 외부 API | 네이버 CLOVA Speech (장문 인식), Google Gemini 2.5 Flash |
| 데이터 저장 | UserDefaults (Codable) |
| Xcode | 12.5 |
| iOS Deployment Target | 14.5 이상 |
| 네트워킹 | URLSession (completion handler 방식) |

---

### 6. 프로젝트 구조

```
Speakup/
├── Screens/
│   ├── HomeViewController.swift          ← 워크스페이스 목록
│   ├── WorkspaceCreateViewController.swift
│   ├── WorkspaceDetailViewController.swift ← 연습 기록 및 그래프
│   ├── RecordingViewController.swift     ← 녹음 / 파일 업로드
│   ├── ResultViewController.swift        ← 점수 + AI 피드백
│   └── HistoryViewController.swift       ← 전체 기록 조회
│
├── Services/
│   ├── RecordingService.swift            ← AVAudioRecorder 래핑
│   ├── ClovaSTTService.swift             ← CLOVA Speech API
│   ├── SpeechAnalyzer.swift              ← WPM·침묵·필러워드 분석
│   └── GeminiFeedbackService.swift       ← Gemini AI 피드백
│
├── Models/
│   ├── Workspace.swift                   ← 워크스페이스 / PracticeRecord 모델
│   └── WorkspaceStore.swift              ← UserDefaults CRUD
│
└── Assets.xcassets
```

---

### 7. 데모 영상

추후 업로드 예정
