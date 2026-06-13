import Foundation

final class ClovaSTTService {

    static let shared = ClovaSTTService()
    private init() {}

    private var config: NSDictionary? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else { return nil }
        return NSDictionary(contentsOfFile: path)
    }

    private var apiKey: String { config?["ClovaAPIKey"] as? String ?? "" }
    private var invokeURLString: String {
        (config?["ClovaInvokeURL"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func transcribe(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let urlString = invokeURLString.isEmpty
            ? "https://clovaspeech-gw.ncloud.com/recog/v1/stt?lang=Kor"
            : invokeURLString + "?lang=Kor"

        print("🌐 STT URL:", urlString)
        print("🔑 API Key:", apiKey.isEmpty ? "(없음)" : apiKey.prefix(8).description + "...")

        guard let url = URL(string: urlString) else {
            print("❌ URL 파싱 실패:", urlString)
            completion(.failure(STTError.invalidURL(urlString)))
            return
        }

        guard let audioData = try? Data(contentsOf: fileURL), !audioData.isEmpty else {
            print("❌ 오디오 파일 읽기 실패:", fileURL.path)
            completion(.failure(STTError.fileReadError(fileURL.path)))
            return
        }

        print("📤 오디오 전송 중... (\(audioData.count) bytes)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        // invoke URL 방식은 URL 자체에 인증 포함 → API Key 헤더 불필요
        if invokeURLString.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-CLOVASPEECH-API-KEY")
        }
        request.httpBody = audioData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 네트워크 에러:", error.localizedDescription)
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            if let http = response as? HTTPURLResponse {
                print("📦 HTTP 상태코드:", http.statusCode)
            }

            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
            print("📦 응답 본문:", body)

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = json["text"] as? String else {
                DispatchQueue.main.async {
                    completion(.failure(STTError.parseError(body)))
                }
                return
            }

            print("✅ STT 결과:", text)
            DispatchQueue.main.async { completion(.success(text)) }
        }.resume()
    }

    enum STTError: LocalizedError {
        case invalidURL(String)
        case fileReadError(String)
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL(let u):  return "URL 오류: \(u)"
            case .fileReadError(let p): return "파일 읽기 실패: \(p)"
            case .parseError(let b):  return "응답 파싱 실패: \(b)"
            }
        }
    }
}
