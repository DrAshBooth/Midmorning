import XCTest
import Constants
@testable import AppLock

/// app-lock spec, "When the app asks" and "Lock after".
final class LockPolicyTests: XCTestCase {
    /// Scenario: Policy with a stub clock.
    func testShouldAskAtOrAfterTheGracePeriod() {
        XCTAssertTrue(LockPolicy.shouldAsk(enteredBackgroundAt: 0, now: 31, grace: 30))
        XCTAssertFalse(LockPolicy.shouldAsk(enteredBackgroundAt: 0, now: 29, grace: 30))
    }

    /// Scenario: Policy with no grace.
    func testShouldAskWithNoGrace() {
        XCTAssertTrue(LockPolicy.shouldAsk(enteredBackgroundAt: 0, now: 1, grace: 0))
    }

    func testShouldAskAtExactlyTheGracePeriod() {
        XCTAssertTrue(LockPolicy.shouldAsk(enteredBackgroundAt: 100, now: 130, grace: 30))
    }

    func testStubContinuousClockReturnsTheSetValue() {
        let clock = StubContinuousClock(10)
        XCTAssertEqual(clock.continuousSeconds(), 10)
        clock.set(45)
        XCTAssertEqual(clock.continuousSeconds(), 45)
    }

    // MARK: Requirement: Lock after

    /// Scenario: Default.
    func testDefaultLockAfterLabelIsAtOnce() {
        XCTAssertEqual(LockGrace.label(forSeconds: 0).english, "At once")
    }

    func testEveryChoiceHasItsOwnLabel() {
        XCTAssertEqual(LockGrace.label(forSeconds: 30).english, "30 seconds")
        XCTAssertEqual(LockGrace.label(forSeconds: 120).english, "2 minutes")
        XCTAssertEqual(LockGrace.label(forSeconds: 300).english, "5 minutes")
        XCTAssertEqual(LockGrace.label(forSeconds: 60).english, "1 minute", "the count picks the plural form")
        XCTAssertEqual(LockGrace.choices.map { LockGrace.label(forSeconds: $0).english }, ["At once", "30 seconds", "2 minutes", "5 minutes"])
    }

    /// `LockGrace.choices` never drifts from `ProgrammeConstants`'s own
    /// four values.
    func testChoicesMatchProgrammeConstants() {
        XCTAssertEqual(LockGrace.choices, ProgrammeConstants.default.lockGraceSecondsChoices)
    }
}
