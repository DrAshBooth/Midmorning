# problem-solving

## Purpose

Problem solving is the stage 4 tool. The app finds patterns in the person's starred entries and states each one as a plain sentence with the numbers filled in. The person works a pattern through with a six-step worksheet, keeps the worksheet in the "Worksheets" list, and reviews it a week later.

## ADDED Requirements

### Requirement: Problem solving opens at stage 4

The `programme` capability opens stage 4 and owns its opening rule. Before stage 4 opens, the app MUST NOT compute a pattern sentence. Before stage 4 opens, the app MUST NOT show a pattern sentence, the suggestion card or the worksheet. The app MUST let the person read the stage 4 cards while stage 4 is closed. The `content` capability owns the cards.

After stage 4 opens, the Problem solving screen MUST show the pattern sentences, a "New worksheet" control and the "Worksheets" list. The Problem solving screen MUST show Get support. The `safeguarding` capability owns that button. Every part of problem solving MUST work with no network.

#### Scenario: Before stage 4 opens
- **WHEN** the person opens the Problem solving screen while stage 4 is closed
- **THEN** the screen shows the stage 4 cards and no pattern sentence, no suggestion card and no worksheet control

#### Scenario: After stage 4 opens
- **WHEN** stage 4 opens after the urge outcome "It passed" and the person opens the Problem solving screen
- **THEN** the screen shows "New worksheet", the "Worksheets" list and Get support

#### Scenario: No network
- **WHEN** the device has no network connection
- **THEN** the app computes the pattern sentences and saves a worksheet

### Requirement: The pattern window and the minimum data

The pattern window is the PATTERN_WINDOW_DAYS = 28 record days that end with the current record day. The starred total is the number of starred entries in the pattern window. A pattern group is a set of starred entries in the window that share one dimension value.

The app MUST NOT show a pattern sentence when the starred total is below PATTERN_MIN_STARRED = 5. The app MUST show a sentence for a group only when the group holds at least PATTERN_MIN_GROUP = 3 entries. The group MUST also hold more than half of the starred total. The `programme` capability names PATTERN_WINDOW_DAYS, PATTERN_MIN_STARRED and PATTERN_MIN_GROUP in ProgrammeConstants. The app MUST NOT show any text about the absence of a pattern.

#### Scenario: Four starred entries
- **WHEN** the pattern window holds four starred entries, all after 20:00
- **THEN** the Problem solving screen shows no pattern sentence and no text about the absence of one

#### Scenario: Seven starred entries, five after 20:00
- **WHEN** the pattern window holds seven starred entries and five of them have a time between 20:00 and 03:59
- **THEN** the screen shows "5 of your 7 starred entries were after 20:00."

#### Scenario: Seven starred entries, three after 20:00
- **WHEN** the pattern window holds seven starred entries and three of them have a time between 20:00 and 03:59
- **THEN** the screen shows no sentence for the after 20:00 group

#### Scenario: Starred entries outside the window
- **WHEN** the record holds six starred entries from 40 days ago and two starred entries in the pattern window
- **THEN** the screen shows no pattern sentence

### Requirement: The pattern dimensions

The app MUST place a starred entry in one time band by its entry time. The before 12:00 band runs from the day start to 11:59. The between 12:00 and 17:00 band runs from 12:00 to 16:59. The between 17:00 and 20:00 band runs from 17:00 to 19:59. The after 20:00 band runs from 20:00 to the minute before the day start.

The record day of an entry is the record day key the store wrote with the entry at save. The `record` capability owns that key. The app MUST read the saved key. The app MUST NOT compute an entry's record day again from its time. The day of week of a starred entry is the weekday of its record day. The weekend group holds the starred entries whose record day is a Saturday or a Sunday.

A Where group holds the starred entries with one chip, fixed or custom. The fixed chips are "Home", "Work", "Out" and "Travelling". The app MUST build a group from a custom chip by the same minimum as any group.

The gap before a starred entry is the time from the previous entry in the same record day. When no earlier entry exists in that record day, the gap before is unknown. The app MUST NOT count an entry with an unknown gap before in the long-gap group. The long-gap group holds the starred entries with a gap before over MAX_AWAKE_GAP_HOURS = 4 hours.

A fasting day counts no gap. The app MUST NOT count an entry on a fasting day in the long-gap group. The `record` capability owns the fasting state. Every other group still counts the entry.

