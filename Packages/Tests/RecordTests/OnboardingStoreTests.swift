import Foundation
import XCTest
@testable import Record

/// Onboarding spec, "What onboarding keeps and what it never keeps"
/// (mm-t14.12), "Screen 3: the start day" (mm-t14.6), "Screen 3: weigh-in
/// day and quiet hours" (mm-t14.7), "Screen 4: your record" (mm-t14.9) and
/// "Finish" (mm-t14.14).
@MainActor
final class OnboardingStoreTests: XCTestCase {
    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OnboardingStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return try RecordStore(directory: directory)
    }

    /// "The store after onboarding": the store holds exactly the four
    /// screening values, the start day, quiet hours and the weigh-in day —
    /// no age, weight, other date, creation moment or yes-or-no answer.
    func testTheStoreAfterOnboarding() throws {
        let store = try makeStore()
        let askedAt = Date(timeIntervalSince1970: 1_758_700_000)

        try store.setProfile(heightCm: 170, onboardingBMI: 20.76, cautionFlag: false, askedAt: askedAt)
        try store.setStartDayKey("2026-09-27")
        try store.setWeighInDayChoice(.weekday(1)) // Sunday
        try store.setQuietHoursOn(true)
        try store.setQuietHoursStart("22:00")
        try store.setQuietHoursEnd("07:00")
        try store.setOnboardingCompleted(true)
        try store.setSyncOn(false)

        let profile = try store.profile()
        XCTAssertEqual(profile?.heightCm, 170)
        XCTAssertEqual(profile?.onboardingBMI, 20.76)
        XCTAssertEqual(profile?.cautionFlag, false)
        XCTAssertEqual(profile?.askedAt, askedAt)

        XCTAssertEqual(try store.startDayKey(), "2026-09-27")
        XCTAssertEqual(try store.weighInDayChoice(), .weekday(1))
        XCTAssertTrue(try store.quietHoursOn())
        XCTAssertEqual(try store.quietHoursStart(), "22:00")
        XCTAssertEqual(try store.quietHoursEnd(), "07:00")
        XCTAssertTrue(try store.onboardingCompleted())
        XCTAssertFalse(try store.syncOn())
    }

    /// "First weigh-in day": the store keeps no weight from onboarding for a
    /// rolling average to read.
    func testFirstWeighInDayHasNoOnboardingWeight() throws {
        let store = try makeStore()
        try store.setProfile(heightCm: 170, onboardingBMI: 20.76, cautionFlag: false, askedAt: .now)
        // Profile carries height and BMI, never the typed weight itself.
        let mirror = Mirror(reflecting: try XCTUnwrap(store.profile()))
        XCTAssertFalse(mirror.children.contains { $0.label == "weightKg" || $0.label == "weight" })
    }

    /// "Relaunch after exclusion" / "The store after exclusion"
    /// (safeguarding spec, "The app keeps nothing from an exclusion"): a
    /// store that never received a `setProfile` call (an exclusion writes
    /// nothing) holds no Profile row at all.
    func testNoProfileRowBeforeAnyWrite() throws {
        let store = try makeStore()
        XCTAssertNil(try store.profile())
        XCTAssertNil(try store.startDayKey())
        XCTAssertFalse(try store.onboardingCompleted())
    }

    func testWeighInDayWontBeWeighing() throws {
        let store = try makeStore()
        try store.setWeighInDayChoice(.wontBeWeighing)
        XCTAssertEqual(try store.weighInDayChoice(), .wontBeWeighing)
    }

    /// "A later start day wins": a restart's write, with a later
    /// `changedAt`, replaces the earlier start day on read.
    func testALaterStartDayWins() throws {
        let store = try makeStore()
        let earlier = Date(timeIntervalSince1970: 1_000)
        let later = Date(timeIntervalSince1970: 2_000)
        try store.setStartDayKey("2026-09-24", changedAt: earlier)
        try store.setStartDayKey("2026-10-05", changedAt: later)
        XCTAssertEqual(try store.startDayKey(), "2026-10-05")
    }

    /// "This device only" (Screen 4): the sync choice is off until a later
    /// change turns it on.
    func testSyncOffByDefault() throws {
        let store = try makeStore()
        XCTAssertFalse(try store.syncOn())
    }

    func testInstallMomentRoundTrips() throws {
        let store = try makeStore()
        let moment = Date(timeIntervalSince1970: 1_758_600_000)
        try store.setInstallMoment(moment)
        let read = try XCTUnwrap(store.installMoment())
        XCTAssertEqual(read.timeIntervalSince1970, moment.timeIntervalSince1970, accuracy: 0.001)
    }
}
