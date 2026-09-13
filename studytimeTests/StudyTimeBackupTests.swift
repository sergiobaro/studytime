import Foundation
import Testing
@testable import studytime

struct StudyTimeBackupTests {

    let store = InMemoryKeyValueStore()
    /// Has a fractional part, so a round trip that dropped it would show.
    let date = Date(timeIntervalSinceReferenceDate: 800_000_000.25)

    /// Two tasks, the first with a recorded session and the second selected.
    func populatedList() -> TaskList {
        let tasks = TaskList(store: InMemoryKeyValueStore(), now: { [date] in date })
        tasks.add(named: "Maths")
        tasks.recordStudied(seconds: 90)
        tasks.add(named: "Reading")
        return tasks
    }

    @Test func aBackupSurvivesTheRoundTripThroughAFile() throws {
        let backup = populatedList().backup()

        let decoded = try StudyTimeBackup.decoded(from: backup.encoded())

        #expect(decoded == backup)
        #expect(decoded.version == StudyTimeBackup.currentVersion)
    }

    @Test func restoringReplacesEveryTaskAndTheSelection() throws {
        let source = populatedList()
        let target = TaskList(store: store)
        target.add(named: "Old")

        try target.restore(source.backup())

        #expect(target.tasks == source.tasks)
        #expect(target.selectedTaskID == source.selectedTaskID)
    }

    @Test func aRestoreSurvivesRelaunch() throws {
        let source = populatedList()
        try TaskList(store: store).restore(source.backup())

        // A second list over the same store stands in for a relaunch.
        let relaunched = TaskList(store: store)
        #expect(relaunched.tasks == source.tasks)
        #expect(relaunched.selectedTaskID == source.selectedTaskID)
    }

    @Test func restoringEndsTheSessionInProgress() throws {
        let target = TaskList(store: store)
        target.add(named: "Maths")
        target.recordStudied(seconds: 5)
        #expect(target.sessionInProgress != nil)

        try target.restore(populatedList().backup())

        #expect(target.sessionInProgress == nil)
    }

    @Test func aSelectionNamingNoTaskIsDropped() throws {
        var backup = populatedList().backup()
        backup.selectedTaskID = UUID()
        let target = TaskList(store: store)

        try target.restore(backup)

        #expect(target.selectedTaskID == nil)
    }

    @Test func namesAreTidiedOnRestore() throws {
        var backup = populatedList().backup()
        backup.tasks[0].name = "  Maths  "
        let target = TaskList(store: store)

        try target.restore(backup)

        #expect(target.tasks[0].name == "Maths")
    }

    @Test func aBackupWithRepeatedNamesIsRejectedAndChangesNothing() {
        var backup = populatedList().backup()
        backup.tasks[1].name = " maths "
        let target = TaskList(store: store)
        target.add(named: "Old")

        #expect(throws: StudyTimeBackupError.invalidContents) {
            try target.restore(backup)
        }
        #expect(target.tasks.map(\.name) == ["Old"])
    }

    @Test func aBackupWithABlankNameIsRejected() {
        var backup = populatedList().backup()
        backup.tasks[0].name = "   "

        #expect(throws: StudyTimeBackupError.invalidContents) {
            try TaskList(store: store).restore(backup)
        }
    }

    @Test func aBackupWithRepeatedSessionsIsRejected() {
        var backup = populatedList().backup()
        backup.tasks[1].sessions = backup.tasks[0].sessions

        #expect(throws: StudyTimeBackupError.invalidContents) {
            try TaskList(store: store).restore(backup)
        }
    }

    @Test func aFileFromANewerVersionIsRefused() {
        let data = Data(#"{"version": 99, "somethingNew": true}"#.utf8)

        #expect(throws: StudyTimeBackupError.newerVersion(99)) {
            try StudyTimeBackup.decoded(from: data)
        }
    }

    @Test func somethingThatIsNotABackupIsUnreadable() {
        #expect(throws: StudyTimeBackupError.unreadable) {
            try StudyTimeBackup.decoded(from: Data("not json".utf8))
        }
        #expect(throws: StudyTimeBackupError.unreadable) {
            try StudyTimeBackup.decoded(from: Data(#"{"version": 1}"#.utf8))
        }
    }

    @Test func datesWithoutFractionalSecondsStillLoad() throws {
        let json = #"{"version": 1, "exportedAt": "2026-09-13T10:00:00Z", "tasks": []}"#

        let backup = try StudyTimeBackup.decoded(from: Data(json.utf8))

        #expect(backup.tasks.isEmpty)
        #expect(backup.selectedTaskID == nil)
    }
}
