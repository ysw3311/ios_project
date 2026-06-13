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
            : invokeURLString

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

        let request: URLRequest
        if invokeURLString.isEmpty {
            // 단문 인식: octet-stream + API Key 헤더
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            req.setValue(apiKey, forHTTPHeaderField: "X-CLOVASPEECH-API-KEY")
            req.httpBody = audioData
            request = req
        } else {
            // 장문 인식 invoke URL: multipart/form-data (인증은 URL에 포함)
            let boundary = "Boundary-\(UUID().uuidString)"
            var body = Data()
            let filename = fileURL.lastPathComponent

            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"media\"; filename=\"\(filename)\"\r\n")
            body.appendString("Content-Type: application/octet-stream\r\n\r\n")
            body.append(audioData)
            body.appendString("\r\n--\(boundary)--\r\n")

            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
            request = req
        }

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
            case .invalidURL(let u):    return "URL 오류: \(u)"
            case .fileReadError(let p): return "파일 읽기 실패: \(p)"
            case .parseError(let b):    return "응답 파싱 실패: \(b)"
            }
        }
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}
