import UIKit

class ScriptViewController: UIViewController {

    var workspaceId: String = ""
    var initialScript: String = ""

    // MARK: - Views

    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let counterLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "대본 편집"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "저장", style: .done, target: self, action: #selector(saveTapped)
        )

        setupLayout()
        textView.text = initialScript
        textViewDidChange(textView)
        textView.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(textView)
        view.addSubview(counterLabel)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            counterLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8),
            counterLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            counterLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            counterLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }

    // MARK: - Keyboard

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = max(0, view.bounds.height - frame.origin.y)
        textView.contentInset.bottom = keyboardHeight
        textView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }

    // MARK: - Actions

    @objc private func saveTapped() {
        let script = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if var workspace = WorkspaceStore.shared.workspaces.first(where: { $0.id == workspaceId }) {
            workspace.script = script
            WorkspaceStore.shared.update(workspace)
        }
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITextViewDelegate

extension ScriptViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let current = textView.text ?? ""
        guard let r = Range(range, in: current) else { return true }
        return current.replacingCharacters(in: r, with: text).count <= 2000
    }

    func textViewDidChange(_ textView: UITextView) {
        let count = textView.text.count
        counterLabel.text = "\(count) / 2000"
        counterLabel.textColor = count > 1800 ? .systemOrange : .secondaryLabel
    }
}
