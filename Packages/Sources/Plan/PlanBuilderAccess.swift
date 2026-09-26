import Foundation

/// Whether the plan builder is offered from Today (regular-eating-plan spec,
/// "The plan builder opens at stage 2"). `programme-engine` (2.1) is not
/// built yet, so this reads a `stage2Open` fact, the same fixture-fact
/// pattern `GapBand` and `TodayCardSlot` already use; `mm-t21.23` wires the
/// live stage into it.
public enum PlanBuilderAccess {
    /// "Today's plan" shows in the day heading's menu, and the plan section
    /// shows beside the record, only once stage 2 is open.
    public static func isOffered(stage2Open: Bool) -> Bool {
        stage2Open
    }
}
