import Foundation

/// The UTC offset an entry keeps (record spec, "The app keeps the entry's
/// UTC offset and creation moment"). Ash ruled on 26 September 2026
/// (r13-16, mm-t12b.22) that the offset is the one in effect at the entry's
/// own time by the device's current zone rules, not the one in effect at
/// the save moment. The store computes the record day key at save from that
/// offset, so an entry that the person backdates across a clock change
/// keeps its own clock time and its own record day. On edit, the offset is
/// the one of the entry's edit zone at the edited time (record spec, "Edit
/// an entry"). Ash ruled on 7 October 2026 (r15-02, mm-t12b.25,
/// mm-t12b.26) that the time control and the save use the same edit zone:
/// travel never moves an entry, and the control and Today show the same
/// clock time. `RecordStore.add` and `RecordStore.update` apply these
/// rules, so the new-entry screen and the edit screen pass no offset.
public enum EntryOffset {
    /// The offset a new entry keeps: the offset of `deviceZone` at
    /// `entryTime`.
    public static func forNewEntry(at entryTime: Date, deviceZone: TimeZone = .current) -> Int {
        deviceZone.secondsFromGMT(for: RecordStore.truncatedToMinute(entryTime))
    }

    /// The offset an edit keeps: the offset of the edit zone (`editZone`)
    /// at the edited time ("On save the app MUST keep the UTC offset of the
    /// edit zone at the edited time. In a fixed zone, that offset is the
    /// entry's kept offset."). For an entry from the device zone, a time
    /// change takes the device zone's offset at the new time, also across a
    /// clock change. For an entry from another zone, the edit keeps the
    /// entry's own offset, so Today shows the clock time that the time
    /// control showed, and the edited time and that offset still give the
    /// entry's record day key. When the time stays, the entry's own offset,
    /// so an edit of the What, the Where, the star or the Context does not
    /// move the entry's clock time.
    public static func forEdit(entryTime: Date, entryOffsetSeconds: Int, editedTime: Date, deviceZone: TimeZone = .current) -> Int {
        forEdit(
            entryTime: entryTime, entryOffsetSeconds: entryOffsetSeconds, editedTime: editedTime,
            editZone: editZone(entryTime: entryTime, entryOffsetSeconds: entryOffsetSeconds, deviceZone: deviceZone)
        )
    }

    /// The offset an edit keeps in `editZone`, the zone that the edit
    /// screen's time control showed. The edit screen gives its own zone, so
    /// the save uses the zone of the control also when the device zone
    /// changes while the screen is open (ruling r15-02).
    public static func forEdit(entryTime: Date, entryOffsetSeconds: Int, editedTime: Date, editZone: TimeZone) -> Int {
        let edited = RecordStore.truncatedToMinute(editedTime)
        guard edited != RecordStore.truncatedToMinute(entryTime) else { return entryOffsetSeconds }
        return editZone.secondsFromGMT(for: edited)
    }

    /// The entry's edit zone: the zone of the edit screen's time control
    /// and of the offset an edit keeps (record spec, "Edit an entry"). When
    /// the device zone gives the entry's own offset at the entry's time,
    /// the entry belongs to the device zone: the control uses its rules, so
    /// a record day on a clock-change date is 23 or 25 hours long. Otherwise
    /// the person saved the entry in another zone, and the control uses a
    /// fixed zone at the entry's own offset, so it opens at the clock time
    /// that Today shows on the row. The edit zone of an edit zone is that
    /// same zone.
    public static func editZone(entryTime: Date, entryOffsetSeconds: Int, deviceZone: TimeZone = .current) -> TimeZone {
        if deviceZone.secondsFromGMT(for: entryTime) == entryOffsetSeconds { return deviceZone }
        return TimeZone(secondsFromGMT: entryOffsetSeconds) ?? deviceZone
    }
}
