# urge-toolkit

## Purpose

The urge toolkit is the stage 3 tool for the moment an urge comes. One tap on Today starts a 20-minute timer with a wave that shows the urge rising and fading. Under the wave sit the person's own alternatives list and one grounding exercise. When the urge is over, the person saves what happened in one tap, and the app keeps it without judgement.

## ADDED Requirements

### Requirement: The Urge button on Today

From stage 3, Today MUST show a button with the label "Urge". `programme` owns when stage 3 opens. Before stage 3 opens, Today MUST NOT show the button. The button MUST sit at the bottom of the Today stack that `record` defines. The button MUST stay on screen while Today is on screen, whatever the scroll position.

The button MUST be at least 56 points tall. The button MUST span the content width. The button MUST NOT show a number or a dot. One tap on the button MUST open the urge screen with no confirmation step. While an urge is open, a tap on the button MUST show that urge. The tap MUST NOT start a new urge.

#### Scenario: Stage 3 open
- **WHEN** stage 3 is open and the person opens Today
- **THEN** Today shows the "Urge" button, and it stays on screen when the person scrolls the record

#### Scenario: Before stage 3
- **WHEN** the person is in stage 2 and opens Today
- **THEN** Today shows no "Urge" button

#### Scenario: One tap
- **WHEN** the person taps "Urge" at 21:10 on Thursday 24 September
- **THEN** the urge screen opens at once with the timer at "00:00"

#### Scenario: Tap while an urge is open
- **WHEN** an urge started at 21:10 has no outcome and the person taps "Urge" at 21:25
- **THEN** the urge screen shows that urge with the timer at "15:00"

### Requirement: The timer

When the person taps "Urge", the app MUST start an urge and save its `startedAt` and `startDayKey`. The urge screen MUST show the elapsed time since the start moment as minutes and seconds, for example "12:40". After sixty minutes the app MUST show hours as well, for example "1:02:15".

The timer's length is URGE_TIMER_MINUTES = 20. `programme` holds the constant in `ProgrammeConstants`. The timer MUST count up. The timer MUST NOT stop at 20 minutes.

At 20 minutes the wave MUST be complete. At half of URGE_TIMER_MINUTES and at URGE_TIMER_MINUTES the app MUST post one VoiceOver announcement. The announcement MUST be "%lld minutes" with the minutes filled in: "10 minutes", then "20 minutes".

With "Buzz at 20 minutes" on and VoiceOver off, the app MUST play one system haptic at 20 minutes. Those two announcements and that haptic MUST be the only sounds, haptics or announcements in the toolkit. The app MUST NOT play an alarm. The app MUST NOT schedule a notification about an urge.

#### Scenario: Elapsed time
- **WHEN** the person tapped "Urge" at 21:10:00 and looks at the urge screen at 21:22:40
- **THEN** the timer shows "12:40"

#### Scenario: Twenty minutes
- **WHEN** the elapsed time reaches 20:00
- **THEN** the timer shows "20:00", the wave is complete, and the app shows no message

#### Scenario: Ten minutes with VoiceOver
- **WHEN** VoiceOver is on and the elapsed time reaches 10:00
- **THEN** the app posts one announcement "10 minutes", and VoiceOver focus stays where it was

#### Scenario: Twenty minutes with VoiceOver
- **WHEN** VoiceOver is on and the elapsed time reaches 20:00
- **THEN** the app posts one announcement "20 minutes", plays no haptic, and VoiceOver focus stays where it was

#### Scenario: Buzz at 20 minutes off
- **WHEN** "Buzz at 20 minutes" is off, VoiceOver is off, and the elapsed time reaches 20:00
- **THEN** the app plays no haptic and no sound

#### Scenario: Buzz at 20 minutes on
- **WHEN** "Buzz at 20 minutes" is on, VoiceOver is off, and the elapsed time reaches 20:00
- **THEN** the app plays one system haptic and nothing at any other moment of the urge

#### Scenario: Past twenty minutes
- **WHEN** the person tapped "Urge" at 21:10:00 and looks at the urge screen at 21:52:00
- **THEN** the timer shows "42:00"

