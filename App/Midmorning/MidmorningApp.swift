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

/// Where the store file lives: the app's own container. Only the app process
/// opens the store (decided 25 September 2026). The App Group holds only the
/// widget snapshot and the action queue, added by later changes.
enum StoreLocation {
    static let appGroup = "group.uk.midmorning"

    /// Creates a `Record` directory under Application Support with
    /// NSFileProtectionComplete and backup exclusion, so the store and its
    /// -wal and -shm files inherit both. Returns the store file's URL.
    static func url() throws -> URL {
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var directory = support.appendingPathComponent("Record", isDirectory: true)
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

}
