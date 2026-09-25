# record

## ADDED Requirements

### Requirement: The Today stack

Today MUST show these fixed elements, in this order from the top:

- the pinned note, when one exists
- the "Weekly review" or "Check-in" line, when one is due
- one card slot
- the "Getting started" line, from the end of onboarding until stage 2 opens (`programme` owns the rule)
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

The `programme` capability owns the stage 1, plan and Focus cards. When more than one card is waiting, the app MUST show the oldest first. The app MUST show the next card after the person dismisses the first.

After a starred entry or an "I binged" outcome, the app MUST NOT show a card in the same record day. The one exception is the stage 7 lapse card, the maintenance plan card that `staying-on-track` shows. That card can show in the same record day as the starred entry or the outcome. After that entry or outcome, Today MUST NOT show the pinned note until the next record day. The `weekly-review` capability owns that rule.

Each day section MUST show its heading and its rows. It MUST show a state line when the day is paused or has the state "didn't record". From stage 2 it MUST show the plan beside the record and the gap bands. The current day section MUST come first. The previous day section MUST follow it, collapsed by default, and only when it has an entry.

The navigation bar MUST hold the lock control at its leading end and Get support at its trailing end. The navigation bar MUST hold no other control. The lock control MUST show the cover and lock at once. With the app lock off, it MUST still show the cover until a tap.

A bottom toolbar MUST hold these text controls, in this order:

- "Programme"
- "Reviews", from the moment the first weekly review becomes due
- "Settings"

Before the first weekly review becomes due, the bottom toolbar MUST NOT show "Reviews". The settings screen MUST be one tap from Today, through "Settings". From stage 3, the "Urge" button MUST sit above the bottom toolbar. The button MUST stay on screen while the rows scroll. In VoiceOver's reading order the "Urge" button MUST come first from stage 3.

The current day heading and a full-width control "Add an entry" under it MUST form a pinned section header. That header MUST stay on screen while the current day's rows scroll. "Pause for today" MUST sit under the rows as a visible control. "Close the day" MUST sit beside it only after the last planned meal's time, or after 17:00 in stage 1.

"Fasting today", "Didn't record" and "Earlier days" MUST live in the day heading's menu, one tap inside it. The heading MUST also offer them as custom actions. "Earlier days" MUST appear there only when a record day before the previous record day has an entry or a state. From stage 2, "Today's plan" MUST also live in the day heading's menu and as a custom action. It MUST open the plan builder at the current day's plan, as `regular-eating-plan` states in "Edit tonight for tomorrow, or this morning for today".

The `reminders` capability owns the rule and the two strings of the notification permission line. The line MUST sit under the pinned section header, above the rows, as a control. When permission is not determined, the line MUST read "Allow notifications to get reminders.". A tap on it MUST make the system permission request.

When permission is denied and a reminder switch is on, the line MUST read "Notifications are off in iOS Settings.". A tap on it MUST open the iOS Settings app. After that tap, the app MUST hide the line while permission stays denied. Only the Reminders group then shows the state.

Ash chose this layout on 25 September 2026 so the record is the first thing a new person sees. On the same day Ash moved "Programme", "Reviews" and "Settings" to the bottom toolbar, so one "Add an entry" stays on screen.

A two-finger double tap on Today MUST open the new-entry screen. After the new-entry screen closes, VoiceOver focus MUST return to "Add an entry". Each day heading MUST carry the header trait. "Collapse day", "Expand day" and "Didn't record" MUST be VoiceOver custom actions on the heading.

The order above is the only order. Another capability MUST NOT add an element to Today except through the card slot or a day section row.

#### Scenario: Empty day, no cards
- **WHEN** the current record day has no entries, no review or check-in has ever become due, no card is waiting and notification permission is granted
- **THEN** Today shows the lock control and Get support in the navigation bar, the "Getting started" line before stage 2, the pinned current day heading with its menu and "Add an entry", "Pause for today", and "Programme" and "Settings" in the bottom toolbar, and nothing else

#### Scenario: Card after a starred entry
- **WHEN** the person saves a starred entry at 20:15 and an opening card became due at 20:15
- **THEN** Today shows no card on that load, and shows the card from 04:00 the next record day

#### Scenario: Lapse card in the same record day
- **WHEN** stage 7 is open, the person saves a starred entry at 14:10, and the next planned meal is at 16:00
- **THEN** from 16:00 the card slot shows the maintenance plan card in that record day, and every other card waits for the next record day

