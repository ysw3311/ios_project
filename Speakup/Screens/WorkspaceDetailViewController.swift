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
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 16
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // Dynamic refs for refresh
    private var scriptPreviewLabel: UILabel?
    private var emptyScriptLabel: UILabel?
    private var statsStack: UIStackView?
    private var graphView: LineGraphView?
    private var recordsStack: UIStackView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = workspace.name
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "대본 편집", style: .plain, target: self, action: #selector(editScript)
        )

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
        // --- Script card ---
        let scriptCard = makeCard()

        let scriptHeaderRow = makeRow()
        let scriptTitle = makeSection("대본")
        scriptHeaderRow.addArrangedSubview(scriptTitle)

        let scriptPreview = UILabel()
        scriptPreview.font = .systemFont(ofSize: 14)
        scriptPreview.numberOfLines = 4
        scriptPreview.textColor = .label
        scriptPreview.translatesAutoresizingMaskIntoConstraints = false
        self.scriptPreviewLabel = scriptPreview

        let emptyScript = UILabel()
        emptyScript.text = "아직 대본이 없어요.\n우측 상단 '대본 편집'을 눌러 추가해보세요."
        emptyScript.font = .systemFont(ofSize: 14)
        emptyScript.textColor = .secondaryLabel
        emptyScript.numberOfLines = 0
        emptyScript.translatesAutoresizingMaskIntoConstraints = false
        self.emptyScriptLabel = emptyScript

        let scriptInner = UIStackView(arrangedSubviews: [scriptHeaderRow, scriptPreview, emptyScript])
        scriptInner.axis = .vertical
        scriptInner.spacing = 8
        scriptInner.translatesAutoresizingMaskIntoConstraints = false
        scriptCard.addSubview(scriptInner)
        NSLayoutConstraint.activate([
            scriptInner.topAnchor.constraint(equalTo: scriptCard.topAnchor, constant: 14),
            scriptInner.leadingAnchor.constraint(equalTo: scriptCard.leadingAnchor, constant: 16),
            scriptInner.trailingAnchor.constraint(equalTo: scriptCard.trailingAnchor, constant: -16),
            scriptInner.bottomAnchor.constraint(equalTo: scriptCard.bottomAnchor, constant: -14),
        ])
        contentStack.addArrangedSubview(scriptCard)

        // --- Stats bar ---
        let statsBar = UIStackView()
        statsBar.axis = .horizontal
        statsBar.distribution = .fillEqually
        statsBar.spacing = 8
        statsBar.translatesAutoresizingMaskIntoConstraints = false
        self.statsStack = statsBar
        contentStack.addArrangedSubview(statsBar)
        statsBar.heightAnchor.constraint(equalToConstant: 72).isActive = true

        // --- Graph card ---
        let graphCard = makeCard()

        let graphTitle = makeSection("점수 추이")
        graphTitle.translatesAutoresizingMaskIntoConstraints = false

        let graph = LineGraphView()
        graph.translatesAutoresizingMaskIntoConstraints = false
        self.graphView = graph

        let graphInner = UIStackView(arrangedSubviews: [graphTitle, graph])
        graphInner.axis = .vertical
        graphInner.spacing = 10
        graphInner.translatesAutoresizingMaskIntoConstraints = false
        graphCard.addSubview(graphInner)
        NSLayoutConstraint.activate([
            graphInner.topAnchor.constraint(equalTo: graphCard.topAnchor, constant: 14),
            graphInner.leadingAnchor.constraint(equalTo: graphCard.leadingAnchor, constant: 16),
            graphInner.trailingAnchor.constraint(equalTo: graphCard.trailingAnchor, constant: -16),
            graphInner.bottomAnchor.constraint(equalTo: graphCard.bottomAnchor, constant: -14),
            graph.heightAnchor.constraint(equalToConstant: 130),
        ])
        contentStack.addArrangedSubview(graphCard)

        // --- Records ---
        let recordsHeader = makeRow()
        recordsHeader.addArrangedSubview(makeSection("연습 기록"))

        let records = UIStackView()
        records.axis = .vertical
        records.spacing = 0
        records.translatesAutoresizingMaskIntoConstraints = false
        self.recordsStack = records

        let recordsCard = makeCard()
        recordsCard.addSubview(records)
        NSLayoutConstraint.activate([
            records.topAnchor.constraint(equalTo: recordsCard.topAnchor),
            records.leadingAnchor.constraint(equalTo: recordsCard.leadingAnchor),
            records.trailingAnchor.constraint(equalTo: recordsCard.trailingAnchor),
            records.bottomAnchor.constraint(equalTo: recordsCard.bottomAnchor),
        ])

        contentStack.addArrangedSubview(recordsHeader)
        contentStack.addArrangedSubview(recordsCard)

        refreshContent()
    }

    private func refreshContent() {
        // Script
        let hasScript = !workspace.script.isEmpty
        scriptPreviewLabel?.text = workspace.script
        scriptPreviewLabel?.isHidden = !hasScript
        emptyScriptLabel?.isHidden = hasScript

        // Stats
        statsStack?.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let statItems: [(String, String)] = [
            ("총 연습", "\(workspace.practiceCount)회"),
            ("최고 점수", workspace.bestScore > 0 ? "\(workspace.bestScore)점" : "--"),
            ("평균 점수", workspace.averageScore > 0 ? "\(workspace.averageScore)점" : "--"),
        ]
        statItems.forEach { title, value in
            statsStack?.addArrangedSubview(StatBadgeView(title: title, value: value))
        }

        // Graph
        let scores = workspace.records.reversed().map { $0.totalScore }
        graphView?.setScores(scores)
        graphView?.superview?.superview?.isHidden = scores.count < 2

        // Records
        recordsStack?.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if workspace.records.isEmpty {
            let empty = UILabel()
            empty.text = "아직 연습 기록이 없어요"
            empty.font = .systemFont(ofSize: 14)
            empty.textColor = .secondaryLabel
            empty.textAlignment = .center
            empty.translatesAutoresizingMaskIntoConstraints = false
            recordsStack?.addArrangedSubview(empty)
            empty.heightAnchor.constraint(equalToConstant: 56).isActive = true
        } else {
            for (i, record) in workspace.records.enumerated() {
                let row = RecordRowView(record: record)
                recordsStack?.addArrangedSubview(row)
                if i < workspace.records.count - 1 {
                    let sep = UIView()
                    sep.backgroundColor = .separator
                    sep.translatesAutoresizingMaskIntoConstraints = false
                    recordsStack?.addArrangedSubview(sep)
                    sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func makeRow() -> UIStackView {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }

    private func makeSection(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .boldSystemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
            let alert = UIAlertController(title: "대본이 없어요", message: "먼저 대본을 입력해야 연습할 수 있어요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "대본 입력하기", style: .default) { [weak self] _ in self?.editScript() })
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd  HH:mm"

        let dateLabel = UILabel()
        dateLabel.text = dateFormatter.string(from: record.date)
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
