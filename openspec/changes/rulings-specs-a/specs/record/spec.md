# record

## Purpose

Ash's rulings of 26 September 2026 change three record requirements: the UTC offset at the entry's own time, the time zone of the edit screen, and the six-words rule beside the plan's text.

## MODIFIED Requirements

### Requirement: The app keeps the entry's UTC offset and creation moment

The app MUST keep, with each entry, the UTC offset for the entry's own time. On the new-entry screen, the app MUST compute that offset from the device's current time zone rules at the entry time, with `TimeZone.current.secondsFromGMT(for:)`. The app MUST NOT use the offset at the save moment. On the edit screen, the app MUST compute the offset at the edited time in the edit zone. The "Edit an entry" requirement defines the edit zone. The store writes the record day key from the entry's time and this offset, as "The record day" requirement states. Ash ruled this on 26 September 2026. The app MUST NOT keep a time zone name. The app MUST keep the moment the person saved the entry, separate from the entry time. The app MUST NOT show the creation moment or any "logged later" label to the person. Today MUST show the entry's clock time at the entry's UTC offset.

#### Scenario: Entry with an earlier time
- **WHEN** the person saves an entry with a time two hours before now
- **THEN** Today shows the entry at that time with no label and no message about when the person saved it

#### Scenario: Creation moment is kept
- **WHEN** the person saves an entry at 13:08 with the time 13:05
- **THEN** the app keeps 13:08 as the creation moment and 13:05 as the entry time

#### Scenario: Offset change
- **WHEN** the person saves an entry at 20:00 in London and opens Today in New York while that entry is in the current record day
- **THEN** Today shows the entry at 20:00

#### Scenario: Earlier time across a clock change
- **WHEN** the clocks in London go back at 02:00 on Sunday 25 October, and at 10:00 that day the person saves an entry with the time 04:30 on Saturday 24 October
- **THEN** the app keeps the offset UTC+1 with the entry, the store writes the key of Saturday 24 October, and the entry shows at 04:30 under Saturday 24 October

### Requirement: Edit an entry

A tap on a row on Today or on an earlier day MUST open the entry for editing. The edit screen is the new-entry screen filled with the entry's values. The person MUST be able to change the time, the What, the Where, the star and the Context.

The time control MUST offer only times inside the entry's own record day. The time control MUST show one segment, which names that record day. The time control MUST show and offer times in the entry's edit zone. When the device's current time zone gives the entry's kept UTC offset at the entry's time, the edit zone is the device's current time zone. Otherwise the edit zone is a fixed zone at the entry's kept UTC offset. The app MUST compute that record day's bounds in the edit zone, from the day start row. That row is the one in force for that record day key, as `data-and-privacy` states. In the device's current time zone, a record day on a clock-change date is 23 or 25 hours long, as "The record day" requirement states. The time control MUST NOT offer a time after the current moment.

On save the app MUST keep the UTC offset of the edit zone at the edited time. In a fixed zone, that offset is the entry's kept offset. On save the app MUST keep the entry's record day as it was. The edited time and its offset then still give that record day's key. On save the app MUST keep the entry's creation moment as it was. On save the app MUST close the screen as the "Save is quiet" requirement describes. The app MUST NOT show an "edited" label or any text about the edit. "Cancel" MUST discard every change. Ash ruled on 25 September 2026 that an edit keeps the entry in its own record day. The edit zone follows Ash's ruling of 26 September 2026 on the offset at the entry's own time. After travel, it also follows the ruling of 25 September 2026.

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

#### Scenario: Edit after travel
- **WHEN** the person saves an entry at 05:00 on Saturday 26 September in London at UTC+1, then on Sunday 27 September opens it in New York at UTC-4 and sets the time 05:30
- **THEN** the time control shows 05:00 when it opens, the app keeps UTC+1 with the entry, and the entry shows at 05:30 under Saturday 26 September

#### Scenario: Edit across a clock change
- **WHEN** the clocks in London go back at 02:00 on Sunday 25 October, and at 09:00 that day the person in London opens the Saturday 24 October 23:00 entry and sets the time 03:30 on Sunday
- **THEN** the time control offers times from 04:00 on Saturday to 03:59 on Sunday, 25 hours, the app keeps UTC+0 with the entry, and the entry shows at 03:30 under Saturday 24 October

### Requirement: Today's appearance

Today's heading MUST show the record day's weekday and date. Between 00:00 and 03:59 the current day's heading MUST add ", night" after the date.

Today MUST show a starred entry with an asterisk glyph in the same colour and weight as the entry's time. The time and the asterisk MUST use the primary text colour. The asterisk MUST be at least the x-height of the time. The glyph MUST use no accent colour and no fill. A starred row MUST have the same background, height, spacing and text style as an unstarred row. Every row MUST have the same height and spacing, whatever the time since the previous entry.

Today MUST show absolute times only, with no relative times, no divider and no grouping within a record day, except the gap band. Today MUST NOT show a count of entries, a total, a count of consecutive days or a rating, except the count line of a collapsed day. Today MUST NOT show any text about the absence of entries. On an empty current record day, Today MUST show only these elements:

- the heading
- the control that opens the new-entry screen
- the fixed elements that the Today stack defines

The `record` capability in change `v1-programme` defines the Today stack. The new-entry screen MUST have no title. On Today's rows and on the new-entry screen, the app MUST NOT use six words. Those words are "meal", "food", "log", "diary", "intake" and "eat". This rule does not apply to the plan's text on Today: the slot labels, the next-planned-meal line and the missed planned meal prompt. The `regular-eating-plan` capability owns that text, and `product-rules` requires the words "planned meal". The rule still applies to the app's own text on every entry row and on the new-entry screen. Ash ruled this on 26 September 2026. The `product-rules` capability owns vocabulary on every other screen.

A reviewer checks these rules on the simulator. No test in this change covers them.

#### Scenario: Starred entry
- **WHEN** an entry has the star on
- **THEN** Today shows the entry with an asterisk glyph beside the time and no other difference from an unstarred row

#### Scenario: No entries
- **WHEN** the current record day has no entries and the previous record day has none
- **THEN** Today shows the heading, the control that opens the new-entry screen, the fixed elements of the Today stack, and nothing else

#### Scenario: Heading after midnight
- **WHEN** the current time is 01:00 on Friday 25 September
- **THEN** the current day's heading reads "Thursday 24 September, night"

#### Scenario: Plan text on Today
- **WHEN** Today shows the planned meal "Evening meal" at 19:00 and the line "Evening meal at 19:00 still happens."
- **THEN** the six-words rule does not apply to those two rows, and the app's own text on the entry rows and on the new-entry screen holds none of the six words
