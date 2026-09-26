import Foundation
import Constants

/// The shared PDF's file name (export spec, "What the PDF never contains":
/// "The PDF and its file name MUST NOT contain the product name or the
/// person's name."). `fromDayKey`/`toDayKey` are record day keys
/// ("2026-08-28"), already in the app's neutral format. The words come from
/// the app's string catalogue (content spec, "Strings live in catalogues").
public enum ExportFileName {
    public static func name(fromDayKey: String, toDayKey: String) -> CatalogueText {
        .key("export.fileName", .verbatim(fromDayKey), .verbatim(toDayKey))
    }
}
