import Foundation

/// The two side effects Delete-all and "Delete from this device" both need,
/// beside the file deletion itself (data-and-privacy spec, "Delete-all":
/// "the app MUST first cancel every pending notification request. The app
/// MUST delete every delivered notification at the same step... The app
/// MUST reload every widget"). Named narrowly, for this one engine only;
/// `2.4` (reminders) builds its own `NotificationCentre` seam for the
/// scheduler, over the same system APIs, and may fold this in at that
/// epic's own merge.
public protocol DeleteAllSideEffects: Sendable {
    func cancelEveryNotification()
    func reloadWidgets()
}

/// The local half of Delete-all and "Delete from this device": every step
/// neither the erasure marker nor the sync zone touches (data-and-privacy
/// spec, "Delete-all", "Delete from this device"; `4.1b`, decision 45, owns
/// the "Erasure" zone). The App target's `RealDeleteAllSeam` is a thin
/// adapter over this engine, conforming to both `DeleteAllSeam` (the Privacy
/// group's "Delete everything") and `AppLock.DeleteAllPerforming` (the
/// cover); this is the tested part.
public struct LocalDeletion: Sendable {
    public let directory: URL
    public let appGroupDirectory: URL?
    public let launchMarkerURL: URL
    /// The folder that holds export PDFs in `tmp/` (`Export
    /// .ExportTemporaryFiles`), or `nil` when the caller has none. A PDF
    /// stays there when the process ends while the share sheet shows.
    public let exportDirectory: URL?

    public init(directory: URL, appGroupDirectory: URL?, launchMarkerURL: URL, exportDirectory: URL? = nil) {
        self.directory = directory
        self.appGroupDirectory = appGroupDirectory
        self.launchMarkerURL = launchMarkerURL
        self.exportDirectory = exportDirectory
    }

    /// Scenario: "Pending requests first" — cancels and deletes every
    /// notification before the store directory goes, so none can fire once
    /// the record is gone. Then deletes the whole store directory and
    /// creates it again empty, deletes the two side files, the launch
    /// marker and the export folder (each one only if it exists), and
    /// reloads every widget. Throws when a file that exists cannot be
    /// deleted ("The app MUST leave no file"), so the caller never shows
    /// the deleted screen for a deletion that did not happen.
    public func perform(sideEffects: DeleteAllSideEffects, fileManager: FileManager = .default) throws {
        sideEffects.cancelEveryNotification()
        try LocalEraser.eraseAndRecreate(directory: directory, fileManager: fileManager)
        if let appGroupDirectory {
            for url in AppGroupContent.fileURLs(inAppGroupDirectory: appGroupDirectory) {
                try removeIfPresent(url, fileManager: fileManager)
            }
        }
        try removeIfPresent(launchMarkerURL, fileManager: fileManager)
        if let exportDirectory {
            try removeIfPresent(exportDirectory, fileManager: fileManager)
        }
        sideEffects.reloadWidgets()
    }

    /// A missing file is already deleted; any other failure throws.
    private func removeIfPresent(_ url: URL, fileManager: FileManager) throws {
        do {
            try fileManager.removeItem(at: url)
        } catch CocoaError.fileNoSuchFile {
            return
        }
    }
}
