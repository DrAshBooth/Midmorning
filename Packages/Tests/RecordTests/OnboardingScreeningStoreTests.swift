import Foundation
import XCTest
@testable import Record
import Programme

/// Onboarding spec, "Finish": "The app MUST NOT keep answers from an
/// unfinished onboarding."; safeguarding spec, "The app keeps nothing from
/// an exclusion" (mm-t14.33). The App target's `OnboardingRootView` holds
/// `OnboardingScreening.evaluate`'s kept values in `OnboardingAnswers` and
/// calls `setProfile` only in `finish()`, at "Start". This test runs the same
/// composition over a real store.
@MainActor
final class OnboardingScreeningStoreTests: XCTestCase {
    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OnboardingScreeningStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return try RecordStore(directory: directory)
    }

    /// The four kept values reach the store only at "Start".
    private func start(_ store: RecordStore, kept: ScreeningKeptValues?) throws {
        if let kept {
            try store.setProfile(heightCm: kept.heightCm, onboardingBMI: kept.onboardingBMI, cautionFlag: kept.cautionFlag, askedAt: kept.askedAt)
        }
        try store.setOnboardingCompleted(true)
    }

    /// The person passes screen 2, leaves on "Your start", comes back, and
    /// a second attempt excludes. The store holds no height, BMI, caution
    /// flag or `askedAt` at any point.
    func testLeaveThenExcludeKeepsNothing() throws {
        let store = try makeStore()
        let first = OnboardingScreening.evaluate(age: 34, heightCm: 170, weightKg: 60, pregnancy: .no, treatment: .no, selfHarm: .noFollowUp, now: Date(timeIntervalSince1970: 1_758_700_000))
        guard case .continues = first else { return XCTFail("the first attempt continues to \"Your start\"") }
        // Screen 2's "Continue" writes nothing. The person closes the app on
        // "Your start"; the kept values were only in memory.
        XCTAssertNil(try store.profile())

        let second = OnboardingScreening.evaluate(age: 17, heightCm: 170, weightKg: 60, pregnancy: .no, treatment: .no, selfHarm: .noFollowUp, now: Date(timeIntervalSince1970: 1_758_800_000))
        XCTAssertEqual(second, .excluded([.age]))
        XCTAssertNil(try store.profile())
        XCTAssertFalse(try store.onboardingCompleted())
    }

    /// The caution sheet path: the flag is set, and the store holds it only
    /// after "Start".
    func testCautionThenStartWritesTheFourValues() throws {
        let store = try makeStore()
        let screenedAt = Date(timeIntervalSince1970: 1_758_700_000)
        let outcome = OnboardingScreening.evaluate(age: 34, heightCm: 170, weightKg: 54, pregnancy: .no, treatment: .no, selfHarm: .noFollowUp, now: screenedAt)
        guard case .cautionSheet(let kept) = outcome else { return XCTFail("170 cm and 54 kg shows the caution sheet") }
        XCTAssertNil(try store.profile(), "the caution sheet's Continue writes nothing")

        try start(store, kept: kept)
        let profile = try XCTUnwrap(store.profile())
        XCTAssertEqual(profile.heightCm, 170)
        XCTAssertEqual(profile.onboardingBMI, 54 / (1.7 * 1.7), accuracy: 0.000_001)
        XCTAssertTrue(profile.cautionFlag)
        XCTAssertEqual(profile.askedAt, screenedAt, "askedAt is the moment of the screening, not of Start")
    }

    /// Scenario "The store after onboarding": 170 cm and 60 kg keeps 170,
    /// 20.76 and the caution flag off.
    func testStartAfterAScreeningThatContinues() throws {
        let store = try makeStore()
        let outcome = OnboardingScreening.evaluate(age: 34, heightCm: 170, weightKg: 60, pregnancy: .no, treatment: .no, selfHarm: .supportLine, now: .now)
        guard case .continues(let kept) = outcome else { return XCTFail("Yes then No to the self-harm item does not exclude") }
        try start(store, kept: kept)
        let profile = try XCTUnwrap(store.profile())
        XCTAssertEqual(BMI.rounded(profile.onboardingBMI), 20.76)
        XCTAssertFalse(profile.cautionFlag)
    }
}
