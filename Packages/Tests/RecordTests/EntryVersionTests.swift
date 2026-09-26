import Foundation
import SwiftData
import XCTest
import Export
@testable import Record
import RecordTestSupport

/// data-and-privacy spec: "Every synced row carries its own change moment",
/// "Entries are append-only versions", "Date-keyed rows keep the key
/// written at creation".
final class EntryVersionTests: XCTestCase {
    // MARK: Every synced row carries its own change moment (mm-t12.6)

    /// Scenario: Delete a list item.
    func testDeleteAListItemKeepsTheRowWithDeletedOnAndItsMoment() {
        let id = UUID()
        let deletedAt = Date(timeIntervalSince1970: 500)
        let item = ListItem(id: id, kind: "alternative", text: "Ring Sam", changedAt: Date(timeIntervalSince1970: 100))
        let deletion = ListItem(id: id, kind: "alternative", text: "Ring Sam", deleted: true, changedAt: deletedAt)
        XCTAssertEqual(ListItemReconciler.merged([item, deletion]), [], "no list shows a deleted item")

        let winner = Reconciler.latestWins([item, deletion], key: \.id, changedAt: \.changedAt)[id]!
        XCTAssertTrue(winner.deleted)
        XCTAssertEqual(winner.changedAt, deletedAt)
    }

    /// Scenario: Delete a ladder step. Deleting a step leaves its
    /// reintroductions unchanged; no screen shows the step or its dependants,
    /// and the app writes no cascade of deletes.
    func testDeleteALadderStepLeavesItsReintroductionsUnchanged() {
        let stepId = UUID()
        let step = ListItem(id: stepId, kind: "ladderStep", text: "Cake at a cafe", deleted: true, changedAt: .now)
        let reintroductionOne = Sheet(kind: "reintroduction", payloadJSON: "{\"stepId\":\"\(stepId)\"}", changedAt: Date(timeIntervalSince1970: 10))
        let reintroductionTwo = Sheet(kind: "reintroduction", payloadJSON: "{\"stepId\":\"\(stepId)\"}", changedAt: Date(timeIntervalSince1970: 20))

        XCTAssertTrue(step.deleted)
        // The dependants carry no deleted flag of their own: deleting the
        // step never wrote to them.
        XCTAssertFalse(reintroductionOne.deleted)
        XCTAssertFalse(reintroductionTwo.deleted)
        XCTAssertEqual(SheetReconciler.winners(in: [reintroductionOne, reintroductionTwo]).count, 2, "both survive; deleting the step wrote no cascade")
    }

    /// Scenario: System dates unread. Every model's own schema exposes
    /// `changedAt` (or, for `ItemVersion`, also `createdAt`, never shown to
    /// the person) and no CKRecord system-date field; every conflict rule
    /// in `Reconciler` reads `changedAt`, never a system date.
    func testSystemDatesUnread() {
        for entity in Schema(RecordSchema.models).entities {
            let propertyNames = Set(entity.properties.map(\.name))
            XCTAssertFalse(propertyNames.contains("creationDate"), "\(entity.name) exposes no CKRecord creation date")
            XCTAssertFalse(propertyNames.contains("modificationDate"), "\(entity.name) exposes no CKRecord modification date")
        }
        XCTAssertTrue(Set(Schema(RecordSchema.models).entities.first { $0.name == "ItemVersion" }!.properties.map(\.name)).contains("changedAt"))
    }

    // MARK: Entries are append-only versions (mm-t12.8)

    private func version(entryId: UUID, changedAt: Date, deleted: Bool = false, what: String = "", feltLikeABinge: Bool = false, id: UUID = UUID()) -> ItemVersion {
        ItemVersion(id: id, entryId: entryId, changedAt: changedAt, deleted: deleted, dayKey: "2026-09-25", time: changedAt, utcOffsetSeconds: 0, what: what, feltLikeABinge: feltLikeABinge, createdAt: changedAt)
    }

    /// Scenario: Two devices offline. Different entry ids both survive.
    func testTwoDevicesOfflineBothEntriesSurvive() {
        let a = version(entryId: UUID(), changedAt: at(8, 10), what: "Toast and tea")
        let b = version(entryId: UUID(), changedAt: at(8, 15), what: "Coffee")
        let winners = EntryWinner.winners(in: [a, b])
        XCTAssertEqual(winners.count, 2)
        XCTAssertEqual(Set(winners.values.map(\.what)), ["Toast and tea", "Coffee"])
    }

    /// Scenario: Same entry edited on both devices.
    func testSameEntryEditedOnBothDevicesTheLaterChangeWinsWhole() {
        let entryId = UUID()
        let a = version(entryId: entryId, changedAt: at(13, 10), what: "Edited What", feltLikeABinge: false)
        let b = version(entryId: entryId, changedAt: at(13, 12), what: "", feltLikeABinge: true)
        let winner = EntryWinner.pick([a, b])!
        XCTAssertEqual(winner.id, b.id)
        XCTAssertTrue(winner.feltLikeABinge)
        XCTAssertNotEqual(winner.what, "Edited What", "device A's What edit is absent")
    }

    /// Scenario: Edit then delete.
    func testEditThenDeleteShowsNoRow() {
        let entryId = UUID()
        let edit = version(entryId: entryId, changedAt: at(13, 10), what: "Edited")
        let delete = version(entryId: entryId, changedAt: at(13, 12), deleted: true)
        let winner = EntryWinner.pick([edit, delete])!
        XCTAssertTrue(winner.deleted)
    }

    /// Scenario: Delete then edit.
    func testDeleteThenEditShowsTheEdit() {
        let entryId = UUID()
        let delete = version(entryId: entryId, changedAt: at(13, 10), deleted: true)
        let edit = version(entryId: entryId, changedAt: at(13, 12), what: "Toast")
        let winner = EntryWinner.pick([delete, edit])!
        XCTAssertFalse(winner.deleted)
        XCTAssertEqual(winner.what, "Toast")
    }