#### Scenario: Past an hour
- **WHEN** the person tapped "Urge" at 21:10:00 and looks at the urge screen at 22:12:15
- **THEN** the timer shows "1:02:15"

### Requirement: The wave

The urge screen MUST show one curve that rises to one peak and falls back to its base. The peak MUST be at 10 minutes and the base MUST be at 20 minutes. After the base the curve MUST continue as a flat tail. The curve MUST show a marker at the elapsed time's position. After 20 minutes the marker MUST keep moving along the flat tail. The curve MUST use the primary text colour and no other colour.

When Reduce Motion is on, the marker MUST move once a minute, with no animation between positions. At an accessibility text size the wave MUST be at most 120 points tall.

The curve MUST show no number, no axis and no label. The curve MUST show the wave line under it and no other text. The wave line MUST be "Urges rise, peak and fade. Most fade in about %lld minutes. Some take longer." with URGE_TIMER_MINUTES in %lld. With the constant at 20 the line reads "Urges rise, peak and fade. Most fade in about 20 minutes. Some take longer."

#### Scenario: Marker before the peak
- **WHEN** the elapsed time is 04:00
- **THEN** the marker is on the rising part of the curve

#### Scenario: Marker at the peak
- **WHEN** the elapsed time is 10:00
- **THEN** the marker is at the top of the curve

#### Scenario: Marker on the flat tail
- **WHEN** the elapsed time is 42:00
- **THEN** the marker is on the flat tail, further along than it was at 30:00

#### Scenario: The marker with Reduce Motion
- **WHEN** Reduce Motion is on and the elapsed time passes from 11:59 to 12:00
- **THEN** the marker moves to the 12-minute position in one step, with no animation between the positions

#### Scenario: The wave at an accessibility text size
- **WHEN** the person sets an accessibility text size and taps "Urge"
- **THEN** the wave is at most 120 points tall

#### Scenario: The wave line
- **WHEN** the person reads under the curve
- **THEN** the text reads "Urges rise, peak and fade. Most fade in about 20 minutes. Some take longer." and nothing else

### Requirement: The alternatives list on the urge screen

The urge screen MUST show the person's alternatives list under the wave. The screen MUST show each item as the person typed it, in the person's order. The screen MUST NOT show an example the person has not added. The screen MUST NOT rank, tick, colour or reorder an item. When the list is empty, the screen MUST show one control, "Add an alternative", that opens the setup. The screen MUST show one control, "Edit list", that opens the setup.

#### Scenario: The list is shown
- **WHEN** the person's list holds "Walk round the block", "Ring Sam" and "Shower" and the person taps "Urge"
- **THEN** the urge screen shows those three items in that order and no other item

#### Scenario: Empty list
- **WHEN** the person's list is empty and the person taps "Urge"
- **THEN** the urge screen shows "Add an alternative" in the list's place

#### Scenario: Edit from the urge screen
- **WHEN** the person taps "Edit list" while an urge is open
- **THEN** the setup opens, and the urge keeps its start moment

### Requirement: The alternatives list setup

The setup MUST be reachable from the "Alternatives list" row and from the urge screen. That row sits in the "Tools" group of the "Alternatives" stage screen. `programme` owns the stage screen, its "Tools" group and the stage title "Alternatives". The setup's title MUST be "Alternatives list". The list MUST hold at most 10 items. Each item MUST hold at most 80 characters of free text. The setup MUST show examples the person can add with one tap.

The examples MUST be bundled text with the clinical reviewer's sign-off. `content` owns that sign-off. The examples MUST include "Go out for a walk", "Call or message a friend", "Have a shower or a bath", "Do a puzzle or a game", "Go to another room and shut the door", "Put music or a podcast on" and "Do one small job with your hands". An added example MUST become the person's item. The person MUST be able to edit its text.

The person MUST be able to add, edit, reorder and delete an item at any time. In edit mode each item MUST show "Move up" and "Move down" as visible controls. Each item MUST offer "Move up" and "Move down" as VoiceOver actions. The setup MUST NOT need a drag to reorder.

