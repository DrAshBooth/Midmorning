import Foundation
import XCTest
@testable import Record

/// record spec, "Where chips", scenario "Add a custom place": the person
/// taps "Add a place", types "Mum's" and taps Save in the navigation bar.
/// Each test makes the calls `NewEntryView.save()` makes: the place still
/// in the field wins, the store keeps it as a custom place, and the entry
/// saves with it (mm-t12b.12).
@MainActor
final class WhereOnSaveTests: XCTestCase {
    private let moment = Date(timeIntervalSince1970: 1_790_000_000)

    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WhereOnSaveTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return try RecordStore(directory: directory)
    }

    /// The calls of `NewEntryView.save()`.
    private func save(in store: RecordStore, selection: String?, pendingPlace: String?) throws -> RecordRow {
        let place = WhereSelection.onSave(selection: selection, pendingPlace: pendingPlace)
        if let kept = place.placeToKeep {
            try store.touchCustomPlace(kept, at: moment)
        }
        return try store.add(time: moment, what: "Toast and tea", feltLikeABinge: false, createdAt: moment, utcOffsetSeconds: 3600, whereText: place.whereText)
    }

    /// Scenario: Add a custom place, saved from the navigation bar while the
    /// field still has the text.
    func testTypedPlaceSavesWithTheEntry() throws {
        let store = try makeStore()
        let row = try save(in: store, selection: nil, pendingPlace: "Mum's")
        XCTAssertEqual(row.whereText, "Mum's")
        XCTAssertEqual(try store.customPlaces(), ["Mum's"], "the next new-entry screen shows the chip")
    }

    func testTypedPlaceWinsOverASelectedChip() throws {
        let store = try makeStore()
        let row = try save(in: store, selection: "Home", pendingPlace: "  Mum's ")
        XCTAssertEqual(row.whereText, "Mum's")
    }

    /// Scenario: Save with a fixed chip. An empty field changes nothing.
    func testEmptyFieldKeepsTheSelectedChip() throws {
        let store = try makeStore()
        let row = try save(in: store, selection: "Home", pendingPlace: "   ")
        XCTAssertEqual(row.whereText, "Home")
        XCTAssertEqual(try store.customPlaces(), [])
    }

    /// Scenario: Save with no Where.
    func testNoChipAndNoFieldSavesNoWhere() throws {
        let store = try makeStore()
        let row = try save(in: store, selection: nil, pendingPlace: nil)
        XCTAssertEqual(row.whereText, "")
        XCTAssertEqual(try store.customPlaces(), [])
    }

    /// A fixed chip's name typed in the field saves as that chip and adds no
    /// custom chip.
    func testTypedFixedChipNameAddsNoCustomChip() throws {
        let store = try makeStore()
        let row = try save(in: store, selection: nil, pendingPlace: "Work")
        XCTAssertEqual(row.whereText, "Work")
        XCTAssertEqual(try store.customPlaces(), [])
    }
}
