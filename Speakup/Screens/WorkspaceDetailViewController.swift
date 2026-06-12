import UIKit

class WorkspaceDetailViewController: UIViewController {

    private var workspace: Workspace

    init(workspace: Workspace) {
        self.workspace = workspace
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Views

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("연습 시작", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.layer.cornerRadius = 16
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // Stored card refs for safe show/hide
    private var scriptCard: UIView!
    private var statsBar: UIStackView!
    private var graphCard: UIView!
    private var recordsHeaderLabel: UILabel!
    private var recordsCard: UIView!

    // Dynamic content refs
    private var scriptPreviewLabel: UILabel!
    private var emptyScriptView: UIView!
    private var graphView: LineGraphView!
    private var recordsStack: UIStackView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = workspace.name
        view.backgroundColor = .systemGroupedBackground
        setupScrollView()
        buildContent()
        startButton.addTarget(self, action: #selector(startPractice), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let updated = WorkspaceStore.shared.workspaces.first(where: { $0.id == workspace.id }) {
            workspace = updated
        }
        title = workspace.name
        refreshContent()
    }

    // MARK: - Layout

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -12),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            startButton.heightAnchor.constraint(equalToConstant: 54),
        ])
    }

    private func buildContent() {
        buildScriptCard()
        buildStatsBar()
        buildGraphCard()
        buildRecordsSection()
        refreshContent()
    }

    // MARK: - Script Card

    private func buildScriptCard() {
        let card = makeCard()
        self.scriptCard = card

        // Header: "대본" 타이틀 + "편집 >" 버튼
        let titleLabel = UILabel()
        titleLabel.text = "대본"
        titleLabel.font = .boldSystemFont(ofSize: 15)

        let editButton = UIButton(type: .system)
        editButton.setTitle("편집", for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 14)
        editButton.setTitleColor(.systemBlue, for: .normal)
        editButton.addTarget(self, action: #selector(editScript), for: .touchUpInside)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .systemBlue
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 9).isActive = true

        let editRow = UIStackView(arrangedSubviews: [editButton, chevron])
        editRow.axis = .horizontal
        editRow.spacing = 2
        editRow.alignment = .center

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), editRow])
        headerRow.axis = .horizontal
        headerRow.alignment = .center

        // 대본 미리보기 (있을 때)
        let preview = UILabel()
        preview.font = .systemFont(ofSize: 14)
        preview.textColor = .secondaryLabel
        preview.numberOfLines = 3
        self.scriptPreviewLabel = preview

        // 빈 상태 (없을 때) — 탭 유도
        let emptyView = buildEmptyScriptView()
        self.emptyScriptView = emptyView

        let inner = UIStackView(arrangedSubviews: [headerRow, preview, emptyView])
        inner.axis = .vertical
        inner.spacing = 10
        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)

        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])

        // 카드 전체 탭 → 편집
        let tap = UITapGestureRecognizer(target: self, action: #selector(editScript))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true

        contentStack.addArrangedSubview(card)
    }

    private func buildEmptyScriptView() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBlue.withAlphaComponent(0.06)
        container.layer.cornerRadius = 8
        container.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
        container.layer.borderWidth = 1
        container.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "square.and.pencil"))
        icon.tintColor = .systemBlue
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "탭해서 대본을 추가해보세요"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
            row.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            row.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
        ])
        return container
    }

    // MARK: - Stats Bar

    private func buildStatsBar() {
        let bar = UIStackView()
        bar.axis = .horizontal
        bar.distribution = .fillEqually
        bar.spacing = 8
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.heightAnchor.constraint(equalToConstant: 72).isActive = true
        self.statsBar = bar
        contentStack.addArrangedSubview(bar)
    }

    // MARK: - Graph Card

    private func buildGraphCard() {
        let card = makeCard()
        self.graphCard = card

        let titleLabel = UILabel()
        titleLabel.text = "점수 추이"
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let graph = LineGraphView()
        graph.translatesAutoresizingMaskIntoConstraints = false
        self.graphView = graph

        let inner = UIStackView(arrangedSubviews: [titleLabel, graph])
        inner.axis = .vertical
        inner.spacing = 10
        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)

        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            graph.heightAnchor.constraint(equalToConstant: 130),
        ])
        contentStack.addArrangedSubview(card)
    }

    // MARK: - Records Section

    private func buildRecordsSection() {
        let header = UILabel()
        header.text = "연습 기록"
        header.font = .boldSystemFont(ofSize: 15)
        header.translatesAutoresizingMaskIntoConstraints = false
        self.recordsHeaderLabel = header
        contentStack.addArrangedSubview(header)

        let card = makeCard()
        self.recordsCard = card

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.recordsStack = stack
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])
        contentStack.addArrangedSubview(card)
    }

    // MARK: - Refresh

    private func refreshContent() {
        refreshScriptCard()
        refreshStats()
        refreshGraph()
        refreshRecords()
        refreshStartButton()
    }

    private func refreshScriptCard() {
        let hasScript = !workspace.script.isEmpty
        scriptPreviewLabel.text = workspace.script
        scriptPreviewLabel.isHidden = !hasScript
        emptyScriptView.isHidden = hasScript
    }

    private func refreshStats() {
        statsBar.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let hasRecords = !workspace.records.isEmpty
        statsBar.isHidden = !hasRecords
        guard hasRecords else { return }

        let items: [(String, String)] = [
            ("총 연습", "\(workspace.practiceCount)회"),
            ("최고 점수", "\(workspace.bestScore)점"),
            ("평균 점수", "\(workspace.averageScore)점"),
        ]
        items.forEach { statsBar.addArrangedSubview(StatBadgeView(title: $0.0, value: $0.1)) }
    }

    private func refreshGraph() {
        let scores = workspace.records.reversed().map { $0.totalScore }
        graphView.setScores(scores)
        graphCard.isHidden = scores.count < 2
    }

    private func refreshRecords() {
        recordsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let hasRecords = !workspace.records.isEmpty
        recordsHeaderLabel.isHidden = !hasRecords
        recordsCard.isHidden = !hasRecords
        guard hasRecords else { return }

        for (i, record) in workspace.records.enumerated() {
            recordsStack.addArrangedSubview(RecordRowView(record: record))
            if i < workspace.records.count - 1 {
                let sep = UIView()
                sep.backgroundColor = .separator
                sep.translatesAutoresizingMaskIntoConstraints = false
                recordsStack.addArrangedSubview(sep)
                sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            }
        }
    }

    private func refreshStartButton() {
        let hasScript = !workspace.script.isEmpty
        startButton.backgroundColor = hasScript ? .systemBlue : .systemGray4
        startButton.setTitleColor(hasScript ? .white : .systemGray2, for: .normal)
    }

    // MARK: - Helpers

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    // MARK: - Actions

    @objc private func editScript() {
        let vc = ScriptViewController()
        vc.workspaceId = workspace.id
        vc.initialScript = workspace.script
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func startPractice() {
        guard !workspace.script.isEmpty else {
            let alert = UIAlertController(title: "대본이 없어요",
                                          message: "먼저 대본을 입력해야 연습할 수 있어요.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "대본 입력하기", style: .default) { [weak self] _ in
                self?.editScript()
            })
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            present(alert, animated: true)
            return
        }
        let vc = RecordingViewController()
        vc.script = workspace.script
        vc.workspaceId = workspace.id
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - StatBadgeView

private class StatBadgeView: UIView {
    init(title: String, value: String) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 10
        translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .boldSystemFont(ofSize: 20)
        valueLabel.textAlignment = .center
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(valueLabel)
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - RecordRowView

private class RecordRowView: UIView {
    init(record: PracticeRecord) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupViews(record: record)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews(record: PracticeRecord) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd  HH:mm"

        let dateLabel = UILabel()
        dateLabel.text = formatter.string(from: record.date)
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .secondaryLabel
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        let detailLabel = UILabel()
        detailLabel.text = "대본 \(record.scriptScore) · 속도 \(record.speedScore) · 침묵 \(record.silenceScore) · 필러 \(record.fillerScore)"
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .tertiaryLabel
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        let scoreLabel = UILabel()
        scoreLabel.text = "\(record.totalScore)"
        scoreLabel.font = .boldSystemFont(ofSize: 26)
        scoreLabel.textColor = record.totalScore >= 80 ? .systemGreen : record.totalScore >= 60 ? .systemOrange : .systemRed
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false

        let pointLabel = UILabel()
        pointLabel.text = "점"
        pointLabel.font = .systemFont(ofSize: 12)
        pointLabel.textColor = .secondaryLabel
        pointLabel.translatesAutoresizingMaskIntoConstraints = false

        let m = record.duration / 60
        let s = record.duration % 60
        let durationLabel = UILabel()
        durationLabel.text = m > 0 ? "\(m)분 \(s)초" : "\(s)초"
        durationLabel.font = .systemFont(ofSize: 11)
        durationLabel.textColor = .tertiaryLabel
        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        [dateLabel, detailLabel, scoreLabel, pointLabel, durationLabel].forEach { addSubview($0) }

        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            detailLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            detailLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),

            scoreLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -5),
            scoreLabel.trailingAnchor.constraint(equalTo: pointLabel.leadingAnchor, constant: -1),

            pointLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            pointLabel.bottomAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: -3),

            durationLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            durationLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 3),
        ])
    }
}