#### Scenario: Previous day
- **WHEN** the previous record day has three entries and the person has not collapsed or expanded it
- **THEN** Today shows the previous day section under the current day, collapsed to its heading and "3 entries", and expands it on a tap

#### Scenario: Add an entry on a long day
- **WHEN** the current record day has fifteen entries and the person scrolls to the last row
- **THEN** the current day heading and "Add an entry" stay on screen, and one tap on "Add an entry" opens the new-entry screen

#### Scenario: Reviews in the bottom toolbar
- **WHEN** the first weekly review becomes due
- **THEN** the bottom toolbar shows "Programme", "Reviews" and "Settings", in that order

### Requirement: Where chips

The new-entry screen MUST show a Where control under What. The control MUST show the chips "Home", "Work", "Out" and "Travelling", then a chip "Add a place". "Add a place" MUST open a one-line text field with no placeholder. The app MUST keep autocorrection and sentence capitalisation in that field. The app MUST turn off the keyboard's inline predictions in that field.

When the person saves a custom place, the app MUST keep it. The app MUST then show it as a chip after the four fixed chips. The app MUST show at most eight custom chips, most recently used first.

An entry MUST have at most one Where. The person MUST be able to save an entry with no Where. A second tap on the selected chip MUST clear the Where. The app MUST NOT show a message when the person leaves Where empty.

The new-entry screen MUST NOT show a previous entry's What, Where or Context as a suggestion or a chip. The person's own custom places stay.

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

#### Scenario: No suggestion from a previous entry
- **WHEN** the person saved an entry with What "Toast and tea", Where "Mum's" and Context "Row with my sister", and opens the new-entry screen
- **THEN** the screen shows the chip "Mum's", an empty What, an empty Context, and no suggestion from an earlier entry

#### Scenario: Keyboard in "Add a place"
- **WHEN** the person taps "Add a place" and types in the field
- **THEN** the keyboard offers autocorrection and a capital letter at the start of a sentence, and shows no inline prediction

### Requirement: The Context field

The new-entry screen MUST show a Context field under the "felt like a binge" star. Context MUST accept free text. Context MUST accept an empty text. The app MUST NOT show a placeholder in Context.

When the star is off, the field's label MUST read "Context". When the star is on, the field's label MUST read "What was going on just before?". The app MUST NOT show any other text, icon, colour change or message when the star turns on.

The star control is the system toggle. Its on state MUST use the system grey as its tint. The knob then shows in light and dark mode. The screen MUST show no other colour change when the star turns on.

The app MUST trim white space and line breaks from the start and end of Context. The app MUST keep the rest as typed. The app MUST NOT require Context on a starred entry. The app MUST keep autocorrection and sentence capitalisation in Context. The app MUST turn off the keyboard's inline predictions in Context.

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

#### Scenario: Keyboard in Context
- **WHEN** the person types in Context
- **THEN** the keyboard offers autocorrection and a capital letter at the start of a sentence, and shows no inline prediction

### Requirement: The new-entry screen's controls

The new-entry screen MUST show its controls in this order from the top: What, Where, "felt like a binge", Context, Time. The Context label that the star changes then sits under the star. The edit screen MUST show the same order, with "Delete entry" last.

What MUST stay a multi-line field, so Return adds a line break. The app MUST keep autocorrection and sentence capitalisation in What. The app MUST turn off the keyboard's inline predictions in What.

While the keyboard shows, the keyboard's toolbar MUST show a control "Save" at its trailing end. That control MUST have a touch target of at least 44 by 44 points. A tap on it MUST save the entry as a tap on Save in the navigation bar does. Save MUST also stay in the navigation bar.

On a new entry, the time control MUST show two segments, then the system hour-and-minute wheel. The first segment MUST name the previous record day. The second segment MUST name the current record day. Each segment MUST show the weekday and date only, for example "Thursday 24 September". The app MUST select the second segment when the new-entry screen opens.

The wheel MUST offer only times inside the selected record day, up to the current moment. The app MUST put a time before the day start on the calendar date after the segment's date. The time control MUST keep the VoiceOver label "Time" and the value that "Accessibility of the record" states. Ash chose this form on 25 September 2026, so the time control names the days as Today's headings do.

#### Scenario: Order of the controls
- **WHEN** the person opens the new-entry screen
- **THEN** the screen shows What, the Where chips, "felt like a binge", Context and the time control, in that order from the top

#### Scenario: Return in What
- **WHEN** the person types "Toast", taps Return and types "tea" in What
- **THEN** What holds "Toast" and "tea" on two lines, and the screen stays open

