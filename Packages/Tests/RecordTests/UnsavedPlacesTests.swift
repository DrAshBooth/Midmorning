import Foundation
import XCTest
@testable import Record
import RecordTestSupport

/// App-lock spec, "A new entry before authentication", ruling r13-04
/// (mm-t15.19): on the new-entry screen of a pending route, nothing saves
/// before Save. Each test makes the calls that `NewEntryView` makes on that
/// screen: "Add a place" keeps the place in `UnsavedPlaces`, and only a
/// Save that succeeds calls `RecordStore.touchCustomPlaces(_:)`.
@MainActor
final class UnsavedPlacesTests: XCTestCase {
    private let moment = Date(timeIntervalSince1970: 1_790_000_000)

    /// The person types "Mum's" in "Add a place" and taps Save. The request
    /// at Save is cancelled, so the cover closes the keyboard, and editing
    /// in the field ends. The store gets no place.
    func testAPlaceAddedBeforeACancelledRequestAtSaveIsNotSaved() throws {
        let store = try makeTemporaryStore()
        var unsaved = UnsavedPlaces()

        unsaved.add("Mum's", at: moment)

        XCTAssertEqual(try store.customPlaces(), [], "no ListItem before Save succeeds")
        XCTAssertEqual(unsaved.chips(savedPlaces: []), ["Mum's"], "the screen shows the chip from memory")
    }

    /// After "Unlock" or the request at Save succeeds, Save keeps each place
    /// with the moment the person added it.
    func testASaveThatSucceedsKeepsThePlaces() throws {
        let store = try makeTemporaryStore()
        var unsaved = UnsavedPlaces()
        unsaved.add("Mum's", at: moment)
        unsaved.add("Gym", at: moment.addingTimeInterval(60))

        try store.touchCustomPlaces(unsaved)

        XCTAssertEqual(try store.customPlaces(), ["Gym", "Mum's"], "most recently added first")
    }

    /// The same rules as `touchCustomPlace`: no empty text, no fixed chip's
    /// text, and one chip for a place added two times.
    func testAddKeepsOnlyNewCustomPlaces() {
        var unsaved = UnsavedPlaces()
        unsaved.add("   ", at: moment)
        unsaved.add("Home", at: moment)
        unsaved.add(" Mum's ", at: moment)
        unsaved.add("Gym", at: moment.addingTimeInterval(60))
        unsaved.add("Mum's", at: moment.addingTimeInterval(120))

        XCTAssertEqual(unsaved.places.map(\.text), ["Gym", "Mum's"])
        XCTAssertEqual(unsaved.places.last?.addedAt, moment.addingTimeInterval(120))
    }

    /// The chips: the places in memory first, most recent first, then the
    /// saved custom places, with no chip two times and at most eight.
    func testChipsPutThePlacesInMemoryFirst() {
        var unsaved = UnsavedPlaces()
        unsaved.add("Gym", at: moment)
        unsaved.add("Mum's", at: moment.addingTimeInterval(60))
        let saved = ["Café", "Gym", "Car", "Park", "Pub", "Bus", "Train", "Beach"]

        XCTAssertEqual(unsaved.chips(savedPlaces: saved), ["Mum's", "Gym", "Café", "Car", "Park", "Pub", "Bus", "Train"])
    }
}
