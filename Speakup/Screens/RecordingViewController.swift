import UIKit
import AVFoundation
import UniformTypeIdentifiers

class RecordingViewController: UIViewController {

    var script: String = ""
    var workspaceId: String = ""

    // MARK: - Selection UI

    private let selectionStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Recording UI

    private let recordingContainer: UIView = {
        let v = UIView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let timerLabel: UILabel = {
        let l = UILabel()
        l.text = "00:00"
        l.font = .monospacedDigitSystemFont(ofSize: 56, weight: .thin)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.text = "녹음 중..."
        l.font = .systemFont(ofSize: 16)
        l.textColor = .systemRed
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let waveformView = WaveformView()

    private let stopButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .systemRed
        btn.layer.cornerRadius = 40
        btn.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        btn.layer.borderWidth = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        let square = UIView()
        square.backgroundColor = .white
        square.layer.cornerRadius = 4
        square.isUserInteractionEnabled = false
        square.translatesAutoresizingMaskIntoConstraints = false
        btn.addSubview(square)
        NSLayoutConstraint.activate([
            square.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            square.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
            square.widthAnchor.constraint(equalToConstant: 22),
            square.heightAnchor.constraint(equalToConstant: 22),
        ])
        return btn
    }()

    private let stopHintLabel: UILabel = {
        let l = UILabel()
        l.text = "버튼을 눌러 녹음을 중지하세요"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - State

    private var elapsedSeconds = 0
    private var timer: Timer?
    private var audioLevels: [Float] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "연습 시작"
        view.backgroundColor = .systemBackground
        setupSelectionLayout()
        setupRecordingLayout()
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    // MARK: - Selection Layout

    private func setupSelectionLayout() {
        let titleLabel = UILabel()
        titleLabel.text = "어떻게 연습할까요?"
        titleLabel.font = .boldSystemFont(ofSize: 22)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "직접 말하거나 녹음 파일을 업로드하세요"
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let micCard  = makeOptionCard(icon: "🎙️", title: "직접 녹음하기",   desc: "마이크로 발표 연습을 시작해요", action: #selector(startRecordingTapped))
        let fileCard = makeOptionCard(icon: "📁", title: "파일 업로드하기", desc: "녹음 파일을 골라서 분석해요",    action: #selector(fileButtonTapped))

        selectionStack.addArrangedSubview(micCard)
        selectionStack.addArrangedSubview(fileCard)

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(selectionStack)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),

            selectionStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            selectionStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            selectionStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 36),
        ])
    }

    private func makeOptionCard(icon: String, title: String, desc: String, action: Selector) -> UIView {
        let card = UIButton(type: .system)
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addTarget(self, action: action, for: .touchUpInside)

        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 36)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let descLabel = UILabel()
        descLabel.text = desc
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        let arrowLabel = UILabel()
        arrowLabel.text = "›"
        arrowLabel.font = .systemFont(ofSize: 24)
        arrowLabel.textColor = .tertiaryLabel
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false

