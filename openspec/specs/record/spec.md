# record Specification

## Purpose
The record is the person's real-time account of what they ate and drank. The person creates an entry in under 20 seconds. Today shows the record day's entries as a time-ordered column, like the paper record. Every string in the record describes what the person did or noticed. No string names a condition, a treatment, a therapy or an outcome.

## Requirements

### Requirement: The record day

A record day starts at the day start, 04:00 by default, and ends one minute before the next day start. The store MUST write an entry's record day key at save. The key comes from the entry's time, its UTC offset and the day start in force. An entry's record day MUST NOT change after save. The app MUST compute the current record day in the device's current time zone.

The app MUST set the day start with the calendar's "day start on this calendar date" rule. A record day on a clock-change date is therefore 23 or 25 hours long. The current record day is the record day that contains the current moment. Today MUST show the entries whose key equals the current record day's key. Ash chose the fixed key on 25 September 2026 so that travel never moves an entry.

#### Scenario: Entry after midnight
- **WHEN** an entry has the time 00:30 on Friday 25 September
- **THEN** the store writes the key of Thursday 24 September on it

#### Scenario: Travel
- **WHEN** an entry saved at 20:00 in London holds the key of Thursday 24 September and the person opens Today in Sydney the next week
- **THEN** the entry still shows under Thursday 24 September

#### Scenario: Current record day after midnight
- **WHEN** the current time is 01:00 on Friday 25 September
- **THEN** the current record day is Thursday 24 September

#### Scenario: Clock change
- **WHEN** the clocks go back one hour at 02:00 on Sunday 25 October in London
- **THEN** the record day of Saturday 24 October runs from 04:00 on Saturday to 04:00 on Sunday and is 25 hours long

### Requirement: Create an entry

The app MUST let the person create an entry with a time, a What text and a "felt like a binge" star. The time MUST default to the moment the new-entry screen opens. The app MUST accept any entry time from the start of the previous record day to the save moment. The time control MUST let the person choose the date and the time within that range.

The app MUST keep the time to the minute. The What field MUST accept free text. The What field MUST accept an empty text. The app MUST trim white space and line breaks from the start and end of What. The app MUST keep the rest as typed.

The app MUST NOT offer a food database, portions or calories. The app MUST NOT show a placeholder in What.

#### Scenario: Save an entry with the default time
- **WHEN** the person opens the new-entry screen at 13:05, types "Toast and tea" in What and saves at 13:08
- **THEN** the app saves one entry with What "Toast and tea", the time 13:05, and the star off

#### Scenario: Save an entry with an earlier time
- **WHEN** the person sets the time to 08:10 in the current record day, types "Toast and tea" and saves
- **THEN** the app saves one entry with the time 08:10

#### Scenario: Save last night's entry the next morning
- **WHEN** the current time is 07:30 on Friday 25 September and the person sets the time to 23:30 on Thursday 24 September and saves
- **THEN** the app saves the entry with the time 23:30 on Thursday 24 September

#### Scenario: Save an evening entry after midnight
- **WHEN** the current time is 01:00 on Friday 25 September and the person sets the time to 23:00
- **THEN** the app saves the entry with the time 23:00 on Thursday 24 September

#### Scenario: Save an entry with the star
- **WHEN** the person types "Toast and tea", turns on "felt like a binge" and saves
- **THEN** the app saves the entry with the star on

#### Scenario: Save an entry with an empty What
- **WHEN** the person turns on "felt like a binge", leaves What empty and saves
- **THEN** the app saves the entry with an empty What and the star on

#### Scenario: Time range
- **WHEN** the person opens the time control
- **THEN** the control offers dates and times from the start of the previous record day to the current moment, and nothing outside that range

#### Scenario: White space around What
- **WHEN** the person types "  Toast and tea " and saves
- **THEN** the app saves the What "Toast and tea"

### Requirement: Save is quiet

When the person saves, the app MUST close the new-entry screen with the system's standard dismissal. The app MUST then show Today. Today MUST scroll so that the saved entry is on screen. On save the app MUST NOT add a confirmation, a message, a colour change or an icon. On save the app MUST NOT add a sound, a haptic or an animation. The system's standard sheet dismissal and standard list update are not additions.

When the star changes, the app MUST NOT show a confirmation, a message, an icon or a colour change elsewhere. The app MUST NOT add a sound or a haptic. The star control's own state change and the system toggle's standard haptic are not additions.

