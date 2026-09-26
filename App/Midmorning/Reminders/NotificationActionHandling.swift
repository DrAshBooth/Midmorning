import Foundation
import UserNotifications
import Programme
import Record

extension Foundation.Notification.Name {
    /// Posted when a notification action (or a plain tap) should open the
    /// new-entry screen, locked or not (app-lock spec, "A new entry before
    /// authentication"; widgets-and-intents spec, "Notification actions are
    /// entry points"). `AppLockRootView` turns this into
    /// `AppLifecycleEvent.pendingRouteRequested(.newEntry)`.
    static let reminderAddActionTapped = Foundation.Notification.Name("uk.midmorning.reminderAddActionTapped")

    /// Posted on a plain tap on the weigh-in day reminder (reminders spec,
    /// "The weigh-in day reminder": "A tap MUST open the weigh-in
    /// screen."). `RunningRootView` presents `WeighInScreenView` over
    /// Today when it receives this.
    static let weighInReminderTapped = Foundation.Notification.Name("uk.midmorning.weighInReminderTapped")

    /// Posted on a plain tap on the weekly review reminder (reminders spec,
    /// "The weekly review reminder": "A tap MUST open the weekly review.").
    /// `AppLockRootView` presents `ReviewScreenView` over Today when it
    /// receives this.
    static let weeklyReviewReminderTapped = Foundation.Notification.Name("uk.midmorning.weeklyReviewReminderTapped")

    /// Posted after the handler wrote an action to the queue. While the app
    /// runs, `ReminderCoordinator` then applies the queue at once, so a
    /// "Skipped" reaches Today and a snooze reaches `Local.store` with no
    /// wait for the next activation.
    static let reminderActionQueued = Foundation.Notification.Name("uk.midmorning.reminderActionQueued")
}

/// Handles a planned meal reminder's three actions. Registered as
/// `UNUserNotificationCenter.current().delegate` in `AppDelegate`.
///
/// "Skipped" and the snooze action never open the store (app-lock spec: "The
/// handler MUST NOT open the store"): both only call `ActionQueueFile` and
/// `UNUserNotificationCenter`, plain file and framework calls, never
/// `RecordStore`. "Add" opens the app in the foreground (its
/// `UNNotificationAction` options say so) and posts `.reminderAddActionTapped`
/// so the pending-route rule shows the empty new-entry screen with no cover.
final class NotificationActionHandling: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content
        let dayKey = content.userInfo["dayKey"] as? String

        switch response.actionIdentifier {
        case PlannedMealReminderAction.skipped.identifier:
            if let dayKey, let slotIndex = intUserInfo(content, "slotIndex"), let plannedTime = content.userInfo["plannedTime"] as? String {
                ActionQueueFile.append(QueuedAction(kind: .skipped, dayKey: dayKey, slotIndex: slotIndex, plannedTime: plannedTime, snoozeCount: 0, moment: Date()))
                NotificationCenter.default.post(name: .reminderActionQueued, object: nil)
            }

        case PlannedMealReminderAction.snooze.identifier:
            handleSnooze(content: content, center: center)

        case PlannedMealReminderAction.add.identifier:
            NotificationCenter.default.post(name: .reminderAddActionTapped, object: nil)

        default:
            // A plain tap (`UNNotificationDefaultActionIdentifier`). Every
            // reminder kind but the weigh-in day and weekly review
            // reminders opens the app to Today, the system's own default
            // behaviour; each of those two names its own screen instead
            // (reminders spec, "The weigh-in day reminder", "The weekly
            // review reminder").
            switch content.userInfo["kind"] as? String {
            case ReminderKind.weighInDay.rawValue:
                NotificationCenter.default.post(name: .weighInReminderTapped, object: nil)
            case ReminderKind.weeklyReview.rawValue:
                NotificationCenter.default.post(name: .weeklyReviewReminderTapped, object: nil)
            default:
                break
            }
        }

        completionHandler()
    }

    /// Lets a reminder show its banner while the app is in the foreground —
    /// otherwise iOS shows nothing for a foreground app (design.md: the App
    /// target maps `ReminderRequest` to `UNNotificationRequest`, and this is
    /// the one piece of that mapping the delegate itself is responsible
    /// for).
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    private func handleSnooze(content: UNNotificationContent, center: UNUserNotificationCenter) {
        guard let userInfoDictionary = content.userInfo as? [String: String], let userInfo = ReminderUserInfo(dictionary: userInfoDictionary) else { return }
        let now = Date()
        switch SnoozeDecision.decide(userInfo: userInfo, now: now, calendar: .current) {
        case .drop:
            break
        case .scheduleAt(let when):
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: when), repeats: false)
            var nextUserInfo = userInfo
            nextUserInfo.snoozeCount += 1
            let newContent = UNMutableNotificationContent()
            newContent.title = content.title
            newContent.body = content.body
            newContent.sound = .default
            newContent.threadIdentifier = content.threadIdentifier
            newContent.categoryIdentifier = content.categoryIdentifier
            newContent.userInfo = nextUserInfo.dictionary
            let identifier = SnoozeDecision.requestIdentifier(dayKey: userInfo.dayKey, slotIndex: userInfo.slotIndex, snoozeCount: nextUserInfo.snoozeCount)
            center.add(UNNotificationRequest(identifier: identifier, content: newContent, trigger: trigger))
            ActionQueueFile.append(QueuedAction(kind: .snooze, dayKey: userInfo.dayKey, slotIndex: userInfo.slotIndex, plannedTime: userInfo.plannedTime, snoozeCount: nextUserInfo.snoozeCount, moment: now))
            NotificationCenter.default.post(name: .reminderActionQueued, object: nil)
        }
    }

    private func intUserInfo(_ content: UNNotificationContent, _ key: String) -> Int? {
        if let value = content.userInfo[key] as? Int { return value }
        if let text = content.userInfo[key] as? String { return Int(text) }
        return nil
    }
}
