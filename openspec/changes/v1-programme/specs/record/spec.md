# record

## Purpose

This delta adds the rest of the paper record to the entry and to Today. It adds the Where chips, the Context field, edit, delete, "Didn't record", earlier days, the collapsed day, "Pause for today" and the gap band. The `record-entry-on-today` change owns entry creation, the record day, Today's column, storage and the accessibility of the record. Those rules stay as they are. The `reminders` capability owns the neutral midday prompt for a missed morning and the close-the-day reminder of the day.

## ADDED Requirements

### Requirement: The Today stack

Today MUST show these fixed elements, in this order from the top:

- the pinned note, when one exists
- the "Weekly review" or "Check-in" line, when one is due
- one card slot
- the "Urge open since 22:40" line, when an urge is open
- the day sections

The card slot MUST hold at most one card at a time. A card is one of these:

- an opening card
- a suggestion card
- a stage 1 card
- the plan card
- the Focus card
- the week-13 question
- the maintenance plan

The `programme` capability owns the stage 1, plan and Focus cards. When more than one card is waiting, the app MUST show the oldest first. The app MUST show the next card after the person dismisses the first. After a starred entry or an "I binged" outcome, the app MUST NOT show a card in the same record day.

Each day section MUST show its heading and its rows. It MUST show a state line when the day is paused or has the state "didn't record". From stage 2 it MUST show the plan beside the record and the gap bands. The current day section MUST come first. The previous day section MUST follow it, collapsed by default, and only when it has an entry.

The "Urge" button MUST stay pinned at the bottom of Today from stage 3. In VoiceOver's reading order the "Urge" button MUST come first from stage 3. The navigation bar MUST hold five controls, in this order:

- the add control, with the label "Add an entry"
- the Programme control
- the "Reviews" control
- Get support
- the lock control

The lock control MUST show the cover and lock at once. With the app lock off, it MUST still show the cover until a tap.

A full-width control "Add an entry" MUST sit under the current day heading, above the rows. "Pause for today" MUST sit under the rows as a visible control. "Close the day" MUST sit beside it only after the last planned meal's time, or after 17:00 in stage 1. "Fasting today", "Didn't record" and "Earlier days" MUST live in the day heading's menu, one tap inside it. The heading MUST also offer them as custom actions.

Notification permission can be not determined while a reminder switch is on. Then the line "Notifications are off in iOS Settings." MUST sit above the rows as a control. A tap on that control MUST make the system permission request. When permission is denied, the same line MUST show until the person taps it once. After that tap, only the Reminders group shows the state.

Ash chose this layout on 25 September 2026 so the record is the first thing a new person sees. The settings screen MUST be one tap from Today, through the navigation bar.

A two-finger double tap on Today MUST open the new-entry screen. After the new-entry screen closes, VoiceOver focus MUST return to the add control. Each day heading MUST carry the header trait. "Collapse day", "Expand day" and "Didn't record" MUST be VoiceOver custom actions on the heading.

The order above is the only order. Another capability MUST NOT add an element to Today except through the card slot or a day section row.

#### Scenario: Empty day, no cards
- **WHEN** the current record day has no entries, nothing is due and no card is waiting
- **THEN** Today shows the navigation bar, the current day heading with its menu, the "Add an entry" control, "Pause for today", and nothing else

#### Scenario: Two cards waiting
- **WHEN** an opening card and a suggestion card are both waiting
- **THEN** the card slot shows the opening card, and shows the suggestion card after the person taps "Open" or "Close"

#### Scenario: Card after a starred entry
- **WHEN** the person saves a starred entry at 20:15 and an opening card became due at 20:15
- **THEN** Today shows no card on that load, and shows the card from 04:00 the next record day

#### Scenario: Reading order from stage 3
- **WHEN** VoiceOver reads Today with stage 3 open
- **THEN** the first element is the "Urge" button, then the navigation bar starting with "Add an entry"

#### Scenario: Previous day
- **WHEN** the previous record day has three entries
- **THEN** Today shows the previous day section under the current day, collapsed to its heading and "3 entries", and expands it on a tap

### Requirement: Where chips

