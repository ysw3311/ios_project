import UIKit

class ResultViewController: UIViewController {

    var script: String = ""
    var workspaceId: String = ""
    var recordingDuration: Int = 0
    var audioFileURL: URL?
    var audioLevels: [Float] = []

    private var totalScore: Int = 0
    private var scriptScore: Int = 0
    private var speedScore: Int = 0
    private var silenceScore: Int = 0
    private var fillerScore: Int = 0

    // MARK: - Views

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let scoreCircleView = CircleScoreView()
    private var scoreBarViews: [ScoreBarView] = []
    private var barStack: UIStackView!

    private let sttCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let sttLabel: UILabel = {
        let l = UILabel()
        l.text = "STT 인식 결과"
        l.font = .boldSystemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let sttTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.font = .systemFont(ofSize: 14)
        tv.backgroundColor = .clear
        tv.text = "—"
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let comparisonCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let comparisonTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "대본 대조"
        l.font = .boldSystemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let comparisonLegend: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(string: "● ", attributes: [.foregroundColor: UIColor.systemGreen]))
        attr.append(NSAttributedString(string: "말한 단어  "))
        attr.append(NSAttributedString(string: "● ", attributes: [.foregroundColor: UIColor.systemRed]))
        attr.append(NSAttributedString(string: "빠진 단어"))
        l.attributedText = attr
        return l
    }()

    private let comparisonTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("발표로 돌아가기", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 16)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - AI 피드백 뷰
    private let feedbackSection: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let feedbackSpinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    private let feedbackSpinnerLabel: UILabel = {
        let l = UILabel()
        l.text = "AI 피드백 생성 중..."
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let feedbackStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 10
        sv.isHidden = true
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }

    // 로딩 오버레이
    private let loadingView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "분석 결과"
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true

        setupLayout()
        showLoading(true)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        runAnalysis()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 로딩이 끝난 후 animateResults() 에서 처리
    }

    // MARK: - Analysis

    private func runAnalysis() {
        guard let url = audioFileURL else {
            applyDummyScores()
            return
        }

        ClovaSTTService.shared.transcribe(fileURL: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let text):
                let analysis = SpeechAnalyzer.analyze(
                    sttText: text,
                    script: self.script,
                    duration: self.recordingDuration,
                    audioLevels: self.audioLevels
                )
                self.applyAnalysis(analysis)
            case .failure(let error):
                let alert = UIAlertController(
                    title: "STT 분석 실패",
                    message: "음성 인식에 실패했습니다.\n\(error.localizedDescription)\n\n더미 점수로 결과를 표시합니다.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self.present(alert, animated: true)
                self.applyDummyScores(errorMessage: error.localizedDescription)
            }
        }
    }

    private func applyAnalysis(_ result: AnalysisResult) {
        totalScore   = result.totalScore
        scriptScore  = result.scriptScore
        speedScore   = result.speedScore
        silenceScore = result.silenceScore
        fillerScore  = result.fillerScore
        sttTextView.text = result.sttText.isEmpty ? "(인식된 텍스트 없음)" : result.sttText
        comparisonTextView.attributedText = buildComparisonAttributed(script: script, sttText: result.sttText)
        finishAnalysis()
        requestGeminiFeedback(sttText: result.sttText)
    }

    private func requestGeminiFeedback(sttText: String) {
        feedbackSpinner.startAnimating()
        GeminiFeedbackService.shared.requestFeedback(script: script, sttText: sttText) { [weak self] result in
            guard let self = self else { return }
            self.feedbackSpinner.stopAnimating()
            self.feedbackSpinnerLabel.isHidden = true
            switch result {
            case .success(let feedback):
                self.showFeedback(feedback)
            case .failure:
                self.feedbackSection.isHidden = true
            }
        }
    }

    private func showFeedback(_ feedback: GeminiFeedback) {
        feedbackStack.isHidden = false

        // 요약 카드
        feedbackStack.addArrangedSubview(makeFeedbackCard(
            title: "전반 평가", body: feedback.summary, color: .systemBlue
        ))

        // 잘한 점 + 개선점 나란히
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 10
        row.distribution = .fillEqually
        row.addArrangedSubview(makeFeedbackCard(
            title: "잘한 점", bullets: feedback.strengths, color: .systemGreen
        ))
        row.addArrangedSubview(makeFeedbackCard(
            title: "개선할 점", bullets: feedback.improvements, color: .systemOrange
        ))
        feedbackStack.addArrangedSubview(row)

        // 핵심 조언 카드
        feedbackStack.addArrangedSubview(makeFeedbackCard(
            title: "핵심 조언", body: feedback.tip, color: .systemPurple
        ))
    }

    private func makeFeedbackCard(title: String, body: String = "", bullets: [String] = [], color: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = color.withAlphaComponent(0.08)
        card.layer.cornerRadius = 12
        card.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        card.layer.borderWidth = 1
        card.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 13)
        titleLabel.textColor = color
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let bodyLabel = UILabel()
        bodyLabel.numberOfLines = 0
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .label
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        if !body.isEmpty {
            bodyLabel.text = body
        } else {
            bodyLabel.text = bullets.map { "• \($0)" }.joined(separator: "\n")
        }

        card.addSubview(titleLabel)
        card.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            bodyLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            bodyLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            bodyLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
        ])
        return card
    }

    private func applyDummyScores(errorMessage: String = "") {
        scriptScore  = Int.random(in: 20...40)
        speedScore   = Int.random(in: 10...20)
        silenceScore = Int.random(in: 10...20)
        fillerScore  = Int.random(in: 10...20)
        totalScore   = scriptScore + speedScore + silenceScore + fillerScore
        sttTextView.text = errorMessage.isEmpty
            ? "(STT 미연결 — 더미 점수)"
            : "STT 오류: \(errorMessage)"
        comparisonTextView.text = "(대본 대조를 위해 STT 연결이 필요해요)"
        finishAnalysis()
    }

    private func buildComparisonAttributed(script: String, sttText: String) -> NSAttributedString {
        guard !script.isEmpty else {
            return NSAttributedString(string: "(대본 없음)")
        }

        let sttTokens = Set(
            sttText.components(separatedBy: .whitespacesAndNewlines)
                .map { $0.trimmingCharacters(in: .punctuationCharacters) }
                .filter { !$0.isEmpty }
        )

        let scriptWords = script.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        let font = UIFont.systemFont(ofSize: 15)
        let result = NSMutableAttributedString()

        for (i, word) in scriptWords.enumerated() {
            let clean = word.trimmingCharacters(in: .punctuationCharacters)
            let matched = sttTokens.contains(clean)
            let color: UIColor = matched ? .systemGreen : .systemRed
            let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: color, .font: font]
            result.append(NSAttributedString(string: word, attributes: attrs))
            if i < scriptWords.count - 1 {
                result.append(NSAttributedString(string: " ", attributes: [.font: font]))
            }
        }
        return result
    }

    private func finishAnalysis() {
        saveRecord()
        rebuildBars()
        showLoading(false)
        animateResults()
    }

    private func saveRecord() {
        guard !workspaceId.isEmpty else { return }
        let record = PracticeRecord(
            id: UUID().uuidString,
            date: Date(),
            totalScore: totalScore,
            scriptScore: scriptScore,
            speedScore: speedScore,
            silenceScore: silenceScore,
            fillerScore: fillerScore,
            duration: recordingDuration
        )
        WorkspaceStore.shared.addRecord(record, toWorkspaceId: workspaceId)
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        scoreCircleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scoreCircleView)

        let sectionLabel = UILabel()
        sectionLabel.text = "항목별 점수"
        sectionLabel.font = .boldSystemFont(ofSize: 17)
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sectionLabel)

        barStack = UIStackView()
        barStack.axis = .vertical
        barStack.spacing = 16
        barStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(barStack)

        // STT 카드
        sttCard.addSubview(sttLabel)
        sttCard.addSubview(sttTextView)
        contentView.addSubview(sttCard)

        // 대본 대조 카드
        comparisonCard.addSubview(comparisonTitleLabel)
        comparisonCard.addSubview(comparisonLegend)
        comparisonCard.addSubview(comparisonTextView)
        contentView.addSubview(comparisonCard)

        // AI 피드백 섹션
        let feedbackTitleLabel = UILabel()
        feedbackTitleLabel.text = "AI 피드백"
        feedbackTitleLabel.font = .boldSystemFont(ofSize: 17)
        feedbackTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        feedbackSection.addSubview(feedbackTitleLabel)
        feedbackSection.addSubview(feedbackSpinner)
        feedbackSection.addSubview(feedbackSpinnerLabel)
        feedbackSection.addSubview(feedbackStack)
        contentView.addSubview(feedbackSection)

        NSLayoutConstraint.activate([
            feedbackTitleLabel.topAnchor.constraint(equalTo: feedbackSection.topAnchor),
            feedbackTitleLabel.leadingAnchor.constraint(equalTo: feedbackSection.leadingAnchor),

            feedbackSpinner.topAnchor.constraint(equalTo: feedbackTitleLabel.bottomAnchor, constant: 12),
            feedbackSpinner.leadingAnchor.constraint(equalTo: feedbackSection.leadingAnchor),

            feedbackSpinnerLabel.centerYAnchor.constraint(equalTo: feedbackSpinner.centerYAnchor),
            feedbackSpinnerLabel.leadingAnchor.constraint(equalTo: feedbackSpinner.trailingAnchor, constant: 8),

            feedbackStack.topAnchor.constraint(equalTo: feedbackTitleLabel.bottomAnchor, constant: 10),
            feedbackStack.leadingAnchor.constraint(equalTo: feedbackSection.leadingAnchor),
            feedbackStack.trailingAnchor.constraint(equalTo: feedbackSection.trailingAnchor),
            feedbackStack.bottomAnchor.constraint(equalTo: feedbackSection.bottomAnchor),
        ])

        contentView.addSubview(backButton)

        NSLayoutConstraint.activate([
            scoreCircleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            scoreCircleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            scoreCircleView.widthAnchor.constraint(equalToConstant: 160),
            scoreCircleView.heightAnchor.constraint(equalToConstant: 160),

            sectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            sectionLabel.topAnchor.constraint(equalTo: scoreCircleView.bottomAnchor, constant: 32),

            barStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            barStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            barStack.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 16),

            // STT 카드
            sttCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            sttCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            sttCard.topAnchor.constraint(equalTo: barStack.bottomAnchor, constant: 28),

            sttLabel.leadingAnchor.constraint(equalTo: sttCard.leadingAnchor, constant: 12),
            sttLabel.topAnchor.constraint(equalTo: sttCard.topAnchor, constant: 12),
            sttLabel.trailingAnchor.constraint(equalTo: sttCard.trailingAnchor, constant: -12),

            sttTextView.leadingAnchor.constraint(equalTo: sttCard.leadingAnchor, constant: 8),
            sttTextView.trailingAnchor.constraint(equalTo: sttCard.trailingAnchor, constant: -8),
            sttTextView.topAnchor.constraint(equalTo: sttLabel.bottomAnchor, constant: 4),
            sttTextView.bottomAnchor.constraint(equalTo: sttCard.bottomAnchor, constant: -8),

            // 대본 대조 카드
            comparisonCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            comparisonCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            comparisonCard.topAnchor.constraint(equalTo: sttCard.bottomAnchor, constant: 16),

            comparisonTitleLabel.leadingAnchor.constraint(equalTo: comparisonCard.leadingAnchor, constant: 12),
            comparisonTitleLabel.topAnchor.constraint(equalTo: comparisonCard.topAnchor, constant: 12),

            comparisonLegend.trailingAnchor.constraint(equalTo: comparisonCard.trailingAnchor, constant: -12),
            comparisonLegend.centerYAnchor.constraint(equalTo: comparisonTitleLabel.centerYAnchor),

            comparisonTextView.leadingAnchor.constraint(equalTo: comparisonCard.leadingAnchor, constant: 8),
            comparisonTextView.trailingAnchor.constraint(equalTo: comparisonCard.trailingAnchor, constant: -8),
            comparisonTextView.topAnchor.constraint(equalTo: comparisonTitleLabel.bottomAnchor, constant: 8),
            comparisonTextView.bottomAnchor.constraint(equalTo: comparisonCard.bottomAnchor, constant: -8),

            feedbackSection.topAnchor.constraint(equalTo: comparisonCard.bottomAnchor, constant: 28),
            feedbackSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            feedbackSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            backButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            backButton.topAnchor.constraint(equalTo: feedbackSection.bottomAnchor, constant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 52),
            backButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
        ])

        // 로딩 오버레이 (가장 위에)
        view.addSubview(loadingView)
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false

        let loadingLabel = UILabel()
        loadingLabel.text = "발표를 분석하고 있어요..."
        loadingLabel.font = .systemFont(ofSize: 15)
        loadingLabel.textColor = .secondaryLabel
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false

        loadingView.addSubview(spinner)
        loadingView.addSubview(loadingLabel)

        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -20),

            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
        ])
    }

    private func rebuildBars() {
        barStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        scoreBarViews.removeAll()

        let items: [(String, Int, Int)] = [
            ("대본 일치율", scriptScore, 40),
            ("말하기 속도", speedScore, 20),
            ("침묵 구간",  silenceScore, 20),
            ("필러워드",   fillerScore, 20),
        ]
        for (title, score, max) in items {
            let bar = ScoreBarView(title: title, score: score, maxScore: max)
            scoreBarViews.append(bar)
            barStack.addArrangedSubview(bar)
        }
    }

    private func showLoading(_ loading: Bool) {
        loadingView.isHidden = !loading
    }

    private func animateResults() {
        scoreCircleView.animate(to: totalScore)
        scoreBarViews.forEach { $0.animateBar() }
    }

    // MARK: - Actions

    @objc private func backTapped() {
        if let vc = navigationController?.viewControllers.first(where: { $0 is WorkspaceDetailViewController }) {
            navigationController?.popToViewController(vc, animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
}

// MARK: - CircleScoreView

class CircleScoreView: UIView {

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.text = "0"
        l.font = .boldSystemFont(ofSize: 40)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let pointLabel: UILabel = {
        let l = UILabel()
        l.text = "점"
        l.font = .systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(scoreLabel)
        addSubview(pointLabel)
        NSLayoutConstraint.activate([
            scoreLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            scoreLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),
            pointLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            pointLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 2),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayers()
    }

    private func setupLayers() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.width / 2 - 10
        let path = UIBezierPath(arcCenter: center, radius: radius,
                                startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)

        [trackLayer, progressLayer].forEach { $0.removeFromSuperlayer() }

        trackLayer.path = path.cgPath
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.secondarySystemBackground.cgColor
        trackLayer.lineWidth = 12
        layer.addSublayer(trackLayer)

        progressLayer.path = path.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.systemBlue.cgColor
        progressLayer.lineWidth = 12
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }

    func animate(to score: Int) {
        scoreLabel.text = "\(score)"
        let fraction = CGFloat(score) / 100.0
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = 0
        anim.toValue = fraction
        anim.duration = 1.0
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        progressLayer.strokeEnd = fraction
        progressLayer.add(anim, forKey: "progress")
        progressLayer.strokeColor = (score >= 80 ? UIColor.systemGreen
                                     : score >= 60 ? .systemOrange : .systemRed).cgColor
    }
}

// MARK: - ScoreBarView

class ScoreBarView: UIView {

    private let fillView = UIView()
    private var fillConstraint: NSLayoutConstraint?
    private let score: Int
    private let maxScore: Int

    init(title: String, score: Int, maxScore: Int) {
        self.score = score
        self.maxScore = maxScore
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let scoreLabel = UILabel()
        scoreLabel.text = "\(score) / \(maxScore)"
        scoreLabel.font = .boldSystemFont(ofSize: 14)
        scoreLabel.textColor = .secondaryLabel
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false

        let track = UIView()
        track.backgroundColor = .secondarySystemBackground
        track.layer.cornerRadius = 4
        track.translatesAutoresizingMaskIntoConstraints = false

        fillView.backgroundColor = .systemBlue
        fillView.layer.cornerRadius = 4
        fillView.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(fillView)

        [titleLabel, scoreLabel, track].forEach { addSubview($0) }
        fillConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),

            scoreLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            scoreLabel.topAnchor.constraint(equalTo: topAnchor),

            track.leadingAnchor.constraint(equalTo: leadingAnchor),
            track.trailingAnchor.constraint(equalTo: trailingAnchor),
            track.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            track.heightAnchor.constraint(equalToConstant: 8),
            track.bottomAnchor.constraint(equalTo: bottomAnchor),

            fillView.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fillView.topAnchor.constraint(equalTo: track.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fillConstraint!,
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func animateBar() {
        layoutIfNeeded()
        let fraction = CGFloat(score) / CGFloat(maxScore)
        fillConstraint?.isActive = false
        fillConstraint = fillView.widthAnchor.constraint(
            equalTo: fillView.superview!.widthAnchor, multiplier: fraction)
        fillConstraint?.isActive = true
        UIView.animate(withDuration: 0.8, delay: 0, options: .curveEaseOut) {
            self.layoutIfNeeded()
        }
    }
}
