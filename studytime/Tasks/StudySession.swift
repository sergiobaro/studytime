import Foundation

/// One run of the clock against a task: when it began, when it last counted a
/// second, and how much time it actually credited.
///
/// `seconds` is not `endedAt - startedAt`: a session survives pausing, so the
/// span can be longer than the time counted.
struct StudySession: Identifiable, Hashable, Codable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date
    var seconds: Int

    init(id: UUID = UUID(), startedAt: Date, endedAt: Date, seconds: Int) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.seconds = seconds
    }
}