The app MUST NOT add an item without a tap from the person. The app MUST NOT show a message about an item's content. The app MUST NOT require any item.

The setup MUST show a switch, "Buzz at %lld minutes", with URGE_TIMER_MINUTES in %lld. With the constant at 20 the label reads "Buzz at 20 minutes". The switch MUST be off by default. The timer requirement defines what the switch does.

#### Scenario: The setup's title
- **WHEN** the person taps "Alternatives list" in the "Tools" group of the "Alternatives" stage screen
- **THEN** the screen's title reads "Alternatives list"

#### Scenario: Add an example
- **WHEN** the person taps "Go out for a walk" in the examples
- **THEN** the list gains the item "Go out for a walk", and the person can change its text

#### Scenario: Add an own item
- **WHEN** the person types "Ring Sam" and adds it
- **THEN** the list gains the item "Ring Sam" as typed

#### Scenario: Reorder and delete
- **WHEN** the person moves "Shower" to the top and deletes "Ring Sam"
- **THEN** the list shows "Shower" first and no "Ring Sam", and the store keeps the "Ring Sam" row with `deleted = true`

#### Scenario: Move up in edit mode
- **WHEN** the list holds "Walk round the block", "Ring Sam" and "Shower" and the person taps "Move up" on "Shower" in edit mode
- **THEN** the list shows "Walk round the block", "Shower", "Ring Sam"

#### Scenario: Move down with VoiceOver
- **WHEN** a person using VoiceOver reaches "Walk round the block" and chooses the action "Move down"
- **THEN** the item moves one place down the list

#### Scenario: Buzz at 20 minutes off by default
- **WHEN** the person opens the setup for the first time
- **THEN** "Buzz at 20 minutes" is off

#### Scenario: Full list
- **WHEN** the list holds 10 items
- **THEN** the setup offers no add control until the person deletes an item

#### Scenario: Empty list on leaving
- **WHEN** the person leaves the setup with no items
- **THEN** the app shows no message and the list stays empty

### Requirement: The grounding exercise

The urge screen MUST offer one grounding exercise below the alternatives list. The exercise MUST be the breathing exercise or the walk text. The setup MUST hold a control, "Grounding exercise", with the choices "Breathing" and "A walk". The default MUST be "Breathing".

The breathing exercise MUST start on one tap of "Breathe". The shape MUST grow for four seconds with the text "Breathe in". The shape MUST shrink for six seconds with the text "Breathe out".

The breathing exercise MUST repeat for two minutes or until the person taps "Stop". When Reduce Motion is on, the shape MUST NOT scale. The app MUST then cross-fade "Breathe in" and "Breathe out" on the same timing. The alternatives list MUST come before the exercise at every text size.

The walk text MUST read "If you can, leave the room and walk for ten minutes. If you can't leave, walk to the door and back, or stand at a window for two minutes." The exercise MUST show no other text. The urge screen MUST NOT show a card, an explanation of urges or a link to content.

#### Scenario: Breathing
- **WHEN** the exercise is "Breathing" and the person taps "Breathe"
- **THEN** the shape grows with "Breathe in" for four seconds, shrinks with "Breathe out" for six seconds, and repeats

#### Scenario: Stop breathing early
- **WHEN** the breathing exercise is running and the person taps "Stop"
- **THEN** the shape stops, and the app shows no message

#### Scenario: Breathing with Reduce Motion
- **WHEN** Reduce Motion is on and the person taps "Breathe"
- **THEN** the shape keeps one size, and "Breathe in" cross-fades to "Breathe out" after four seconds and back after six seconds

#### Scenario: The list before the exercise at an accessibility text size
- **WHEN** the person sets an accessibility text size and taps "Urge"
- **THEN** the alternatives list comes before the exercise

#### Scenario: The walk text
- **WHEN** the exercise is "A walk" and the person taps "Urge"
- **THEN** the urge screen shows "If you can, leave the room and walk for ten minutes. If you can't leave, walk to the door and back, or stand at a window for two minutes."

