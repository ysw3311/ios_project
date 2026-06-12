import UIKit
import AVFoundation

class RecordingViewController: UIViewController {

    var script: String = ""
    var workspaceId: String = ""

    // MARK: - Views

    private let timerLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = .monospacedDigitSystemFont(ofSize: 56, weight: .thin)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "녹음 중..."
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let waveformView = WaveformView()

    private let stopButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 40
        button.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        button.layer.borderWidth = 8
        button.translatesAutoresizingMaskIntoConstraints = false

        let square = UIView()
        square.backgroundColor = .white
        square.layer.cornerRadius = 4
        square.isUserInteractionEnabled = false
        square.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(square)
        NSLayoutConstraint.activate([
            square.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            square.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            square.widthAnchor.constraint(equalToConstant: 22),
            square.heightAnchor.constraint(equalToConstant: 22),
        ])
        return button
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = "버튼을 눌러 녹음을 중지하세요"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - State

    private var elapsedSeconds = 0
    private var timer: Timer?
    private var audioLevels: [Float] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "녹음"
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        setupLayout()
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        startRecording()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    // MARK: - Layout

    private func setupLayout() {
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        [timerLabel, statusLabel, waveformView, stopButton, hintLabel].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 8),

            waveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            waveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            waveformView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            waveformView.heightAnchor.constraint(equalToConstant: 80),

            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopButton.widthAnchor.constraint(equalToConstant: 96),
            stopButton.heightAnchor.constraint(equalToConstant: 96),
            stopButton.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 60),

            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.topAnchor.constraint(equalTo: stopButton.bottomAnchor, constant: 16),
        ])
    }

    // MARK: - Recording

    private func startRecording() {
        // 타이머 시작
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }

        // RecordingService 연동 — 레벨 콜백으로 파형 업데이트
        RecordingService.shared.onLevelUpdate = { [weak self] level in
            self?.audioLevels.append(level)
            self?.waveformView.pushLevel(level)
        }
        RecordingService.shared.startRecording()

        // 시뮬레이터: RecordingService가 마이크를 못 열 수 있으므로 더미 파형 병행
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

    // MARK: - Actions

    @objc private func stopButtonTapped() {
        timer?.invalidate()
        stopButton.isEnabled = false
        statusLabel.text = "분석 중..."
        statusLabel.textColor = .secondaryLabel

        let audioURL = RecordingService.shared.stopRecording()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            let vc = ResultViewController()
            vc.script = self.script
            vc.workspaceId = self.workspaceId
            vc.recordingDuration = self.elapsedSeconds
            vc.audioFileURL = audioURL
            vc.audioLevels = self.audioLevels
            self.navigationController?.pushViewController(vc, animated: true)
        }
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