        [iconLabel, titleLabel, descLabel, arrowLabel].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 88),

            iconLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            iconLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: card.centerYAnchor, constant: -20),

            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            arrowLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            arrowLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])

        return card
    }

    // MARK: - Recording Layout

    private func setupRecordingLayout() {
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        recordingContainer.addSubview(timerLabel)
        recordingContainer.addSubview(statusLabel)
        recordingContainer.addSubview(waveformView)
        recordingContainer.addSubview(stopButton)
        recordingContainer.addSubview(stopHintLabel)
        view.addSubview(recordingContainer)

        NSLayoutConstraint.activate([
            recordingContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            recordingContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            recordingContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            recordingContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            timerLabel.centerXAnchor.constraint(equalTo: recordingContainer.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: recordingContainer.topAnchor, constant: 60),

            statusLabel.centerXAnchor.constraint(equalTo: recordingContainer.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 8),

            waveformView.leadingAnchor.constraint(equalTo: recordingContainer.leadingAnchor, constant: 24),
            waveformView.trailingAnchor.constraint(equalTo: recordingContainer.trailingAnchor, constant: -24),
            waveformView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            waveformView.heightAnchor.constraint(equalToConstant: 80),

            stopButton.centerXAnchor.constraint(equalTo: recordingContainer.centerXAnchor),
            stopButton.widthAnchor.constraint(equalToConstant: 96),
            stopButton.heightAnchor.constraint(equalToConstant: 96),
            stopButton.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 60),

            stopHintLabel.centerXAnchor.constraint(equalTo: recordingContainer.centerXAnchor),
            stopHintLabel.topAnchor.constraint(equalTo: stopButton.bottomAnchor, constant: 16),
        ])
    }

    // MARK: - Actions

    @objc private func startRecordingTapped() {
        selectionStack.isHidden = true
        // selectionStack의 형제 뷰(titleLabel, subtitleLabel)도 숨김
        for sub in view.subviews where sub != recordingContainer {
            sub.isHidden = true
        }
        recordingContainer.isHidden = false
        navigationItem.hidesBackButton = true
        title = "녹음"
        startRecording()
    }

    @objc private func fileButtonTapped() {
        let types: [UTType] = [.audio, .mpeg4Audio, .mp3]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    @objc private func stopButtonTapped() {
        timer?.invalidate()
        stopButton.isEnabled = false
        statusLabel.text = "분석 중..."
        statusLabel.textColor = .secondaryLabel

        let audioURL = RecordingService.shared.stopRecording()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.pushResult(audioURL: audioURL, duration: self.elapsedSeconds)
        }
    }

    // MARK: - Recording

    private func startRecording() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }

        RecordingService.shared.onLevelUpdate = { [weak self] level in
            self?.audioLevels.append(level)
            self?.waveformView.pushLevel(level)
        }
        RecordingService.shared.startRecording()

        #if targetEnvironment(simulator)
        Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] t in
            guard let self = self, self.navigationController?.topViewController == self else {
                t.invalidate(); return
            }
            let level = Float.random(in: 0.2...0.9)
            self.audioLevels.append(level)
            self.waveformView.pushLevel(level)
        }
        #endif
    }

    private func tick() {
        elapsedSeconds += 1
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", m, s)
    }

    private func pushResult(audioURL: URL, duration: Int) {
        let vc = ResultViewController()
        vc.script = self.script
        vc.workspaceId = self.workspaceId
        vc.recordingDuration = duration
        vc.audioFileURL = audioURL
        vc.audioLevels = self.audioLevels
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate

extension RecordingViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let srcURL = urls.first else { return }

        let accessing = srcURL.startAccessingSecurityScopedResource()
        defer { if accessing { srcURL.stopAccessingSecurityScopedResource() } }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(srcURL.lastPathComponent)
        try? FileManager.default.removeItem(at: tempURL)
        do {
            try FileManager.default.copyItem(at: srcURL, to: tempURL)
        } catch {
            let alert = UIAlertController(title: "오류", message: "파일을 읽을 수 없어요: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        let asset = AVURLAsset(url: tempURL)
        let duration = max(Int(CMTimeGetSeconds(asset.duration)), 1)

        pushResult(audioURL: tempURL, duration: duration)
    }
}

// MARK: - WaveformView

class WaveformView: UIView {

    private var levels: [CGFloat] = Array(repeating: 0.3, count: 30)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func pushLevel(_ level: Float) {
        levels.removeFirst()
        levels.append(CGFloat(level))
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        let count = CGFloat(levels.count)
        let totalSpacing = rect.width * 0.3
        let barWidth = (rect.width - totalSpacing) / count
        let gap = totalSpacing / count

        UIColor.systemBlue.setFill()
        for (i, level) in levels.enumerated() {
            let barHeight = max(4, level * rect.height)
            let x = CGFloat(i) * (barWidth + gap)
            let y = (rect.height - barHeight) / 2
            UIBezierPath(roundedRect: CGRect(x: x, y: y, width: barWidth, height: barHeight),
                         cornerRadius: 2).fill()
        }
    }
}