#### Scenario: No lecture
- **WHEN** the person reads the whole urge screen
- **THEN** the screen holds the timer, the wave and its one line, the list, the exercise, the three outcome controls, "Close" and Get support, and nothing else

### Requirement: The urge outcome

The urge screen MUST show three controls from the start of the urge: "It passed", "I ate as planned" and "I binged". The three controls MUST have the same size, weight and colour. The three controls MUST have 12 points between them. The three controls MUST stay on screen at every scroll position of the urge screen.

A tap on "It passed" or "I ate as planned" MUST save an urge outcome. The app MUST write the choice into the urge's row as `outcome`. `outcomeAt` MUST be the moment of the tap. `outcomeDayKey` MUST be its record day. The app MUST then close the urge and show Today.

On save the app MUST NOT show a confirmation, a message, a sound or a haptic. On save the app MUST NOT show a colour change or an animation. The system's standard sheet dismissal is not an addition. The app MUST NOT ask a further question about the urge. The app MUST NOT let the person change a saved urge outcome. After the app saves an outcome, a tap on "Urge" MUST start a new urge.

#### Scenario: It passed
- **WHEN** the person taps "It passed" at 21:28 on an urge that started at 21:10
- **THEN** the store holds one urge with `startedAt` 21:10, `outcome` "It passed" and `outcomeAt` 21:28, and Today shows with no message

#### Scenario: I ate as planned
- **WHEN** the person taps "I ate as planned" at 21:40 on an urge that started at 21:10
- **THEN** the store holds one urge with `startedAt` 21:10, `outcome` "I ate as planned" and `outcomeAt` 21:40, and Today shows with no message

#### Scenario: Outcome controls while scrolled
- **WHEN** the person scrolls the urge screen to the end of a ten-item list
- **THEN** "It passed", "I ate as planned" and "I binged" stay on screen with 12 points between them

#### Scenario: Early outcome
- **WHEN** the person taps "It passed" at 03:00 elapsed
- **THEN** the app saves the outcome and closes the urge without a question about the time

#### Scenario: New urge after an outcome
- **WHEN** the person saved an outcome at 21:28 and taps "Urge" at 23:05
- **THEN** the urge screen opens a new urge with the timer at "00:00"

### Requirement: "Close" keeps the urge open

The urge screen MUST show a control with the label "Close". "Close" MUST sit in the sheet's leading navigation position. "Close" MUST be at least 44 points from any outcome control. "Close" MUST stay on screen at every scroll position.

A tap on "Close" MUST take the urge screen off the screen and show Today. The urge MUST stay open with no outcome. While an urge is open and off the screen, Today MUST show one line, "Urge open since %@". The app MUST fill %@ with the urge's `startedAt` as a 24-hour clock time. The time MUST come from the en_GB formatter, for example "Urge open since 22:40".

The line MUST be a control that returns to the urge screen with the elapsed time. `record` owns where the line sits in the Today stack.

Today MUST take the line off the screen when the app saves the urge's outcome. Today MUST take the line off the screen when the urge's record day ends. The line MUST NOT show the elapsed time, a count or any other text.

#### Scenario: Close the urge screen
- **WHEN** an urge started at 22:40 and the person taps "Close" at 22:47
- **THEN** Today shows "Urge open since 22:40", and the store holds the urge with no outcome

#### Scenario: "Close" while scrolled
- **WHEN** the person scrolls the urge screen to the end of a ten-item list
- **THEN** "Close" stays in the leading navigation position, at least 44 points from any outcome control

#### Scenario: Return from the line
- **WHEN** Today shows "Urge open since 22:40" and the person taps it at 23:02
- **THEN** the urge screen shows that urge with the timer at "22:00"

#### Scenario: The line goes after an outcome
- **WHEN** the person returns from the line and taps "It passed"
- **THEN** Today shows no "Urge open since" line

