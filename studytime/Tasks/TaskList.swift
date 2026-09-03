import Foundation

/// The user's tasks and which one is selected, persisted as JSON.
///
/// Follows the same shape as `StudyTimer` and `AppearanceSettings`: computed
/// properties over private storage, with a `KeyValueStore` injected for tests.
@Observable
final class TaskList {
    static let maxNameLength = 60

    private enum Key {
        static let tasks = "tasks"
        static let selectedTaskID = "selectedTaskID"
    }

    private var storedTasks: [StudyTask]
    private var storedSelectionID: StudyTask.ID?

    private let store: KeyValueStore

    init(store: KeyValueStore = UserDefaults.standard) {
        self.store = store

        let data: Data? = store.value(forKey: Key.tasks)
        self.storedTasks = data
            .flatMap { try? JSONDecoder().decode([StudyTask].self, from: $0) } ?? []

        let storedID: String? = store.value(forKey: Key.selectedTaskID)
        let id = storedID.flatMap(UUID.init(uuidString:))
        // A selection that no longer names a task is dropped rather than kept
        // as a dangling id.
        self.storedSelectionID = storedTasks.contains { $0.id == id } ? id : nil
    }
}

extension TaskList {

    var tasks: [StudyTask] { storedTasks }

    /// Selecting an id that names no task clears the selection instead.
    var selectedTaskID: StudyTask.ID? {
        get { storedSelectionID }
        set {
            let id = storedTasks.contains { $0.id == newValue } ? newValue : nil
            guard id != storedSelectionID else { return }
            storedSelectionID = id
            store.set(id?.uuidString, forKey: Key.selectedTaskID)
        }
    }

    var selectedTask: StudyTask? {
        storedTasks.first { $0.id == storedSelectionID }
    }

    /// Adds a task and selects it, so a task created mid-session starts
    /// collecting time straight away.
    ///
    /// Returns `nil` — and changes nothing — for a blank name or one that
    /// repeats an existing task.
    @discardableResult
    func add(named name: String) -> StudyTask? {
        guard let name = Self.sanitised(name), !contains(named: name) else { return nil }

        let task = StudyTask(name: name)
        storedTasks.append(task)
        storedSelectionID = task.id
        persist()
        return task
    }

    func remove(_ id: StudyTask.ID) {
        guard let index = storedTasks.firstIndex(where: { $0.id == id }) else { return }

        storedTasks.remove(at: index)
        if storedSelectionID == id { storedSelectionID = nil }
        persist()
    }

    /// Renames a task, leaving its total untouched. Returns whether it happened.
    @discardableResult
    func rename(_ id: StudyTask.ID, to name: String) -> Bool {
        guard let name = Self.sanitised(name),
              let index = storedTasks.firstIndex(where: { $0.id == id }),
              storedTasks[index].name != name,
              // A rename onto another task's name would make the two
              // indistinguishable in the picker.
              !contains(named: name, ignoring: id)
        else { return false }

        storedTasks[index].name = name
        persist()
        return true
    }

    /// Credits studied time to the selected task. Does nothing when no task is
    /// selected — the timer still runs, it just isn't counted against anything.
    func recordStudied(seconds: Int) {
        guard seconds > 0,
              let index = storedTasks.firstIndex(where: { $0.id == storedSelectionID })
        else { return }

        storedTasks[index].studiedSeconds += seconds
        persist()
    }
}

private extension TaskList {

    func persist() {
        store.set(try? JSONEncoder().encode(storedTasks), forKey: Key.tasks)
        store.set(storedSelectionID?.uuidString, forKey: Key.selectedTaskID)
    }

    func contains(named name: String, ignoring id: StudyTask.ID? = nil) -> Bool {
        storedTasks.contains {
            $0.id != id && $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }
    }

    /// Trimmed and length-capped, or `nil` if nothing is left.
    static func sanitised(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxNameLength))
    }
}
