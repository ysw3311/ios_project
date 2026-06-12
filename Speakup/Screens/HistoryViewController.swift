import UIKit

// MARK: - Data Model (legacy placeholder — real data uses Models/Workspace.swift)

private struct LegacyRecord {
    let date: String
    let totalScore: Int
    let scriptScore: Int
    let speedScore: Int
    let silenceScore: Int
    let fillerScore: Int
}

// MARK: - HistoryViewController

class HistoryViewController: UIViewController {

    private let records: [LegacyRecord] = [
        LegacyRecord(date: "2026.06.10", totalScore: 82, scriptScore: 34, speedScore: 18, silenceScore: 16, fillerScore: 14),
        LegacyRecord(date: "2026.06.09", totalScore: 74, scriptScore: 28, speedScore: 16, silenceScore: 14, fillerScore: 16),
        LegacyRecord(date: "2026.06.08", totalScore: 65, scriptScore: 24, speedScore: 14, silenceScore: 14, fillerScore: 13),
        LegacyRecord(date: "2026.06.07", totalScore: 58, scriptScore: 22, speedScore: 12, silenceScore: 12, fillerScore: 12),
        LegacyRecord(date: "2026.06.05", totalScore: 45, scriptScore: 18, speedScore: 10, silenceScore: 10, fillerScore: 7),
    ]

    private let graphView = LineGraphView()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "연습 기록"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        graphView.setScores(records.reversed().map { $0.totalScore })
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HistoryCell.self, forCellReuseIdentifier: "HistoryCell")
    }

    // MARK: - Layout

    private func setupLayout() {
        graphView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(graphView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            graphView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            graphView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            graphView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            graphView.heightAnchor.constraint(equalToConstant: 160),

            tableView.topAnchor.constraint(equalTo: graphView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { "날짜별 연습 기록" }
}

// MARK: - HistoryCell

private class HistoryCell: UITableViewCell {

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 28)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let pointLabel: UILabel = {
        let label = UILabel()
        label.text = "점"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        [dateLabel, scoreLabel, pointLabel, detailLabel].forEach { contentView.addSubview($0) }

        NSLayoutConstraint.activate([
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),

            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -36),
            scoreLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            pointLabel.leadingAnchor.constraint(equalTo: scoreLabel.trailingAnchor, constant: 2),
            pointLabel.bottomAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: -4),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with record: LegacyRecord) {
        dateLabel.text = record.date
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
            let point = CGPoint(x: x, y: y)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        UIColor.systemBlue.setStroke()
        path.lineWidth = 2
        path.lineJoinStyle = .round
        path.stroke()

        for (i, score) in scores.enumerated() {
            let x = padding + CGFloat(i) * step
            let y = padding + h * (1 - CGFloat(score) / 100.0)
            let dotRect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
            UIColor.systemBlue.setFill()
            UIBezierPath(ovalIn: dotRect).fill()

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel,
            ]
            ("\(score)" as NSString).draw(at: CGPoint(x: x - 8, y: y - 18), withAttributes: attrs)
        }
    }
}
