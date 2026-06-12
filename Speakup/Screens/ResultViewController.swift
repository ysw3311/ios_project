import UIKit

class ResultViewController: UIViewController {

    var script: String = ""
    var workspaceId: String = ""
    var recordingDuration: Int = 0

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

    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("발표로 돌아가기", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var scoreBarViews: [ScoreBarView] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "분석 결과"
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        computeDummyScores()
        saveRecord()
        setupLayout()
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scoreCircleView.animate(to: totalScore)
        scoreBarViews.forEach { $0.animateBar() }
    }

    // MARK: - Score Computation (더미 — 추후 실제 분석으로 교체)

    private func computeDummyScores() {
        scriptScore = Int.random(in: 20...40)
        speedScore = Int.random(in: 10...20)
        silenceScore = Int.random(in: 10...20)
        fillerScore = Int.random(in: 10...20)
        totalScore = scriptScore + speedScore + silenceScore + fillerScore
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

        let items: [(String, Int, Int)] = [
            ("대본 일치율", scriptScore, 40),
            ("말하기 속도", speedScore, 20),
            ("침묵 구간", silenceScore, 20),
            ("필러워드", fillerScore, 20),
        ]
        let barStack = UIStackView()
        barStack.axis = .vertical
        barStack.spacing = 16
        barStack.translatesAutoresizingMaskIntoConstraints = false

        for (title, score, maxScore) in items {
            let barView = ScoreBarView(title: title, score: score, maxScore: maxScore)
            scoreBarViews.append(barView)
            barStack.addArrangedSubview(barView)
        }
        contentView.addSubview(barStack)

        let sectionLabel = UILabel()
        sectionLabel.text = "항목별 점수"
        sectionLabel.font = .boldSystemFont(ofSize: 17)
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sectionLabel)

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

            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            backButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            backButton.topAnchor.constraint(equalTo: barStack.bottomAnchor, constant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 52),
            backButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
        ])
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
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
        let label = UILabel()
        label.text = "0"
        label.font = .boldSystemFont(ofSize: 40)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let pointLabel: UILabel = {
        let label = UILabel()
        label.text = "점"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        let path = UIBezierPath(arcCenter: center, radius: radius,
                                startAngle: startAngle, endAngle: endAngle, clockwise: true)

        trackLayer.path = path.cgPath
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.secondarySystemBackground.cgColor
        trackLayer.lineWidth = 12
        trackLayer.removeFromSuperlayer()
        layer.addSublayer(trackLayer)

        progressLayer.path = path.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.systemBlue.cgColor
        progressLayer.lineWidth = 12
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        progressLayer.removeFromSuperlayer()
        layer.addSublayer(progressLayer)
    }

    func animate(to score: Int) {
        scoreLabel.text = "\(score)"
        let fraction = CGFloat(score) / 100.0
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = fraction
        animation.duration = 1.0
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        progressLayer.strokeEnd = fraction
        progressLayer.add(animation, forKey: "progress")

        let color: UIColor = score >= 80 ? .systemGreen : score >= 60 ? .systemOrange : .systemRed
        progressLayer.strokeColor = color.cgColor
    }
}

// MARK: - ScoreBarView

class ScoreBarView: UIView {

    private let titleLabel = UILabel()
    private let scoreLabel = UILabel()
    private let trackView = UIView()
    private let fillView = UIView()
    private var fillConstraint: NSLayoutConstraint?

    private let score: Int
    private let maxScore: Int

    init(title: String, score: Int, maxScore: Int) {
        self.score = score
        self.maxScore = maxScore
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupViews(title: title)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews(title: String) {
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        scoreLabel.text = "\(score) / \(maxScore)"
        scoreLabel.font = .boldSystemFont(ofSize: 14)
        scoreLabel.textColor = .secondaryLabel
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false

        trackView.backgroundColor = .secondarySystemBackground
        trackView.layer.cornerRadius = 4
        trackView.translatesAutoresizingMaskIntoConstraints = false

        fillView.backgroundColor = .systemBlue
        fillView.layer.cornerRadius = 4
        fillView.translatesAutoresizingMaskIntoConstraints = false
        trackView.addSubview(fillView)

        [titleLabel, scoreLabel, trackView].forEach { addSubview($0) }

        fillConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),

            scoreLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            scoreLabel.topAnchor.constraint(equalTo: topAnchor),

            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            trackView.heightAnchor.constraint(equalToConstant: 8),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            fillConstraint!,
        ])
    }

    func animateBar() {
        layoutIfNeeded()
        let fraction = CGFloat(score) / CGFloat(maxScore)
        fillConstraint?.isActive = false
        fillConstraint = fillView.widthAnchor.constraint(equalTo: trackView.widthAnchor, multiplier: fraction)
        fillConstraint?.isActive = true
        UIView.animate(withDuration: 0.8, delay: 0, options: .curveEaseOut) {
            self.layoutIfNeeded()
        }
    }
}
