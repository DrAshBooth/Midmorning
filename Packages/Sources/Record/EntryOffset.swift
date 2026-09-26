import Foundation

/// The UTC offset an entry keeps (record spec, "The app keeps the entry's
/// UTC offset and creation moment"). Ash ruled on 26 September 2026
/// (r13-16, mm-t12b.22) that the offset is the one in effect at the entry's
/// own time by the device zone rules, not the one in effect at the save
/// moment. The store computes the record day key at save from that offset,
/// so an entry that the person backdates across a clock change keeps its
/// own clock time and its own record day.
public enum EntryOffset {
    /// The UTC offset of `zone` at `entryTime`. The new-entry screen and
    /// the edit screen pass this to the store on save.
    public static func seconds(at entryTime: Date, in zone: TimeZone = .current) -> Int {
        zone.secondsFromGMT(for: entryTime)
    }

    /// The zone of the edit screen's time control, and so the zone of the
    /// offset that an edit keeps. When the device zone gives the entry's own
    /// offset at the entry's time, the entry belongs to the device zone: the
    /// control uses its rules, so a record day on a clock-change date is 23
    /// or 25 hours long, and an edited time gets the offset in effect at
    /// that time. Otherwise the person saved the entry in another zone, and
    /// the control uses a fixed zone at the entry's own offset, so the edit
    /// does not move the entry's clock time.
    public static func editZone(entryTime: Date, entryOffsetSeconds: Int, deviceZone: TimeZone = .current) -> TimeZone {
        if deviceZone.secondsFromGMT(for: entryTime) == entryOffsetSeconds { return deviceZone }
        return TimeZone(secondsFromGMT: entryOffsetSeconds) ?? deviceZone
    }
}
