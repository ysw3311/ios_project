import Foundation

struct AnalysisResult {
    let sttText: String
    let totalScore: Int
    let scriptScore: Int
    let speedScore: Int
    let silenceScore: Int
    let fillerScore: Int
}

final class SpeechAnalyzer {

    static func analyze(sttText: String,
                        script: String,
                        duration: Int,
                        audioLevels: [Float]) -> AnalysisResult {
        let scriptScore  = computeScriptScore(sttText: sttText, script: script)
        let speedScore   = computeSpeedScore(sttText: sttText, duration: duration)
        let silenceScore = computeSilenceScore(audioLevels: audioLevels)
        let fillerScore  = computeFillerScore(sttText: sttText)
        let total = scriptScore + speedScore + silenceScore + fillerScore

        return AnalysisResult(
            sttText: sttText,
            totalScore: total,
            scriptScore: scriptScore,
            speedScore: speedScore,
            silenceScore: silenceScore,
            fillerScore: fillerScore
        )
    }

    // MARK: - 대본 일치율 (40점)
    // 대본 단어 집합 대비 STT 단어 적중률

    private static func computeScriptScore(sttText: String, script: String) -> Int {
        let sttWords    = tokenize(sttText)
        let scriptWords = tokenize(script)
        guard !scriptWords.isEmpty else { return 0 }

        let sttSet    = Set(sttWords)
        let scriptSet = Set(scriptWords)
        let matched   = Double(sttSet.intersection(scriptSet).count)
        let ratio     = matched / Double(scriptSet.count)
        return min(40, Int(ratio * 40))
    }

    // MARK: - 말하기 속도 (20점)
    // 적정 범위: 분당 120~150 단어(어절)

    private static func computeSpeedScore(sttText: String, duration: Int) -> Int {
        guard duration > 0 else { return 10 }
        let words   = tokenize(sttText).count
        let minutes = Double(duration) / 60.0
        let wpm     = Double(words) / minutes

        switch wpm {
        case 120...150: return 20
        case 100..<120: return Int(10 + (wpm - 100) / 20.0 * 10)
        case 150...180: return Int(10 + (180 - wpm) / 30.0 * 10)
        default:        return max(0, 5)
        }
    }

    // MARK: - 침묵 구간 (20점)
    // 0.1초 간격 레벨 배열에서 연속 2초(20프레임) 이상 저음량 구간 카운트

    private static func computeSilenceScore(audioLevels: [Float]) -> Int {
        let silenceThreshold: Float = 0.05
        let silenceFrames = 20  // 0.1s × 20 = 2초
        var silenceCount  = 0
        var consecutive   = 0

        for level in audioLevels {
            if level < silenceThreshold {
                consecutive += 1
                if consecutive == silenceFrames { silenceCount += 1 }
            } else {
                consecutive = 0
            }
        }

        return max(0, 20 - silenceCount * 5)
    }

    // MARK: - 필러워드 (20점)
    // "음", "어", "그", "저" 등 독립 어절로 등장한 횟수 기반

    private static func computeFillerScore(sttText: String) -> Int {
        let fillers: Set<String> = ["음", "어", "그", "저", "뭐", "아", "이제"]
        let words = tokenize(sttText)
        let count = words.filter { fillers.contains($0) }.count
        return max(0, 20 - count * 2)
    }

    // MARK: - 공통

    private static func tokenize(_ text: String) -> [String] {
        text.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
    }
}
