import Foundation

/// Something the user studies, and the time already spent on it.
struct StudyTask: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var icon: TaskIcon
    var color: TaskColor
    /// Seconds the timer has run while this task was the selected one.
    var studiedSeconds: Int
    /// Every run of the clock against this task, oldest first.
    var sessions: [StudySession]

    init(
        id: UUID = UUID(),
        name: String,
        icon: TaskIcon = .default,
        color: TaskColor = .blue,
        studiedSeconds: Int = 0,
        sessions: [StudySession] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.studiedSeconds = studiedSeconds
        self.sessions = sessions
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, icon, color, studiedSeconds, sessions
    }

    /// Decoded by hand so that tasks stored before sessions, icons or colours
    /// existed still load: a synthesised decoder throws on the missing key,
    /// which would have thrown away the whole list along with its totals.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.icon = try container.decodeIfPresent(TaskIcon.self, forKey: .icon) ?? .default
        self.color = try container.decodeIfPresent(TaskColor.self, forKey: .color) ?? .blue
        self.studiedSeconds = try container.decode(Int.self, forKey: .studiedSeconds)
        self.sessions = try container.decodeIfPresent([StudySession].self, forKey: .sessions) ?? []
    }
}

extension StudyTask {

    var studiedTime: String {
        studiedSeconds.formatted(.clockTime)
    }
}