#### Scenario: The line with VoiceOver
- **WHEN** a person using VoiceOver reaches the line
- **THEN** VoiceOver reads "Urge open since 22:40, button"

### Requirement: "I binged" opens a pre-filled entry

A tap on "I binged" MUST open the new-entry screen. `record` owns that screen. The time MUST be the moment of the tap. The star "felt like a binge" MUST be on. What MUST be empty with the keyboard in it. The person MUST be able to change the time, What and the star before saving.

When the person saves the entry, the app MUST save an urge outcome "I binged". The app MUST then close the urge. The app MUST write the entry's id into the urge's `entryId`. The app MUST then show Today.

The new-entry screen MUST show nothing about the next planned meal. From the next time Today appears, Today MUST show the next-planned-meal line as `regular-eating-plan` defines it after a starred entry. The app MUST NOT show any other message about the outcome.

Today MUST NOT show an opening card on a load in the same record day as the "I binged" outcome. `programme` owns the opening card and holds it until the next record day.

When the person cancels the new-entry screen, the app MUST save no entry and no outcome. The urge MUST then stay open and the urge screen MUST show again.

#### Scenario: Save the entry
- **WHEN** the person taps "I binged" at 14:45 and saves the entry with What "Crisps and cereal"
- **THEN** the store holds an entry at 14:45 with the star on, and the urge holds `outcome` "I binged" and that entry's id in `entryId`, and Today shows "Mid-afternoon at 16:00 still happens." on the Mid-afternoon row

#### Scenario: Nothing on the new-entry screen
- **WHEN** the person taps "I binged" at 14:45 and the new-entry screen is open
- **THEN** the new-entry screen shows no line about the next planned meal

#### Scenario: The new-entry screen is pre-filled
- **WHEN** the person taps "I binged" at 21:35
- **THEN** the new-entry screen shows the time 21:35, the star on, an empty What and the keyboard in What

#### Scenario: Cancel the entry
- **WHEN** the person taps "I binged" and then taps "Cancel"
- **THEN** the store holds no new entry and no new outcome, and the urge screen shows the same urge

#### Scenario: Change the time before saving
- **WHEN** the person taps "I binged" at 21:35 and sets the time to 21:20 before saving
- **THEN** the store holds an entry at 21:20 with the star on and an urge outcome "I binged"

#### Scenario: No opening card after "I binged"
- **WHEN** the person's first urge outcome is "I binged" at 21:35 on Thursday 24 September and Today loads at 21:36
- **THEN** Today shows no opening card for stage 4, and the card appears on a Today load on Friday 25 September at the earliest

### Requirement: The first urge outcome opens stage 4

The app MUST make every saved urge outcome available to `programme`. `programme` owns the opening rule of stage 4, its other route and what the person sees about progress. The first saved urge outcome of any kind MUST count for that opening. An urge with no outcome MUST NOT count. The urge screen MUST NOT show a message about the opening.

#### Scenario: First outcome
- **WHEN** the person saves the first urge outcome, "It passed"
- **THEN** `programme` reads one urge outcome, and the urge screen shows no message about stage 4

#### Scenario: First outcome is a binge
- **WHEN** the person's first saved urge outcome is "I binged"
- **THEN** `programme` reads one urge outcome in the same way as for "It passed"

#### Scenario: Urge without an outcome
- **WHEN** the person has one urge with no outcome and no other urge
- **THEN** `programme` reads no urge outcome

### Requirement: The timer keeps running in the background

The app MUST compute the elapsed time from the saved start moment and the current moment. The timer MUST NOT reset when the app enters the background or closes. When the app becomes active, it MUST NOT open the urge screen. The urge screen opens only from the "Urge" button or the "Urge open since" line. While the urge is open in the same record day, Today MUST show the "Urge open since" line. `record` defines the record day.

When the record day of an open urge ends, the app MUST keep the urge with no outcome. The app MUST NOT show that urge again. The app MUST NOT show a message about an urge that ended without an outcome.

On read the store MUST hold at most one open urge per record day. When two open urges share a `startDayKey`, for example after a sync, the app keeps the urge with the earliest `startedAt` as the open urge. The other urges MUST close silently at the day end, with no outcome and no message. The app MUST NOT delete them.