    /// Scenario: Tie on moment, star and length.
    func testTieOnMomentStarAndLength() {
        let entryId = UUID()
        let moment = at(13, 10)
        let toast = version(entryId: entryId, changedAt: moment, what: "Toast", id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        let beans = version(entryId: entryId, changedAt: moment, what: "Beans", id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)
        XCTAssertEqual(toast.what.count, beans.what.count)
        let winner = EntryWinner.pick([toast, beans])!
        XCTAssertEqual(winner.what, "Toast", "lexically greater wins the tie: T > B")

        // A second tie, both reading "Toast": the greater version id wins.
        let toastAgain = version(entryId: entryId, changedAt: moment, what: "Toast", id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!)
        let secondWinner = EntryWinner.pick([toast, toastAgain])!
        XCTAssertEqual(secondWinner.id, toastAgain.id, "the greater version id wins the final tie")
    }

    /// Scenario: Versions pruned.
    func testVersionsPrunedWhenBothRetentionTestsPass() {
        let losingChangedAt = date(2026, 6, 1)
        let now = date(2026, 8, 31)
        let latestSync = date(2026, 9, 1)
        XCTAssertTrue(Reconciler.canDeleteLosingRow(changedAt: losingChangedAt, now: now, latestSyncMoment: latestSync))
    }

    /// Scenario: Clock ahead of sync.
    func testClockAheadOfSyncKeepsTheLosingVersion() {
        let losingChangedAt = date(2026, 6, 1)
        let now = date(2026, 9, 1) // the device clock
        let latestSync = date(2026, 7, 1) // the sync test fails
        XCTAssertFalse(Reconciler.canDeleteLosingRow(changedAt: losingChangedAt, now: now, latestSyncMoment: latestSync))
    }

    /// Scenario: Deleted entry kept reduced.
    func testDeletedEntryKeptReducedAfterBothTestsPass() {
        let entryId = UUID()
        let deletion = version(entryId: entryId, changedAt: date(2026, 6, 1), deleted: true, what: "Porridge")
        let now = date(2026, 10, 1)
        let latestSync = date(2026, 9, 15)
        XCTAssertTrue(Reconciler.canDeleteLosingRow(changedAt: deletion.changedAt, now: now, latestSyncMoment: latestSync))
        // Reducing a winning deleted version keeps only the entry id,
        // changedAt and the deleted flag.
        let reduced = ItemVersion(id: deletion.id, entryId: deletion.entryId, changedAt: deletion.changedAt, deleted: true, dayKey: "", time: deletion.changedAt, utcOffsetSeconds: 0, what: "", feltLikeABinge: false, createdAt: deletion.changedAt)
        XCTAssertEqual(reduced.what, "", "no What survives the reduction")
        XCTAssertTrue(reduced.deleted)
    }

    // MARK: Date-keyed rows keep the key written at creation (mm-t12.9)

    /// Scenario: Entry across a zone change. The real store writes the key
    /// at save from the entry's own offset. Read later from Tokyo, the
    /// entry stays on 6 October, on the day view and in the export.
    @MainActor
    func testEntryAcrossAZoneChangeKeepsItsSavedDayKey() throws {
        let store = try makeTemporaryStore()
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London")!
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let savedAt = london.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: 23, minute: 30))!
        let row = try store.add(time: savedAt, what: "Late snack", feltLikeABinge: false, createdAt: savedAt, utcOffsetSeconds: london.timeZone.secondsFromGMT(for: savedAt))
        XCTAssertEqual(row.dayKey, "2026-10-06")

        // In Tokyo the same moment is 07:30 on 7 October, a different record day.
        XCTAssertEqual(RecordDay.key(containing: savedAt, calendar: tokyo, startHour: RecordDay.startHour), "2026-10-07")
        XCTAssertFalse(try store.entries(recordDayContaining: savedAt, calendar: tokyo).contains { $0.id == row.id }, "Tokyo's 7 October does not take the entry")
        XCTAssertEqual(try store.entries(dayKey: "2026-10-06").map(\.id), [row.id], "the entry stays on 6 October")

        let days = try ["2026-10-06", "2026-10-07"].map { ExportDayInput(dayKey: $0, entries: try store.entries(dayKey: $0), states: try store.dayStates(dateKey: $0)) }
        let document = ExportDocumentBuilder.build(request: ExportBuildRequest(fromDayKey: "2026-10-06", toDayKey: "2026-10-07", includeContext: true, dayStartHour: 4), days: days)
        XCTAssertEqual(document.days.first { $0.dayKey == "2026-10-06" }?.entries.map(\.what), ["Late snack"], "and in the export")
        XCTAssertEqual(document.days.first { $0.dayKey == "2026-10-07" }?.entries.count, 0)
    }

    /// Scenario: Row received by sync. Device A created the planned day in
    /// another zone; the row arrives in device B's store as written, and
    /// device B reads it by its key without computing a new one.
    @MainActor
    func testRowReceivedBySyncKeepsTheSendersKey() throws {
        let store = try makeTemporaryStore()
        let received = ModelContext(store.container)
        received.insert(Day(dateKey: "2026-10-06", slotsJSON: "[]", changedAt: date(2026, 10, 5)))
        try received.save()
        XCTAssertEqual(try store.dayPlan(dateKey: "2026-10-06")?.dateKey, "2026-10-06", "device B keeps the key 6 October")
        XCTAssertNil(try store.dayPlan(dateKey: "2026-10-05"), "and shows it on no other day")
    }

    // MARK: Helpers

    private func at(_ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: hour, minute: minute))!
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