There is one missed-slot group per slot. A missed-slot group holds the starred entries on a record day where that slot's planned meal has the answer "Skipped". An entry MUST count in the missed-slot group of every skipped slot on its record day. The `regular-eating-plan` capability owns that answer. A combined group holds the starred entries in one time band and one missed-slot group.

#### Scenario: A starred entry after midnight
- **WHEN** a starred entry has the time 00:30 on Friday 25 September and the saved record day key Thursday 24 September
- **THEN** the app places it in the after 20:00 band and in the Thursday group, and does not compute the record day again

#### Scenario: The first entry of a record day
- **WHEN** a starred entry at 07:30 is the first entry of its record day
- **THEN** the app counts it in the starred total and not in the long-gap group

#### Scenario: A long gap before
- **WHEN** a record day has an entry at 12:40 and a starred entry at 19:00
- **THEN** the app counts the starred entry in the long-gap group

#### Scenario: A long gap on a fasting day
- **WHEN** a record day with the state fasting has an entry at 12:40 and a starred entry at 19:00
- **THEN** the app counts the starred entry in the starred total and its time band, and not in the long-gap group

#### Scenario: A custom chip
- **WHEN** four of the seven starred entries in the pattern window have the custom chip "Mum's house"
- **THEN** the app builds a Where group of four entries for "Mum's house"

#### Scenario: A missed lunch
- **WHEN** a starred entry at 21:15 is on a record day where lunch has the answer "Skipped"
- **THEN** the app counts it in the missed-lunch group and in the combined after 20:00 and missed-lunch group

#### Scenario: Two skipped slots on one day
- **WHEN** a starred entry at 21:15 is on a record day where lunch and mid-afternoon both have the answer "Skipped"
- **THEN** the app counts it in the missed-lunch group and in the missed-mid-afternoon group

### Requirement: Pattern sentence templates

Every pattern sentence MUST come from a bundled template that the clinical reviewer signed off. The app MUST fill only a template's placeholders. These are the group size, the starred total, the slot label in a missed-slot template and, in the custom chip template, the chip's text. The app MUST fill {slot} with the slot's label as the person typed it.

The app MUST read that label from the Settings key `slot.label.<index>`. The app MUST NOT change the label's case or add a word to it. The app MUST NOT generate any other word at runtime. The `product-rules` capability states the "No AI at runtime" rule.

The bundle MUST hold one template per time band, one per weekday and one for the weekend. The bundle MUST hold one template per fixed chip and one for a custom chip. The bundle MUST hold one for the long-gap group. The bundle MUST hold one missed-slot template with a {slot} placeholder. The bundle MUST hold one combined template per time band, each with a {slot} placeholder. Every clock time in a template MUST use the 24-hour clock.

The templates are:
- "{n} of your {m} starred entries were before 12:00."
- "{n} of your {m} starred entries were between 12:00 and 17:00."
- "{n} of your {m} starred entries were between 17:00 and 20:00."
- "{n} of your {m} starred entries were after 20:00."
- "{n} of your {m} starred entries were on a Friday." and one like it per weekday
- "{n} of your {m} starred entries were at the weekend."
- "{n} of your {m} starred entries were at home." and one like it for "at work", "when you were out" and "when you were travelling"
- "{n} of your {m} starred entries were at {place}." for a custom chip, where {place} is the person's chip text and the app adds no other word
- "{n} of your {m} starred entries came more than {hours} hours after the entry before them."
- "{n} of your {m} starred entries were on days when {slot} didn't happen." where {slot} is the slot's label as typed
- "{n} of your {m} starred entries were after 20:00 on days when {slot} didn't happen." and one like it per time band

A template MUST NOT contain "you skipped". The `content` capability keeps the version of the template bundle and owns the permitted placeholders.

#### Scenario: A time band sentence
- **WHEN** the group for the after 20:00 band holds 5 entries and the starred total is 7
- **THEN** the sentence reads "5 of your 7 starred entries were after 20:00."

#### Scenario: A weekday sentence
- **WHEN** the Friday group holds 4 entries and the starred total is 6
- **THEN** the sentence reads "4 of your 6 starred entries were on a Friday."

#### Scenario: A custom chip sentence
- **WHEN** the Where group for the custom chip "Mum's house" holds 4 entries and the starred total is 7
- **THEN** the sentence reads "4 of your 7 starred entries were at Mum's house."

