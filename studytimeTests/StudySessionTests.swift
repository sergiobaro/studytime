import Foundation
import Testing
@testable import studytime

struct StudySessionTests {

    let store: InMemoryKeyValueStore
    let tasks: TaskList
    /// A clock the test drives, so recorded dates are exact.
    let clock: Clock

    init() {
        self.store = InMemoryKeyValueStore()
        self.clock = Clock()
        self.tasks = TaskList(store: store, now: { [clock] in clock.now })
    }

    final class Clock {
        var now = Date(timeIntervalSinceReferenceDate: 1_000_000)

        func advance(_ seconds: TimeInterval) {
            now += seconds
        }
    }

    /// Runs the clock for `seconds`, a second at a time, the way the ticker does.
    private func study(seconds: Int) {
        for _ in 0..<seconds {
            clock.advance(1)
            tasks.recordStudied(seconds: 1)
        }
    }

    @Test func thefirstCountedSecondOpensASession() {
        tasks.add(named: "Maths")
        let start = clock.now

        study(seconds: 1)

        let session = try! #require(tasks.selectedTask?.sessions.first)
        // The second had already elapsed when it was counted.
        #expect(session.startedAt == start)
        #expect(session.endedAt == start.addingTimeInterval(1))
        #expect(session.seconds == 1)
    }

    @Test func furtherSecondsExtendTheSameSession() {
        tasks.add(named: "Maths")
        let start = clock.now

        study(seconds: 30)

        #expect(tasks.selectedTask?.sessions.count == 1)
        let session = try! #require(tasks.selectedTask?.sessions.first)
        #expect(session.startedAt == start)
        #expect(session.endedAt == start.addingTimeInterval(30))
        #expect(session.seconds == 30)
    }

    @Test func aPauseStaysInsideTheSameSession() {
        tasks.add(named: "Maths")
        let start = clock.now

        study(seconds: 10)
        // Paused: the clock moves on without counting.
        clock.advance(300)
        study(seconds: 5)

        #expect(tasks.selectedTask?.sessions.count == 1)
        let session = try! #require(tasks.selectedTask?.sessions.first)
        #expect(session.startedAt == start)
        #expect(session.endedAt == start.addingTimeInterval(315))
        // The gap is not studied time.
        #expect(session.seconds == 15)
    }

    @Test func endingASessionStartsAFreshOneOnTheNextSecond() {
        tasks.add(named: "Maths")

        study(seconds: 10)
        tasks.endSession()
        clock.advance(60)
        study(seconds: 5)

        let sessions = tasks.selectedTask?.sessions ?? []
        #expect(sessions.count == 2)
        #expect(sessions.first?.seconds == 10)
        #expect(sessions.last?.seconds == 5)
        #expect(sessions.last!.startedAt > sessions.first!.endedAt)
    }

    @Test func switchingTaskEndsTheRunInProgress() {
        let maths = tasks.add(named: "Maths")!
        study(seconds: 10)

        let reading = tasks.add(named: "Reading")!
        study(seconds: 4)

        #expect(tasks.tasks.first { $0.id == maths.id }?.sessions.count == 1)
        #expect(tasks.tasks.first { $0.id == reading.id }?.sessions.count == 1)
        #expect(tasks.selectedTask?.sessions.first?.seconds == 4)
    }

    @Test func theSessionInProgressIsReportedUntilItEnds() {
        tasks.add(named: "Maths")
        #expect(tasks.sessionInProgress == nil)

        study(seconds: 3)
        #expect(tasks.sessionInProgress?.seconds == 3)

        tasks.endSession()
        #expect(tasks.sessionInProgress == nil)
    }

    @Test func sessionTotalsAgreeWithTheTaskTotal() {
        tasks.add(named: "Maths")

        study(seconds: 10)
        tasks.endSession()
        study(seconds: 20)

        let task = try! #require(tasks.selectedTask)
        #expect(task.sessions.reduce(0) { $0 + $1.seconds } == task.studiedSeconds)
    }

    @Test func deletingASessionTakesItsTimeOutOfTheTotal() {
        tasks.add(named: "Maths")
        study(seconds: 10)
        tasks.endSession()
        study(seconds: 20)
        tasks.endSession()

        let first = try! #require(tasks.selectedTask?.sessions.first)
        tasks.removeSession(first.id)

        let task = try! #require(tasks.selectedTask)
        #expect(task.sessions.count == 1)
        #expect(task.sessions.first?.seconds == 20)
        #expect(task.studiedSeconds == 20)
        // The invariant the history relies on still holds.
        #expect(task.sessions.reduce(0) { $0 + $1.seconds } == task.studiedSeconds)
    }

    @Test func deletingTheRunInProgressStopsItCollecting() {
        tasks.add(named: "Maths")
        study(seconds: 10)

        let open = try! #require(tasks.sessionInProgress)
        tasks.removeSession(open.id)
        #expect(tasks.sessionInProgress == nil)

        // The next second opens a fresh session rather than reviving the old one.
        study(seconds: 5)
        #expect(tasks.selectedTask?.sessions.count == 1)
        #expect(tasks.selectedTask?.sessions.first?.seconds == 5)
        #expect(tasks.selectedTask?.studiedSeconds == 5)
    }

    @Test func deletingAnUnknownSessionChangesNothing() {
        tasks.add(named: "Maths")
        study(seconds: 10)

        tasks.removeSession(UUID())

        #expect(tasks.selectedTask?.sessions.count == 1)
        #expect(tasks.selectedTask?.studiedSeconds == 10)
    }

    @Test func aDeletedSessionStaysDeletedAfterRelaunch() {
        tasks.add(named: "Maths")
        study(seconds: 10)
        tasks.endSession()
        study(seconds: 20)

        let first = try! #require(tasks.selectedTask?.sessions.first)
        tasks.removeSession(first.id)

        let relaunched = TaskList(store: store)
        #expect(relaunched.selectedTask?.sessions.count == 1)
        #expect(relaunched.selectedTask?.studiedSeconds == 20)
    }

    @Test func sessionsSurviveRelaunch() {
        tasks.add(named: "Maths")
        study(seconds: 7)

        let relaunched = TaskList(store: store)
        let session = try! #require(relaunched.selectedTask?.sessions.first)
        #expect(session.seconds == 7)
        #expect(relaunched.sessionInProgress == nil)
    }

    /// Tasks stored before sessions existed must still load — dropping them
    /// would take their totals with them.
    @Test func tasksStoredWithoutASessionLogStillLoad() {
        let legacy = """
        [{"id":"\(UUID().uuidString)","name":"Maths","studiedSeconds":4210}]
        """
        let loaded = TaskList(store: InMemoryKeyValueStore(["tasks": Data(legacy.utf8)]))

        #expect(loaded.tasks.map(\.name) == ["Maths"])
        #expect(loaded.tasks.first?.studiedSeconds == 4210)
        #expect(loaded.tasks.first?.sessions.isEmpty == true)
    }
}