#### Scenario: Keyboard in What
- **WHEN** the person types in What
- **THEN** the keyboard offers autocorrection and a capital letter at the start of a sentence, and shows no inline prediction

#### Scenario: Save from the keyboard's toolbar
- **WHEN** the person types "Toast and tea" in What and taps "Save" in the keyboard's toolbar
- **THEN** the app saves the entry and closes the screen, as a tap on Save in the navigation bar does

#### Scenario: The time control in the morning
- **WHEN** the current time is 07:30 on Friday 25 September and the person opens the new-entry screen
- **THEN** the time control shows "Thursday 24 September" and "Friday 25 September", with "Friday 25 September" selected, and the wheel at 07:30

#### Scenario: Last night's time after midnight
- **WHEN** the current time is 02:00 on Friday 25 September, and the person sets the wheel to 23:30 and saves
- **THEN** the segments read "Wednesday 23 September" and "Thursday 24 September", and the app saves the entry at 23:30 on Thursday 24 September

#### Scenario: A time before the day start
- **WHEN** the current time is 02:00 on Friday 25 September, and the person sets the wheel to 01:30 and saves
- **THEN** the app saves the entry at 01:30 on Friday 25 September, and Today shows it under Thursday 24 September

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

The time control MUST offer only times inside the entry's own record day. The time control MUST show one segment, which names that record day. The app MUST compute that record day's bounds from the entry's UTC offset and the day start row. That row is the one in force for that record day key, as `data-and-privacy` states. The time control MUST NOT offer a time after the current moment.

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

### Requirement: Delete an entry

The edit screen MUST show a control "Delete entry". Today MUST also offer the system's standard swipe to delete on a row. Before it deletes, the app MUST ask once: "Delete this entry?" with the choices "Delete" and "Cancel".

On "Delete" the store MUST write a version of the entry with the deleted flag on, as `data-and-privacy` states. Every reader MUST hide an entry whose winning version is deleted. After the delete the app MUST show the day with no message, sound or haptic. The store MUST keep the deleted version. The `data-and-privacy` capability owns how a delete reaches the person's iCloud private database.

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
- **THEN** no screen, count or export shows the entry, and the store holds its deleted version

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

The current day heading's menu MUST offer a control "Earlier days". The control MUST appear only when a record day before the previous record day has an entry or a state.

The control MUST open a list of record days, most recent first. The list MUST start at the earliest record day with an entry or a state. The list MUST end at the day before the previous record day. Each row in the list MUST show the weekday and date only. A tap on a row MUST open that day.

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

#### Scenario: No earlier day yet
- **WHEN** the person saved the first entry on Wednesday 23 September and opens Today on Thursday 24 September
- **THEN** the current day heading's menu shows no "Earlier days"

#### Scenario: An earlier day with a state only
- **WHEN** the current record day is Wednesday 23 September, and Monday 21 September has the state "didn't record" and no entries
- **THEN** the current day heading's menu offers "Earlier days", and the list shows "Monday 21 September"

### Requirement: Collapse a day to a count

Each day heading with at least one entry MUST show a control that collapses the day. A collapsed day MUST show its heading and one line with the count of entries, and nothing else. The count line MUST read "1 entry" for one entry and "N entries" for more. The count line MUST use the same text style as a row. The app MUST NOT show a count of starred entries on a collapsed day. On Today, the app MUST NOT show a count of entries except the count line of a collapsed day.

The app MUST show the current record day expanded until the person collapses it. The app MUST show the previous record day collapsed until the person expands it. The app MUST show a day before the previous record day expanded until the person collapses it. These are the default states. The app MUST keep the person's last collapse or expand choice per record day. For a day with no kept choice, the app MUST show the default state. When the person saves an entry into a collapsed day, the app MUST expand that day. The app MUST then keep the expanded state as the last choice for that record day.

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

#### Scenario: Default states
- **WHEN** the current record day has two entries, the previous record day has three entries, and the person has not collapsed or expanded either day
- **THEN** Today shows the current day's heading and two rows, then the previous day's heading and "3 entries"

#### Scenario: Save into the previous day
- **WHEN** the previous record day is collapsed and the person saves an entry at 23:30 on it
- **THEN** Today expands the previous day and shows the 23:30 entry, and after the person closes the app and opens it again on the same record day, Today still shows the previous day expanded

#### Scenario: Kept choice after the app opens again
- **WHEN** the person expands the previous record day, closes the app and opens it again on the same record day
- **THEN** Today shows the previous day expanded

