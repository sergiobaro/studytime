import Foundation
import Testing
@testable import studytime

struct CountdownAlertTests {

    let notifier: RecordingCountdownNotifier
    let timer: StudyTimer
    let alert: CountdownAlert

    init() {
        self.notifier = RecordingCountdownNotifier()
        self.timer = StudyTimer(store: InMemoryKeyValueStore())
        self.alert = CountdownAlert(notifier: notifier)
    }

    @Test func startingACountdownSchedulesTheAlertForWhenItReachesZero() {
        timer.durationMinutes = 25

        timer.toggle()
        alert.update(for: timer)

        #expect(notifier.scheduledSeconds == 25 * 60)
    }

    @Test func resumingReschedulesForTheTimeLeft() {
        timer.durationMinutes = 1
        timer.toggle()
        for _ in 0..<20 { timer.tick() }
        timer.toggle()
        alert.update(for: timer)

        timer.toggle()
        alert.update(for: timer)

        #expect(notifier.scheduledSeconds == 40)
    }

    @Test func pausingCancelsTheAlert() {
        timer.toggle()
        alert.update(for: timer)
        timer.tick()

        timer.toggle()
        alert.update(for: timer)

        #expect(notifier.scheduledSeconds == nil)
    }

    @Test func finishingEarlyCancelsTheAlert() {
        timer.toggle()
        alert.update(for: timer)

        timer.reset()
        alert.update(for: timer)

        #expect(notifier.scheduledSeconds == nil)
    }

    @Test func switchingToTheStopwatchCancelsTheAlert() {
        timer.toggle()
        alert.update(for: timer)

        timer.mode = .stopwatch
        alert.update(for: timer)

        #expect(notifier.scheduledSeconds == nil)
    }

    @Test func reachingZeroLeavesTheAlertToGoOff() {
        timer.durationMinutes = 1
        timer.toggle()
        alert.update(for: timer)

        for _ in 0..<60 { timer.tick() }
        alert.update(for: timer)

        #expect(timer.isFinished)
        #expect(notifier.scheduledSeconds == 60)
    }

    @Test func aStopwatchNeverSchedulesAnAlert() {
        timer.mode = .stopwatch

        timer.toggle()
        alert.update(for: timer)

        #expect(notifier.scheduledSeconds == nil)
    }
}

final class RecordingCountdownNotifier: CountdownNotifier {
    /// The pending alert's delay, or `nil` when none is pending.
    private(set) var scheduledSeconds: Int?

    func scheduleAlert(in seconds: Int) {
        scheduledSeconds = seconds
    }

    func cancelAlert() {
        scheduledSeconds = nil
    }
}