#### Scenario: A long-gap sentence
- **WHEN** the long-gap group holds 6 entries and the starred total is 8
- **THEN** the sentence reads "6 of your 8 starred entries came more than 4 hours after the entry before them."

#### Scenario: A missed-lunch sentence
- **WHEN** the slot label is "Lunch", the missed-lunch group holds 4 entries and the starred total is 7
- **THEN** the sentence reads "4 of your 7 starred entries were on days when Lunch didn't happen."

#### Scenario: A renamed slot
- **WHEN** the person renamed the lunch slot "midday bite", its missed-slot group holds 4 entries and the starred total is 7
- **THEN** the sentence reads "4 of your 7 starred entries were on days when midday bite didn't happen."

#### Scenario: A combined sentence
- **WHEN** the slot label is "Lunch", the combined after 20:00 and missed-lunch group holds 5 entries and the starred total is 7
- **THEN** the sentence reads "5 of your 7 starred entries were after 20:00 on days when Lunch didn't happen."

### Requirement: How pattern sentences appear

The Problem solving screen MUST show each pattern sentence as body text in one paragraph. The app MUST NOT show a chart, a graph, a table or a bar for a pattern. The app MUST NOT show a percentage or a colour for a pattern. The screen MUST show at most three pattern sentences.

The app MUST order the sentences by group size, largest first. Groups of the same size MUST follow this order: time band, day of week, Where, long gap, missed slot, combined. Inside one category, groups of the same size MUST follow the earlier weekday, then the earlier time band.

When a combined group equals its time band group, the app MUST show only the combined sentence. Each sentence MUST have a "Work it through" control that opens a new worksheet linked to that sentence. The app MUST compute the sentences again each time the Problem solving screen opens. The app MUST NOT schedule a reminder about a pattern sentence.

#### Scenario: Five groups qualify
- **WHEN** five groups meet the minimum, with sizes 6, 5, 5, 4 and 4
- **THEN** the screen shows three sentences, for the groups of 6, 5 and 5, and no sentence for the groups of 4

#### Scenario: Two weekday groups of the same size
- **WHEN** the Monday group and the Friday group each hold 5 entries and no other group is larger
- **THEN** the Monday sentence comes before the Friday sentence

#### Scenario: Two time band groups of the same size
- **WHEN** the before 12:00 group and the after 20:00 group each hold 4 entries
- **THEN** the before 12:00 sentence comes before the after 20:00 sentence

#### Scenario: A combined group with the same entries
- **WHEN** the after 20:00 group and the combined after 20:00 and missed-lunch group hold the same five entries
- **THEN** the screen shows the combined sentence and not the after 20:00 sentence

#### Scenario: Work it through
- **WHEN** the person taps "Work it through" under "5 of your 7 starred entries were after 20:00."
- **THEN** the app opens a new worksheet with that sentence above step 1

#### Scenario: A new starred entry
- **WHEN** the person saves a starred entry and opens the Problem solving screen
- **THEN** the sentences show numbers that include the new entry

### Requirement: The suggestion card

When a group first meets the minimum, the app MUST show one suggestion card in the Today card slot. The `record` capability defines the Today stack, the card slot and its rules. The suggestion card MUST show the pattern sentence, a "Work it through" control and a "Close" control.

The app MUST show the suggestion card once per template, whatever the numbers. The card slot holds one card at a time. When the person taps either control, the app MUST take the card off Today. The app MUST NOT show the suggestion card for that template again. "Work it through" MUST open a new worksheet linked to the sentence.

The app MUST keep the answer to a suggestion card as a card answer row in Record.store. The row's key is the template id. The row MUST carry the answer and its own changedAt. The `data-and-privacy` capability owns card answer rows and their sync. When any device holds a card answer row for a template, the app MUST NOT show that template's card. While the first import after sync turns on is running, the app MUST show no suggestion card.

After a starred entry, the app MUST NOT show the card on a Today load in the same record day. After an "I binged" outcome, the app MUST NOT show the card on a Today load in the same record day. The card MUST wait for the next record day. The app MUST NOT schedule a reminder for a suggestion card.

#### Scenario: First time a group qualifies
- **WHEN** the after 20:00 group meets the minimum for the first time and the person opens Today the next record day
- **THEN** the card slot shows one card with "5 of your 7 starred entries were after 20:00.", "Work it through" and "Close"

