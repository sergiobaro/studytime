import Foundation

/// Something the user studies, and the time already spent on it.
///
/// Named `StudyTask` rather than `Task` so it does not collide with Swift
/// concurrency's `Task`.
struct StudyTask: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    /// Seconds the timer has run while this task was the selected one.
    var studiedSeconds: Int

    init(id: UUID = UUID(), name: String, studiedSeconds: Int = 0) {
        self.id = id
        self.name = name
        self.studiedSeconds = studiedSeconds
    }
}

extension StudyTask {

    var studiedTime: String {
        studiedSeconds.formatted(.clockTime)
    }
}