The new-entry screen MUST show a Where control under What. The control MUST show the chips "Home", "Work", "Out" and "Travelling", then a chip "Add a place". "Add a place" MUST open a one-line text field with no placeholder. When the person saves a custom place, the app MUST keep it. The app MUST then show it as a chip after the four fixed chips. The app MUST show at most eight custom chips, most recently used first.

An entry MUST have at most one Where. The person MUST be able to save an entry with no Where. A second tap on the selected chip MUST clear the Where. The app MUST NOT show a message when the person leaves Where empty.

#### Scenario: Save with a fixed chip
- **WHEN** the person types "Toast and tea", taps "Home" and saves
- **THEN** the app saves one entry with What "Toast and tea" and Where "Home"

#### Scenario: Save with no Where
- **WHEN** the person types "Toast and tea" and saves without a tap on a chip
- **THEN** the app saves the entry with no Where and shows no message

#### Scenario: Add a custom place
- **WHEN** the person taps "Add a place", types "Mum's" and saves the entry
- **THEN** the app saves the entry with Where "Mum's" and the next new-entry screen shows a chip "Mum's" after "Travelling"

#### Scenario: Clear a chip
- **WHEN** the person taps "Work" and then taps "Work" again
- **THEN** the entry has no Where

#### Scenario: Ninth custom place
- **WHEN** the person has eight custom places and saves an entry with a new custom place "Gym"
- **THEN** the next new-entry screen shows "Gym" first among the custom chips and shows the least recently used custom place no more

### Requirement: The Context field

The new-entry screen MUST show a Context field under Where. Context MUST accept free text. Context MUST accept an empty text. The app MUST NOT show a placeholder in Context.

When the star is off, the field's label MUST read "Context". When the star is on, the field's label MUST read "What was going on just before?". The app MUST NOT show any other text, icon, colour change or message when the star turns on.

The app MUST trim white space and line breaks from the start and end of Context. The app MUST keep the rest as typed. The app MUST NOT require Context on a starred entry.

#### Scenario: Star on changes one label
- **WHEN** the person turns on "felt like a binge"
- **THEN** the Context label reads "What was going on just before?" and no other text on the screen changes

#### Scenario: Star off
- **WHEN** the star is off
- **THEN** the Context label reads "Context"

#### Scenario: Starred entry with an empty Context
- **WHEN** the person turns on "felt like a binge", leaves Context empty and saves
- **THEN** the app saves the entry with an empty Context and shows no message

#### Scenario: Context with white space
- **WHEN** the person types "  Row with my sister " in Context and saves
- **THEN** the app saves the Context "Row with my sister"

### Requirement: Today shows Where and Context

Today MUST show an entry's Where after the What when the Where is not empty. Today MUST show an entry's Context under the What when the Context is not empty. Where and Context MUST use the same text style as the What. Today MUST NOT limit Context to one line. A row with Where or Context MUST have the same background and spacing as any other row. Today MUST NOT show a label "Where" or "Context" on a row.

#### Scenario: Entry with Where and Context
- **WHEN** an entry at 13:05 has What "Toast and tea", Where "Home" and Context "Row with my sister"
- **THEN** Today shows "13:05", "Toast and tea", "Home" and "Row with my sister" in that row and no field label

#### Scenario: Entry with an empty What and a Where
- **WHEN** an entry at 13:05 has an empty What and Where "Out"
- **THEN** Today shows "13:05" and "Out" and no other text on that row

#### Scenario: Long Context at the largest text size
- **WHEN** the person sets the largest accessibility text size and an entry has a Context of forty words
- **THEN** Today shows the whole Context without truncation

### Requirement: Edit an entry

A tap on a row on Today or on an earlier day MUST open the entry for editing. The edit screen is the new-entry screen filled with the entry's values. The person MUST be able to change the time, the What, the Where, the star and the Context.

The time control MUST offer times from the start of the entry's record day to the current moment. On save the app MUST keep the entry's creation moment as it was. On save the app MUST close the screen as the "Save is quiet" requirement describes. The app MUST NOT show an "edited" label or any text about the edit. "Cancel" MUST discard every change.

#### Scenario: Change the What
- **WHEN** the person taps the 13:05 entry "Toast and tea", changes What to "Toast, tea and a biscuit" and saves
- **THEN** Today shows the 13:05 entry with What "Toast, tea and a biscuit" and no other change

