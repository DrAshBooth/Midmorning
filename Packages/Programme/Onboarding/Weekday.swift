import Foundation

/// A weekday, numbered as `Calendar`'s own `weekday` component (1 is
/// Sunday, 7 is Saturday), for onboarding's "Weigh-in day" and, later,
/// `weigh-in`'s own screen.
public enum Weekday: Int, Sendable, Equatable, CaseIterable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    /// Every weekday in the order a weekday list shows them, Monday to
    /// Sunday (weigh-in spec, "The weigh-in day": VoiceOver reads "Monday"
    /// to "Sunday"). `allCases` keeps `Calendar`'s own Sunday-first order.
    public static let mondayFirst: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    /// The weekday's name from the en_GB formatter, as every date the app
    /// shows (content spec, "Catalogue rules": "Every date ... MUST enter a
    /// string as %@, filled by the en_GB formatter"), not a literal in code.
    public var name: String {
        Self.names[rawValue - 1]
    }

    /// Sunday first, as `Calendar`'s own `weekday` numbering.
    private static let names: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        return formatter.standaloneWeekdaySymbols
    }()
}
