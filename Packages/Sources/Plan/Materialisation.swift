import Foundation

/// Which template applies to a record day, and the copy a record day's plan
/// starts as (regular-eating-plan spec, "Weekday and weekend templates").
/// Checking whether a `Day` row already exists, and writing the new one with
/// no `changedAt`, is the store's job (`RecordStore.materialiseDayFromTemplate`);
/// this holds the pure part.
public enum Materialisation {
    /// "weekday" for a record day starting Monday to Friday, "weekend" for
    /// Saturday or Sunday. `weekday` is `Calendar.Component.weekday`: 1 is
    /// Sunday, 7 is Saturday.
    public static func templateKind(forRecordDayStartingOnWeekday weekday: Int) -> String {
        (weekday == 1 || weekday == 7) ? "weekend" : "weekday"
    }
}
