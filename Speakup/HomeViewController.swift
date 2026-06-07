import UIKit

class HomeViewController: UIViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SpeakUp"
        label.font = .boldSystemFont(ofSize: 36)
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
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
    }

    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),

            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    @objc private func startButtonTapped() {
        // TODO: ScriptViewController로 전환
    }
}
