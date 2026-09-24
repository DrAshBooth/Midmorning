import SwiftUI
import UIKit
import RecordCore

@main
struct MidmorningApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let store: RecordStore

    init() {
        do {
            store = try RecordStore(url: StoreLocation.url())
        } catch {
            // The error carries no entry data. A store that cannot open is a
            // fault the person cannot fix; stop rather than run with no record.
            fatalError("The record store did not open: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TodayView(store: store)
        }
    }
}

/// Blocks third-party keyboards so no keyboard extension reads What.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     shouldAllowExtensionPointIdentifier identifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        identifier != .keyboard
    }
}

/// Where the store file lives: the App Group container, so the widget,
/// notification actions and App Intents can reach it later.
enum StoreLocation {
    static let appGroup = "group.uk.midmorning"

    /// Creates `Library/Application Support` in the group container with
    /// NSFileProtectionComplete and backup exclusion, so the store and its
    /// -wal and -shm files inherit both. Returns the store file's URL.
    static func url() throws -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            throw StoreLocationError.noAppGroupContainer
        }
        var directory = container.appendingPathComponent("Library/Application Support", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: directory.path)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        return directory.appendingPathComponent("Record.store")
    }

    enum StoreLocationError: Error {
        case noAppGroupContainer
    }
}
