import Foundation

/// Deletes the whole store directory and creates it again empty, with
/// `NSFileProtectionComplete` (data-and-privacy spec, "Delete-all", "Delete
/// from this device", "File protection"). Never opens a `ModelContainer` and
/// never touches iCloud; `4.1b` (`sync`) owns the erasure marker and the
/// sync zone (decision 45, design.md "Store opening is lazy and checks
/// protected data first").
public enum LocalEraser {
    /// Carries no path and no entry data.
    public enum Failure: Error {
        case eraseFailed
    }

    /// Deletes every item at `directory` when it exists, then creates
    /// `directory` again, empty, with `NSFileProtectionComplete` and
    /// excluded from backup (data-and-privacy spec, "The app excludes the
    /// whole store directory from backups": a fresh directory carries
    /// neither by default, so the new directory needs both set again, the
    /// same as the directory the app first creates).
    public static func eraseAndRecreate(directory: URL, fileManager: FileManager = .default) throws {
        do {
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
            }
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
            try FileProtection.protectStoreDirectory(directory, fileManager: fileManager)
        } catch {
            throw Failure.eraseFailed
        }
    }
}
