# record

## Purpose

This change makes record "Edit an entry" agree with Ash's ruling of 26 September 2026 on the entry's UTC offset. The edit screen computes the record day's bounds from the device's time zone rules for an entry from the device's own time zone.

## MODIFIED Requirements

### Requirement: Edit an entry

A tap on a row on Today or on an earlier day MUST open the entry for editing. The edit screen is the new-entry screen filled with the entry's values. The person MUST be able to change the time, the What, the Where, the star and the Context.

The time control MUST offer only times inside the entry's own record day. The time control MUST show one segment, which names that record day. The app MUST compute that record day's bounds from the day start row and a time zone. That row is the one in force for that record day key, as `data-and-privacy` states. When the device's current time zone gives the entry's UTC offset at the entry time, the app MUST use the rules of that time zone. A record day on the date of a clock change is then 23 or 25 hours long. In every other case, the app MUST use a fixed time zone at the entry's UTC offset. Ash's ruling of 26 September 2026 on the entry's UTC offset sets this rule. The time control MUST NOT offer a time after the current moment.

On save the app MUST keep the entry's record day as it was. On save the app MUST keep the entry's creation moment as it was. On save the app MUST close the screen as the "Save is quiet" requirement describes. The app MUST NOT show an "edited" label or any text about the edit. "Cancel" MUST discard every change. Ash ruled on 25 September 2026 that an edit keeps the entry in its own record day.

#### Scenario: Change the What
- **WHEN** the person taps the 13:05 entry "Toast and tea", changes What to "Toast, tea and a biscuit" and saves
- **THEN** Today shows the 13:05 entry with What "Toast, tea and a biscuit" and no other change

#### Scenario: Change the time inside the entry's record day
- **WHEN** "Day starts at" is 04:00, the current time is 09:00 on Friday 25 September, and the person opens the Friday 08:30 entry
- **THEN** the time control offers times from 04:00 to 09:00 on Friday only, and after the person sets 06:45 and saves, Today shows the entry under Friday 25 September at 06:45

#### Scenario: One segment on the edit screen
- **WHEN** the current time is 02:00 on Friday 25 September and the person opens the Wednesday 23 September 21:00 entry
- **THEN** the time control shows one segment, "Wednesday 23 September", and the hour-and-minute wheel

#### Scenario: Creation moment stays
- **WHEN** the person edits an entry with the creation moment 13:08 and saves at 18:00
- **THEN** the app keeps 13:08 as the creation moment

#### Scenario: Cancel an edit
- **WHEN** the person turns the star on in the edit screen and taps "Cancel"
- **THEN** the entry keeps the star off

#### Scenario: Edit on the day of a clock change
- **WHEN** "Day starts at" is 04:00, the clocks in London go back at 02:00 on Sunday 25 October, the current time is 09:00 that day, and the person opens the Saturday 24 October 23:00 entry
- **THEN** the time control offers times up to 03:59 on Sunday in the segment "Saturday 24 October", and after the person sets 03:30 and saves, Today shows the entry under Saturday 24 October at 03:30
