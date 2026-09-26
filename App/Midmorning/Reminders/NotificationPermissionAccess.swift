import UIKit
import UserNotifications
import Programme

/// The one reader and requester of notification permission, shared by
/// Today, the Reminders group and onboarding Screen 4 (reminders spec,
/// "Reminder types and their switches"). One option set for every request:
/// an alert and a sound, never a badge ("Discreet text by default": "The
/// app MUST NOT show a number on the app icon.").
enum NotificationPermissionAccess {
    static let options: UNAuthorizationOptions = [.alert, .sound]

    /// Reads the permission and answers on the main actor.
    static func read(_ completion: @escaping @MainActor (NotificationPermission) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let permission = permission(for: settings.authorizationStatus)
            Task { @MainActor in completion(permission) }
        }
    }

    /// Makes the system permission request, then reads the permission and
    /// answers on the main actor. When the person has already answered,
    /// iOS shows no dialog and the answer is the current permission.
    static func request(_ completion: @escaping @MainActor (NotificationPermission) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: options) { _, _ in
            read(completion)
        }
    }

    /// Opens this app's page in the iOS Settings app.
    @MainActor
    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    static func permission(for status: UNAuthorizationStatus) -> NotificationPermission {
        switch status {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        default: return .granted
        }
    }
}
