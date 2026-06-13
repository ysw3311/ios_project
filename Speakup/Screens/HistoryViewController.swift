import UIKit

class HistoryViewController: UIViewController {

    // 모든 워크스페이스의 기록을 날짜순으로 합산
    struct FlatRecord {
        let workspaceName: String
        let date: Date
        let totalScore: Int
        let scriptScore: Int
        let speedScore: Int
        let silenceScore: Int
        let fillerScore: Int
    }

    private var records: [FlatRecord] = []
    private let graphView = LineGraphView()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "아직 연습 기록이 없어요\n발표를 연습하면 여기에 기록됩니다"
        l.font = .systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "연습 기록"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HistoryCell.self, forCellReuseIdentifier: "HistoryCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecords()
    }

    // MARK: - Data

    private func loadRecords() {
        records = WorkspaceStore.shared.workspaces
            .flatMap { ws in
                ws.records.map { r in
                    FlatRecord(
                        workspaceName: ws.name,
                        date: r.date,
                        totalScore: r.totalScore,
                        scriptScore: r.scriptScore,
                        speedScore: r.speedScore,
                        silenceScore: r.silenceScore,
                        fillerScore: r.fillerScore
                    )
                }
            }
            .sorted { $0.date > $1.date }

        let scores = records.prefix(20).reversed().map { $0.totalScore }
        graphView.setScores(Array(scores))
        emptyLabel.isHidden = !records.isEmpty
        graphView.isHidden = records.count < 2
        tableView.reloadData()
    }

    // MARK: - Layout

    private func setupLayout() {
        graphView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(graphView)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            graphView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            graphView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            graphView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            graphView.heightAnchor.constraint(equalToConstant: 160),

            tableView.topAnchor.constraint(equalTo: graphView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

// MARK: - UITableViewDataSource / Delegate

extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryCell
        cell.configure(with: records[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        records.isEmpty ? nil : "날짜별 연습 기록 (\(records.count)회)"
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let r = records[indexPath.row]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일 HH:mm"

        let message = """
        📅 \(formatter.string(from: r.date))
        🏢 \(r.workspaceName)

        종합 점수: \(r.totalScore)점
        ───────────────
        대본 일치율: \(r.scriptScore) / 40
        말하기 속도: \(r.speedScore) / 20
        침묵 구간:   \(r.silenceScore) / 20
        필러워드:    \(r.fillerScore) / 20
        """

        let alert = UIAlertController(title: "연습 상세", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - HistoryCell

private class HistoryCell: UITableViewCell {

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let workspaceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let scoreLabel: UILabel = {
        let l = UILabel()
        l.font = .boldSystemFont(ofSize: 28)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let pointLabel: UILabel = {
        let l = UILabel()
        l.text = "점"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let detailLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        [dateLabel, workspaceLabel, scoreLabel, pointLabel, detailLabel].forEach { contentView.addSubview($0) }

        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            workspaceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            workspaceLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 2),

            detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailLabel.topAnchor.constraint(equalTo: workspaceLabel.bottomAnchor, constant: 2),

            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -36),
            scoreLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            pointLabel.leadingAnchor.constraint(equalTo: scoreLabel.trailingAnchor, constant: 2),
            pointLabel.bottomAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: -4),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with record: HistoryViewController.FlatRecord) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        dateLabel.text = formatter.string(from: record.date)
        workspaceLabel.text = record.workspaceName
        scoreLabel.text = "\(record.totalScore)"
        scoreLabel.textColor = record.totalScore >= 80 ? .systemGreen : record.totalScore >= 60 ? .systemOrange : .systemRed
        detailLabel.text = "대본 \(record.scriptScore) · 속도 \(record.speedScore) · 침묵 \(record.silenceScore) · 필러 \(record.fillerScore)"
    }
}

// MARK: - LineGraphView

class LineGraphView: UIView {

    private var scores: [Int] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
    }

    required init?(coder: NSCoder) { fatalError() }

    func setScores(_ scores: [Int]) {
        self.scores = scores
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard scores.count > 1 else { return }

        let padding: CGFloat = 20
        let w = rect.width - padding * 2
        let h = rect.height - padding * 2
        let step = w / CGFloat(scores.count - 1)

        let gridColor = UIColor.separator.withAlphaComponent(0.4)
        gridColor.setStroke()
        for i in 0...4 {
            let y = padding + h * CGFloat(i) / 4
            let line = UIBezierPath()
            line.move(to: CGPoint(x: padding, y: y))
            line.addLine(to: CGPoint(x: rect.width - padding, y: y))
            line.lineWidth = 0.5
            line.stroke()
        }

        let path = UIBezierPath()
        for (i, score) in scores.enumerated() {
            let x = padding + CGFloat(i) * step
            let y = padding + h * (1 - CGFloat(score) / 100.0)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        UIColor.systemBlue.setStroke()
        path.lineWidth = 2
        path.lineJoinStyle = .round
        path.stroke()

        for (i, score) in scores.enumerated() {
            let x = padding + CGFloat(i) * step
            let y = padding + h * (1 - CGFloat(score) / 100.0)
            UIColor.systemBlue.setFill()
            UIBezierPath(ovalIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8)).fill()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel,
            ]
            ("\(score)" as NSString).draw(at: CGPoint(x: x - 8, y: y - 18), withAttributes: attrs)
        }
    }
}