#### Scenario: Change the time into the previous record day
- **WHEN** the current time is 09:00 on Friday 25 September and the person moves a Friday entry to 23:30 on Thursday 24 September
- **THEN** Today shows the entry under Thursday 24 September at 23:30

#### Scenario: Creation moment stays
- **WHEN** the person edits an entry with the creation moment 13:08 and saves at 18:00
- **THEN** the app keeps 13:08 as the creation moment

#### Scenario: Cancel an edit
- **WHEN** the person turns the star on in the edit screen and taps "Cancel"
- **THEN** the entry keeps the star off

### Requirement: Delete an entry

The edit screen MUST show a control "Delete entry". Today MUST also offer the system's standard swipe to delete on a row. Before it deletes, the app MUST ask once: "Delete this entry?" with the choices "Delete" and "Cancel".

On "Delete" the app MUST delete the entry from the store. After the delete the app MUST show the day with no message, sound or haptic. The app MUST NOT keep a deleted entry in the store. The `data-and-privacy` capability owns how a delete reaches the person's iCloud private database.

#### Scenario: Delete from the edit screen
- **WHEN** the person taps "Delete entry" on the 13:05 entry and taps "Delete"
- **THEN** Today shows the day without the 13:05 entry and shows no message

#### Scenario: Cancel a delete
- **WHEN** the person taps "Delete entry" and taps "Cancel"
- **THEN** the entry stays on Today unchanged

#### Scenario: Delete the only entry of the previous record day
- **WHEN** the person deletes the only entry in the previous record day
- **THEN** Today shows no heading for the previous record day

#### Scenario: Deleted entry after restart
- **WHEN** the person deletes an entry, closes the app and opens it again
- **THEN** the entry is not in the store

### Requirement: "Didn't record"

The current day heading's menu and each earlier day's menu MUST offer "Didn't record". The heading MUST also offer it as a custom action. When the toggle is on, the app MUST keep the state "didn't record" for that record day. The day MUST then show the line "Didn't record" under its heading in the same text style as a row.

The person MUST be able to turn the toggle off at any time. The person MUST still be able to create, edit and delete entries on that day. The app MUST NOT show a message, a prompt or a change to reminders because of the state. The app MUST NOT infer anything from the state. The `programme` capability owns what counts as a recorded day for pacing.

#### Scenario: Set the current day
- **WHEN** the person turns on "Didn't record" on the current record day at 21:00
- **THEN** the day shows "Didn't record" under its heading and the app shows no other change

#### Scenario: Set an earlier day
- **WHEN** the person opens Monday 21 September and turns on "Didn't record"
- **THEN** Monday 21 September shows "Didn't record" under its heading

#### Scenario: Turn it off
- **WHEN** the person turns off "Didn't record" on a day that has the state
- **THEN** the line "Didn't record" disappears and nothing else changes

#### Scenario: Entry on a "didn't record" day
- **WHEN** a day has the state "didn't record" and the person saves an entry at 19:00 on it
- **THEN** the day shows "Didn't record" and the 19:00 entry

### Requirement: "Pause for today"

Today MUST show a control "Pause for today" under the current day's rows, reachable in one tap. One tap MUST set the state "paused" for the current record day with no confirmation and no message. When the person pauses the day, the scheduler MUST cancel every reminder for the rest of the record day. The `reminders` capability owns that cancellation. The control MUST then read "Paused for today". A tap on "Paused for today" MUST clear the state.

The app MUST NOT infer anything from a paused day. The app MUST NOT show a message, a prompt or a summary line because a day was paused. The person MUST still be able to create, edit and delete entries on a paused day. The state MUST end at the day start. The plan and its reminders then resume. An earlier day with the state MUST show the line "Paused" under its heading.

#### Scenario: Pause
- **WHEN** the person taps "Pause for today" at 14:00
- **THEN** the control reads "Paused for today", no reminder arrives for the rest of the record day, and the app shows no message

#### Scenario: Entry on a paused day
- **WHEN** the day is paused and the person saves an entry at 19:00
- **THEN** Today shows the 19:00 entry and the day stays paused

#### Scenario: The next day
- **WHEN** the person paused Thursday and opens Today at 09:00 on Friday
- **THEN** Friday's control reads "Pause for today" and Friday's plan and reminders are in effect

