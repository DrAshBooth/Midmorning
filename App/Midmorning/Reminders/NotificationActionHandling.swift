import Foundation
import UserNotifications
import Programme
import Record

/// Handles a planned meal reminder's three actions and a tap on any
/// reminder. Registered as `UNUserNotificationCenter.current().delegate` in
/// `AppDelegate`.
///
/// "Skipped" and the snooze action never open the store (app-lock spec: "The
/// handler MUST NOT open the store"): both only call `ActionQueueFile` and
/// `UNUserNotificationCenter`, plain file and framework calls, never
/// `RecordStore`. Every other response puts its `ReminderTapRoute` in the
/// inbox `AppDelegate` owns, and Today opens it when it can
/// (`ReminderRouteOpening`). "Add" opens the app in the foreground (its
/// `UNNotificationAction` options say so), and its route uses the
/// pending-route rule, so the empty new-entry screen shows with no cover.
final class NotificationActionHandling: NSObject, UNUserNotificationCenterDelegate {
    private let routes: ReminderRouteInbox

    init(routes: ReminderRouteInbox) {
        self.routes = routes
    }

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
            }

        case PlannedMealReminderAction.snooze.identifier:
            handleSnooze(content: content, center: center)

        default:
            // "Add" and a plain tap (`UNNotificationDefaultActionIdentifier`).
            if let route = ReminderTapRoute.forResponse(
                actionIdentifier: response.actionIdentifier,
                requestIdentifier: response.notification.request.identifier,
                kind: content.userInfo["kind"] as? String,
                dayKey: dayKey
            ) {
                let routes = self.routes
                Task { @MainActor in routes.request(route) }
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
        switch SnoozeDecision.decide(userInfo: userInfo, now: Date()) {
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
            let request = UNNotificationRequest(identifier: "snooze.\(userInfo.dayKey).\(userInfo.slotIndex).\(nextUserInfo.snoozeCount)", content: newContent, trigger: trigger)
            center.add(request)
            ActionQueueFile.append(QueuedAction(kind: .snooze, dayKey: userInfo.dayKey, slotIndex: userInfo.slotIndex, plannedTime: userInfo.plannedTime, snoozeCount: nextUserInfo.snoozeCount, moment: Date()))
        }
    }

    private func intUserInfo(_ content: UNNotificationContent, _ key: String) -> Int? {
        if let value = content.userInfo[key] as? Int { return value }
        if let text = content.userInfo[key] as? String { return Int(text) }
        return nil
    }
}
