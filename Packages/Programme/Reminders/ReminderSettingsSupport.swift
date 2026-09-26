import Foundation
import Constants

// MARK: - Delivered reminders are grouped and removed (reminders spec,
// "Delivered reminders are grouped and removed")

/// One reminder still in Notification Centre.
public struct DeliveredReminder: Sendable, Equatable {
    public var id: String
    public var kind: ReminderKind
    public var dayKey: String
    /// A planned meal only: the clock time its window ends, that day.
    public var windowEndTime: String?
    /// A planned meal only: an entry matched it, or the person answered
    /// it (reminders spec, "A reminder for every planned meal": "When an
    /// entry matches a planned meal after its reminder's delivery, the app
    /// MUST take that reminder off Notification Centre.").
    public var recordedOrAnswered: Bool

    public init(id: String, kind: ReminderKind, dayKey: String, windowEndTime: String? = nil, recordedOrAnswered: Bool = false) {
        self.id = id
        self.kind = kind
        self.dayKey = dayKey
        self.windowEndTime = windowEndTime
        self.recordedOrAnswered = recordedOrAnswered
    }
}

public enum DeliveredReminderRemoval {
    /// The ids to take off Notification Centre right now: every reminder of
    /// an earlier record day, plus a planned meal reminder whose window has
    /// ended or that an entry or an answer settled. `dayStartMinute` is the current record day's day-start clock
    /// minute: both clock times are ordered from it, so a window that ends
    /// after midnight is still open in the evening.
    public static func idsToRemove(delivered: [DeliveredReminder], currentRecordDayKey: String, nowClockTime: String, dayStartMinute: Int = 0) -> Set<String> {
        var ids: Set<String> = []
        for reminder in delivered {
            if reminder.dayKey < currentRecordDayKey {
                ids.insert(reminder.id)
                continue
            }
            if reminder.dayKey == currentRecordDayKey, reminder.kind == .plannedMeal, reminder.recordedOrAnswered {
                ids.insert(reminder.id)
                continue
            }
            if reminder.dayKey == currentRecordDayKey, reminder.kind == .plannedMeal, let end = reminder.windowEndTime,
               ClockTime.minutesSinceDayStart(nowClockTime, dayStartMinute: dayStartMinute) >= ClockTime.minutesSinceDayStart(end, dayStartMinute: dayStartMinute) {
                ids.insert(reminder.id)
            }
        }
        return ids
    }
}

// MARK: - Reminder types and their switches (reminders spec: notification
// permission text)

public enum NotificationPermission: Sendable, Equatable {
    case notDetermined, denied, granted
}

/// The fixed sentences the Reminders group and Today show for each
/// notification-permission state (reminders spec, "Reminder types and their
/// switches"). Each one is the catalogue key the Reminders group and Today
/// show (content spec, "Strings live in catalogues").
public enum ReminderPermissionText {
    public static let groupNotDeterminedLine: CatalogueText = .key("settings.reminders.notDetermined.line")
    public static let groupAllowControl: CatalogueText = .key("settings.reminders.notDetermined.allowControl")
    public static let groupDeniedLine: CatalogueText = .key("settings.reminders.denied.line")
    public static let todayLineBeforePermission: CatalogueText = .key("today.reminders.notDetermined")
    public static let todayLineDenied: CatalogueText = .key("today.reminders.denied")
    public static let eachDeviceSendsItsOwn: CatalogueText = .key("settings.reminders.eachDeviceCaption")

    /// Today's line, or `nil` to show none. `hasTappedDeniedLineOnce` is the
    /// device flag this capability keeps: after one tap on the denied line,
    /// Today hides it while permission stays denied (reminders spec: "After
    /// the person taps the line once, the app MUST hide it while permission
    /// stays denied.").
    /// `anySwitchOn` is false when the person turned every reminder switch
    /// off: the denied line then does not show ("When permission is denied
    /// and any switch is on, Today MUST show a line").
    public static func todayLine(permission: NotificationPermission, hasTappedDeniedLineOnce: Bool, anySwitchOn: Bool = true) -> CatalogueText? {
        switch permission {
        case .notDetermined: return todayLineBeforePermission
        case .denied: return hasTappedDeniedLineOnce || !anySwitchOn ? nil : todayLineDenied
        case .granted: return nil
        }
    }
}
