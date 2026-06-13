import Foundation

struct GeminiFeedback {
    let summary: String
    let strengths: [String]
    let improvements: [String]
    let tip: String
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

    func requestFeedback(script: String, sttText: String,
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
        발표 연습 피드백을 JSON으로만 답해줘. 마크다운 없이 JSON만:
        {
          "summary": "전반적 평가 1-2문장",
          "strengths": ["잘한 점 1", "잘한 점 2"],
          "improvements": ["개선할 점 1", "개선할 점 2"],
          "tip": "핵심 조언 1문장"
        }

        [원본 대본]
        \(script.isEmpty ? "(대본 없음)" : script)

        [실제 발표 내용 (STT 인식)]
        \(sttText.isEmpty ? "(인식된 텍스트 없음)" : sttText)
        """

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]]
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(FeedbackError.encodingError))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

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
                DispatchQueue.main.async {
                    completion(.failure(FeedbackError.parseError(body)))
                }
                return
            }

            // JSON 블록 제거 (```json ... ``` 대응)
            let cleaned = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let jsonData = cleaned.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                DispatchQueue.main.async {
                    completion(.failure(FeedbackError.parseError(text)))
                }
                return
            }

            let feedback = GeminiFeedback(
                summary: parsed["summary"] as? String ?? "",
                strengths: parsed["strengths"] as? [String] ?? [],
                improvements: parsed["improvements"] as? [String] ?? [],
                tip: parsed["tip"] as? String ?? ""
            )
            DispatchQueue.main.async { completion(.success(feedback)) }
        }.resume()
    }

    enum FeedbackError: LocalizedError {
        case noAPIKey
        case invalidURL
        case encodingError
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "Gemini API 키가 Config.plist에 없습니다"
            case .invalidURL: return "잘못된 URL"
            case .encodingError: return "요청 인코딩 실패"
            case .parseError(let b): return "응답 파싱 실패: \(b)"
            }
        }
    }
}
