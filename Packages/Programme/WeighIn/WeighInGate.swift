import Foundation

/// What today's weigh-in (a saved row for the current record day, if any)
/// looks like to the gate, before the 10-minute edit window is checked.
public struct TodaysWeighInFact: Sendable, Equatable {
    public var weightKg: Double
    public var savedAt: Date

    public init(weightKg: Double, savedAt: Date) {
        self.weightKg = weightKg
        self.savedAt = savedAt
    }
}

/// Whether the weigh-in screen shows the weekday chooser, the weight input,
/// or the refusal text, and whether the number can still change (weigh-in
/// spec, "The weigh-in day", "The app accepts a weight on the weigh-in day
/// only"). Independent of whether the chart shows: the chart's own rule
/// (`RollingAverage`/`WeighInChartRule`) only needs a weigh-in day and at
/// least one weigh-in, whatever this state is.
public enum WeighInInputState: Sendable, Equatable {
    /// No weigh-in day exists: "Choose a weigh-in day" with the weekdays.
    case chooseDay
    /// The weigh-in screen accepts a number. `prefill` is the value to show
    /// already in the input — set only while today's own just-saved weigh-in
    /// is still inside its 10-minute edit window; `nil` for an empty input.
    case entry(prefill: Double?)
    /// Today is the weigh-in day, a weigh-in already exists for it, and its
    /// 10-minute edit window has passed: the app shows the chart with no
    /// weight input and no refusal text (weigh-in spec, "The number is
    /// fixed after 10 minutes").
    case fixedForToday
    /// Any other day, or a weigh-in day the six-day gate still blocks: the
    /// refusal text, naming the next day the app accepts a weigh-in.
    case refusal(nextDayKey: String)
}

public enum WeighInGate {
    /// The screen's input state (weigh-in spec, "The weigh-in day", "The app
    /// accepts a weight on the weigh-in day only"). `weighInWeekday` is
    /// `nil` for "I won't be weighing" or before any choice.
    public static func inputState(
        weighInWeekday: Int?,
        currentDayKey: String,
        todaysWeighIn: TodaysWeighInFact?,
        lastWeighInDayKey: String?,
        now: Date,
        calendar: Calendar,
        editWindowSeconds: TimeInterval = 600
    ) -> WeighInInputState {
        guard let weighInWeekday else { return .chooseDay }

        if WeighInDayRule.isWeighInDay(dayKey: currentDayKey, weighInWeekday: weighInWeekday, calendar: calendar) {
            if let todaysWeighIn {
                let editable = now.timeIntervalSince(todaysWeighIn.savedAt) < editWindowSeconds
                return editable ? .entry(prefill: todaysWeighIn.weightKg) : .fixedForToday
            }
            if WeighInDayRule.sixDayGatePasses(candidateDayKey: currentDayKey, lastWeighInDayKey: lastWeighInDayKey, calendar: calendar) {
                return .entry(prefill: nil)
            }
        }

        let nextDayKey = WeighInDayRule.nextAcceptedDayKey(strictlyAfter: currentDayKey, weighInWeekday: weighInWeekday, lastWeighInDayKey: lastWeighInDayKey, calendar: calendar)
        return .refusal(nextDayKey: nextDayKey)
    }
}

/// Whether the chart and its one-line explanation show (weigh-in spec, "The
/// chart": "When at least one weigh-in and a weigh-in day exist, the
/// weigh-in screen MUST show a chart on every day. While no weigh-in day
/// exists, the screen MUST NOT show the chart.").
public enum WeighInChartRule {
    public static func showsChart(weighInWeekday: Int?, hasAnyWeighIn: Bool) -> Bool {
        weighInWeekday != nil && hasAnyWeighIn
    }
}