#### Scenario: Default state of an earlier day
- **WHEN** Thursday 24 September has two entries, the person has not collapsed or expanded it, and on Saturday 26 September the person opens it from "Earlier days"
- **THEN** the app shows Thursday 24 September's two rows and no count line

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

When a save throws, the new-entry screen MUST stay open. It MUST show "Could not save. Try again." under the navigation bar and no other text. Both Save controls follow this rule. It MUST keep the typed text and the chosen values.

#### Scenario: Full storage
- **WHEN** the device has no free storage and the person taps Save
- **THEN** the screen stays open with the text intact and shows "Could not save. Try again."

### Requirement: The app keeps day states on the device

The store MUST keep the states "didn't record", "paused" and "fasting" per record day. The app MUST keep the collapse or expand choice per record day in `Local.store`, as `data-and-privacy` states. A state MUST survive the app closing and opening again. The app MUST keep the states with the same protection, backup exclusion and system-log rules as an entry. The app MUST NOT need a network to set or read a state or a collapse or expand choice. The `data-and-privacy` capability owns how a state syncs to the person's iCloud private database.

#### Scenario: Restart
- **WHEN** the person turns on "Didn't record", closes the app and opens it again
- **THEN** the day shows "Didn't record"

#### Scenario: No network
- **WHEN** the device has no network connection
- **THEN** the person can pause the day and collapse a day

#### Scenario: A failed state save
- **WHEN** the store fails to save a state for Thursday 24 September
- **THEN** the error the store throws contains no date and no state

### Requirement: Accessibility of the additions

Every chip, field and control in this delta MUST have a VoiceOver label. A row's label MUST hold, in order: the time, the What, the Where, the Context, "felt like a binge". The label MUST hold only the parts that are present. A comma and a space MUST separate the parts. The band MUST be one accessibility element with the label "Gap of more than %lld hours". The app MUST fill the label from MAX_AWAKE_GAP_HOURS.

When the new-entry screen or the edit screen opens, VoiceOver focus MUST move to What. Cancel and Save MUST stay in the navigation bar, which VoiceOver reads before the content. The new-entry screen's content reading order MUST be What, Where, "felt like a binge", Context, Time.

The edit screen's content reading order MUST be the same. The app MUST then put "Delete entry" last, after Time. Ash ruled on 25 September 2026 that Cancel and Save stay in the navigation bar, as on every iOS sheet.

The collapse control's label MUST read "Collapse day" when the day is expanded and "Expand day" when it is collapsed. A row MUST offer "Delete" as a VoiceOver action. Every text in this delta MUST use system text styles. Every text in this delta MUST scale with Dynamic Type. A state in this delta MUST NOT depend on colour alone.

#### Scenario: Label of a full row
- **WHEN** VoiceOver reads a starred entry at 13:05 with What "Toast and tea", Where "Home" and Context "Row with my sister"
- **THEN** it reads "13:05, Toast and tea, Home, Row with my sister, felt like a binge"

#### Scenario: Label of a row with Where only
- **WHEN** VoiceOver reads an unstarred entry at 13:05 with an empty What and Where "Out"
- **THEN** it reads "13:05, Out"

#### Scenario: Reading order with Where and Context
- **WHEN** the person opens the new-entry screen from "Add an entry" with the star off and VoiceOver on
- **THEN** VoiceOver focus is on What, the next elements are Where, "felt like a binge", Context and Time, and Cancel and Save come before What

#### Scenario: Reading order on the edit screen
- **WHEN** the person taps the 13:05 entry "Toast and tea" on Today with VoiceOver on
- **THEN** VoiceOver focus is on What, the next elements are Where, "felt like a binge", Context, Time and "Delete entry", and Cancel and Save come before What

#### Scenario: The band
- **WHEN** VoiceOver moves over a band
- **THEN** it reads "Gap of more than 4 hours"

#### Scenario: Delete with VoiceOver
- **WHEN** a person who uses VoiceOver chooses the "Delete" action on a row and taps "Delete"
- **THEN** the app deletes the entry

## MODIFIED Requirements

### Requirement: Today's appearance

Today's heading MUST show the record day's weekday and date. Between 00:00 and 03:59 the current day's heading MUST add ", night" after the date.

Today MUST show a starred entry with an asterisk glyph in the same colour and weight as the entry's time. The time and the asterisk MUST use the primary text colour. The asterisk MUST be at least the x-height of the time. The glyph MUST use no accent colour and no fill. A starred row MUST have the same background, height, spacing and text style as an unstarred row. Every row MUST have the same height and spacing, whatever the time since the previous entry.