#### Scenario: Save a starred entry
- **WHEN** the person turns on "felt like a binge" and saves
- **THEN** the screen closes as any sheet closes, and Today shows the entry with no message or other response

#### Scenario: Turn the star on
- **WHEN** the person turns on "felt like a binge"
- **THEN** the star control shows on, and the app shows no message, colour change elsewhere, icon or sound

#### Scenario: Save on a long day
- **WHEN** the current record day has fifteen entries and the person saves a sixteenth
- **THEN** Today shows the sixteenth entry on screen without a change to any row's appearance

### Requirement: The app keeps the entry on the device

The app MUST save every entry in a file on the device. The app MUST give the store's files the protection class that iOS can read only while the device is unlocked. The app MUST exclude the store's files from iCloud Backup and from local device backups. The app MUST NOT send any entry field off the device by any channel, including Apple services. This rule permits sync to the person's own iCloud private database in a later change, and no other channel.

The app MUST NOT index an entry in Spotlight or donate it to Siri. The app MUST NOT write an entry to the pasteboard or place it in an NSUserActivity. An entry MUST survive the app closing and opening again.

#### Scenario: Restart
- **WHEN** the person saves an entry, closes the app and opens it again
- **THEN** Today shows the entry

#### Scenario: No network
- **WHEN** the device has no network connection
- **THEN** the person can save an entry and see it on Today

#### Scenario: New phone without sync
- **WHEN** the person restores a new phone from a backup made before sync exists
- **THEN** the record on the new phone is empty

### Requirement: The app keeps entry data out of logs

The app MUST NOT write any entry field to the system log or to standard output. The app MUST NOT put any entry field in an error description, a crash report or an analytics event. The store's errors MUST carry no entry data.

#### Scenario: Store error
- **WHEN** the store fails to save an entry with What "Toast and tea"
- **THEN** the error the store throws contains no part of "Toast and tea"

### Requirement: The app keeps the entry's UTC offset and creation moment

The app MUST keep, with each entry, the UTC offset in effect on the device when the person saved. The app MUST NOT keep a time zone name. The app MUST keep the moment the person saved the entry, separate from the entry time. The app MUST NOT show the creation moment or any "logged later" label to the person. Today MUST show the entry's clock time at the entry's UTC offset.

#### Scenario: Entry with an earlier time
- **WHEN** the person saves an entry with a time two hours before now
- **THEN** Today shows the entry at that time with no label and no message about when the person saved it

#### Scenario: Creation moment is kept
- **WHEN** the person saves an entry at 13:08 with the time 13:05
- **THEN** the app keeps 13:08 as the creation moment and 13:05 as the entry time

#### Scenario: Offset change
- **WHEN** the person saves an entry at 20:00 in London and opens Today in New York while that entry is in the current record day
- **THEN** Today shows the entry at 20:00

### Requirement: Today shows the record day's entries in time order

Today MUST show every entry in the current record day. When the previous record day has at least one entry, Today MUST show those entries above. They sit under that day's date heading. Today MUST NOT show a heading for a previous record day with no entries. Today MUST order the entries in each day by entry time, earliest first.

When two entries have the same time, Today MUST order them by creation moment, earliest first. Today MUST show each entry's time. Today MUST show each entry's What when it is not empty. Today MUST show a control that opens the new-entry screen in one tap.

#### Scenario: Two entries out of creation order
- **WHEN** the person saves an entry with the time 13:05 and then saves an entry with the time 08:10
- **THEN** Today shows the 08:10 entry above the 13:05 entry

#### Scenario: Same time
- **WHEN** the person saves two entries with the time 13:05
- **THEN** Today shows the one the person saved first above the other

#### Scenario: Previous record day with entries
- **WHEN** the previous record day has one entry and the current record day has two
- **THEN** Today shows the previous day's entry under the previous day's heading, above the current day's heading and entries

#### Scenario: Previous record day without entries
- **WHEN** the previous record day has no entries
- **THEN** Today shows no heading for it

#### Scenario: Entry with an empty What
- **WHEN** an entry has an empty What
- **THEN** Today shows the entry's time, and the star when it is on, and no other text on that row

#### Scenario: One tap to a new entry
- **WHEN** the person is on Today
- **THEN** one tap opens the new-entry screen with the keyboard in What

