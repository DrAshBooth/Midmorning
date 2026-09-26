import Foundation
import Constants

/// One kept weigh-in: its record day key and its kilogram value (weigh-in
/// spec, "The rolling average"). The App target builds this from
/// `RecordStore.WeighInRow`; `Programme` never imports `Record`.
public struct WeighInFact: Sendable, Equatable {
    public var dayKey: String
    public var weightKg: Double

    public init(dayKey: String, weightKg: Double) {
        self.dayKey = dayKey
        self.weightKg = weightKg
    }
}

/// One weigh-in's own point on the chart: its raw value and its rolling
/// average, both in kilograms (weigh-in spec, "The chart").
public struct RollingAveragePoint: Sendable, Equatable {
    public var dayKey: String
    public var weightKg: Double
    public var averageKg: Double

    public init(dayKey: String, weightKg: Double, averageKg: Double) {
        self.dayKey = dayKey
        self.weightKg = weightKg
        self.averageKg = averageKg
    }
}

/// The four-week rolling average (weigh-in spec, "The rolling average":
/// "The average is the mean of that weigh-in and every weigh-in in the 27
/// days before its day."). `ROLLING_AVERAGE_WEEKS = 4` lives in
/// `ProgrammeConstants.rollingAverageWeeks`.
public enum RollingAverage {
    /// One point per `weighIns` entry, in date order. The app never fills a
    /// missing week with an estimate, the previous value or zero: a week
    /// with no weigh-in simply narrows the mean to the weigh-ins that exist.
    public static func series(_ weighIns: [WeighInFact], constants: ProgrammeConstants = .default, calendar: Calendar) -> [RollingAveragePoint] {
        let sorted = weighIns.sorted { $0.dayKey < $1.dayKey }
        let windowDays = constants.rollingAverageWeeks * 7 - 1
        return sorted.map { fact in
            let windowStart = DayKeyMath.adding(-windowDays, to: fact.dayKey, calendar: calendar)
            let inWindow = sorted.filter { $0.dayKey >= windowStart && $0.dayKey <= fact.dayKey }
            let average = inWindow.map(\.weightKg).reduce(0, +) / Double(inWindow.count)
            return RollingAveragePoint(dayKey: fact.dayKey, weightKg: fact.weightKg, averageKg: average)
        }
    }

    /// For display, the app MUST round the average to one decimal place in
    /// kilograms, or to the nearest whole pound — the same rounding
    /// `WeighInWeight` gives a raw value.
    public static func display(_ averageKg: Double, unit: WeightUnit) -> String {
        WeighInWeight.display(kg: averageKg, unit: unit)
    }

    /// The rolling average at the latest weigh-in `minDaysEarlier` (28) or
    /// more days before `dayKey`, or `nil` when none is old enough
    /// (safeguarding spec, "The underweight check": "When no weigh-in is 28
    /// or more days old, the app MUST NOT apply Rule C."). `series` MUST
    /// already be in date order (`RollingAverage.series`'s own output).
    public static func averageAtLeastDaysEarlier(_ minDaysEarlier: Int = 28, before dayKey: String, in series: [RollingAveragePoint], calendar: Calendar) -> Double? {
        let cutoff = DayKeyMath.adding(-minDaysEarlier, to: dayKey, calendar: calendar)
        return series.filter { $0.dayKey <= cutoff }.last?.averageKg
    }
}
