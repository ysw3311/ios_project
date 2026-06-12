import Foundation

struct Workspace: Codable {
    var id: String
    var name: String
    var script: String
    var createdAt: Date
    var records: [PracticeRecord]

    var bestScore: Int { records.map(\.totalScore).max() ?? 0 }
    var averageScore: Int {
        guard !records.isEmpty else { return 0 }
        return records.map(\.totalScore).reduce(0, +) / records.count
    }
    var practiceCount: Int { records.count }
    var lastPracticedAt: Date? { records.map(\.date).max() }
}

struct PracticeRecord: Codable {
    var id: String
    var date: Date
    var totalScore: Int
    var scriptScore: Int
    var speedScore: Int
    var silenceScore: Int
    var fillerScore: Int
    var duration: Int
}