#### Scenario: Return after a walk
- **WHEN** the person tapped "Urge" at 21:10, left the app at 21:13 and opens it at 21:52
- **THEN** the app shows Today with "Urge open since 21:10", and a tap on the line shows the timer at "42:00"

#### Scenario: The app closed
- **WHEN** the person tapped "Urge" at 21:10, the system closed the app, and the person opens it at 21:30
- **THEN** the app shows Today with "Urge open since 21:10", and a tap on the line shows the timer at "20:00"

#### Scenario: Return in the same record day after midnight
- **WHEN** the person tapped "Urge" at 21:10 on Thursday 24 September and opens the app at 02:00 on Friday 25 September
- **THEN** Today shows "Urge open since 21:10", and a tap on the line shows the timer at "4:50:00"

#### Scenario: Two open urges on one record day
- **WHEN** device A started an urge at 21:10 and device B started one at 21:15, both with the `startDayKey` Thursday 24 September and no outcome, and both then sync
- **THEN** Today on each device shows "Urge open since 21:10", a tap on "Urge" shows the 21:10 urge, and the 21:15 urge closes at the day end with no outcome and no message

#### Scenario: Return the next day
- **WHEN** the person tapped "Urge" at 21:10 on Thursday 24 September and opens the app at 09:00 on Friday 25 September
- **THEN** the app shows Today with no "Urge open since" line, the store keeps the urge with no outcome, and the app shows nothing about it

### Requirement: What the toolkit never shows

The app MUST show a count of urges or outcomes only inside the weekly review's urge part. That part reads "Urges: %1$lld. Passed: %2$lld." and `weekly-review` owns that text.

The "Urge" button, the urge screen and the setup MUST NOT show how many urges the person has had. The app MUST NOT show a list of past urges. The urge screen MUST NOT show an entry, a weight value or a planned meal. The app MUST NOT show praise, a word of blame or advice after any outcome. The tone rules in `product-rules` apply to every string in the toolkit.

#### Scenario: Urge button after many urges
- **WHEN** the person has saved twelve urge outcomes
- **THEN** the "Urge" button reads "Urge" and shows no number

#### Scenario: After "I binged"
- **WHEN** the person saves the entry after "I binged"
- **THEN** Today shows the next-planned-meal line and no other text about the urge

#### Scenario: The weekly review
- **WHEN** the weekly review builds a week with three urges, two of which passed
- **THEN** the urge part of the weekly review reads "Urges: 3. Passed: 2.", and no other screen shows those numbers

### Requirement: The store keeps urges and the list on the device

The store MUST keep each urge as one row with the fields `startedAt`, `startDayKey`, `outcome`, `outcomeAt`, `outcomeDayKey`, `entryId` and `changedAt`. `startDayKey` is the record day of `startedAt`. `outcome`, `outcomeAt`, `outcomeDayKey` and `entryId` MUST be empty until the app saves an outcome. `entryId` MUST hold a value only for the outcome "I binged". The app MUST resolve `entryId` to its entry on read. The store MUST keep the alternatives list, the grounding exercise choice and the "Buzz at 20 minutes" choice.

The store MUST keep each alternatives item as one row. The row holds its text, its position, its `changedAt` and a `deleted` flag with a moment. A delete MUST write `deleted = true` with the moment. The app MUST NOT hard-delete an urge or a list item.

The app MUST hide a deleted item on every read. An edit or a move MUST write into the winning row with a later `changedAt`. When two versions of a row share an id, the app keeps the version with the later `changedAt` on read. The app MUST NOT read a CKRecord system date for an urge or a list item.

Urges and the list MUST have the same file protection and backup exclusion as an entry. `record` sets those.

An urge, an outcome or a list item MUST NOT leave the device. The one exception is the person's own iCloud private database. `data-and-privacy` owns sync and Delete-all.

The app MUST NOT write a list item to the system log, an error description or a crash report. The toolkit MUST work with no network.

