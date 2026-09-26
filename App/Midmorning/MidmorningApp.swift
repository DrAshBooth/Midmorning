import SwiftUI
import UIKit
import Record

@main
struct MidmorningApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let store: RecordStore

    init() {
        do {
            store = try RecordStore(directory: StoreLocation.directory())
        } catch {
            // The error carries no entry data. A store that cannot open is a
            // fault the person cannot fix; stop rather than run with no record.
            fatalError("The record store did not open: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(store: store)
                // The one place the tint is set: every control below inherits
                // the accent colour unless it overrides it, as the star
                // control does with the system grey (product-rules spec,
                // "Appearance").
                .tint(Color.accentColor)
        }
    }
}

/// Onboarding, once, before anything else (onboarding spec, "Four screens,
/// once, in order": "The app MUST show onboarding the first time the app
/// opens after install... MUST NOT show onboarding again after the person
/// completes it."). The app lock's own cover only ever sits over Today, so
/// gating here, above `AppLockRootView`, keeps the cover from showing before
/// the person has chosen it on screen 4.
struct AppRootView: View {
    let store: RecordStore
    @State private var isOnboardingCompleted: Bool

    init(store: RecordStore) {
        self.store = store
        _isOnboardingCompleted = State(initialValue: (try? store.onboardingCompleted()) ?? false)
    }

    var body: some View {
        if isOnboardingCompleted {
            AppLockRootView(store: store)
        } else {
            OnboardingRootView(store: store) { isOnboardingCompleted = true }
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

    /// Creates the `Record` directory under Application Support with
    /// NSFileProtectionComplete and backup exclusion, so `Record.store`,
    /// `Local.store` and their -wal and -shm files all inherit both
    /// (data-and-privacy spec, "The store lives in the app's own
    /// container"; "Two store configurations in one directory"). Returns the
    /// directory; `RecordStore` places both files inside it.
    static func directory() throws -> URL {
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = StoreLayout.storeDirectory(applicationSupportDirectory: support)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: directory.path)
        var mutableDirectory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try mutableDirectory.setResourceValues(values)
        return directory
    }
}
