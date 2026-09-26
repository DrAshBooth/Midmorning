import Foundation

/// The one path to open the store on the device (data-and-privacy spec,
/// "File protection", "The app excludes the whole store directory from
/// backups"). SwiftData creates a missing directory with no backup
/// exclusion, so the app never lets it create the directory: it prepares
/// the directory first, on every open.
extension StoreLayout {
    /// Creates `Application Support/Record` when it does not exist yet, with
    /// `NSFileProtectionComplete`. Then sets `NSFileProtectionComplete` and
    /// backup exclusion on the directory again. The app calls this before
    /// each store open, so a directory from an earlier build that has no
    /// backup exclusion gets it at the next open. Returns the directory.
    public static func prepareStoreDirectory(applicationSupportDirectory: URL, fileManager: FileManager = .default) throws -> URL {
        let directory = storeDirectory(applicationSupportDirectory: applicationSupportDirectory)
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtection.protectionClass(for: .databaseFile)]
        )
        try FileProtection.protectStoreDirectory(directory, fileManager: fileManager)
        return directory
    }
}

extension RecordStore {
    /// Prepares the store directory, then opens `Record.store` and
    /// `Local.store` in it. The App target opens the store only through
    /// this call, so every open on the device sets backup exclusion first.
    public static func openInPreparedDirectory(applicationSupportDirectory: URL, fileManager: FileManager = .default) throws -> RecordStore {
        let directory = try StoreLayout.prepareStoreDirectory(applicationSupportDirectory: applicationSupportDirectory, fileManager: fileManager)
        return try RecordStore(directory: directory)
    }
}

/// The real names of the two side files in the App Group container
/// (widgets-and-intents spec, "The action queue"; data-and-privacy spec,
/// "Delete-all"). The writer, Delete-all and the backup exclusion all get
/// the path from here, so a name can never differ between them.
extension AppGroupContent {
    public static let actionQueueFileName = "queue.json"
    public static let snapshotFileName = "snapshot.json"

    public static func actionQueueURL(inAppGroupDirectory directory: URL) -> URL {
        directory.appendingPathComponent(actionQueueFileName, isDirectory: false)
    }

    public static func snapshotURL(inAppGroupDirectory directory: URL) -> URL {
        directory.appendingPathComponent(snapshotFileName, isDirectory: false)
    }
}
