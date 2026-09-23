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

    /// The session currently collecting time, if the clock is mid-run. Not
    /// persisted: a relaunch starts a new session rather than reopening one.
    private var openSession: (taskID: StudyTask.ID, sessionID: StudySession.ID)?

    private let store: KeyValueStore
    private let now: () -> Date

    init(store: KeyValueStore = UserDefaults.standard, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.now = now

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
            // Time cannot carry across tasks, so the run being recorded ends
            // with the switch.
            endSession()
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

        let task = StudyTask(name: name, color: TaskColor.next(after: storedTasks.map(\.color)))
        storedTasks.append(task)
        storedSelectionID = task.id
        persist()
        return task
    }

    func remove(_ id: StudyTask.ID) {
        guard let index = storedTasks.firstIndex(where: { $0.id == id }) else { return }

        storedTasks.remove(at: index)
        if openSession?.taskID == id { endSession() }
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

    /// Changes the icon and colour a task is drawn with.
    func restyle(_ id: StudyTask.ID, icon: TaskIcon, color: TaskColor) {
        guard let index = storedTasks.firstIndex(where: { $0.id == id }),
              storedTasks[index].icon != icon || storedTasks[index].color != color
        else { return }

        storedTasks[index].icon = icon
        storedTasks[index].color = color
        persist()
    }

    /// Credits studied time to the selected task, and to the session it is
    /// part of — opening one if the clock has just started running. Does
    /// nothing when no task is selected: the timer still runs, it just isn't
    /// counted against anything.
    func recordStudied(seconds: Int) {
        guard seconds > 0,
              let index = storedTasks.firstIndex(where: { $0.id == storedSelectionID })
        else { return }

        storedTasks[index].studiedSeconds += seconds
        record(seconds: seconds, inSessionOf: index)
        persist()
    }

    /// Removes a recorded session, taking its time out of the task's total —
    /// the total is the sum of the runs, so the two would otherwise disagree.
    func removeSession(_ id: StudySession.ID) {
        guard let taskIndex = storedTasks.firstIndex(where: { task in
            task.sessions.contains { $0.id == id }
        }),
        let sessionIndex = storedTasks[taskIndex].sessions.firstIndex(where: { $0.id == id })
        else { return }

        let session = storedTasks[taskIndex].sessions.remove(at: sessionIndex)
        storedTasks[taskIndex].studiedSeconds = max(
            0,
            storedTasks[taskIndex].studiedSeconds - session.seconds
        )
        // Deleting the run in progress stops it collecting any more time.
        if openSession?.sessionID == id { endSession() }
        persist()
    }

    /// Moves a recorded session onto another task, taking its time with it so
    /// both totals still equal the sum of their sessions. Returns whether it
    /// happened: an unknown session or task, or the task it is already on,
    /// changes nothing.
    @discardableResult
    func moveSession(_ id: StudySession.ID, to taskID: StudyTask.ID) -> Bool {
        guard let fromIndex = storedTasks.firstIndex(where: { task in
            task.sessions.contains { $0.id == id }
        }),
        let toIndex = storedTasks.firstIndex(where: { $0.id == taskID }),
        fromIndex != toIndex,
        let sessionIndex = storedTasks[fromIndex].sessions.firstIndex(where: { $0.id == id })
        else { return false }

        let session = storedTasks[fromIndex].sessions.remove(at: sessionIndex)
        storedTasks[fromIndex].studiedSeconds = max(
            0,
            storedTasks[fromIndex].studiedSeconds - session.seconds
        )

        // Sessions are kept oldest first.
        let insertion = storedTasks[toIndex].sessions
            .firstIndex { $0.startedAt > session.startedAt } ?? storedTasks[toIndex].sessions.endIndex
        storedTasks[toIndex].sessions.insert(session, at: insertion)
        storedTasks[toIndex].studiedSeconds += session.seconds

        // The clock keeps counting against the selected task, so the run in
        // progress can't follow its session elsewhere: the next second starts
        // a fresh one.
        if openSession?.sessionID == id { endSession() }
        persist()
        return true
    }

    /// Closes the run being recorded, so the next second counted starts a new
    /// session. Called when the clock is finished or reset — pausing does not
    /// end a session, it just leaves a gap inside it.
    func endSession() {
        openSession = nil
    }

    /// The session currently collecting time, if any.
    var sessionInProgress: StudySession? {
        guard let openSession,
              let task = storedTasks.first(where: { $0.id == openSession.taskID })
        else { return nil }

        return task.sessions.first { $0.id == openSession.sessionID }
    }

    /// Every task and the selection, ready to export.
    func backup() -> StudyTimeBackup {
        StudyTimeBackup(exportedAt: now(), tasks: storedTasks, selectedTaskID: storedSelectionID)
    }

    /// Replaces every task, and its history, with the ones in a backup.
    ///
    /// Throws — and changes nothing — for a backup `validatedTasks(in:)`
    /// rejects. The run being recorded ends, since its task is being replaced.
    func restore(_ backup: StudyTimeBackup) throws {
        let tasks = try Self.validatedTasks(in: backup)

        endSession()
        storedTasks = tasks
        // Same rule as the stored selection on launch: drop one naming no task.
        storedSelectionID = tasks.contains { $0.id == backup.selectedTaskID }
            ? backup.selectedTaskID
            : nil
        persist()
    }

    /// A backup's tasks with their names tidied, or an error if they include
    /// anything the list could not have made itself: blank or repeated names,
    /// repeated ids, or negative times.
    static func validatedTasks(in backup: StudyTimeBackup) throws -> [StudyTask] {
        var taskIDs = Set<StudyTask.ID>()
        var names = Set<String>()
        var sessionIDs = Set<StudySession.ID>()

        return try backup.tasks.map { task in
            guard let name = sanitised(task.name),
                  taskIDs.insert(task.id).inserted,
                  names.insert(name.localizedLowercase).inserted,
                  task.studiedSeconds >= 0,
                  // Sessions are removed by id, so a repeat would delete the wrong one.
                  task.sessions.allSatisfy({ $0.seconds >= 0 && sessionIDs.insert($0.id).inserted })
            else { throw StudyTimeBackupError.invalidContents }

            var task = task
            task.name = name
            return task
        }
    }
}

private extension TaskList {

    /// Extends the open session, or opens one on this task.
    func record(seconds: Int, inSessionOf index: Int) {
        let end = now()
        let task = storedTasks[index]

        if openSession?.taskID == task.id,
           let sessionIndex = task.sessions.firstIndex(where: { $0.id == openSession?.sessionID }) {
            storedTasks[index].sessions[sessionIndex].endedAt = end
            storedTasks[index].sessions[sessionIndex].seconds += seconds
            return
        }

        // The seconds have already elapsed by the time they are counted, so
        // the run began that far back.
        let session = StudySession(
            startedAt: end.addingTimeInterval(-Double(seconds)),
            endedAt: end,
            seconds: seconds
        )
        storedTasks[index].sessions.append(session)
        openSession = (taskID: task.id, sessionID: session.id)
    }

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
