import Foundation

/// Every PDF file in the app's temporary directory (`tmp`), at any depth
/// (bug mm-t45.11). The app writes its own export PDF to `tmp/Export`
/// (`Export.ExportTemporaryFiles`). iOS can write a copy of that PDF beside
/// it: when the person taps Print in the export share sheet, iOS writes the
/// PDF to `tmp/<UUID>/` and removes it when the print options close. When
/// the app ends while the print options show (a force-quit), that copy
/// stays. So the launch sweep (`ExportTemporaryFiles.removeAll`),
/// Delete-all and "Delete from this device" (`LocalDeletion`) remove each
/// PDF in `tmp`, not only `tmp/Export` (export spec, "Share sheet only":
/// "no PDF file remains in the app's container"; data-and-privacy spec,
/// "Delete-all": "The app MUST leave no file").
///
/// Only a file or a folder whose name ends in ".pdf" (in any case) goes.
/// Every other item in `tmp` stays: iOS and its frameworks keep their own
/// files there.
public enum TemporaryPDFFiles {
    /// Each item in `temporaryDirectory`, at any depth, whose name ends in
    /// ".pdf". A missing directory holds none.
    public static func urls(inTemporaryDirectory temporaryDirectory: URL, fileManager: FileManager = .default) -> [URL] {
        var found: [URL] = []
        walk(temporaryDirectory, fileManager: fileManager) { url, _ in found.append(url) }
        return found
    }

    /// Removes each PDF in `temporaryDirectory`, at any depth. A missing
    /// directory, or a file that goes while the sweep runs (iOS removes
    /// its print copy when the print options close), is not an error. A
    /// PDF that the sweep finds and cannot remove makes it throw, after it
    /// has tried each PDF, so that Delete-all never shows the deleted
    /// screen while a PDF stays.
    ///
    /// A folder that the sweep cannot read does not make it throw. The app
    /// writes its PDF, and iOS writes the print copy, in the app's own
    /// process, so each folder that holds one of them can be read. A folder
    /// of another owner must not stop Delete-all every time.
    public static func removeAll(inTemporaryDirectory temporaryDirectory: URL, fileManager: FileManager = .default) throws {
        var firstFailure: Error?
        walk(temporaryDirectory, fileManager: fileManager) { url, enumerator in
            // A folder named "*.pdf" goes with its contents, so the walk
            // does not go into it. (Only a folder: for a file, the walk
            // would skip the folder that it read last.)
            if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                enumerator.skipDescendants()
            }
            do {
                try fileManager.removeItem(at: url)
            } catch CocoaError.fileNoSuchFile {
                // Already gone.
            } catch {
                firstFailure = firstFailure ?? error
            }
        }
        if let firstFailure { throw firstFailure }
    }

    /// Calls `visit` for each item whose name ends in ".pdf".
    private static func walk(_ temporaryDirectory: URL, fileManager: FileManager, visit: (URL, FileManager.DirectoryEnumerator) -> Void) {
        guard let enumerator = fileManager.enumerator(at: temporaryDirectory, includingPropertiesForKeys: [.isDirectoryKey], options: [], errorHandler: { _, _ in true }) else { return }
        while let url = enumerator.nextObject() as? URL {
            if url.pathExtension.lowercased() == "pdf" {
                visit(url, enumerator)
            }
        }
    }
}
