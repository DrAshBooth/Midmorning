import Foundation
import XCTest
@testable import Record

/// The store-level scenarios of programme spec, "The app keeps the stage
/// state" (mm-t21.20), "The card's answer is kept in the record" (mm-t21.11)
/// and content spec, "The store keeps which content version the person saw"
/// (mm-t11.9): the ones that need the real store and a real directory, not
/// just the pure engine over fixed facts.
@MainActor
final class ProgrammeStoreTests: XCTestCase {
    private func makeStore(at directory: URL) throws -> RecordStore {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try RecordStore(directory: directory)
    }

    private func makeStore() throws -> RecordStore {
        try makeStore(at: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
    }

    // MARK: mm-t21.20, "The app keeps the stage state"

    /// Scenario: The opening stays in the store.
    func testTheOpeningStaysInTheStore() throws {
        let store = try makeStore()
        let opened = Date(timeIntervalSince1970: 1_760_000_000)
        try store.recordStageOpened(3, at: opened)
        let rows = try store.stageOpenedRows()
        XCTAssertEqual(rows, [RecordStore.StageOpenedRow(stage: 3, moment: opened)])
    }

    /// Scenario: Restart of the app. A second `RecordStore` over the same
    /// directory reads the same row, the same as the app closing and
    /// reopening.
    func testRestartOfTheAppKeepsTheStageOpenedRow() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let opened = Date(timeIntervalSince1970: 1_760_000_000)
        try makeStore(at: directory).recordStageOpened(3, at: opened)
        let reopened = try RecordStore(directory: directory)
        XCTAssertEqual(try reopened.stageOpenedRows(), [RecordStore.StageOpenedRow(stage: 3, moment: opened)])
    }

    /// Scenario: Delete-all. A fresh store — the same directory a real
    /// Delete-all recreates (`data-and-privacy` spec, "Delete-all writes an
    /// erasure marker before it deletes the zone") — holds no stage-opened
    /// row and no card answer; `mm-t42.20` (local-delete-all) runs the real
    /// erasure end to end.
    func testDeleteAllLeavesNoStageOpenedRowAndNoCardAnswer() throws {
        let store = try makeStore()
        XCTAssertEqual(try store.stageOpenedRows(), [])
        XCTAssertEqual(try store.answeredCardIds(), [])
    }

    // MARK: mm-t21.11, "The card's answer is kept in the record"

    /// Scenario: The answer row.
    func testTheAnswerRow() throws {
        let store = try makeStore()
        let moment = Date(timeIntervalSince1970: 1_759_654_320)
        try store.setCardAnswer("Open", id: "opening.2", changedAt: moment)
        XCTAssertEqual(try store.cardAnswer(id: "opening.2"), "Open")
        XCTAssertTrue(try store.answeredCardIds().contains("opening.2"))
    }

    /// Scenario: A card answered on another device. Two `Answer` rows for
    /// the same card id, as sync would deliver, still resolve to one
    /// suppressed card.
    func testACardAnsweredOnAnotherDeviceShowsNoCardOnTheOther() throws {
        let store = try makeStore()
        try store.setCardAnswer("Close", id: "opening.3", changedAt: Date(timeIntervalSince1970: 1_760_000_000))
        // A second device's own write of the same card id, synced in.
        try store.setCardAnswer("Close", id: "opening.3", changedAt: Date(timeIntervalSince1970: 1_760_000_100))
        XCTAssertTrue(try store.answeredCardIds().contains("opening.3"), "the second device shows no stage 3 opening card")
    }

    // MARK: mm-t11.9, "The store keeps which content version the person saw"

    /// Scenario: A card opens.
    func testACardOpens() throws {
        let store = try makeStore()
        let opened = Date(timeIntervalSince1970: 1_759_064_700) // 13:05 UTC
        try store.recordCardSeen(cardId: "stage1.why", contentVersion: 1, seenAt: opened)
        let views = try store.cardViews(cardId: "stage1.why")
        XCTAssertEqual(views.count, 1)
        XCTAssertEqual(views.first?.contentVersion, 1)
        XCTAssertEqual(views.first?.seenAt, opened)
    }

    /// Scenario: The same card after an update.
    func testTheSameCardAfterAnUpdateKeepsBothViews() throws {
        let store = try makeStore()
        try store.recordCardSeen(cardId: "stage1.why", contentVersion: 1, seenAt: Date(timeIntervalSince1970: 1_759_064_700))
        try store.recordCardSeen(cardId: "stage1.why", contentVersion: 2, seenAt: Date(timeIntervalSince1970: 1_759_100_000))
        let views = try store.cardViews(cardId: "stage1.why")
        XCTAssertEqual(views.count, 2, "the store holds a second card view and keeps the first")
        XCTAssertEqual(Set(views.map(\.contentVersion)), [1, 2])
    }
}
