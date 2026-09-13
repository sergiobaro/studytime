import Foundation
import UniformTypeIdentifiers

/// Every task and its history, in the shape written to an exported file.
///
/// Wrapped rather than written as a bare task array so the format can grow:
/// `version` lets a later app keep reading today's files, and lets this one
/// refuse files it is too old to understand.
struct StudyTimeBackup: Codable, Equatable {
    static let currentVersion = 1

    var version: Int
    var exportedAt: Date
    var tasks: [StudyTask]
    var selectedTaskID: StudyTask.ID?

    init(
        version: Int = StudyTimeBackup.currentVersion,
        exportedAt: Date,
        tasks: [StudyTask],
        selectedTaskID: StudyTask.ID?
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.tasks = tasks
        self.selectedTaskID = selectedTaskID
    }
}

enum StudyTimeBackupError: LocalizedError, Equatable {
    case unreadable
    case newerVersion(Int)
    case invalidContents

    var errorDescription: String? {
        switch self {
        case .unreadable:
            "The file isn't a StudyTime backup, or it is damaged."
        case .newerVersion:
            "This backup was made by a newer version of StudyTime. Update the app to import it."
        case .invalidContents:
            "The backup contains tasks StudyTime can't use, such as blank or repeated names."
        }
    }
}

extension StudyTimeBackup {

    /// Pretty-printed with ISO 8601 dates, so the file is readable by people
    /// and other tools — unlike the stored format, which it doesn't affect.
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(.iso8601WithFractionalSeconds))
        }
        return try encoder.encode(self)
    }

    static func decoded(from data: Data) throws -> StudyTimeBackup {
        // The version is read on its own first, so a newer file is reported
        // as newer rather than as damaged once its shape has moved on.
        struct Header: Decodable { let version: Int }

        guard let header = try? JSONDecoder().decode(Header.self, from: data),
              header.version >= 1
        else { throw StudyTimeBackupError.unreadable }

        guard header.version <= currentVersion else {
            throw StudyTimeBackupError.newerVersion(header.version)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            // Whole seconds too, for a file edited by hand or another tool.
            guard let date = (try? Date.ISO8601FormatStyle.iso8601WithFractionalSeconds.parse(string))
                    ?? (try? Date.ISO8601FormatStyle().parse(string))
            else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Not an ISO 8601 date: \(string)"
                )
            }
            return date
        }

        do {
            return try decoder.decode(StudyTimeBackup.self, from: data)
        } catch {
            throw StudyTimeBackupError.unreadable
        }
    }
}

extension FormatStyle where Self == Date.ISO8601FormatStyle {

    /// Without the fractions a round trip would move every session start.
    static var iso8601WithFractionalSeconds: Self {
        Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    }
}

extension UTType {

    /// A `.studytime` file. Declared in Info.plist, whose identifier this must match.
    static let studyTimeBackup = UTType(exportedAs: "sbs.studytime.backup", conformingTo: .json)
}
