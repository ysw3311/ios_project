import AVFoundation

final class RecordingService: NSObject {

    static let shared = RecordingService()
    private override init() {}

    private var recorder: AVAudioRecorder?
    private var levelTimer: Timer?

    var onLevelUpdate: ((Float) -> Void)?
    private(set) var isRecording = false

    // MARK: - Public

    func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard granted else { return }
                self?.beginRecording()
            }
        }
    }

    /// 녹음 중지 후 오디오 파일 URL 반환.
    /// 시뮬레이터에서는 번들의 demo.m4a를 반환 (없으면 실제 녹음 파일).
    func stopRecording() -> URL {
        stopLevelTimer()
        recorder?.stop()
        isRecording = false

        #if targetEnvironment(simulator)
        if let demoURL = Bundle.main.url(forResource: "demo", withExtension: "m4a") {
            return demoURL
        }
        #endif

        return recordingFileURL()
    }

    // MARK: - Private

    private func beginRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch { return }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            recorder = try AVAudioRecorder(url: recordingFileURL(), settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            isRecording = true
            startLevelTimer()
        } catch {}
    }

    private func recordingFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("speakup_recording.m4a")
    }

    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.recorder else { return }
            recorder.updateMeters()
            let db = recorder.averagePower(forChannel: 0)
            // -60dB ~ 0dB → 0.0 ~ 1.0
            let normalized = max(0, min(1, (db + 60) / 60))
            self.onLevelUpdate?(normalized)
        }
    }

    private func stopLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = nil
    }
}
