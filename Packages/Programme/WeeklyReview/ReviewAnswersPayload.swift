import Foundation

/// The shape of a `Review` row's `answersJSON` (weekly-review spec, "Finish
/// and reopen a review", "The week's counts are frozen in the Review row").
/// The row itself is generic, owned by `data-and-privacy`; `weekly-review`
/// owns this payload the same way `regular-eating-plan` owns `Day.slotsJSON`
/// — an opaque, additively-grown JSON string to the store.
///
/// The self-harm answer never enters this payload (the safeguarding spec,
/// "Re-screening at every weekly review and check-in": "The store MUST NOT
/// keep the answer."); only whether it was answered, which the `Review` row
/// keeps in its own dedicated `selfHarmAnswered` field.
public struct ReviewAnswersPayload: Sendable, Equatable, Codable {
    /// `true` once the person has tapped "Done" at least once on this
    /// review. A row can exist with `finished == false` when only the
    /// freeze process has written it — the frozen counts, never the
    /// person's own answers.
    public var finished: Bool
    /// Written once, at freeze time; never recomputed after.
    public var frozenCounts: FrozenReviewCounts?
    /// The three reflection answers, in the fixed order "What did you
    /// notice this week?", "What made things harder?", "What helped?".
    public var reflectionAnswers: [String]
    /// "What's the one thing to change next week?" — mirrored onto the
    /// `Review` row's own `pinnedNote` field at "Done".
    public var oneThingToChange: String
    /// The three week-1 answers, only ever set on week 1's own review.
    public var weekOneAnswers: [String]?

    public init(
        finished: Bool = false,
        frozenCounts: FrozenReviewCounts? = nil,
        reflectionAnswers: [String] = ["", "", ""],
        oneThingToChange: String = "",
        weekOneAnswers: [String]? = nil
    ) {
        self.finished = finished
        self.frozenCounts = frozenCounts
        self.reflectionAnswers = reflectionAnswers
        self.oneThingToChange = oneThingToChange
        self.weekOneAnswers = weekOneAnswers
    }

    public static let empty = ReviewAnswersPayload()

    /// Decodes `json`, or `.empty` when it does not parse — the same
    /// forgiving pattern `PlannedMeal.decode` uses for `Day.slotsJSON`.
    public static func decode(_ json: String) -> ReviewAnswersPayload {
        guard let data = json.data(using: .utf8), let value = try? JSONDecoder().decode(ReviewAnswersPayload.self, from: data) else {
            return .empty
        }
        return value
    }

    public func encoded() -> String {
        guard let data = try? JSONEncoder().encode(self), let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }
}
