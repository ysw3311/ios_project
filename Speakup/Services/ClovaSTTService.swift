import Foundation

final class ClovaSTTService {

    static let shared = ClovaSTTService()
    private init() {}

    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["ClovaAPIKey"] as? String else { return "" }
        return key
    }

    /// 오디오 파일을 CLOVA Speech API로 전송해 인식된 텍스트를 반환.
    func transcribe(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://clovaspeech-gw.ncloud.com/recog/v1/stt?lang=Kor") else {
            completion(.failure(STTError.invalidURL))
            return
        }

        guard let audioData = try? Data(contentsOf: fileURL) else {
            completion(.failure(STTError.fileReadError))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-CLOVASPEECH-API-KEY")
        request.httpBody = audioData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = json["text"] as? String else {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                DispatchQueue.main.async {
                    completion(.failure(STTError.parseError(body)))
                }
                return
            }

            DispatchQueue.main.async { completion(.success(text)) }
        }.resume()
    }

    enum STTError: Error {
        case invalidURL
        case fileReadError
        case parseError(String)
    }
}