#### Scenario: Close, then the numbers change
- **WHEN** the person taps "Close" on the after 20:00 card, and a week later the after 20:00 group holds 7 of 9 starred entries
- **THEN** Today shows no card for the after 20:00 template

#### Scenario: Work it through from Today
- **WHEN** the person taps "Work it through" on the card
- **THEN** the app opens a new worksheet with the sentence above step 1, and Today shows no card when the person returns

#### Scenario: Two templates qualify on the same day
- **WHEN** the after 20:00 group and the Friday group meet the minimum on the same day
- **THEN** the card slot shows one card for the larger group, and the card for the other group after the person acts on the first

#### Scenario: A starred entry the same record day
- **WHEN** the person saves a starred entry at 21:30 that makes the after 20:00 group qualify, then opens Today at 22:00
- **THEN** the card slot shows no suggestion card, and the card appears on the first Today load of the next record day

#### Scenario: Answered on another device
- **WHEN** the person tapped "Close" on the after 20:00 card on another device and that card answer row has synced to this device
- **THEN** this device shows no card for the after 20:00 template

#### Scenario: During the first import
- **WHEN** the person turns sync on, the first import is running, and the after 20:00 group meets the minimum
- **THEN** Today shows no suggestion card until the import completes

### Requirement: Pattern sentences are opt-out

The app MUST offer a switch named "Pattern sentences" in the settings screen, on by default. The `product-rules` capability states the "The person can put it down" rule. When the switch is off, the app MUST NOT compute or show a pattern sentence or a suggestion card. When the switch is off, the worksheet and the "Worksheets" list MUST stay available. A saved worksheet MUST keep its linked sentence when the switch is off.

When the person turns the switch on again, the app MUST compute the sentences again. The app MUST keep the card answer rows of the suggestion cards while the switch is off.

#### Scenario: Switch off
- **WHEN** the person turns "Pattern sentences" off and opens the Problem solving screen
- **THEN** the screen shows "New worksheet" and the "Worksheets" list, and no pattern sentence

#### Scenario: A saved worksheet keeps its sentence
- **WHEN** a worksheet is linked to "5 of your 7 starred entries were after 20:00." and the person turns "Pattern sentences" off
- **THEN** the worksheet still shows that sentence above step 1

#### Scenario: Switch on again
- **WHEN** the person tapped "Close" for the after 20:00 template, turned the switch off, and turns it on again
- **THEN** the Problem solving screen shows the sentences, and Today shows no card for the after 20:00 template

### Requirement: The six-step worksheet

A worksheet MUST have six steps in this order. Each step MUST show its question as its heading. The steps are:
1. "What is the problem, exactly?" with the line "Be as precise as you can." under it. One free-text field.
2. "What could you do about it?" with the line "List every option, even the unlikely ones. Don't judge them yet." under it. A list of free-text lines, one per solution.
3. "How would each one work out?" One free-text field under each solution from step 2.
4. "Which will you try?" with the line "One, or a combination." under it. The solutions from step 2 as choices; the person picks one or more.
5. "What are the steps?" A list of free-text lines.
6. "How did it go?" with the line "Look at how you went about it, not only whether it worked." under it. One free-text field.

Step 5 MUST show the solutions chosen in step 4 above its list. Step 6 MUST show step 1's text, then the solutions chosen in step 4, above its field. When step 1 is empty or step 4 has no chosen solution, the step MUST show no empty space.

The worksheet MUST move between steps with a "Back" control, a "Next" control and a list of the six questions. A tap on a question in the list MUST open that step. The person MUST be able to move to any step at any time. The app MUST NOT require text in a step before the person moves on.

The app MUST save each field's text as the person types. The app MUST NOT rank, judge or comment on a solution. The app MUST NOT show a placeholder in any field.

In steps 2 and 5, the person MUST be able to reorder the lines. In edit mode, each line MUST show "Move up" and "Move down" as visible controls. Each line MUST offer "Move up" and "Move down" as VoiceOver actions. The worksheet MUST NOT need a drag to reorder a line.

The worksheet MUST have a "Done" control that closes the worksheet with the system's standard dismissal. The app MUST NOT show a message, a sound, a haptic or an animation on "Done".

#### Scenario: Start from a pattern sentence
- **WHEN** the person taps "Work it through" and the worksheet opens
- **THEN** the worksheet shows the sentence, then "What is the problem, exactly?" with an empty field and the keyboard in that field

