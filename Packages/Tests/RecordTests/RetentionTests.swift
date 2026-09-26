import Foundation
import SwiftData
import XCTest
@testable import Record

/// data-and-privacy spec, "Retention". Both scenarios hold structurally:
/// `Profile` (model-foundation) has no field for a screening date other than
/// `askedAt`, and `Review`'s self-harm field is a flag, never the answer
/// text. This change adds no field to either model; it proves the shape
/// `Retention` depends on.
final class RetentionTests: XCTestCase {
    /// Scenario: Screening date.
    func testProfileHoldsAskedAtAndNoOtherScreeningDate() {
        let fields = Set(Schema(RecordSchema.models).entities.first { $0.name == "Profile" }!.properties.map(\.name))
        XCTAssertEqual(fields, ["id", "heightCm", "onboardingBMI", "cautionFlag", "askedAt", "changedAt"])

        let askedAt = Date(timeIntervalSince1970: 1_759_000_000)
        let profile = Profile(heightCm: 165, onboardingBMI: 21, cautionFlag: false, askedAt: askedAt, changedAt: askedAt)
        XCTAssertEqual(profile.askedAt, askedAt)
        // `changedAt` is a field, but the requirement states it is not a
        // screening moment: only `askedAt` is.
    }

    /// Scenario: Self-harm answer.
    func testReviewKeepsOnlySelfHarmAnsweredNeverTheAnswerItself() {
        let fields = Set(Schema(RecordSchema.models).entities.first { $0.name == "Review" }!.properties.map(\.name))
        XCTAssertEqual(fields, ["id", "kind", "dueDateKey", "frozenAt", "answersJSON", "selfHarmAnswered", "pinnedNote", "changedAt"])

        let review = Review(kind: "weeklyReview", dueDateKey: "2026-10-06", selfHarmAnswered: true, changedAt: Date(timeIntervalSince1970: 1_759_000_000))
        XCTAssertTrue(review.selfHarmAnswered)
        // No field on `Review` holds an answer's text; `answersJSON` is the
        // non-safeguarding review answers `weekly-review`/`staying-on-track`
        // own, never the self-harm question's own answer.
    }
}
