import Foundation
import UserNotifications

/// Delivers the countdown alert as a local notification with a sound.
final class SystemCountdownNotifier: NSObject, CountdownNotifier {

    static let shared = SystemCountdownNotifier()

    private static let requestIdentifier = "countdownFinished"

    private let center = UNUserNotificationCenter.current()
    /// Bumped on every schedule and cancel, so a schedule still waiting on
    /// authorization doesn't land after the user has already paused.
    private var generation = 0

    /// Call at launch, before any notification can arrive.
    func activate() {
        center.delegate = self
        // A running countdown doesn't survive a relaunch, so neither should its alert.
        cancelAlert()
    }

    func scheduleAlert(in seconds: Int) {
        generation += 1
        let scheduled = generation

        let content = UNMutableNotificationContent()
        content.title = "Time's up"
        content.body = "Your countdown has finished."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(seconds, 1)), repeats: false)
        let request = UNNotificationRequest(identifier: Self.requestIdentifier, content: content, trigger: trigger)

        Task {
            // Permission is asked the first time a countdown starts, when the
            // reason for it is obvious; later calls return straight away.
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted, scheduled == generation else { return }
            // The completion-handler form queues the request right here, with
            // no suspension in which a cancel could slip ahead of it.
            center.add(request, withCompletionHandler: nil)
        }
    }

    func cancelAlert() {
        generation += 1
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier])
    }
}

extension SystemCountdownNotifier: UNUserNotificationCenterDelegate {

    // Without this the system drops notifications that arrive while the app is open.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
