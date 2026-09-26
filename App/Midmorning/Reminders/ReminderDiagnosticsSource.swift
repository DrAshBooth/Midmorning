import UserNotifications
import Record

/// The two Diagnostics counts that come from the device, not the store
/// (data-and-privacy spec, "The Diagnostics counts come from the device":
/// "pending reminders: the count of pending requests in the notification
/// centre; queue length: the count of actions in the action queue file").
struct ReminderDiagnosticsSource: DiagnosticsSourceCounts {
    let pendingReminders: Int
    let queueLength: Int

    /// Reads both counts and answers on the main actor.
    static func read(_ completion: @escaping @MainActor (ReminderDiagnosticsSource) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let pending = requests.count
            Task { @MainActor in
                completion(ReminderDiagnosticsSource(pendingReminders: pending, queueLength: ActionQueueFile.readAll().count))
            }
        }
    }
}
