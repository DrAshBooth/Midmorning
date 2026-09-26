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

    public var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}
