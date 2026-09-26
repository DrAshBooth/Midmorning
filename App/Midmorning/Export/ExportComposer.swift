import Foundation
import Record
import Programme
import Export

/// The one seam that reads `RecordStore` and hands `Export`'s pure builders
/// what they need (export spec, "The PDF is formatted like the paper
/// record", "The optional weigh-in page"). Untested directly by `swift test`
/// (`no-app-target-test-runner`): `ExportDocumentBuilderTests` and
/// `ExportWeighInPageBuilderTests` prove the same composition over fixed
/// rows.
enum ExportComposer {
    /// export spec, "Offline and out of logs": "An error in the build of
    /// the PDF MUST carry no entry field and no weight value." A plain,
    /// data-free case, like `RecordStore.Failure`.
    enum Failure: Error {
        case buildFailed
    }

    @MainActor
    static func buildPDF(store: RecordStore, fromDayKey: String, toDayKey: String, includeContext: Bool, includeWeighIns: Bool, dayStartHour: Int) throws -> (data: Data, fileName: String) {
        let days: [ExportDayInput] = try ExportDayKey.range(from: fromDayKey, to: toDayKey).map { dayKey in
            ExportDayInput(dayKey: dayKey, entries: try store.entries(dayKey: dayKey), states: try store.dayStates(dateKey: dayKey))
        }

        var weighInLines: [ExportWeighInLine] = []
        if includeWeighIns {
            let unit = WeightUnit(rawValue: (try? store.weighInUnit()) ?? RecordStore.Defaults.weighInUnit) ?? .kg
            weighInLines = ExportWeighInPageBuilder.lines(from: try store.weighIns(), fromDayKey: fromDayKey, toDayKey: toDayKey, unit: unit)
        }

        let request = ExportBuildRequest(fromDayKey: fromDayKey, toDayKey: toDayKey, includeContext: includeContext, dayStartHour: dayStartHour)
        let document = ExportDocumentBuilder.build(request: request, days: days, weighInLines: weighInLines)
        let data = ExportPDFRenderer.render(document: document, title: document.pdfTitle)
        return (data, ExportFileName.name(fromDayKey: fromDayKey, toDayKey: toDayKey))
    }

    /// export spec, "Share sheet only": "The app MUST write the PDF to a
    /// temporary file with the store's protection class." The store's own
    /// files carry `NSFileProtectionComplete` (`Record.FileProtection`);
    /// `.completeFileProtection` is the same class for a plain file write.
    /// The file goes under `tmp/Export` (`Export.ExportTemporaryFiles`), the
    /// one folder the launch sweep and Delete-all remove.
    static func writeTemporaryFile(data: Data, fileName: String) throws -> URL {
        try ExportTemporaryFiles.write(data, fileName: fileName, temporaryDirectory: FileManager.default.temporaryDirectory)
    }

    /// export spec, "Share sheet only": "The app MUST delete the file when
    /// the share sheet closes." Removes the whole per-export directory, not
    /// only the file, so no empty directory is left behind either.
    static func deleteTemporaryFile(at url: URL) {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}