Today MUST show absolute times only, with no relative times, no divider and no grouping within a record day, except the gap band. Today MUST NOT show a count of entries, a total, a count of consecutive days or a rating, except the count line of a collapsed day. Today MUST NOT show any text about the absence of entries. On an empty current record day, Today MUST show only these elements:

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

### Requirement: Today shows the record day's entries in time order

Today MUST show every entry in the current record day. When the previous record day has at least one entry, Today MUST show those entries in a section below the current day's section, collapsed by default, as "Collapse a day to a count" states. That section sits under the previous day's date heading. Today MUST NOT show a section for a previous record day with no entries. Today MUST order the entries in each day by entry time, earliest first.

When two entries have the same time, Today MUST order them by creation moment, earliest first. Today MUST show each entry's time. Today MUST show each entry's What when it is not empty. Today MUST show each entry's Where and Context as "Today shows Where and Context" states. Today MUST show a control that opens the new-entry screen in one tap.

#### Scenario: Two entries out of creation order
- **WHEN** the person saves an entry with the time 13:05 and then saves an entry with the time 08:10
- **THEN** Today shows the 08:10 entry above the 13:05 entry

#### Scenario: Same time
- **WHEN** the person saves two entries with the time 13:05
- **THEN** Today shows the one the person saved first above the other

#### Scenario: Previous record day with entries
- **WHEN** the previous record day has one entry and the current record day has two, and the person has not collapsed or expanded either day
- **THEN** Today shows the current day's heading and its two rows first, then the previous day's heading collapsed to "1 entry"

#### Scenario: Previous record day without entries
- **WHEN** the previous record day has no entries
- **THEN** Today shows no heading for it

#### Scenario: Entry with an empty What
- **WHEN** an entry has an empty What, no Where and no Context
- **THEN** Today shows the entry's time, and the star when it is on, and no other text on that row

#### Scenario: One tap to a new entry
- **WHEN** the person is on Today
- **THEN** one tap opens the new-entry screen with the keyboard in What

### Requirement: Accessibility of the record

Each row on Today MUST be one accessibility element. The row's label MUST hold, in order: the time, the What, the Where, the Context, "felt like a binge", as "Accessibility of the additions" states. A comma and a space MUST separate the parts. Every control on Today and the new-entry screen MUST have a VoiceOver label.

When the new-entry screen opens, VoiceOver focus MUST move to What. Cancel and Save MUST stay in the navigation bar, which VoiceOver reads before the content. The content's reading order MUST be What, Where, "felt like a binge", Context, Time. The time control's label MUST be "Time". Its VoiceOver value MUST read the date and time, for example "Thursday 24 September, 21:35". What MUST accept dictation from the system keyboard with no extra tap. The star control's visible label and VoiceOver label MUST both be "felt like a binge".

The star MUST NOT depend on colour alone. Text on Today and the new-entry screen MUST use system text styles. Text on Today and the new-entry screen MUST scale with Dynamic Type. The app MUST NOT limit What to one line on Today.

#### Scenario: Label of a starred entry
- **WHEN** VoiceOver reads a starred entry at 13:05 with What "Toast and tea"
- **THEN** it reads "13:05, Toast and tea, felt like a binge"

#### Scenario: Label of an unstarred entry with an empty What
- **WHEN** VoiceOver reads an unstarred entry at 13:05 with an empty What
- **THEN** it reads "13:05"

#### Scenario: Reading order of the new-entry screen
- **WHEN** the person opens the new-entry screen with VoiceOver on
- **THEN** VoiceOver focus is on What, and the next elements are Where, "felt like a binge", Context and Time, in that order

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** Today and the new-entry screen show all text without truncation

### Requirement: Create an entry

The app MUST let the person create an entry with a time, a What text and a "felt like a binge" star. The time MUST default to the moment the new-entry screen opens. The app MUST accept any entry time from the start of the previous record day to the save moment. The time control MUST let the person choose the date and the time within that range. This range applies to the new-entry screen. The "Edit an entry" requirement states the edit screen's own time range, scoped to the entry's own record day.

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
- **WHEN** the person opens the time control on the new-entry screen
- **THEN** the control offers dates and times from the start of the previous record day to the current moment, and nothing outside that range

#### Scenario: White space around What
- **WHEN** the person types "  Toast and tea " and saves
- **THEN** the app saves the What "Toast and tea"
