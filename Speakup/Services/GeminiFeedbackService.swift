import Foundation

struct GeminiFeedback {
    struct Section {
        let summary: String
        let improvements: [String]
        let tip: String
    }
    let script: Section  // 대사 피드백
    let tone: Section    // 톤 피드백
}

final class GeminiFeedbackService {

    static let shared = GeminiFeedbackService()
    private init() {}

    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GeminiAPIKey"] as? String else { return "" }
        return key
    }

    func requestFeedback(script: String,
                         sttText: String,
                         audioFileURL: URL?,
                         completion: @escaping (Result<GeminiFeedback, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(FeedbackError.noAPIKey))
            return
        }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(.failure(FeedbackError.invalidURL))
            return
        }

        let prompt = """
        발표 음성과 대본을 분석해서 아래 JSON 형식으로만 답해줘. 마크다운 없이 JSON만:
        {
          "script_feedback": {
            "summary": "대사 전반 평가 1-2문장",
            "improvements": ["대사 개선점 1", "대사 개선점 2"],
            "tip": "대사 핵심 조언 1문장"
          },
          "tone_feedback": {
            "summary": "목소리 톤 전반 평가 1-2문장",
            "improvements": ["톤 개선점 1", "톤 개선점 2"],
            "tip": "톤 핵심 조언 1문장"
          }
        }

        [원본 대본]
        \(script.isEmpty ? "(대본 없음)" : script)

        [실제 발표 내용 (STT 인식)]
        \(sttText.isEmpty ? "(인식된 텍스트 없음)" : sttText)
        """

        // 오디오가 있으면 인라인 데이터로 포함 (톤 분석용)
        var parts: [[String: Any]] = []

        if let audioURL = audioFileURL,
           let audioData = try? Data(contentsOf: audioURL),
           !audioData.isEmpty {
            let base64Audio = audioData.base64EncodedString()
            parts.append([
                "inlineData": [
                    "mimeType": "audio/mp4",
                    "data": base64Audio
                ]
            ])
        }

        parts.append(["text": prompt])

        let body: [String: Any] = [
            "contents": [["parts": parts]]
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(FeedbackError.encodingError))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        request.timeoutInterval = 60

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let text = parts.first?["text"] as? String else {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                DispatchQueue.main.async { completion(.failure(FeedbackError.parseError(body))) }
                return
            }

            let cleaned = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let jsonData = cleaned.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let scriptRaw = parsed["script_feedback"] as? [String: Any],
                  let toneRaw   = parsed["tone_feedback"]   as? [String: Any] else {
                DispatchQueue.main.async { completion(.failure(FeedbackError.parseError(text))) }
                return
            }

            let feedback = GeminiFeedback(
                script: .init(
                    summary:      scriptRaw["summary"]      as? String   ?? "",
                    improvements: scriptRaw["improvements"] as? [String] ?? [],
                    tip:          scriptRaw["tip"]          as? String   ?? ""
                ),
                tone: .init(
                    summary:      toneRaw["summary"]      as? String   ?? "",
                    improvements: toneRaw["improvements"] as? [String] ?? [],
                    tip:          toneRaw["tip"]          as? String   ?? ""
                )
            )
            DispatchQueue.main.async { completion(.success(feedback)) }
        }.resume()
    }

    enum FeedbackError: LocalizedError {
        case noAPIKey, invalidURL, encodingError
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey:          return "Gemini API 키가 Config.plist에 없습니다"
            case .invalidURL:        return "잘못된 URL"
            case .encodingError:     return "요청 인코딩 실패"
            case .parseError(let b): return "응답 파싱 실패: \(b)"
            }
        }
    }
}
