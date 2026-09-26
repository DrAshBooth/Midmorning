import Foundation

/// The two protection classes the store ever writes (data-and-privacy spec,
/// "File protection"). A database file (`Record.store`, `Local.store` and
/// each one's `-wal`/`-shm` side files) carries `.complete`. The action
/// queue and the widget snapshot, the App Group's two side files, carry
/// `.completeUntilFirstUserAuthentication`, because a background delivery
/// (a locked-state notification action, a widget timeline refresh) writes
/// them before the first unlock.
public enum StoreFileRole: Sendable, Equatable {
    case databaseFile
    case sideFile
}

public enum FileProtection {
    public static func protectionClass(for role: StoreFileRole) -> FileProtectionType {
        switch role {
        case .databaseFile: return .complete
        case .sideFile: return .completeUntilFirstUserAuthentication
        }
    }

    /// Sets `.complete` on every file directly inside `directory` (never
    /// recursing into a subdirectory, because the store directory holds no
    /// subdirectory). Skips a file it cannot read the attributes of rather
    /// than throw, so one locked or missing file never stops the others.
    public static func applyToDatabaseFiles(in directory: URL, fileManager: FileManager = .default) {
        guard let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        let protectionClass = protectionClass(for: .databaseFile)
        for file in contents {
            try? fileManager.setAttributes([.protectionKey: protectionClass], ofItemAtPath: file.path)
        }
    }

    /// Sets `NSFileProtectionComplete` and backup exclusion on `directory`
    /// itself (data-and-privacy spec, "File protection", "The app excludes
    /// the whole store directory from backups"). Both `StoreLayout
    /// .prepareStoreDirectory` (before every store open) and `LocalEraser
    /// .eraseAndRecreate` (Delete-all, "Delete from this device") call this
    /// on the same directory, so a fresh directory never loses either
    /// property, however it came to exist.
    public static func protectStoreDirectory(_ directory: URL, fileManager: FileManager = .default) throws {
        try fileManager.setAttributes([.protectionKey: protectionClass(for: .databaseFile)], ofItemAtPath: directory.path)
        try excludeFromBackup(directory)
    }

    /// Sets `NSFileProtectionCompleteUntilFirstUserAuthentication` and
    /// backup exclusion on one App Group side file, the action queue or the
    /// widget snapshot (data-and-privacy spec, "File protection": "Side
    /// files"; "The app excludes the whole store directory from backups":
    /// "The app MUST exclude every file it writes in the App Group
    /// container."). Call it after each write: an atomic write replaces
    /// the file, and the new file does not keep the old exclusion.
    public static func protectSideFile(_ file: URL, fileManager: FileManager = .default) throws {
        try fileManager.setAttributes([.protectionKey: protectionClass(for: .sideFile)], ofItemAtPath: file.path)
        try excludeFromBackup(file)
    }

    /// Sets `isExcludedFromBackup` on one file or directory.
    public static func excludeFromBackup(_ url: URL) throws {
        var mutableURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try mutableURL.setResourceValues(values)
    }
}
