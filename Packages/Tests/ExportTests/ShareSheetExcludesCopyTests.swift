import Foundation
import XCTest

/// r13-14 (mm-t42.27): the export share sheet does not offer Copy. There is
/// no App-target test runner, and `UIActivityViewController` is UIKit-only,
/// so this structural test reads the App sources. The device check in
/// mm-t42.14 proves the sheet on a device.
final class ShareSheetExcludesCopyTests: XCTestCase {
    private let appDirectory: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // ExportTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent() // repo root
        .appendingPathComponent("App/Midmorning", isDirectory: true)

    private func swiftSources() throws -> [(path: String, text: String)] {
        let enumerator = try XCTUnwrap(FileManager.default.enumerator(at: appDirectory, includingPropertiesForKeys: nil))
        var result: [(String, String)] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            result.append((url.lastPathComponent, try String(contentsOf: url, encoding: .utf8)))
        }
        return result
    }

    func testTheShareSheetExcludesCopy() throws {
        let text = try String(contentsOf: appDirectory.appendingPathComponent("Export/ShareSheetView.swift"), encoding: .utf8)
        XCTAssertTrue(text.contains("[.copyToPasteboard]"), "ShareSheetView lists Copy as an excluded activity")
        XCTAssertTrue(text.contains("controller.excludedActivityTypes = Self.excludedActivityTypes"), "ShareSheetView sets the excluded activities on the controller")
    }

    /// Every share sheet in the App goes through `ShareSheetView`, so no
    /// other sheet can offer Copy. `ShareLink` has no way to exclude Copy.
    func testNoOtherShareSheetInTheApp() throws {
        for source in try swiftSources() where source.path != "ShareSheetView.swift" {
            XCTAssertFalse(source.text.contains("UIActivityViewController("), "\(source.path) builds its own share sheet")
            XCTAssertFalse(source.text.contains("ShareLink("), "\(source.path) uses ShareLink, which offers Copy")
        }
    }
}
