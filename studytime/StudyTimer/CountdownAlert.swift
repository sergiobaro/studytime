import Foundation

/// Delivers the notification that tells the user a countdown has run out.
protocol CountdownNotifier: AnyObject {

    /// Schedules the alert to go off after `seconds`, replacing any pending one.
    func scheduleAlert(in seconds: Int)
    func cancelAlert()
}

/// Keeps the pending "time's up" alert in step with the timer.
///
/// The alert is scheduled for when the countdown will reach zero rather than
/// posted from the tick that gets there, so it still goes off while the app
/// is in the background.
final class CountdownAlert {

    private let notifier: CountdownNotifier

    init(notifier: CountdownNotifier = SystemCountdownNotifier.shared) {
        self.notifier = notifier
    }

    /// Call whenever the timer starts or stops.
    func update(for timer: StudyTimer) {
        if timer.isRunning && timer.mode == .countdown {
            notifier.scheduleAlert(in: timer.seconds)
        } else if !timer.isFinished {
            // Paused, reset or switched away: the countdown won't reach zero.
            // A finished one keeps its alert, which may still be about to fire.
            notifier.cancelAlert()
        }
    }
}
