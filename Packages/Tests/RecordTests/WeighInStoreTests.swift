import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// weigh-in spec, "The store keeps the weigh-in on the device and away from
/// HealthKit" (mm-t22.12). `NoRecordContentInErrorsTests.testASaveFailureCarriesNoData`
/// already proves "Store error" ahead of this bead, over the store's one
/// `Failure.saveFailed` case; this file does not repeat it.
@MainActor
final class WeighInStoreTests: XCTestCase {
    private var london: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        london.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    /// Scenario: The record day key is written at save.
    func testTheRecordDayKeyIsWrittenAtSave() throws {
        let store = try makeTemporaryStore()
        try store.saveWeighIn(dateKey: "2026-09-28", weightKg: 68.6, unit: "kg", at: at(2026, 9, 28, 8))
        let row = try store.weighIn(dateKey: "2026-09-28")
        XCTAssertEqual(row?.dateKey, "2026-09-28")
        XCTAssertEqual(row?.weightKg, 68.6)
    }

    /// Scenario: A change writes into the same row.
    func testAChangeWritesIntoTheSameRow() throws {
        let store = try makeTemporaryStore()
        try store.saveWeighIn(dateKey: "2026-09-28", weightKg: 68.6, unit: "kg", at: at(2026, 9, 28, 8))
        try store.saveWeighIn(dateKey: "2026-09-28", weightKg: 66.8, unit: "kg", at: at(2026, 9, 28, 8, 5))
        let rows = try store.weighIns()
        XCTAssertEqual(rows.count, 1, "one row for the record day key")
        XCTAssertEqual(rows.first?.weightKg, 66.8)
        XCTAssertEqual(rows.first?.savedAt, at(2026, 9, 28, 8), "savedAt is the first save's moment and never changes")
        XCTAssertEqual(rows.first?.changedAt, at(2026, 9, 28, 8, 5))
    }

    /// Scenario: The day start changes after a save / The device zone
    /// changes after a save. Neither `setDayStartHour` nor any timezone
    /// concept ever touches a `Measure` row: the key is written once, at
    /// save, and every reader uses the saved key (weigh-in spec: "A weigh-in
    /// MUST NOT change record day after save.").
    func testTheKeyStaysAfterADayStartChange() throws {
        let store = try makeTemporaryStore()
        try store.saveWeighIn(dateKey: "2026-09-28", weightKg: 68.6, unit: "kg", at: at(2026, 9, 28, 8))
        try store.setDayStartHour(9, now: at(2026, 9, 29, 6), calendar: london)
        let row = try store.weighIn(dateKey: "2026-09-28")
        XCTAssertEqual(row?.dateKey, "2026-09-28", "the weigh-in keeps its key")
    }

    /// Scenario: Delete-all.
    func testDeleteAllLeavesNoWeighIn() throws {
        let directory = try makeTemporaryDirectory()
        let store = try RecordStore(directory: directory)
        try store.saveWeighIn(dateKey: "2026-09-28", weightKg: 68.6, unit: "kg", at: at(2026, 9, 28, 8))
        try LocalEraser.eraseAndRecreate(directory: directory)
        let reopened = try RecordStore(directory: directory)
        XCTAssertEqual(try reopened.weighIns().count, 0, "Delete-all leaves no weigh-in")
    }

    /// Scenario: The Health app (structural: no source file in `Record`
    /// imports `HealthKit`, and the app's own Info.plist and entitlements
    /// carry no HealthKit key — the app never asks for the entitlement or
    /// the permission).
    func testNoHealthKitImportOrEntitlement() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // RecordTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // Packages
            .deletingLastPathComponent() // repo root
        let sourceRoot = repoRoot.appendingPathComponent("Packages/Sources/Record")
        let sourceFiles = try FileManager.default.contentsOfDirectory(at: sourceRoot, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])
            + (try? FileManager.default.contentsOfDirectory(at: sourceRoot.appendingPathComponent("Models"), includingPropertiesForKeys: nil)).map { $0 }.orEmpty
        for file in sourceFiles where file.pathExtension == "swift" {
            let text = try String(contentsOf: file, encoding: .utf8)
            XCTAssertFalse(text.contains("import HealthKit"), "\(file.lastPathComponent) imports HealthKit")
        }
        let infoPlist = try String(contentsOf: repoRoot.appendingPathComponent("App/Midmorning-Info.plist"), encoding: .utf8)
        XCTAssertFalse(infoPlist.contains("Health"), "Info.plist names no HealthKit usage description")
        let entitlements = try String(contentsOf: repoRoot.appendingPathComponent("App/Midmorning/Midmorning.entitlements"), encoding: .utf8)
        XCTAssertFalse(entitlements.contains("healthkit"), "the entitlements file requests no HealthKit entitlement")
    }
}

private extension Optional where Wrapped == [URL] {
    var orEmpty: [URL] { self ?? [] }
}
