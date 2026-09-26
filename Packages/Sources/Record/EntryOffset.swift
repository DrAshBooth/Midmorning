import Foundation

/// The UTC offset an entry keeps (record spec, "The app keeps the entry's
/// UTC offset and creation moment"). Ash ruled on 26 September 2026
/// (r13-16, mm-t12b.22) that the offset is the one in effect at the entry's
/// own time by the device's current zone rules, not the one in effect at
/// the save moment, on add and on edit. The store computes the record day
/// key at save from that offset, so an entry that the person backdates
/// across a clock change keeps its own clock time and its own record day.
/// `RecordStore.add` and `RecordStore.update` apply these rules, so the
/// new-entry screen and the edit screen pass no offset.
public enum EntryOffset {
    /// The offset a new entry keeps: the offset of `deviceZone` at
    /// `entryTime`.
    public static func forNewEntry(at entryTime: Date, deviceZone: TimeZone = .current) -> Int {
        deviceZone.secondsFromGMT(for: RecordStore.truncatedToMinute(entryTime))
    }

    /// The offset an edit keeps. When the edit changes the entry's time,
    /// the offset of `deviceZone` at the new time ("When an edit changes
    /// the entry's time, the app MUST compute the offset again for the new
    /// time."). When the time stays, the entry's own offset, so an edit of
    /// the What, the Where, the star or the Context does not move the
    /// entry's clock time.
    public static func forEdit(entryTime: Date, entryOffsetSeconds: Int, editedTime: Date, deviceZone: TimeZone = .current) -> Int {
        let edited = RecordStore.truncatedToMinute(editedTime)
        guard edited != RecordStore.truncatedToMinute(entryTime) else { return entryOffsetSeconds }
        return deviceZone.secondsFromGMT(for: edited)
    }

    /// The zone of the edit screen's time control. When the device zone
    /// gives the entry's own offset at the entry's time, the entry belongs
    /// to the device zone: the control uses its rules, so a record day on a
    /// clock-change date is 23 or 25 hours long, and the control shows the
    /// same clock time that the offset at the edited time gives. Otherwise
    /// the person saved the entry in another zone, and the control uses a
    /// fixed zone at the entry's own offset, so it opens at the clock time
    /// that Today shows on the row. For that entry a time change still
    /// takes the device zone's offset at the new time (`forEdit`), so Today
    /// can then show a clock time that is not the one the control showed.
    /// mm-t12b.25 holds that question for Ash.
    public static func editZone(entryTime: Date, entryOffsetSeconds: Int, deviceZone: TimeZone = .current) -> TimeZone {
        if deviceZone.secondsFromGMT(for: entryTime) == entryOffsetSeconds { return deviceZone }
        return TimeZone(secondsFromGMT: entryOffsetSeconds) ?? deviceZone
    }
}