### Requirement: Today refreshes the record day

Today MUST compute the current record day again when the app becomes active. Today MUST compute it again at the day start while Today is on screen.

#### Scenario: Return in the morning
- **WHEN** the person opened Today at 23:00 on Thursday, left the app open in the background, and returns at 09:00 on Friday
- **THEN** Today shows Friday as the current record day

### Requirement: Today's appearance

Today's heading MUST show the record day's weekday and date. Between 00:00 and 03:59 the current day's heading MUST add ", night" after the date.

Today MUST show a starred entry with an asterisk glyph in the same colour and weight as the entry's time. The time and the asterisk MUST use the primary text colour. The asterisk MUST be at least the x-height of the time. The glyph MUST use no accent colour and no fill. A starred row MUST have the same background, height, spacing and text style as an unstarred row. Every row MUST have the same height and spacing, whatever the time since the previous entry.

Today MUST show absolute times only, with no relative times, no dividers and no grouping within a record day. Today MUST NOT show a count of entries, a total, a count of consecutive days or a rating. Today MUST NOT show any text about the absence of entries. On an empty current record day, Today MUST show only these elements:

- the heading
- the control that opens the new-entry screen
- the fixed elements that the Today stack defines

The `record` capability in change `v1-programme` defines the Today stack. The visible strings of this change are "Today", "What", "felt like a binge", "Save" and "Cancel". The new-entry screen MUST have no title. On Today's rows and on the new-entry screen, the app MUST NOT use six words. Those words are "meal", "food", "log", "diary", "intake" and "eat". The `product-rules` capability owns vocabulary on every other screen.

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

### Requirement: Today hides entries when the app is not active

When the app is not active, Today and the new-entry screen MUST hide entry text and stars. The app switcher MUST show no entry.

#### Scenario: App switcher
- **WHEN** the person opens the app switcher while Today shows entries
- **THEN** the app's snapshot shows no entry text and no star

### Requirement: Keyboards on the new-entry screen

The app MUST NOT allow a third-party keyboard on the new-entry screen.

#### Scenario: Third-party keyboard installed
- **WHEN** the person has a third-party keyboard as the active keyboard and opens the new-entry screen
- **THEN** the system keyboard appears

### Requirement: Accessibility of the record

Each row on Today MUST be one accessibility element. The row's label MUST hold the time, then the What when not empty, then "felt like a binge" when the star is on. A comma and a space MUST separate the parts. Every control on Today and the new-entry screen MUST have a VoiceOver label.

When the new-entry screen opens, VoiceOver focus MUST move to What. Cancel and Save MUST stay in the navigation bar, which VoiceOver reads before the content. The content's reading order MUST be What, "felt like a binge", Time. The time control's label MUST be "Time". Its VoiceOver value MUST read the date and time, for example "Thursday 24 September, 21:35". What MUST accept dictation from the system keyboard with no extra tap. The star control's visible label and VoiceOver label MUST both be "felt like a binge".

The star MUST NOT depend on colour alone. Text on Today and the new-entry screen MUST use system text styles. Text on Today and the new-entry screen MUST scale with Dynamic Type. The app MUST NOT limit What to one line on Today.

#### Scenario: Label of a starred entry
- **WHEN** VoiceOver reads a starred entry at 13:05 with What "Toast and tea"
- **THEN** it reads "13:05, Toast and tea, felt like a binge"

#### Scenario: Label of an unstarred entry with an empty What
- **WHEN** VoiceOver reads an unstarred entry at 13:05 with an empty What
- **THEN** it reads "13:05"

#### Scenario: Reading order of the new-entry screen
- **WHEN** the person opens the new-entry screen with VoiceOver on
- **THEN** VoiceOver focus is on What, and the next elements are "felt like a binge" and Time, in that order

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** Today and the new-entry screen show all text without truncation

### Requirement: Review before archive

Before the team archives `record-entry-on-today`, one person MUST save a starred entry on the built app. That person MUST answer, for each screen: could a person who has just binged read this as judgement? The clinical reviewer, once engaged, MUST repeat this walk before any build reaches a person outside the team.

#### Scenario: Sign-off
- **WHEN** `record-entry-on-today` is ready to archive
- **THEN** the change's README holds who walked the starred-entry path, on which date, and their answer for each screen
