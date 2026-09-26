import Foundation
import UserNotifications
import Programme

/// Reads and takes delivered reminders off Notification Centre (reminders
/// spec, "Delivered reminders are grouped and removed").
/// `ReminderCoordinator` reads them before it takes them off, and folds the
/// same reading into the morning-plan unanswered count and the silent-day
/// count, as the spec requires.
enum DeliveredReminderCleanup {
    /// Every delivered Midmorning reminder, as `DeliveredReminderRemoval`
    /// reads it, with no window end yet (the coordinator adds it from the
    /// live plan).
    static func reminders(in notifications: [UNNotification]) -> [DeliveredReminder] {
        notifications.compactMap { notification -> DeliveredReminder? in
            let content = notification.request.content
            guard let dayKey = content.userInfo["dayKey"] as? String else { return nil }
            // A planned meal reminder's userInfo carries the seven keys the
            // reminders spec names, with a slot index and no "kind" key (the
            // "kind" key is this App target's own addition for every other
            // reminder type's userInfo).
            if content.userInfo["slotIndex"] != nil {
                return DeliveredReminder(id: notification.request.identifier, kind: .plannedMeal, dayKey: dayKey)
            }
            guard let kindRaw = content.userInfo["kind"] as? String, let kind = ReminderKind(rawValue: kindRaw) else { return nil }
            return DeliveredReminder(id: notification.request.identifier, kind: kind, dayKey: dayKey)
        }
    }

    /// Reads every delivered Midmorning reminder and answers on any queue.
    static func readDelivered(_ completion: @escaping @Sendable ([DeliveredReminder]) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            completion(reminders(in: notifications))
        }
    }

    /// Takes the reminders with these ids off Notification Centre.
    static func remove(ids: Set<String>) {
        guard !ids.isEmpty else { return }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: Array(ids))
    }

    /// At launch: every delivered reminder off Notification Centre,
    /// whatever its day or window (reminders spec, "Launch": "Notification
    /// Centre holds no Midmorning reminder after Today appears").
    static func removeAllAtLaunch() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
