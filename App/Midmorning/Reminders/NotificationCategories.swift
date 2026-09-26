import Foundation
import UserNotifications
import Constants
import Programme

/// Registers the notification categories and actions (reminders spec,
/// "Actions on a planned meal reminder"; widgets-and-intents spec,
/// "Notification actions are entry points"). The options on each
/// `UNNotificationAction` are the real, declarative iOS behaviour a device
/// check proves: `.authenticationRequired` for "Skipped", `.foreground` for
/// "Add", neither for the snooze action. Every title is a catalogue entry;
/// the snooze title is "Remind me in %lld minutes" with its plural form,
/// filled from SNOOZE_MINUTES (reminders spec, "Snooze a reminder").
enum NotificationCategories {
    /// At launch, before the store opens: registers the categories only
    /// when none exist yet. iOS keeps the categories the app registered
    /// last, so the snooze title the person chose stays until
    /// `ReminderCoordinator` registers it again from the store.
    static func registerAll() {
        UNUserNotificationCenter.current().getNotificationCategories { existing in
            guard !existing.contains(where: { $0.identifier == ReminderKind.plannedMeal.notificationCategory }) else { return }
            register(snoozeMinutes: ProgrammeConstants.default.snoozeMinutes)
        }
    }

    /// Registers both categories with the snooze title for `snoozeMinutes`.
    static func register(snoozeMinutes: Int) {
        let snooze = UNNotificationAction(
            identifier: PlannedMealReminderAction.snooze.identifier,
            title: snoozeTitle(minutes: snoozeMinutes),
            options: []
        )
        let add = UNNotificationAction(
            identifier: PlannedMealReminderAction.add.identifier,
            title: String(localized: "reminders.action.add"),
            options: [.foreground]
        )
        let skipped = UNNotificationAction(
            identifier: PlannedMealReminderAction.skipped.identifier,
            title: String(localized: "reminders.action.skipped"),
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

    /// "Remind me in %lld minutes", through the catalogue's plural form.
    static func snoozeTitle(minutes: Int) -> String {
        String(localized: "reminders.action.snooze \(minutes)")
    }
}
