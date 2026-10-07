import Foundation
import XCTest
@testable import Export
import Record

/// export spec, "Share sheet only" (mm-t42.24): every export PDF goes under
/// `tmp/Export`, the one folder the launch sweep and Delete-all remove.
/// `ExportComposer.writeTemporaryFile` (App target) calls `write`, and
/// `AppDelegate` calls `removeAll` at launch. The launch sweep also removes
/// each other PDF in `tmp` (mm-t45.11).
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

    /// mm-t45.11: when the person taps Print, iOS writes its own copy of
    /// the PDF to `tmp/<UUID>/`. A force-quit while the print options show
    /// leaves that copy, so the launch sweep removes each PDF in `tmp`, at
    /// any depth and in any case of ".pdf", not only `tmp/Export`. Each item
    /// that is not a PDF stays.
    func testTheLaunchSweepRemovesThePrintCopyAndEveryOtherPDFInTmp() throws {
        let manager = FileManager.default
        let exported = try ExportTemporaryFiles.write(Data("%PDF".utf8), fileName: "Record 2026-10-07 to 2026-10-07.pdf", temporaryDirectory: temporaryDirectory)
        let printFolder = temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try manager.createDirectory(at: printFolder, withIntermediateDirectories: true)
        let printCopy = printFolder.appendingPathComponent("Record 2026-10-07 to 2026-10-07.pdf")
        let upperCase = temporaryDirectory.appendingPathComponent("Record.PDF")
        let deep = temporaryDirectory.appendingPathComponent("a/b/c", isDirectory: true)
        try manager.createDirectory(at: deep, withIntermediateDirectories: true)
        let deepCopy = deep.appendingPathComponent("Record.pdf")
        let secondPrintFolder = temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try manager.createDirectory(at: secondPrintFolder, withIntermediateDirectories: true)
        let secondPrintCopy = secondPrintFolder.appendingPathComponent("Record 2026-10-06 to 2026-10-06.pdf")
        for url in [printCopy, upperCase, deepCopy, secondPrintCopy] {
            try Data("%PDF".utf8).write(to: url)
        }
        // A folder whose name ends in ".pdf" goes with its contents.
        let folderNamedPDF = temporaryDirectory.appendingPathComponent("Bundle.pdf", isDirectory: true)
        try manager.createDirectory(at: folderNamedPDF, withIntermediateDirectories: true)
        try Data("%PDF".utf8).write(to: folderNamedPDF.appendingPathComponent("inner.pdf"))
        let besidePrintCopy = printFolder.appendingPathComponent("notes.txt")
        let systemFile = temporaryDirectory.appendingPathComponent("com.apple.cache.db")
        let folderNamedPdf = temporaryDirectory.appendingPathComponent("pdf", isDirectory: true)
        try manager.createDirectory(at: folderNamedPdf, withIntermediateDirectories: true)
        let insideFolderNamedPdf = folderNamedPdf.appendingPathComponent("keep.dat")
        for url in [besidePrintCopy, systemFile, insideFolderNamedPdf] {
            try Data("x".utf8).write(to: url)
        }
        XCTAssertEqual(TemporaryPDFFiles.urls(inTemporaryDirectory: temporaryDirectory).count, 7, "the set-up puts six PDF files and one folder named \"Bundle.pdf\" in tmp")

        ExportTemporaryFiles.removeAll(temporaryDirectory: temporaryDirectory)

        for url in [exported, printCopy, upperCase, deepCopy, secondPrintCopy, folderNamedPDF] {
            XCTAssertFalse(manager.fileExists(atPath: url.path), "\(url.lastPathComponent) is removed")
        }
        XCTAssertEqual(TemporaryPDFFiles.urls(inTemporaryDirectory: temporaryDirectory), [], "tmp holds no PDF")
        XCTAssertFalse(manager.fileExists(atPath: ExportTemporaryFiles.directory(inTemporaryDirectory: temporaryDirectory).path), "tmp/Export is removed, as before")
        for url in [besidePrintCopy, systemFile, insideFolderNamedPdf] {
            XCTAssertTrue(manager.fileExists(atPath: url.path), "\(url.lastPathComponent), which is not a PDF, stays")
        }
    }

    func testTheSweepWithNoExportFolderIsNotAnError() {
        ExportTemporaryFiles.removeAll(temporaryDirectory: temporaryDirectory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: ExportTemporaryFiles.directory(inTemporaryDirectory: temporaryDirectory).path))
    }
}
