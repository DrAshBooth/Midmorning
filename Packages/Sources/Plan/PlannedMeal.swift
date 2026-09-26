import Foundation

/// One planned meal on a day or in a template: a slot and a time, held to
/// the minute (regular-eating-plan spec, "Slots and planned meals": "A
/// planned meal MUST hold a slot and a time and nothing else").
public struct PlannedMeal: Sendable, Equatable, Codable {
    public let slotIndex: Int
    /// "HH:mm", the wall-clock time of day.
    public var time: String

    enum CodingKeys: String, CodingKey {
        case slotIndex = "slot"
        case time
    }

    public init(slotIndex: Int, time: String) {
        self.slotIndex = slotIndex
        self.time = time
    }

    public init(slotIndex: Int, hour: Int, minute: Int) {
        self.init(slotIndex: slotIndex, time: PlanTime.string(hour: hour, minute: minute))
    }

    public var hourAndMinute: (hour: Int, minute: Int) {
        PlanTime.parse(time) ?? (0, 0)
    }
}

/// Encodes and decodes a day's or a template's `slotsJSON` (regular-eating-
/// plan spec, "Slots and planned meals"). `Day.slotsJSON` and
/// `Template.slotsJSON` are opaque, additively-grown strings to the store;
/// only this capability reads their shape (model-foundation, `Day.swift`,
/// `Template.swift`).
public enum PlanCodec {
    public static func decode(_ json: String) -> [PlannedMeal] {
        guard let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([PlannedMeal].self, from: data)) ?? []
    }

    public static func encode(_ meals: [PlannedMeal]) -> String {
        let ordered = meals.sorted { $0.slotIndex < $1.slotIndex }
        guard let data = try? JSONEncoder().encode(ordered), let json = String(data: data, encoding: .utf8) else { return "[]" }
        return json
    }

    /// Places `slotIndex` at `time`, replacing any planned meal already at
    /// that slot (regular-eating-plan spec, "Slots and planned meals": "A day
    /// MUST hold each slot at most once").
    public static func placing(_ slotIndex: Int, at time: String, in meals: [PlannedMeal]) -> [PlannedMeal] {
        removing(slotIndex, from: meals) + [PlannedMeal(slotIndex: slotIndex, time: time)]
    }

    /// Removes the planned meal at `slotIndex`, if any.
    public static func removing(_ slotIndex: Int, from meals: [PlannedMeal]) -> [PlannedMeal] {
        meals.filter { $0.slotIndex != slotIndex }
    }
}
