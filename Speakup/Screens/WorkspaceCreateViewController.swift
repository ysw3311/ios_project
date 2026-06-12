import UIKit

class WorkspaceCreateViewController: UIViewController {

    var onCreated: ((Workspace) -> Void)?

    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "예: 기말 발표, 회사 PT, 토론 대회"
        tf.font = .systemFont(ofSize: 17)
        tf.returnKeyType = .done
        tf.clearButtonMode = .whileEditing
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "새 발표 만들기"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "만들기", style: .done, target: self, action: #selector(create)
        )

        setupLayout()
        nameField.delegate = self
        nameField.becomeFirstResponder()
    }

    // MARK: - Layout

    private func setupLayout() {
        let fieldCard = UIView()
        fieldCard.backgroundColor = .secondarySystemGroupedBackground
        fieldCard.layer.cornerRadius = 12
        fieldCard.translatesAutoresizingMaskIntoConstraints = false

        let fieldLabel = UILabel()
        fieldLabel.text = "발표 이름"
        fieldLabel.font = .systemFont(ofSize: 12)
        fieldLabel.textColor = .secondaryLabel
        fieldLabel.translatesAutoresizingMaskIntoConstraints = false

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false

        let hintLabel = UILabel()
        hintLabel.text = "발표마다 대본과 연습 기록이 분리돼요."
        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.textColor = .secondaryLabel
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        fieldCard.addSubview(fieldLabel)
        fieldCard.addSubview(divider)
        fieldCard.addSubview(nameField)
        view.addSubview(fieldCard)
        view.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            fieldCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            fieldCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fieldCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            fieldLabel.topAnchor.constraint(equalTo: fieldCard.topAnchor, constant: 12),
            fieldLabel.leadingAnchor.constraint(equalTo: fieldCard.leadingAnchor, constant: 16),

            divider.topAnchor.constraint(equalTo: fieldLabel.bottomAnchor, constant: 10),
            divider.leadingAnchor.constraint(equalTo: fieldCard.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: fieldCard.trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            nameField.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 10),
            nameField.leadingAnchor.constraint(equalTo: fieldCard.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: fieldCard.trailingAnchor, constant: -16),
            nameField.heightAnchor.constraint(equalToConstant: 32),
            nameField.bottomAnchor.constraint(equalTo: fieldCard.bottomAnchor, constant: -14),

            hintLabel.topAnchor.constraint(equalTo: fieldCard.bottomAnchor, constant: 10),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
        ])
    }

    // MARK: - Actions

    @objc private func cancel() { dismiss(animated: true) }

    @objc private func create() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            shake(nameField)
            return
        }
        let workspace = Workspace(
            id: UUID().uuidString,
            name: name,
            script: "",
            createdAt: Date(),
            records: []
        )
        onCreated?(workspace)
        dismiss(animated: true)
    }

    private func shake(_ view: UIView) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.duration = 0.4
        anim.values = [-8, 8, -6, 6, -4, 4, 0]
        view.layer.add(anim, forKey: "shake")
    }
}

extension WorkspaceCreateViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        create(); return true
    }
}
