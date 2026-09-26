import Foundation

// MARK: - Delivered reminders are grouped and removed (reminders spec,
// "Delivered reminders are grouped and removed")

/// One reminder still in Notification Centre.
public struct DeliveredReminder: Sendable, Equatable {
    public var id: String
    public var kind: ReminderKind
    public var dayKey: String
    /// A planned meal only: the clock time its window ends, that day.
    public var windowEndTime: String?

    public init(id: String, kind: ReminderKind, dayKey: String, windowEndTime: String? = nil) {
        self.id = id
        self.kind = kind
        self.dayKey = dayKey
        self.windowEndTime = windowEndTime
    }
}

public enum DeliveredReminderRemoval {
    /// The ids to take off Notification Centre right now: every reminder of
    /// an earlier record day, plus a planned meal reminder whose window has
    /// ended.
    public static func idsToRemove(delivered: [DeliveredReminder], currentRecordDayKey: String, nowClockTime: String) -> Set<String> {
        var ids: Set<String> = []
        for reminder in delivered {
            if reminder.dayKey < currentRecordDayKey {
                ids.insert(reminder.id)
                continue
            }
            if reminder.dayKey == currentRecordDayKey, reminder.kind == .plannedMeal, let end = reminder.windowEndTime,
               ReminderClock.minutesOfDay(nowClockTime) >= ReminderClock.minutesOfDay(end) {
                ids.insert(reminder.id)
            }
        }
        return ids
    }
}

// MARK: - The Diagnostics counts (settings spec, "The About group")

public enum ReminderDiagnostics {
    /// The "pending reminders" count: every pending local notification
    /// request.
    public static func pendingReminderCount(_ requests: [ReminderRequest]) -> Int { requests.count }

    /// The "queue length" count: the action queue's own count.
    public static func queueLength(_ queuedActionCount: Int) -> Int { queuedActionCount }
}

// MARK: - Reminder types and their switches (reminders spec: notification
// permission text)

public enum NotificationPermission: Sendable, Equatable {
    case notDetermined, denied, granted
}

/// The fixed sentences the Reminders group and Today show for each
/// notification-permission state (reminders spec, "Reminder types and their
/// switches").
public enum ReminderPermissionText {
    public static let groupNotDeterminedLine = "Reminders need notification permission."
    public static let groupAllowControl = "Allow notifications"
    public static let groupDeniedLine = "Notifications are off in iOS Settings. The plan still shows on Today, and the Home Screen widget can show your next planned time."
    public static let todayLineBeforePermission = "Allow notifications to get reminders."
    public static let todayLineDenied = "Notifications are off in iOS Settings."
    public static let eachDeviceSendsItsOwn = "Each device sends its own reminders."

    /// Today's line, or `nil` to show none. `hasTappedDeniedLineOnce` is the
    /// device flag this capability keeps: after one tap on the denied line,
    /// Today hides it while permission stays denied (reminders spec: "After
    /// the person taps the line once, the app MUST hide it while permission
    /// stays denied.").
    public static func todayLine(permission: NotificationPermission, hasTappedDeniedLineOnce: Bool) -> String? {
        switch permission {
        case .notDetermined: return todayLineBeforePermission
        case .denied: return hasTappedDeniedLineOnce ? nil : todayLineDenied
        case .granted: return nil
        }
    }
}
