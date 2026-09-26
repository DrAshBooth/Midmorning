# record

## Purpose

Ash's rulings of 26 September 2026 change two record requirements: the UTC offset at the entry's own time, and the six-words rule beside the plan's text.

## MODIFIED Requirements

### Requirement: The app keeps the entry's UTC offset and creation moment

The app MUST keep, with each entry, the UTC offset for the entry's own time. The app MUST compute that offset from the device's current time zone rules at the entry time, with `TimeZone.current.secondsFromGMT(for:)`. The app MUST NOT use the offset at the save moment. When an edit changes the entry's time, the app MUST compute the offset again for the new time. The store writes the record day key from the entry's time and this offset, as "The record day" requirement states. Ash ruled this on 26 September 2026. The app MUST NOT keep a time zone name. The app MUST keep the moment the person saved the entry, separate from the entry time. The app MUST NOT show the creation moment or any "logged later" label to the person. Today MUST show the entry's clock time at the entry's UTC offset.

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
