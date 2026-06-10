import UIKit

class ScriptViewController: UIViewController {

    // MARK: - Views

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "발표할 대본을 입력하세요"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.separator.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 10
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let counterLabel: UILabel = {
        let label = UILabel()
        label.text = "0 / 2000"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("녹음 시작", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "대본 입력"
        view.backgroundColor = .systemBackground
        setupLayout()
        textView.delegate = self
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Layout

    private func setupLayout() {
        [instructionLabel, textView, counterLabel, startButton].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            textView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            textView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45),

            counterLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 6),
            counterLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            startButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    // MARK: - Actions

    @objc private func startButtonTapped() {
        let script = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !script.isEmpty else {
            showAlert("대본을 입력해 주세요.")
            return
        }
        let vc = RecordingViewController()
        vc.script = script
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate

extension ScriptViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let current = textView.text ?? ""
        guard let range = Range(range, in: current) else { return true }
        let updated = current.replacingCharacters(in: range, with: text)
        return updated.count <= 2000
    }

    func textViewDidChange(_ textView: UITextView) {
        let count = textView.text.count
        counterLabel.text = "\(count) / 2000"
        counterLabel.textColor = count > 1800 ? .systemOrange : .secondaryLabel
    }
}
