import Foundation
import Record

/// Where the export PDF waits for the share sheet (export spec, "Share sheet
/// only": "The app MUST write the PDF to a temporary file with the store's
/// protection class ... no PDF file remains in the app's container"). Every
/// export goes in its own folder under one fixed folder, `tmp/Export`, so
/// the app can remove every PDF that a process left behind: at launch, and
/// at Delete-all and "Delete from this device" (data-and-privacy spec,
/// "Delete-all": "The app MUST leave no file"). At the same three times the
/// app also removes each other PDF in `tmp`, for the copy that Print makes
/// (`Record.TemporaryPDFFiles`, mm-t45.11).
public enum ExportTemporaryFiles {
    /// `tmp/Export`.
    public static func directory(inTemporaryDirectory temporaryDirectory: URL) -> URL {
        temporaryDirectory.appendingPathComponent("Export", isDirectory: true)
    }

    /// Writes `data` to `tmp/Export/<UUID>/<fileName>` with
    /// `NSFileProtectionComplete`, the class of the store's own files, and
    /// returns the file's URL.
    public static func write(_ data: Data, fileName: String, temporaryDirectory: URL, fileManager: FileManager = .default) throws -> URL {
        let folder = directory(inTemporaryDirectory: temporaryDirectory).appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(fileName)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    /// The launch sweep. Removes `tmp/Export` and every PDF in it, then
    /// each other PDF in `tmp` (`Record.TemporaryPDFFiles`): the copy that
    /// iOS keeps in `tmp/<UUID>/` while the print options show stays when
    /// the app ends first (mm-t45.11). A missing folder is not an error.
    /// Every item in `tmp` that is not a PDF stays.
    public static func removeAll(temporaryDirectory: URL, fileManager: FileManager = .default) {
        try? fileManager.removeItem(at: directory(inTemporaryDirectory: temporaryDirectory))
        try? TemporaryPDFFiles.removeAll(inTemporaryDirectory: temporaryDirectory, fileManager: fileManager)
    }
}
