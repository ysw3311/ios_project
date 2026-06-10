import UIKit

class HomeViewController: UIViewController {

    // MARK: - Views

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SpeakUp"
        label.font = .boldSystemFont(ofSize: 40)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "발표 연습 도우미"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("오늘 연습하기", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let historyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("연습 기록 보기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.layer.borderWidth = 1.5
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let bestScoreCard = ScoreCardView(title: "최고 점수", value: "--")
    private let recentScoreCard = ScoreCardView(title: "최근 점수", value: "--")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = ""
        view.backgroundColor = .systemBackground
        setupLayout()
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        historyButton.addTarget(self, action: #selector(historyButtonTapped), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Layout

    private func setupLayout() {
        let cardStack = UIStackView(arrangedSubviews: [bestScoreCard, recentScoreCard])
        cardStack.axis = .horizontal
        cardStack.distribution = .fillEqually
        cardStack.spacing = 16
        cardStack.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, subtitleLabel, cardStack, startButton, historyButton].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),

            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

            cardStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cardStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            cardStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            cardStack.heightAnchor.constraint(equalToConstant: 100),

            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startButton.topAnchor.constraint(equalTo: cardStack.bottomAnchor, constant: 48),
            startButton.heightAnchor.constraint(equalToConstant: 56),

            historyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            historyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            historyButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 16),
            historyButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    // MARK: - Actions

    @objc private func startButtonTapped() {
        navigationController?.pushViewController(ScriptViewController(), animated: true)
    }

    @objc private func historyButtonTapped() {
        navigationController?.pushViewController(HistoryViewController(), animated: true)
    }
}

// MARK: - ScoreCardView

private class ScoreCardView: UIView {
    init(title: String, value: String) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .boldSystemFont(ofSize: 28)
        valueLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}