#### Scenario: Paused day seen later
- **WHEN** the person opens Thursday 24 September on Saturday and Thursday was paused
- **THEN** Thursday shows "Paused" under its heading and no other text about the pause

#### Scenario: Undo a pause
- **WHEN** the person taps "Paused for today" at 15:00 on the same day
- **THEN** the control reads "Pause for today" and the app tells `reminders` that the day is not paused

### Requirement: "Fasting today"

The current day heading's menu MUST offer "Fasting today" as a toggle. The heading MUST also offer it as a custom action. An earlier day MUST offer the same toggle in its menu. A day with the state MUST show the line "Fasting" under its heading.

The store MUST keep the state in the day state row. The state MUST end at the day start. Ash added this on 25 September 2026 for religious and medical fasts.

On a fasting day the app MUST show no gap band. The `regular-eating-plan`, `weekly-review`, `problem-solving`, `dieting-module` and `reminders` capabilities MUST read the state. They MUST then count no gap, show no gap line and send no midday reminder. A fasting day MUST still count as a planned day and as a recorded day when it meets those rules. The app MUST NOT show a message because a day was fasting. The app MUST NOT draw a conclusion from it.

#### Scenario: Turn it on
- **WHEN** the person turns on "Fasting today" at 06:00
- **THEN** the heading shows "Fasting", Today shows no gap band that day, and no midday reminder arrives

#### Scenario: Entries on a fasting day
- **WHEN** a fasting day has an entry at 20:30 and one at 21:00
- **THEN** the day counts as a recorded day and the review counts no gap for it

#### Scenario: The day ends
- **WHEN** the day start passes
- **THEN** the next day has no fasting state

### Requirement: Earlier record days

Today MUST show a control "Earlier days". The control MUST open a list of record days, most recent first. The list MUST start at the earliest record day with an entry or a state. The list MUST end at the day before the previous record day. Each row in the list MUST show the weekday and date only. A tap on a row MUST open that day.

The day MUST show its entries with the same rules as a day on Today. The day MUST show controls to move to the previous and the next record day. A control "Today" MUST return to Today. The app MUST NOT offer a control to create an entry on a day before the previous record day.

#### Scenario: Open an earlier day
- **WHEN** the person taps "Earlier days" on Thursday 24 September and taps "Monday 21 September"
- **THEN** the app shows Monday 21 September's entries in time order under its heading

#### Scenario: The list shows dates only
- **WHEN** Monday 21 September has fifteen entries and Tuesday 22 September has none
- **THEN** the list shows "Monday 21 September" and "Tuesday 22 September" as rows with no count and no other text

#### Scenario: Move between days
- **WHEN** the person is on Monday 21 September and taps the next-day control
- **THEN** the app shows Tuesday 22 September

#### Scenario: Return to Today
- **WHEN** the person is on Monday 21 September and taps "Today"
- **THEN** the app shows Today

### Requirement: Collapse a day to a count

Each day heading with at least one entry MUST show a control that collapses the day. A collapsed day MUST show its heading and one line with the count of entries, and nothing else. The count line MUST read "1 entry" for one entry and "N entries" for more. The count line MUST use the same text style as a row. The app MUST NOT show a count of starred entries.

The app MUST show a day expanded until the person collapses it. The app MUST keep the collapsed state per record day until the person expands it. When the person saves an entry into a collapsed day, the app MUST expand that day. This count is the only count of entries the app shows, and only on request.

#### Scenario: Collapse the current day
- **WHEN** the current record day has eight entries and the person collapses it
- **THEN** Today shows the day's heading and "8 entries" and no entry rows

#### Scenario: One entry
- **WHEN** a day has one entry and the person collapses it
- **THEN** the day shows "1 entry"

#### Scenario: Expand
- **WHEN** the person expands a collapsed day
- **THEN** the day shows every entry row and no count

#### Scenario: Save into a collapsed day
- **WHEN** the current record day is collapsed and the person saves an entry
- **THEN** Today expands the day and shows the saved entry on screen

#### Scenario: Empty day
- **WHEN** a day has no entries
- **THEN** the day heading shows no collapse control

### Requirement: The gap band

