import Foundation
import UserNotifications
import Programme

/// Takes delivered reminders off Notification Centre (reminders spec,
/// "Delivered reminders are grouped and removed"). Reads before it removes,
/// so a caller can fold the same read into the morning-plan-unanswered and
/// silent-day counts, as the spec requires.
enum DeliveredReminderCleanup {
    /// Every delivered reminder, as `DeliveredReminderRemoval` reads it. A
    /// planned meal reminder's window end needs the live plan's window
    /// minutes (`Plan.PlanWindow`); `mm-t24.21` (wiring) supplies that from
    /// the real plan, so this reads every other reminder's day-boundary
    /// removal correctly today and leaves a planned meal's own window-end
    /// removal to that wiring.
    static func readDelivered(windowEndTime: @escaping @Sendable (_ dayKey: String, _ slotIndex: Int) -> String? = { _, _ in nil }, completion: @escaping @Sendable ([DeliveredReminder]) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let delivered = notifications.compactMap { notification -> DeliveredReminder? in
                let content = notification.request.content
                guard let dayKey = content.userInfo["dayKey"] as? String else { return nil }
                // A planned meal reminder's userInfo carries the seven keys
                // the reminders spec names, with a slot index and no "kind"
                // key (the "kind" key is this App target's own addition for
                // every other reminder type's userInfo).
                let slotIndex = (content.userInfo["slotIndex"] as? String).flatMap(Int.init)
                let kind: ReminderKind
                if slotIndex != nil {
                    kind = .plannedMeal
                } else if let kindRaw = content.userInfo["kind"] as? String, let parsed = ReminderKind(rawValue: kindRaw) {
                    kind = parsed
                } else {
                    return nil
                }
                let end = slotIndex.flatMap { windowEndTime(dayKey, $0) }
                return DeliveredReminder(id: notification.request.identifier, kind: kind, dayKey: dayKey, windowEndTime: end)
            }
            completion(delivered)
        }
    }

    /// Removes every id `DeliveredReminderRemoval.idsToRemove` names.
    static func removeDelivered(currentRecordDayKey: String, nowClockTime: String) {
        readDelivered { delivered in
            let ids = DeliveredReminderRemoval.idsToRemove(delivered: delivered, currentRecordDayKey: currentRecordDayKey, nowClockTime: nowClockTime)
            guard !ids.isEmpty else { return }
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: Array(ids))
        }
    }

    /// At launch: every delivered reminder off Notification Centre,
    /// whatever its day or window (reminders spec, "Launch": "Notification
    /// Centre holds no Midmorning reminder after Today appears").
    static func removeAllAtLaunch() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
