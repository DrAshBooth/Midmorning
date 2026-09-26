import Foundation

/// A slot's kind (regular-eating-plan spec, "Slots and planned meals"):
/// "Breakfast", "Lunch" and "Evening meal" are meals; "Mid-morning",
/// "Mid-afternoon" and "Evening snack" are snacks.
public enum SlotKind: String, Sendable, Equatable, Codable {
    case meal, snack
}

/// One of the six fixed slots, in slot-index order 0 to 5 (regular-eating-
/// plan spec, "Slots and planned meals"). A slot's kind, its index and its
/// default label and time never change. Only its label can change, through
/// `SlotLabel`.
public struct Slot: Sendable, Equatable {
    public let index: Int
    public let kind: SlotKind
    public let defaultLabel: String
    public let defaultHour: Int
    public let defaultMinute: Int

    public init(index: Int, kind: SlotKind, defaultLabel: String, defaultHour: Int, defaultMinute: Int) {
        self.index = index
        self.kind = kind
        self.defaultLabel = defaultLabel
        self.defaultHour = defaultHour
        self.defaultMinute = defaultMinute
    }

    /// The default time, as "HH:mm".
    public var defaultTime: String { PlanTime.string(hour: defaultHour, minute: defaultMinute) }

    /// The six slots, in slot-index order (regular-eating-plan spec, "Slots
    /// and planned meals"). The default times are Breakfast 08:00,
    /// Mid-morning 10:30, Lunch 13:00, Mid-afternoon 16:00, Evening meal
    /// 19:00 and Evening snack 21:00.
    public static let all: [Slot] = [
        Slot(index: 0, kind: .meal, defaultLabel: "Breakfast", defaultHour: 8, defaultMinute: 0),
        Slot(index: 1, kind: .snack, defaultLabel: "Mid-morning", defaultHour: 10, defaultMinute: 30),
        Slot(index: 2, kind: .meal, defaultLabel: "Lunch", defaultHour: 13, defaultMinute: 0),
        Slot(index: 3, kind: .snack, defaultLabel: "Mid-afternoon", defaultHour: 16, defaultMinute: 0),
        Slot(index: 4, kind: .meal, defaultLabel: "Evening meal", defaultHour: 19, defaultMinute: 0),
        Slot(index: 5, kind: .snack, defaultLabel: "Evening snack", defaultHour: 21, defaultMinute: 0),
    ]

    public static func at(index: Int) -> Slot? { all.first { $0.index == index } }
}