From the record day stage 2 opened, a day MUST show a band at each gap over MAX_AWAKE_GAP_HOURS. The app MUST NOT show a band on a day before that record day. The settings screen MUST hold a "Gap bands" switch, on by default. MAX_AWAKE_GAP_HOURS is 4. The `programme` capability owns the stage state and the constant.

The app MUST compute the gap between two consecutive entries in the same record day, by entry time. The app MUST NOT show a band for the gap after the last entry of a day. The band MUST show no text, no duration, no number and no icon. The band MUST be visible with the system's greyscale filter on.

The band MUST contrast with the row background at 3:1 or more. That contrast MUST hold in light mode, in dark mode and with Increase Contrast on. The band's VoiceOver label MUST be "Gap of more than %lld hours", filled from MAX_AWAKE_GAP_HOURS. The band MUST be a separate element between the two rows. The rows keep their height and text style.

The app MUST NOT show a band on a day with the state "didn't record", "paused" or "fasting". The app MUST NOT show a band on a collapsed day. The `regular-eating-plan` capability owns the plan beside the record on Today.

#### Scenario: Gap over four hours
- **WHEN** stage 2 is open and a day has entries at 08:00 and 13:30
- **THEN** the day shows a band between the two rows

#### Scenario: Gap of exactly four hours
- **WHEN** stage 2 is open and a day has entries at 08:00 and 12:00
- **THEN** the day shows no band between them

#### Scenario: Before stage 2
- **WHEN** stage 2 is not open and a day has entries at 08:00 and 13:30
- **THEN** the day shows no band

#### Scenario: Gap since the last entry
- **WHEN** the last entry of the current record day is at 13:00 and the current time is 19:00
- **THEN** Today shows no band after the 13:00 entry

#### Scenario: "Didn't record" day
- **WHEN** a day has the state "didn't record" and entries at 08:00 and 20:00
- **THEN** the day shows no band

### Requirement: A save that fails

When a save throws, the new-entry screen MUST stay open. It MUST show "Could not save. Try again." under Save and no other text. It MUST keep the typed text and the chosen values.

#### Scenario: Full storage
- **WHEN** the device has no free storage and the person taps Save
- **THEN** the screen stays open with the text intact and shows "Could not save. Try again."

### Requirement: The app keeps day states on the device

The store MUST keep the states "didn't record", "paused" and "collapsed" per record day. A state MUST survive the app closing and opening again. The app MUST keep the states with the same protection, backup exclusion and log rules as an entry. The app MUST NOT need a network to set or read a state. The `data-and-privacy` capability owns how a state syncs to the person's iCloud private database.

#### Scenario: Restart
- **WHEN** the person turns on "Didn't record", closes the app and opens it again
- **THEN** the day shows "Didn't record"

#### Scenario: No network
- **WHEN** the device has no network connection
- **THEN** the person can pause the day and collapse a day

#### Scenario: State in a log
- **WHEN** the store fails to save a state for Thursday 24 September
- **THEN** the error the store throws contains no date and no state

### Requirement: Accessibility of the additions

Every chip, field and control in this delta MUST have a VoiceOver label. A row's label MUST hold, in order: the time, the What, the Where, the Context, "felt like a binge". The label MUST hold only the parts that are present. A comma and a space MUST separate the parts. The band MUST be one accessibility element with the label "Gap".

The collapse control's label MUST read "Collapse day" when the day is expanded and "Expand day" when it is collapsed. A row MUST offer "Delete" as a VoiceOver action. Every text in this delta MUST use system text styles. Every text in this delta MUST scale with Dynamic Type. A state in this delta MUST NOT depend on colour alone.

#### Scenario: Label of a full row
- **WHEN** VoiceOver reads a starred entry at 13:05 with What "Toast and tea", Where "Home" and Context "Row with my sister"
- **THEN** it reads "13:05, Toast and tea, Home, Row with my sister, felt like a binge"

#### Scenario: Label of a row with Where only
- **WHEN** VoiceOver reads an unstarred entry at 13:05 with an empty What and Where "Out"
- **THEN** it reads "13:05, Out"

#### Scenario: The band
- **WHEN** VoiceOver moves over a band
- **THEN** it reads "Gap"

#### Scenario: Delete with VoiceOver
- **WHEN** a person who uses VoiceOver chooses the "Delete" action on a row and taps "Delete"
- **THEN** the app deletes the entry
