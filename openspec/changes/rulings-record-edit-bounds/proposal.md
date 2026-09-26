# Proposal

## Why

Ash ruled on 26 September 2026 (r13-16, `mm-t12b.22`) that an entry keeps the UTC offset for its own time, from the device's current time zone rules. When an edit changes the entry's time, the app computes the offset again for the new time. Change `rulings-specs-a` writes that rule in record "The app keeps the entry's UTC offset and creation moment".

Record "Edit an entry" still says that the app computes the record day's bounds from the entry's UTC offset. With a fixed offset, the record day of Saturday 24 October 2026 in London ends at 03:00 GMT on Sunday, not at 04:00 GMT. So the time control does not offer 03:00 to 03:59 on Sunday, and those times are in Saturday's record day. The code on branch `rulings-record-store` uses the device's time zone rules for an entry from the device's own time zone. This change makes the spec agree with the code.

## What Changes

- record "Edit an entry": the app computes the record day's bounds from the day start row and a time zone. For an entry from the device's own time zone, the app uses the rules of the device's current time zone, so a record day on the date of a clock change is 23 or 25 hours long. For an entry from another time zone, the app uses a fixed time zone at the entry's UTC offset.
- A new scenario, "Edit on the day of a clock change".
- The copy of "Edit an entry" in `openspec/changes/v1-programme/specs/record/spec.md` gets the same change.

`mm-t12b.25` holds an open question for Ash: the clock time that an edit keeps for an entry from another time zone when the person changes its time. This change does not answer it.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `record`: "Edit an entry".

## Impact

- `App/Midmorning/EditEntryView.swift` and `Packages/Sources/Record/EntryOffset.swift` (`EntryOffset.editZone`) already do this.
- `EntryOffsetTests` prove it on the 25-hour record day of Saturday 24 October 2026.
