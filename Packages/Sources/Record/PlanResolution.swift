import Foundation
import Constants
import Plan

/// One record day's plan, resolved the one way that every reader uses
/// (regular-eating-plan spec, "Weekday and weekend templates"; "The window
/// of a planned meal"). A day with a `Day` row takes its planned meals and
/// its window constants from that row. A day with no `Day` row yet takes
/// them from its template and from the current constants (reminders spec,
/// "A reminder for every planned meal": "For a record day the app has not
/// materialised, the scheduler MUST use the day's template"). Today, the
/// plan builder and the reminder scheduler all read a plan through
/// `RecordStore.resolvedPlan` (mm-t23.23).
public struct ResolvedDayPlan: Sendable, Equatable {
    public let dateKey: String
    public let meals: [PlannedMeal]
    public let windowBeforeMinutes: Int
    public let windowAfterMinutes: Int
    /// The "Day starts at" hour in force for this record day.
    public let dayStartHour: Int
    /// True when the plan comes from the day's own `Day` row.
    public let hasDayRow: Bool
    /// The set moment on the `Day` row, when the person set the day.
    public let setAt: Date?

    /// The planned meals in the record day's own time order.
    public var orderedMeals: [PlannedMeal] { PlanOrdering.sorted(meals, dayStartHour: dayStartHour) }

    /// The record day's half-open interval, from its key and its own day
    /// start, in `calendar`'s time zone. `nil` for a malformed key.
    public func recordDay(calendar: Calendar) -> DateInterval? {
        guard let (year, month, day) = Materialisation.calendarDate(ofDateKey: dateKey),
              let start = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: dayStartHour))
        else { return nil }
        return RecordDay.interval(containing: start, calendar: calendar, startHour: dayStartHour)
    }

    /// The day's windows, from the constants on the plan, and the entry
    /// each planned meal matches.
    public func match(entries: [PlanEntryFact], recordDay: DateInterval, calendar: Calendar) -> PlanDayMatch {
        PlanDayMatch(
            meals: meals, recordDay: recordDay, dayStartHour: dayStartHour,
            beforeMinutes: windowBeforeMinutes, afterMinutes: windowAfterMinutes,
            entries: entries, calendar: calendar
        )
    }
}

extension RecordStore {
    /// The template that applies to the record day keyed `dateKey`: the
    /// weekday template for a record day that starts Monday to Friday, the
    /// weekend template for Saturday or Sunday.
    public static func templateKind(forDateKey dateKey: String) -> TemplateKind {
        Materialisation.templateKind(forDateKey: dateKey).flatMap(TemplateKind.init(rawValue:)) ?? .weekday
    }

    /// The plan of the record day keyed `dateKey`: its `Day` row, or its
    /// template when the day has no `Day` row yet.
    public func resolvedPlan(dateKey: String, constants: ProgrammeConstants = .default) throws -> ResolvedDayPlan {
        let startHour = try dayStartHour(effectiveOn: dateKey)
        if let plan = try dayPlan(dateKey: dateKey) {
            return ResolvedDayPlan(
                dateKey: dateKey, meals: PlanCodec.decode(plan.slotsJSON),
                windowBeforeMinutes: plan.windowBeforeMinutes, windowAfterMinutes: plan.windowAfterMinutes,
                dayStartHour: startHour, hasDayRow: true, setAt: plan.setAt
            )
        }
        return ResolvedDayPlan(
            dateKey: dateKey, meals: PlanCodec.decode(try templateSlotsJSON(Self.templateKind(forDateKey: dateKey))),
            windowBeforeMinutes: constants.plannedMealWindowBeforeMinutes, windowAfterMinutes: constants.plannedMealWindowAfterMinutes,
            dayStartHour: startHour, hasDayRow: false, setAt: nil
        )
    }

    /// Copies the templates onto every elapsed record day that has no `Day`
    /// row, up to and including the record day that holds `now`
    /// (regular-eating-plan spec, "Weekday and weekend templates": "The app
    /// MUST make the copy lazily, on activation, for every record day that
    /// started since the last copy"; reminders spec: "On activation, the app
    /// MUST materialise every elapsed record day"). The walk starts at the
    /// earliest `Day` row, so it also fills a day that an earlier walk
    /// missed. With no `Day` row at all, it copies the current record day
    /// only. It never replaces a `Day` row, and it writes no `changedAt`
    /// and no set event (`materialiseDayFromTemplate`). Returns the keys it
    /// wrote, in date order.
    @discardableResult
    public func materialiseElapsedRecordDays(now: Date, calendar: Calendar, constants: ProgrammeConstants = .default) throws -> [String] {
        let currentKey = try recordDayKeyInForce(containing: now, calendar: calendar)
        let existing = try dayRowKeys()
        let firstKey = existing.filter { $0 <= currentKey }.min() ?? currentKey
        var templates: [TemplateKind: String] = [:]
        var written: [String] = []
        for key in Materialisation.dateKeys(from: firstKey, through: currentKey) where !existing.contains(key) {
            let kind = Self.templateKind(forDateKey: key)
            let slotsJSON = try templates[kind] ?? templateSlotsJSON(kind)
            templates[kind] = slotsJSON
            if try materialiseDayFromTemplate(
                dateKey: key, slotsJSON: slotsJSON,
                windowBeforeMinutes: constants.plannedMealWindowBeforeMinutes,
                windowAfterMinutes: constants.plannedMealWindowAfterMinutes
            ) {
                written.append(key)
            }
        }
        return written
    }

    /// Saves a change to a template. First it materialises every elapsed
    /// record day, so the change applies only to record days that start
    /// after it (regular-eating-plan spec, "Weekday and weekend templates":
    /// "A change to a template MUST NOT change the current record day's
    /// plan"). The plan builder's "Save" and "Copy to weekend plan" call
    /// this.
    public func changeTemplate(_ slotsJSON: String, kind: TemplateKind, now: Date, calendar: Calendar, constants: ProgrammeConstants = .default) throws {
        try materialiseElapsedRecordDays(now: now, calendar: calendar, constants: constants)
        try setTemplateSlotsJSON(slotsJSON, kind: kind, changedAt: now)
    }

    /// The key of the record day that holds `now`, under the "Day starts
    /// at" hour in force for it.
    private func recordDayKeyInForce(containing now: Date, calendar: Calendar) throws -> String {
        let provisionalKey = RecordDay.key(containing: now, calendar: calendar, startHour: RecordDay.startHour)
        let startHour = try dayStartHour(effectiveOn: provisionalKey)
        return RecordDay.key(containing: now, calendar: calendar, startHour: startHour)
    }
}