#### Scenario: Solutions carry to step 3
- **WHEN** the person types "Plan an evening snack" and "Leave the kitchen after dinner" in step 2 and opens step 3
- **THEN** step 3 shows "Plan an evening snack" with an empty field under it, then "Leave the kitchen after dinner" with an empty field under it

#### Scenario: Pick a combination
- **WHEN** the person picks both solutions in step 4
- **THEN** step 4 shows both as chosen and the app shows no message

#### Scenario: Step 5 shows the choice
- **WHEN** the person chose "Plan an evening snack" in step 4 and opens step 5
- **THEN** step 5 shows "Plan an evening snack" above its list

#### Scenario: Step 6
- **WHEN** step 1 holds "Evenings after a missed lunch", the person chose "Plan an evening snack" in step 4, and opens step 6
- **THEN** the worksheet shows "How did it go?", then "Look at how you went about it, not only whether it worked.", then "Evenings after a missed lunch", then "Plan an evening snack", then an empty field

#### Scenario: Move between steps
- **WHEN** the person is on step 2 and taps "Next", then taps "What are the steps?" in the question list
- **THEN** the worksheet shows step 3, then step 5

#### Scenario: Move a line up
- **WHEN** step 2 holds "Plan an evening snack" then "Leave the kitchen after dinner", and the person uses "Move up" on the second line
- **THEN** step 2 shows "Leave the kitchen after dinner" then "Plan an evening snack", and step 3 follows that order

#### Scenario: Leave and return
- **WHEN** the person types "Evenings after a missed lunch" in step 1, closes the app, and opens the worksheet again
- **THEN** step 1 shows "Evenings after a missed lunch"

#### Scenario: Done is quiet
- **WHEN** the person taps "Done" with step 3 empty
- **THEN** the worksheet closes as any sheet closes, with no message about the empty step

### Requirement: The "Worksheets" list

The "Worksheets" list MUST show every saved worksheet, newest first by the moment the person started it. Each row MUST show the first line of step 1 and the worksheet's start date. The date MUST come from the en_GB formatter. When step 1 is empty, the row MUST show "Worksheet" and the date.

The "New worksheet" control MUST sit above the "Worksheets" list. When no worksheet exists, the screen MUST show "New worksheet" above an empty list. The app MUST NOT show text or an image in place of the rows. Decision 95 sets this rule. Ash ruled it on 25 September 2026.

The list MUST NOT show a count of worksheets or a count of finished steps. A worksheet MUST show its linked pattern sentence above step 1 as the sentence read when the worksheet started. The app MUST NOT change the linked sentence when the numbers change later.

A worksheet started from "New worksheet" MUST have no linked sentence and no empty space for one. The person MUST be able to open and edit any worksheet at any time. The person MUST be able to delete a worksheet after the system's standard confirmation. A delete MUST write `deleted = true` and the moment into the worksheet row. The store MUST NOT hard-delete the row. A reader MUST NOT show a deleted worksheet.

When the person deletes a worksheet, the app MUST cancel its worksheet review reminder. When a deleted worksheet row arrives by sync, the app MUST cancel that reminder too.

#### Scenario: Order of the list
- **WHEN** the person started a worksheet on 3 October and another on 10 October
- **THEN** the "Worksheets" list shows the 10 October worksheet above the 3 October worksheet

#### Scenario: The linked sentence stays
- **WHEN** a worksheet is linked to "5 of your 7 starred entries were after 20:00." and the group later holds 7 of 9
- **THEN** the worksheet still shows "5 of your 7 starred entries were after 20:00."

#### Scenario: A worksheet without a problem name
- **WHEN** a worksheet started on 3 October has an empty step 1
- **THEN** its row shows "Worksheet" and "3 October"

#### Scenario: No worksheet yet
- **WHEN** stage 4 is open, the person has no worksheet and opens the Problem solving screen
- **THEN** the screen shows "New worksheet" above an empty "Worksheets" list, with no text or image in place of the rows

#### Scenario: Delete a worksheet
- **WHEN** the person deletes a worksheet with a worksheet review reminder set for 17 October
- **THEN** the store writes `deleted = true` with the moment into the worksheet row, the "Worksheets" list stops showing it, and the app cancels the 17 October reminder

#### Scenario: Deleted on another device
- **WHEN** the person deletes a worksheet on another device and its row with `deleted = true` syncs to this device
- **THEN** the "Worksheets" list on this device stops showing it, and the app cancels its worksheet review reminder

