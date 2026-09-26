import Foundation

/// The shared PDF's file name (export spec, "What the PDF never contains":
/// "The PDF and its file name MUST NOT contain the product name or the
/// person's name."). `fromDayKey`/`toDayKey` are record day keys
/// ("2026-08-28"), already in the app's neutral format.
public enum ExportFileName {
    public static func name(fromDayKey: String, toDayKey: String) -> String {
        "Record \(fromDayKey) to \(toDayKey).pdf"
    }
}
