import Foundation

final class WorkspaceStore {
    static let shared = WorkspaceStore()
    private let udKey = "su_workspaces_v1"

    private(set) var workspaces: [Workspace] = []

    private init() { load() }

    func add(_ workspace: Workspace) {
        workspaces.insert(workspace, at: 0)
        save()
    }

    func update(_ workspace: Workspace) {
        guard let idx = workspaces.firstIndex(where: { $0.id == workspace.id }) else { return }
        workspaces[idx] = workspace
        save()
    }

    func delete(id: String) {
        workspaces.removeAll { $0.id == id }
        save()
    }

    func addRecord(_ record: PracticeRecord, toWorkspaceId workspaceId: String) {
        guard let idx = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }
        workspaces[idx].records.insert(record, at: 0)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([Workspace].self, from: data) else { return }
        workspaces = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(workspaces) else { return }
        UserDefaults.standard.set(data, forKey: udKey)
    }
}