#### Scenario: No network
- **WHEN** the device has no network connection and the person taps "Urge"
- **THEN** the timer, the wave, the list, the exercise and the outcome controls all work

#### Scenario: Delete a list item
- **WHEN** the person deletes "Ring Sam" at 09:00
- **THEN** the store keeps the "Ring Sam" row with `deleted = true`, its moment 09:00 and `changedAt` 09:00, and the urge screen and the setup show no "Ring Sam"

#### Scenario: Edit a list item on two devices
- **WHEN** device A changes "Ring Sam" to "Ring Sam or Jo" at 09:00 and device B changes it to "Text Sam" at 09:02, and both then sync
- **THEN** both devices show "Text Sam", the version with the later `changedAt`, and one row for the item

#### Scenario: Store error
- **WHEN** the store fails to save the list item "Ring Sam"
- **THEN** the error the store throws contains no part of "Ring Sam"

#### Scenario: Delete-all
- **WHEN** the person uses Delete-all
- **THEN** the store holds no urge, no outcome and no list item

### Requirement: Accessibility of the urge flow

Every control in the toolkit MUST have a VoiceOver label. The "Urge" button's label MUST be "Urge". The "Close" control's label MUST be "Close". The timer MUST be one accessibility element with the label "Elapsed time". The timer's value MUST be the elapsed time from the en_GB duration formatter, for example "12 minutes 40 seconds".

The timer MUST carry the updates-frequently trait. VoiceOver focus MUST NOT move when the timer or the wave changes. `record` owns Today's reading order, in which the "Urge" button is the first element from stage 3.

The wave MUST be one accessibility element with the label "Urges rise, peak and fade". Before URGE_TIMER_MINUTES the wave's value MUST be "%1$lld minutes of %2$lld". The app fills in the elapsed minutes and URGE_TIMER_MINUTES, for example "12 minutes of 20". From URGE_TIMER_MINUTES the wave's value MUST be "%lld minutes" with the elapsed minutes filled in, for example "42 minutes".

Each list item MUST be one accessibility element that reads the item's text. The breathing text MUST be one accessibility element with the updates-frequently trait. Its value MUST be "Breathe in" or "Breathe out". The app MUST NOT post an announcement for the breathing exercise.

The outcome controls' labels MUST be "It passed", "I ate as planned" and "I binged". The hit-area rule in `product-rules` applies to every control in the toolkit. A control with no visible text MUST have a label a person can say with Voice Control. Meaning in the toolkit MUST NOT depend on colour. Text in the toolkit MUST use system text styles. Text in the toolkit MUST scale with Dynamic Type.

#### Scenario: The whole flow with VoiceOver
- **WHEN** a person using VoiceOver taps "Urge", hears the timer, reads the list, runs the breathing exercise and taps "It passed"
- **THEN** every step has a spoken label and no step needs sight

#### Scenario: The timer with VoiceOver
- **WHEN** a person using VoiceOver reaches the timer at 12:40 elapsed
- **THEN** VoiceOver reads "Elapsed time, 12 minutes 40 seconds"

#### Scenario: The wave with VoiceOver
- **WHEN** a person using VoiceOver reaches the wave at 12:40 elapsed
- **THEN** VoiceOver reads "Urges rise, peak and fade, 12 minutes of 20"

#### Scenario: Focus stays while the timer runs
- **WHEN** a person using VoiceOver has focus on "Ring Sam" and the timer passes 12:00
- **THEN** VoiceOver focus stays on "Ring Sam"

#### Scenario: The breathing text with VoiceOver
- **WHEN** a person using VoiceOver has focus on the breathing text and the phase changes
- **THEN** the element's value changes to "Breathe out", and the app posts no announcement

#### Scenario: Voice Control
- **WHEN** a person using Voice Control says "Show names" on the urge screen
- **THEN** every control shows a name, and "Tap It passed" saves the outcome

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the urge screen shows the timer, a wave at most 120 points tall, the list, the exercise, the three outcome controls and "Close" without truncation
