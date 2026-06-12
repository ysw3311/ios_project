import UIKit

class WorkspaceListViewController: UIViewController {

    private var workspaces: [Workspace] { WorkspaceStore.shared.workspaces }

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = .systemGroupedBackground
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 40, right: 0)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SpeakUp"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WorkspaceCell.self, forCellReuseIdentifier: "WorkspaceCell")

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        refreshEmptyState()
    }

    // MARK: - Layout

    private func setupLayout() {
        let emojiLabel = UILabel()
        emojiLabel.text = "🎙"
        emojiLabel.font = .systemFont(ofSize: 52)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "아직 발표가 없어요"
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subLabel = UILabel()
        subLabel.text = "우측 상단 + 버튼으로\n첫 발표를 만들어보세요"
        subLabel.font = .systemFont(ofSize: 15)
        subLabel.textColor = .secondaryLabel
        subLabel.textAlignment = .center
        subLabel.numberOfLines = 0
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        [emojiLabel, titleLabel, subLabel].forEach { emptyView.addSubview($0) }
        NSLayoutConstraint.activate([
            emojiLabel.topAnchor.constraint(equalTo: emptyView.topAnchor),
            emojiLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            subLabel.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor),
        ])

        [tableView, emptyView].forEach { view.addSubview($0) }
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
    }

    private func refreshEmptyState() {
        let isEmpty = workspaces.isEmpty
        emptyView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    // MARK: - Actions

    @objc private func addTapped() {
        let vc = WorkspaceCreateViewController()
        vc.onCreated = { [weak self] workspace in
            WorkspaceStore.shared.add(workspace)
            self?.tableView.reloadData()
            self?.refreshEmptyState()
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension WorkspaceListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        workspaces.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkspaceCell", for: indexPath) as! WorkspaceCell
        cell.configure(with: workspaces[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 100 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = WorkspaceDetailViewController(workspace: workspaces[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, done in
            guard let self = self else { return }
            WorkspaceStore.shared.delete(id: self.workspaces[indexPath.row].id)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.refreshEmptyState()
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}

// MARK: - WorkspaceCell

private class WorkspaceCell: UITableViewCell {

    private let card = UIView()
    private let accentBar = UIView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let scoreLabel = UILabel()
    private let pointLabel = UILabel()

    private let accentColors: [UIColor] = [
        .systemBlue, .systemPurple, .systemPink,
        .systemOrange, .systemGreen, .systemIndigo,
    ]

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupCard()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupCard() {
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 6
        card.translatesAutoresizingMaskIntoConstraints = false

        accentBar.layer.cornerRadius = 3
        accentBar.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .boldSystemFont(ofSize: 17)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        scoreLabel.font = .boldSystemFont(ofSize: 28)
        scoreLabel.textAlignment = .right
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false

        pointLabel.text = "점"
        pointLabel.font = .systemFont(ofSize: 12)
        pointLabel.textColor = .secondaryLabel
        pointLabel.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(card)
        [accentBar, nameLabel, subtitleLabel, scoreLabel, pointLabel, chevron].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            accentBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            accentBar.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            accentBar.widthAnchor.constraint(equalToConstant: 4),
            accentBar.heightAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 14),
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),

            subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 10),
            chevron.heightAnchor.constraint(equalToConstant: 14),

            pointLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            pointLabel.bottomAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: -3),

            scoreLabel.trailingAnchor.constraint(equalTo: pointLabel.leadingAnchor, constant: -1),
            scoreLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])
    }

    func configure(with workspace: Workspace) {
        nameLabel.text = workspace.name

        let colorIdx = abs(workspace.name.hashValue) % accentColors.count
        accentBar.backgroundColor = accentColors[colorIdx]

        if workspace.records.isEmpty {
            subtitleLabel.text = "아직 연습한 적 없어요"
            scoreLabel.text = "--"
            scoreLabel.textColor = .tertiaryLabel
            pointLabel.isHidden = true
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M월 d일"
            let last = workspace.lastPracticedAt.map { formatter.string(from: $0) } ?? "--"
            subtitleLabel.text = "\(workspace.practiceCount)회 연습 · 마지막 \(last)"
            let best = workspace.bestScore
            scoreLabel.text = "\(best)"
            scoreLabel.textColor = best >= 80 ? .systemGreen : best >= 60 ? .systemOrange : .systemRed
            pointLabel.isHidden = false
        }
    }
}
