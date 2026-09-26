import SwiftUI
import UIKit
import MetricKit
import UserNotifications
import Record

@main
struct MidmorningApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            // `RecordStore` opens lazily, inside `AppLockRootView`, only
            // once protected data is available (data-and-privacy spec,
            // "Launch safety", "File protection": "The app MUST open the
            // store container only when protected data is available. The
            // app MUST NOT call `fatalError` when the container fails to
            // open."). `AppDelegate.metricKitSubscriber` reaches the store
            // through the same view. Onboarding, once the store opens, is
            // `AppLockRootView`'s own gate (onboarding spec, "Four screens,
            // once, in order"), ahead of the cover.
            AppLockRootView(metricKitSubscriber: appDelegate.metricKitSubscriber)
                // The one place the tint is set: every control below inherits
                // the accent colour unless it overrides it, as the star
                // control does with the system grey (product-rules spec,
                // "Appearance").
                .tint(Color.accentColor)
        }
    }
}

/// Blocks third-party keyboards so no keyboard extension reads What
/// (data-and-privacy spec, "The app blocks third-party keyboards"); the
/// decision itself is `Record.KeyboardBlockPolicy.shouldAllow`, a pure
/// function `KeyboardBlockTests` proves with no UIKit import. Also registers
/// the one MetricKit subscriber the app ever has (data-and-privacy spec, "No
/// record content in the system log or crash reports": "The app MUST
/// receive MetricKit crash diagnostics"), and the notification categories
/// and action handler (reminders spec, "Actions on a planned meal
/// reminder"), before anything else runs.
final class AppDelegate: NSObject, UIApplicationDelegate {
    let metricKitSubscriber = MetricKitSubscriber()
    private let notificationActionHandling = NotificationActionHandling()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MXMetricManager.shared.add(metricKitSubscriber)
        UNUserNotificationCenter.current().delegate = notificationActionHandling
        NotificationCategories.registerAll()
        return true
    }

    func application(_ application: UIApplication,
                     shouldAllowExtensionPointIdentifier identifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        KeyboardBlockPolicy.shouldAllow(identifier == .keyboard ? .keyboard : .other)
    }
}

/// Where the store file lives: the app's own container. Only the app process
/// opens the store (decided 25 September 2026). The App Group holds only the
/// widget snapshot and the action queue (data-and-privacy spec, "The app
/// excludes the whole store directory from backups": both directories below
/// are excluded from backup; the App Group's own exclusion is each side
/// file's own job, added by `2.4`/`2.5`).
enum StoreLocation {
    static let appGroup = "group.uk.midmorning"

    /// The app's own `Application Support` directory, created if it does not
    /// exist yet. `directory()` and `LaunchMarker` both build their own path
    /// from this one root.
    static func applicationSupportDirectory() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    /// Creates the `Record` directory under Application Support with
    /// NSFileProtectionComplete and backup exclusion, so `Record.store`,
    /// `Local.store` and their -wal and -shm files all inherit both
    /// (data-and-privacy spec, "The store lives in the app's own
    /// container"; "Two store configurations in one directory"; "The app
    /// excludes the whole store directory from backups"). Returns the
    /// directory; `RecordStore` places both files inside it and protects
    /// each one in turn (data-and-privacy spec, "File protection").
    static func directory() throws -> URL {
        let directory = StoreLayout.storeDirectory(applicationSupportDirectory: try applicationSupportDirectory())
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        try FileProtection.protectStoreDirectory(directory)
        return directory
    }

    /// The App Group container, or `nil` when the device has none yet (no
    /// matching provisioning). Delete-all and "Delete from this device"
    /// treat a missing App Group as nothing to delete there, never an error;
    /// only the widget snapshot and the action queue live here, never the
    /// store (data-and-privacy spec, "The store lives in the app's own
    /// container"; `AppGroupContent.fileStems`).
    static func appGroupDirectory() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }

    /// The action queue file's own path inside the App Group container
    /// (widgets-and-intents spec, "The action queue").
    static func actionQueueURL() -> URL? {
        appGroupDirectory()?.appendingPathComponent("queue.json")
    }
}
