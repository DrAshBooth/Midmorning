import UserNotifications
import Programme

/// Registers the notification categories and actions (reminders spec,
/// "Actions on a planned meal reminder"; widgets-and-intents spec,
/// "Notification actions are entry points"). The options on each
/// `UNNotificationAction` are the real, declarative iOS behaviour a device
/// check proves: `.authenticationRequired` for "Skipped", `.foreground` for
/// "Add", neither for the snooze action.
enum NotificationCategories {
    static func registerAll() {
        let snooze = UNNotificationAction(
            identifier: PlannedMealReminderAction.snooze.identifier,
            title: "Remind me in 15 minutes",
            options: []
        )
        let add = UNNotificationAction(
            identifier: PlannedMealReminderAction.add.identifier,
            title: "Add",
            options: [.foreground]
        )
        let skipped = UNNotificationAction(
            identifier: PlannedMealReminderAction.skipped.identifier,
            title: "Skipped",
            options: [.authenticationRequired]
        )
        let plannedMeal = UNNotificationCategory(
            identifier: ReminderKind.plannedMeal.notificationCategory,
            actions: [snooze, add, skipped],
            intentIdentifiers: [],
            options: []
        )
        let openOnly = UNNotificationCategory(
            identifier: "openOnly",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([plannedMeal, openOnly])
    }
}