### Requirement: The worksheet review reminder a week later

When the person taps "Done" with text in step 5, the app MUST schedule one worksheet review reminder. The reminder time MUST be seven calendar days after that moment, in the record's zone, at the same wall-clock time. The app MUST compute that time by calendar arithmetic, never as 7 × 86400 seconds. The app MUST schedule at most one worksheet review reminder per worksheet. The `reminders` capability owns the reminder's text, its switch, quiet hours, snooze and the daily cap.

When the person opens the reminder, the app MUST open that worksheet at step 6. When the person saves text in step 6 before the reminder time, the app MUST cancel the reminder. The person MUST be able to open step 6 at any time without the reminder.

#### Scenario: Schedule the review
- **WHEN** the person taps "Done" at 21:10 on Saturday 10 October with text in step 5
- **THEN** the app schedules the worksheet review reminder for 21:10 on Saturday 17 October

#### Scenario: Across the end of British Summer Time
- **WHEN** the person taps "Done" at 21:10 on Saturday 24 October 2026 with text in step 5, and the clocks go back one hour on Sunday 25 October
- **THEN** the app schedules the worksheet review reminder for 21:10 on Saturday 31 October 2026, which is 169 hours later, and not for 20:10

#### Scenario: Open from the reminder
- **WHEN** the person opens the worksheet review reminder
- **THEN** the app opens the worksheet at "How did it go?"

#### Scenario: Review before the reminder
- **WHEN** the person types "Had the snack, urge passed" in step 6 on 14 October
- **THEN** the app cancels the 17 October reminder

#### Scenario: Done a second time
- **WHEN** the person edits step 5 on 12 October and taps "Done" again
- **THEN** the reminder stays at 21:10 on 17 October and the app schedules no second reminder

### Requirement: Worksheet text stays on the device

The app MUST save every worksheet in the store on the device. The `data-and-privacy` capability owns sync to the person's iCloud private database and Delete-all. The app MUST NOT send worksheet text or a pattern sentence off the device by any other channel. The app MUST NOT send a group size or a starred total off the device. The app MUST NOT put worksheet text or a pattern sentence in the system log or an error. The app MUST NOT put them in a crash report.

Every worksheet row and every card answer row MUST carry its own changedAt. An edit MUST write into the winning row that `data-and-privacy` defines. The store MUST NOT hard-delete a worksheet row or a card answer row. Only Delete-all, which `data-and-privacy` owns, deletes them.

Delete-all MUST delete every worksheet and every card answer row of a suggestion card. When the app is not active, the worksheet and the Problem solving screen MUST hide their text.

#### Scenario: Store error
- **WHEN** the store fails to save a worksheet with step 1 "Evenings after a missed lunch"
- **THEN** the error the store throws contains no part of "Evenings after a missed lunch"

#### Scenario: App switcher
- **WHEN** the person opens the app switcher while a worksheet is on screen
- **THEN** the app's snapshot shows no worksheet text and no pattern sentence

#### Scenario: Delete-all
- **WHEN** the person taps Delete-all
- **THEN** the "Worksheets" list is empty, and the after 20:00 template can show a suggestion card again

### Requirement: Accessibility of problem solving

Each pattern sentence MUST be one accessibility element whose label is the sentence text. Every control on the Problem solving screen, the suggestion card and the worksheet MUST have a VoiceOver label. The label of each worksheet field MUST be its step's question. Each step's question MUST carry the header trait.

A chosen solution in step 4 MUST NOT depend on colour alone. Text on the Problem solving screen and the worksheet MUST use system text styles. That text MUST scale with Dynamic Type.

#### Scenario: VoiceOver reads a sentence
- **WHEN** VoiceOver reads the first pattern sentence
- **THEN** it reads "5 of your 7 starred entries were after 20:00." and nothing else for that element

#### Scenario: VoiceOver on step 1
- **WHEN** VoiceOver focuses the step 1 field
- **THEN** it reads "What is the problem, exactly?" as the field's label

#### Scenario: A step heading
- **WHEN** VoiceOver focuses the question of step 2
- **THEN** it reads "What could you do about it?" with the header trait, and the headings rotor lists the six questions

#### Scenario: Reorder with VoiceOver
- **WHEN** VoiceOver focuses the second line of step 2
- **THEN** the actions rotor offers "Move up" and "Move down"

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the Problem solving screen and the worksheet show all text without truncation
