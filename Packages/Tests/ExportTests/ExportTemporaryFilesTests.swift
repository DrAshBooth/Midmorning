import Foundation
import XCTest
@testable import Export

/// export spec, "Share sheet only" (mm-t42.24): every export PDF goes under
/// `tmp/Export`, the one folder the launch sweep and Delete-all remove.
/// `ExportComposer.writeTemporaryFile` (App target) calls `write`, and
/// `AppDelegate` calls `removeAll` at launch.
final class ExportTemporaryFilesTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("ExportTemporaryFilesTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testThePDFGoesUnderTheExportFolderWithCompleteProtection() throws {
        let url = try ExportTemporaryFiles.write(Data("%PDF".utf8), fileName: "Record 1 Oct to 7 Oct.pdf", temporaryDirectory: temporaryDirectory)

        let exportFolder = ExportTemporaryFiles.directory(inTemporaryDirectory: temporaryDirectory)
        XCTAssertEqual(url.deletingLastPathComponent().deletingLastPathComponent().standardizedFileURL, exportFolder.standardizedFileURL)
        XCTAssertEqual(url.lastPathComponent, "Record 1 Oct to 7 Oct.pdf")
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType, .complete)
    }

    /// A process that ended while the share sheet showed left a PDF; the
    /// next launch removes it.
    func testTheLaunchSweepRemovesEveryPDFThatAnEarlierProcessLeft() throws {
        let first = try ExportTemporaryFiles.write(Data("%PDF".utf8), fileName: "a.pdf", temporaryDirectory: temporaryDirectory)
        let second = try ExportTemporaryFiles.write(Data("%PDF".utf8), fileName: "b.pdf", temporaryDirectory: temporaryDirectory)

        ExportTemporaryFiles.removeAll(temporaryDirectory: temporaryDirectory)

        XCTAssertFalse(FileManager.default.fileExists(atPath: first.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: second.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: ExportTemporaryFiles.directory(inTemporaryDirectory: temporaryDirectory).path))
    }

    func testTheSweepWithNoExportFolderIsNotAnError() {
        ExportTemporaryFiles.removeAll(temporaryDirectory: temporaryDirectory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: ExportTemporaryFiles.directory(inTemporaryDirectory: temporaryDirectory).path))
    }
}
