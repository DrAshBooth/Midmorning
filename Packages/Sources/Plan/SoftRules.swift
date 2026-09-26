import Foundation
import Constants

/// A planned meal's label, time and kind — the shape every screen-facing
/// computation in this package reads (`SoftRules`, `NextPlannedMeal`,
/// `MissedMealPrompt`), already resolved from the stored slot index and any
/// renamed label.
public struct PlanMealFact: Sendable, Equatable {
    public let label: String
    public let time: String
    public let kind: SlotKind

    public init(label: String, time: String, kind: SlotKind) {
        self.label = label
        self.time = time
        self.kind = kind
    }
}

/// The soft rules: 3 meals and 2 or 3 snacks a day, with no awake gap over
/// `MAX_AWAKE_GAP_HOURS` (regular-eating-plan spec, "The soft rules show and
/// ask"). Every function here is pure: it takes the day's planned meals,
/// already ordered, and returns the lines the builder shows above "Save
/// anyway" and "Go back".
public enum SoftRules {
    /// The meal-and-snack-count line, or `nil` when the day has 3 meals and
    /// 2 or 3 snacks. Counts slot kinds, never labels — a renamed slot keeps
    /// its kind.
    /// Two counts, so each count is its own catalogue entry with zero, one
    /// and other forms ("no meals", "1 meal", "%lld meals"), and the line
    /// fills its two placeholders from them.
    public static func mealLine(mealCount: Int, snackCount: Int) -> CatalogueText? {
        guard !(mealCount == 3 && (snackCount == 2 || snackCount == 3)) else { return nil }
        return .key(
            "plan.softRules.mealLine",
            .key("plan.softRules.meals %lld", .count(mealCount)),
            .key("plan.softRules.snacks %lld", .count(snackCount))
        )
    }

    /// One gap line per gap over `maxAwakeGapHours` between two adjacent
    /// planned meals — never before the first or after the last. No line on
    /// a fasting day, ordered meals already in the record day's own order.
    public static func gapLines(orderedMeals: [PlanMealFact], dayStartHour: Int, maxAwakeGapHours: Int, isFastingDay: Bool) -> [CatalogueText] {
        guard !isFastingDay, orderedMeals.count > 1 else { return [] }
        var lines: [CatalogueText] = []
        for i in 0..<(orderedMeals.count - 1) {
            let gapMinutes = PlanOrdering.minutesAfterDayStart(time: orderedMeals[i + 1].time, dayStartHour: dayStartHour)
                - PlanOrdering.minutesAfterDayStart(time: orderedMeals[i].time, dayStartHour: dayStartHour)
            guard gapMinutes > maxAwakeGapHours * 60 else { continue }
            let earlier = orderedMeals[i]
            let later = orderedMeals[i + 1]
            lines.append(.key(
                "plan.softRules.gapLine",
                .verbatim(DurationText.string(minutes: gapMinutes)),
                .verbatim(earlier.label), .verbatim(earlier.time),
                .verbatim(later.label), .verbatim(later.time)
            ))
        }
        return lines
    }

    /// Every broken-rule line together, the meal line first (regular-eating-
    /// plan spec: "The app MUST show all lines together, once, above the
    /// controls"). An empty result means the day meets every soft rule.
    public static func lines(orderedMeals: [PlanMealFact], dayStartHour: Int, maxAwakeGapHours: Int, isFastingDay: Bool) -> [CatalogueText] {
        let mealCount = orderedMeals.filter { $0.kind == .meal }.count
        let snackCount = orderedMeals.filter { $0.kind == .snack }.count
        var lines: [CatalogueText] = []
        if let mealLine = mealLine(mealCount: mealCount, snackCount: snackCount) { lines.append(mealLine) }
        lines.append(contentsOf: gapLines(orderedMeals: orderedMeals, dayStartHour: dayStartHour, maxAwakeGapHours: maxAwakeGapHours, isFastingDay: isFastingDay))
        return lines
    }
}
