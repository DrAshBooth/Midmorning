# urge-toolkit

## Purpose

The urge toolkit is the stage 3 tool for the moment an urge comes. One tap on Today starts a 20-minute timer with a wave that shows the urge rising and fading. Under the wave sit the person's own alternatives list and one grounding exercise. When the urge is over, the person saves what happened in one tap, and the app keeps it without judgement.

## ADDED Requirements

### Requirement: The Urge button on Today

From stage 3, Today MUST show a button with the label "Urge". `programme` owns when stage 3 opens. Before stage 3 opens, Today MUST NOT show the button. The button MUST sit at the bottom of the Today stack that `record` defines. The button MUST stay on screen while Today is on screen, whatever the scroll position.

The button MUST be at least 56 points tall. The button MUST span the content width. The button MUST NOT show a number or a dot. One tap on the button MUST open the urge screen with no confirmation step. While an urge is open, a tap on the button MUST show that urge. The tap MUST NOT start a new urge.

The button MUST show and work on every record day from stage 3. This includes a paused day, a fasting day and a day with the state "didn't record". `record` owns those states. A day state MUST NOT change the button, the urge screen or the outcome.

An urge starts only from the "Urge" button on Today. The app MUST NOT offer an App Intent, an App Shortcut or a Siri phrase that starts or shows an urge. The app MUST NOT offer a widget, a Control Centre control, a Lock Screen control or a notification action that starts or shows an urge. Ash ruled this on 12 October 2026 (r23-03).

#### Scenario: Only from Today
- **WHEN** a test lists the App Intents, App Shortcuts, widget kinds, Control Centre controls and notification categories that the app declares
- **THEN** no item on the list starts an urge or shows an urge

#### Scenario: A paused day
- **WHEN** stage 3 is open, the person tapped "Pause for today" at 12:00, and taps "Urge" at 21:10
- **THEN** the urge screen opens with the timer at "00:00", as on any other day

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

When the person taps "Urge", the app MUST start an urge and save its `startedAt` and `startDayKey`. The urge screen MUST show the elapsed time since the start moment. The timer text MUST come from the en_GB positional duration formatter. Below one hour, the text MUST show minutes and seconds with two digits each, for example "06:00" and "12:40". From one hour, the text MUST also show hours, for example "1:02:15". When the device clock reads a moment before `startedAt`, the timer MUST show "00:00".

URGE_TIMER_MINUTES = 20 sets the wave, the announcements and the buzz. `programme` holds the constant in `ProgrammeConstants`. The timer MUST count up. The timer MUST NOT stop at URGE_TIMER_MINUTES. It keeps counting until the urge closes.

At URGE_TIMER_MINUTES the wave MUST be complete. At half of URGE_TIMER_MINUTES and at URGE_TIMER_MINUTES, the app MUST post one VoiceOver announcement. The announcement MUST be "%lld minutes" with the minutes filled in: "10 minutes", then "20 minutes".

With "Buzz at 20 minutes" on and VoiceOver off, the app MUST play one system haptic at URGE_TIMER_MINUTES. The haptic MUST be one impact of medium weight. It MUST NOT be the success pattern of the system, because that pattern can read as praise.

The toolkit MUST NOT play a sound. That haptic MUST be the only haptic of the toolkit. Those two announcements and the breathing words that "The grounding exercise" states MUST be its only announcements. The app MUST NOT play an alarm. The app MUST NOT schedule a notification about an urge.

A reminder can arrive while the urge screen shows. Its banner and its sound are not part of the toolkit. The reminder shows and plays its sound as `reminders` states in "Discreet text by default". Ash ruled on the reminder sound on 25 September 2026 (r8-22).

The app MUST post an announcement or play the haptic only when three things are true at that moment. The urge screen is the top screen, so no sheet covers it. Examples of such a sheet are the support sheet, the setup and the new-entry screen of "I binged". The app is active. No cover of `app-lock` shows. When one of the three is not true at that moment, the app MUST NOT post that announcement or play that haptic, then or later.

#### Scenario: Back after twenty minutes
- **WHEN** "Buzz at 20 minutes" is on, the person leaves the app at 15:00 elapsed, and returns to the urge screen at 25:00 elapsed
- **THEN** the timer shows "25:00", and the app plays no haptic and posts no announcement

#### Scenario: Elapsed time
- **WHEN** the person tapped "Urge" at 21:10:00 and looks at the urge screen at 21:22:40
- **THEN** the timer shows "12:40"

#### Scenario: Twenty minutes
- **WHEN** the elapsed time reaches 20:00
- **THEN** the timer shows "20:00", the wave is complete, and the app shows no message

#### Scenario: Ten minutes with VoiceOver
- **WHEN** VoiceOver is on and the elapsed time reaches 10:00
- **THEN** the app posts one announcement "10 minutes" and posts no focus move, so VoiceOver focus stays where it was

#### Scenario: Twenty minutes with VoiceOver
- **WHEN** VoiceOver is on and the elapsed time reaches 20:00
- **THEN** the app posts one announcement "20 minutes", plays no haptic, and posts no focus move, so VoiceOver focus stays where it was

#### Scenario: Buzz at 20 minutes off
- **WHEN** "Buzz at 20 minutes" is off, VoiceOver is off, and the elapsed time reaches 20:00
- **THEN** the app plays no haptic and no sound

#### Scenario: Buzz at 20 minutes on
- **WHEN** "Buzz at 20 minutes" is on, VoiceOver is off, and the elapsed time reaches 20:00
- **THEN** the app plays one impact haptic of medium weight, and nothing at any other moment of the urge

#### Scenario: Past twenty minutes
- **WHEN** the person tapped "Urge" at 21:10:00 and looks at the urge screen at 21:52:00
- **THEN** the timer shows "42:00"

#### Scenario: Past an hour
- **WHEN** the person tapped "Urge" at 21:10:00 and looks at the urge screen at 22:12:15
- **THEN** the timer shows "1:02:15"

#### Scenario: The clock moved back
- **WHEN** the person tapped "Urge" at 21:10:00 on Tuesday 13 October 2026, and then sets the device clock back to 21:05:00
- **THEN** the timer shows "00:00"

#### Scenario: Under the cover
- **WHEN** "Buzz at 20 minutes" is on, VoiceOver is off, "Lock after" is "At once", the urge started at 21:10:00, the person left the app from the urge screen, returns at 21:29:50 and unlocks at 21:30:30
- **THEN** the cover shows from 21:29:50 to 21:30:30, and the app plays no haptic at 21:30:00 or after the unlock

#### Scenario: Under the support sheet
- **WHEN** VoiceOver is on, the support sheet shows over the urge screen, and the elapsed time reaches 10:00
- **THEN** the app posts no announcement

### Requirement: The wave

The urge screen MUST show one curve that rises to one peak and falls back to its base. The peak MUST be at half of URGE_TIMER_MINUTES, which is 10 minutes with the constant at 20. The base MUST be at URGE_TIMER_MINUTES, which is 20 minutes. After the base, the curve MUST continue as a flat tail. The tail MUST end at 60 minutes. That end is a fixed design value, not a constant.

The curve MUST show a marker at the elapsed time's position. After URGE_TIMER_MINUTES the marker MUST keep moving along the flat tail. From 60 minutes the marker MUST stay at the end of the tail. The curve and the marker MUST use the primary text colour and no other colour.

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

#### Scenario: The marker at the end of the tail
- **WHEN** the elapsed time is 1:02:15
- **THEN** the marker is at the end of the flat tail, in the same position as at 1:00:00

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

The urge screen MUST show the person's alternatives list under the wave. The screen MUST show each item as the person typed it, in the person's order. The screen MUST NOT show an example the person has not added. The screen MUST NOT rank, tick, colour or reorder an item.

Under the list, the screen MUST show one control, "Edit list", that opens the setup. When the list is empty, the screen MUST show one control, "Add an alternative", in the list's place. The screen MUST then also show "Edit list" under it. Each of the two controls MUST open the setup as a sheet over the urge screen. "Add an alternative" MUST open the setup with the keyboard in its add field. "The alternatives list setup" states the setup.

#### Scenario: The list is shown
- **WHEN** the person's list holds "Walk round the block", "Ring Sam" and "Shower" and the person taps "Urge"
- **THEN** the urge screen shows those three items in that order and no other item

#### Scenario: Empty list
- **WHEN** the person's list is empty and the person taps "Urge"
- **THEN** the urge screen shows "Add an alternative" in the list's place, then "Edit list"

#### Scenario: Edit from the urge screen
- **WHEN** the person taps "Edit list" while an urge is open
- **THEN** the setup opens, and the urge keeps its start moment

### Requirement: The alternatives list setup

The setup MUST be reachable from the "Alternatives list" row and from the urge screen. That row sits in the "Tools" group of the "Alternatives" stage screen. `programme` owns the stage screen, its "Tools" group and the stage title "Alternatives". From the "Tools" group, the app MUST push the setup onto the navigation stack, as the "Weigh-in" row pushes the weigh-in screen. From "Edit list" or "Add an alternative" on the urge screen, the setup MUST open as a sheet over the urge screen. That sheet MUST show "Close" in the leading position of its navigation bar. The setup's title MUST be "Alternatives list".

The list MUST hold at most 10 items. Each item MUST hold at most 80 characters of free text. The setup MUST show its parts in this order from the top:

- the items of the list, each as a field that the person can edit
- "Edit", under the last item, when the list holds two or more items
- the add field, with the label "Add an alternative" above it, and the control "Add" under it
- the heading "Examples", and the examples under it
- the control "Grounding exercise"
- the switch "Buzz at %lld minutes"

A tap on "Edit" MUST start edit mode. In edit mode the control MUST read "Stop editing", and a tap on it MUST end edit mode. A tap on "Add", or on Return in the add field, MUST add the typed text as an item. Then the add field MUST be empty. A tap on an example MUST add the example as an item. The app MUST add each new item, typed or from an example, at the end of the list.

The setup MUST offer at least six examples that the clinical reviewer signs off. The examples MUST be bundled text. `content` owns that sign-off. An added example MUST become the person's item. The person MUST be able to edit its text.

The person MUST be able to add, edit, reorder and delete an item at any time. In edit mode each item MUST show "Move up" and "Move down" as visible controls. Each item MUST offer "Move up" and "Move down" as VoiceOver actions. The setup MUST NOT need a drag to reorder. Each item MUST offer "Delete" as the system's swipe action and as a VoiceOver action.

The app MUST NOT add an item without a tap from the person. The app MUST NOT show a message about an item's content. The app MUST NOT require any item.

The setup MUST show a switch, "Buzz at %lld minutes", with URGE_TIMER_MINUTES in %lld. With the constant at 20 the label reads "Buzz at 20 minutes". The switch MUST be off by default. The timer requirement defines what the switch does.

The setup MUST NOT offer an example whose text equals the text of an item in the list. When the person deletes that item, the setup MUST offer the example again. An item MUST hold at least one character that is not a space. When the person clears the text of an item and leaves the field, the app MUST keep the item's earlier text.

Two devices can each add items, so a sync can give the list more than 10 items. The setup and the urge screen MUST then show every item. While the list holds 10 or more items, the setup MUST NOT show the add field, "Add" or the examples.

The setup is a full screen when it opens from the "Tools" group. It MUST show Get support in the trailing position of its navigation bar wherever it opens, also as a sheet over the urge screen. `safeguarding` owns the control in "Get support on every screen". When the setup opens from the urge screen, the urge stays open. When the person returns to the urge screen, the urge screen MUST show the list as the person left it in the setup.

When the app locks with unsaved text in the add field, the app MUST keep the text in memory. After the unlock, the add field MUST show the text as typed. `app-lock` states the same rule for the new-entry screen in "Unsaved text survives the lock".

#### Scenario: Get support on the setup
- **WHEN** the person opens "Alternatives list" from the "Tools" group, or taps "Edit list" on the urge screen
- **THEN** the setup shows Get support in the navigation bar

#### Scenario: Two ways to open the setup
- **WHEN** the person taps "Alternatives list" in the "Tools" group, and later taps "Edit list" on the urge screen
- **THEN** the first tap pushes the setup onto the navigation stack, and the second opens it as a sheet over the urge screen with "Close" in the leading position

#### Scenario: Back to the urge screen after an edit
- **WHEN** an urge is open, the person taps "Edit list", adds "Text Jo", and returns to the urge screen
- **THEN** the urge screen shows "Text Jo" at the end of the list, and the timer shows the time since the urge started

#### Scenario: An example already in the list
- **WHEN** the list holds "Go out for a walk"
- **THEN** the examples do not offer "Go out for a walk", and after the person deletes that item the examples offer it again

#### Scenario: An item cleared of its text
- **WHEN** the person clears the text of "Ring Sam" and leaves the field
- **THEN** the list still holds "Ring Sam"

#### Scenario: The setup's title
- **WHEN** the person taps "Alternatives list" in the "Tools" group of the "Alternatives" stage screen
- **THEN** the screen's title reads "Alternatives list"

#### Scenario: Add an example
- **WHEN** the person taps "Go out for a walk" in the examples
- **THEN** the list gains the item "Go out for a walk" at its end, and the person can change its text

#### Scenario: Add an own item
- **WHEN** the person types "Ring Sam" and adds it
- **THEN** the list gains the item "Ring Sam" as typed

#### Scenario: Reorder and delete
- **WHEN** the person moves "Shower" to the top and deletes "Ring Sam"
- **THEN** the list shows "Shower" first and no "Ring Sam", and the store keeps the "Ring Sam" row with `deleted = true`

#### Scenario: The edit control
- **WHEN** the list holds "Walk round the block", "Ring Sam" and "Shower", and the person taps "Edit"
- **THEN** each item shows "Move up" and "Move down", and the control reads "Stop editing"

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

#### Scenario: More than 10 items after a sync
- **WHEN** the list on device A holds 8 items, device B adds 3 items, and the person taps "Sync now" on both devices
- **THEN** the setup shows all 11 items, and shows no add field and no examples until the person deletes 2 items

#### Scenario: Empty list on leaving
- **WHEN** the person leaves the setup with no items
- **THEN** the app shows no message and the list stays empty

#### Scenario: Unsaved text through the lock
- **WHEN** the person types "Text Jo" in the add field, leaves the app for 45 seconds with "Lock after" at "30 seconds", and unlocks
- **THEN** the add field shows "Text Jo"

### Requirement: The grounding exercise

The urge screen MUST offer one grounding exercise below the alternatives list. The exercise MUST be the breathing exercise or the walk text. The setup MUST hold a control, "Grounding exercise", with the choices "Breathing" and "A walk". The default MUST be "Breathing".

The breathing exercise MUST start on one tap of "Breathe". While the exercise runs, the control MUST read "Stop". The shape MUST be a drawn circle in the primary text colour. It MUST NOT be a symbol, and it MUST NOT use the accent colour. The shape MUST grow for four seconds with the text "Breathe in". The shape MUST shrink for six seconds with the text "Breathe out". The four seconds, the six seconds and the two minutes are fixed design values, not constants.

The breathing exercise MUST repeat for two minutes or until the person taps "Stop". The shape MUST then return to its first size, and the breathing text MUST go. The control MUST read "Breathe" again. The app MUST show no message. When Reduce Motion is on, the shape MUST NOT scale. The app MUST then cross-fade "Breathe in" and "Breathe out" on the same timing. The alternatives list MUST come before the exercise at every text size.

While the breathing exercise runs, the app MUST keep the screen awake, so that Auto-Lock does not lock the device. When the exercise stops or the urge screen closes, the app MUST let the screen lock again. With VoiceOver on, the app MUST post "Breathe in" or "Breathe out" as an announcement at each change. The app MUST NOT play a haptic for the breathing exercise.

The walk text MUST read "If you can, leave the room and walk for ten minutes. If you can't leave, walk to the door and back, or stand at a window for two minutes." This text is a draft, and the clinical reviewer can change it before sign-off. It is signed text, so it can state its fixed durations in words, as `content` allows in "Catalogue rules". The exercise MUST show no other text. The urge screen MUST NOT show a card, a link to content or an explanation of urges other than the wave line.

#### Scenario: Breathing
- **WHEN** the exercise is "Breathing" and the person taps "Breathe"
- **THEN** the shape grows with "Breathe in" for four seconds, shrinks with "Breathe out" for six seconds, and repeats

#### Scenario: Stop breathing early
- **WHEN** the breathing exercise is running and the person taps "Stop"
- **THEN** the shape stops, the control reads "Breathe" again, and the app shows no message

#### Scenario: Two minutes of breathing
- **WHEN** the person taps "Breathe" at 21:12:00 and does not tap "Stop"
- **THEN** the exercise stops at 21:14:00, the control reads "Breathe" again, and the app shows no message

#### Scenario: The screen stays awake
- **WHEN** Auto-Lock is "30 seconds" and the person taps "Breathe" at 21:12:00
- **THEN** the device does not lock before 21:14:00, and from 21:14:00 the app lets the screen lock again

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
- **THEN** the screen holds the timer, the wave and its one line, the list or "Add an alternative", "Edit list", the exercise, the three outcome controls, "Close" and Get support, and nothing else

### Requirement: The urge outcome

The urge screen MUST show three controls from the start of the urge: "It passed", "I ate as planned" and "I binged". The three controls MUST be full-width buttons, stacked in that order, with 12 points between them. They MUST have the same size, weight and colour. They MUST sit below the scrolling content of the urge screen, pinned to its bottom edge. So they stay on screen at every scroll position of the urge screen.

A tap on "It passed" or "I ate as planned" MUST save an urge outcome. The app MUST write the outcome's code into the urge's row as `outcome`. The codes are `passed` for "It passed", `atePlanned` for "I ate as planned" and `binged` for "I binged". The labels are display text. The store MUST NOT hold a label as `outcome`. `outcomeAt` MUST be the moment of the tap. `outcomeDayKey` MUST be its record day. The app MUST then close the urge and show Today.

On save the app MUST NOT show a confirmation, a message, a sound or a haptic. On save the app MUST NOT show a colour change or an animation. The system's standard sheet dismissal is not an addition. The app MUST NOT ask a further question about the urge. The app MUST NOT let the person change a saved urge outcome. After the app saves an outcome, a tap on "Urge" MUST start a new urge.

#### Scenario: It passed
- **WHEN** the person taps "It passed" at 21:28 on an urge that started at 21:10
- **THEN** the store holds one urge with `startedAt` 21:10, `outcome` `passed` and `outcomeAt` 21:28, and Today shows with no message

#### Scenario: I ate as planned
- **WHEN** the person taps "I ate as planned" at 21:40 on an urge that started at 21:10
- **THEN** the store holds one urge with `startedAt` 21:10, `outcome` `atePlanned` and `outcomeAt` 21:40, and Today shows with no message

#### Scenario: Outcome controls while scrolled
- **WHEN** the person scrolls the urge screen to the end of a ten-item list
- **THEN** "It passed", "I ate as planned" and "I binged" stay on screen, stacked, with 12 points between them

#### Scenario: Early outcome
- **WHEN** the person taps "It passed" at 03:00 elapsed
- **THEN** the app saves the outcome and closes the urge without a question about the time

#### Scenario: New urge after an outcome
- **WHEN** the person saved an outcome at 21:28 and taps "Urge" at 23:05
- **THEN** the urge screen opens a new urge with the timer at "00:00"

### Requirement: "Close" keeps the urge open

The urge screen MUST have no navigation title. Its navigation bar MUST hold "Close" in the leading position and Get support in the trailing position, and nothing else. "Close" MUST be at least 44 points from any outcome control. "Close" MUST stay on screen at every scroll position.

The urge screen MUST show Get support from the start of the urge. A tap on Get support MUST open the support sheet over the urge screen. "Close" on the support sheet MUST return to the urge screen, and the urge stays open. `safeguarding` owns the control and the sheet, in "Get support on every screen" and "The support sheet". The sheet exemption of "Get support on every screen" MUST NOT apply to the urge screen. This follows Ash's ruling of 25 September 2026 on the side of Get support (r8-11, decision 94). That ruling already shows Get support on the urge screen, with "Close" in the leading position.

A tap on "Close" MUST take the urge screen off the screen and show Today. A swipe down that closes the urge screen MUST act as "Close". The urge MUST stay open with no outcome. While an urge is open and off the screen, Today MUST show one line, "Urge open since %@". The line is the catalogue entry "today.stateLine.urgeOpen". The app MUST fill %@ with the urge's `startedAt` as a 24-hour clock time. The time MUST come from the en_GB formatter, for example "Urge open since 22:40".

The line MUST be a control that returns to the urge screen with the elapsed time. `record` owns where the line sits in the Today stack.

Today MUST take the line off the screen when the app saves the urge's outcome. Today MUST take the line off the screen when the urge's record day ends. The line MUST NOT show the elapsed time, a count or any other text.

#### Scenario: Close the urge screen
- **WHEN** an urge started at 22:40 and the person taps "Close" at 22:47
- **THEN** Today shows "Urge open since 22:40", and the store holds the urge with no outcome

#### Scenario: A swipe down
- **WHEN** an urge started at 22:40 and the person swipes the urge screen down at 22:47
- **THEN** Today shows "Urge open since 22:40", and the store holds the urge with no outcome

#### Scenario: "Close" while scrolled
- **WHEN** the person scrolls the urge screen to the end of a ten-item list
- **THEN** "Close" stays in the leading navigation position, at least 44 points from any outcome control

#### Scenario: Get support on the urge screen
- **WHEN** the person taps "Urge" at 21:10
- **THEN** the urge screen shows no title, "Close" in the leading position and Get support in the trailing position of its navigation bar, and one tap on Get support opens the support sheet over the urge screen

#### Scenario: Close the support sheet
- **WHEN** an urge started at 21:10, the person taps Get support on the urge screen at 21:15, and then taps "Close" on the support sheet at 21:16
- **THEN** the urge screen shows that urge with the timer at "06:00", and the store holds the urge with no outcome

#### Scenario: A call from the support sheet
- **WHEN** the app lock is off, an urge started at 21:10 on Tuesday 13 October 2026, the person calls 116 123 from the support sheet over the urge screen and returns to the app at 21:40, and the system kept the app's process
- **THEN** the support sheet shows over the urge screen, and "Close" on the sheet at 21:40 shows the urge screen with the timer at "30:00"

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

A tap on "I binged" MUST open the new-entry screen as a sheet over the urge screen. `record` owns that screen. The time MUST be the moment of the tap. The star "felt like a binge" MUST be on. What MUST be empty with the keyboard in it. The person MUST be able to change the time, What and the star before saving.

When the person saves the entry, the store MUST save the entry and the urge outcome `binged` in one save. So the store never holds the entry without the outcome, or the outcome without the entry. The app MUST write the entry's id into the urge's `entryId`. `outcomeAt` MUST be the moment the person saves the entry. `outcomeDayKey` MUST be the record day of that moment. The app MUST then close the urge and show Today.

The new-entry screen MUST show nothing about the next planned meal. From the next time Today appears, Today MUST show the next-planned-meal line as `regular-eating-plan` defines it after a starred entry. The line follows the star of the saved entry, as "The next-planned-meal line" states. The app MUST NOT show any other message about the outcome.

Today MUST NOT show an opening card on a load in the same record day as the "I binged" outcome. That record day is the outcome's `outcomeDayKey`. Today's holds use the later of the latest starred entry moment and the latest "I binged" `outcomeAt`, as `record` states in "The Today stack". So the holds stay when the person turns the star off or moves the entry's time. `programme` owns the opening card and holds it until the next record day.

When the person cancels the new-entry screen, the app MUST save no entry and no outcome. The urge MUST then stay open. The urge screen MUST show again. A swipe down that closes the new-entry screen MUST act as "Cancel".

The requirement "An urge keeps its outcome when its entry changes" states what happens when the person later edits or deletes that entry.

#### Scenario: Save the entry
- **WHEN** the plan has Mid-afternoon at 16:00, and the person taps "I binged" at 14:45 and saves the entry with What "Crisps and cereal"
- **THEN** the store holds an entry at 14:45 with the star on, and the urge holds `outcome` `binged` and that entry's id in `entryId`, and Today shows "Mid-afternoon at 16:00 still happens." on the Mid-afternoon row

#### Scenario: Nothing on the new-entry screen
- **WHEN** the person taps "I binged" at 14:45 and the new-entry screen is open
- **THEN** the new-entry screen shows no line about the next planned meal

#### Scenario: The new-entry screen is pre-filled
- **WHEN** the person taps "I binged" at 21:35
- **THEN** the new-entry screen opens as a sheet over the urge screen and shows the time 21:35, the star on, an empty What and the keyboard in What

#### Scenario: Cancel the entry
- **WHEN** the person taps "I binged" and then taps "Cancel"
- **THEN** the store holds no new entry and no new outcome, and the urge screen shows the same urge

#### Scenario: A swipe down on the entry
- **WHEN** the person taps "I binged" and then swipes the new-entry screen down
- **THEN** the store holds no new entry and no new outcome, and the urge screen shows the same urge

#### Scenario: Change the time before saving
- **WHEN** the person taps "I binged" at 21:35 and sets the time to 21:20 before saving
- **THEN** the store holds an entry at 21:20 with the star on and an urge outcome `binged`

#### Scenario: The outcome moment is the save
- **WHEN** the day start is 04:00, and the person taps "I binged" at 03:58 on Friday 23 October 2026 and saves the entry at 04:03
- **THEN** the urge holds `outcomeAt` 04:03 and the `outcomeDayKey` Friday 23 October

#### Scenario: No opening card after "I binged"
- **WHEN** the person's first urge outcome is "I binged" at 21:35 on Thursday 24 September and Today loads at 21:36
- **THEN** Today shows no opening card for stage 4, and the card appears on a Today load on Friday 25 September at the earliest

#### Scenario: The star turned off before saving
- **WHEN** the person taps "I binged" at 21:35 on Thursday 24 September, turns the star off, saves the entry, and stage 4 opens with that outcome
- **THEN** Today shows no opening card for stage 4 on Thursday 24 September

### Requirement: The first urge outcome opens stage 4

The app MUST make every saved urge outcome available to `programme`. `programme` owns the opening rule of stage 4, its other route and what the person sees about progress. The first saved urge outcome of any kind MUST count for that opening. An urge with no outcome MUST NOT count. An urge that is still open at the end of its record day keeps no outcome, so it MUST NOT count. The urge screen MUST NOT show a message about the opening.

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

The app MUST compute the elapsed time from the saved start moment and the current moment. The timer MUST NOT reset when the app enters the background or closes. While the urge is open in the same record day, Today MUST show the "Urge open since" line. `record` defines the record day.

The person leaves the app when the app enters the background. The person can leave the app while the urge screen is on screen. When the person returns and the system kept the app's process, the app MUST show the urge screen again, as the person left it. The timer MUST then show the time from the saved start. With the app lock off, the urge screen stays on screen, and the app MUST NOT close it. With the app lock on, the rules of `app-lock` apply with no change. Inside the "Lock after" grace period, the urge screen shows at once. After the cover and a successful unlock, the urge screen shows as the screen that the cover hid. Ash ruled this on 12 October 2026 (r23-02).

In three cases the app MUST show Today and MUST NOT show the urge screen on a return:

- The system ended the app's process. The next launch shows Today, as `programme` states in "Today is home". Today then shows the "Urge open since" line.
- The person tapped "Close" before leaving. Today shows the "Urge open since" line.
- The record day of the urge ended while the app was in the background. The app MUST close the urge screen, also under the cover. The urge stays with no outcome, and the store MUST NOT write an outcome for it. The app shows no message.

An entry point can open the app while the app keeps the urge screen. The entry points are a widget, the App Intent, the Control Centre control and "Add" on a reminder, as `widgets-and-intents` states. The app MUST then close the urge screen as "Close" does, and open the new-entry screen. The urge stays open with no outcome. After Save or Cancel on the new-entry screen, Today MUST show the "Urge open since" line. With the app lock on, the rules of `app-lock` in "A new entry before authentication" apply with no change. So no part of the urge screen shows before authentication.

Apart from a return, the urge screen opens only from the "Urge" button and the "Urge open since" line on Today.

The urge screen is a sheet of Today. A tap on a reminder MUST NOT close the urge screen or a screen that the person opened from it. The app MUST open the screen of the reminder only after the urge screen closes, with "Close" or with an outcome. `reminders` states this rule in "A tap on a reminder opens its screen from Today". This follows Ash's rulings of 11 October 2026 on the sheets of Today (r22-02) and of 12 October 2026 on the urge screen (r23-02).

After an "I binged" outcome, the app MUST NOT open the screen of a reminder that waited for the urge screen. The app MUST drop that route and show Today. The line of that reminder on Today stays, for example the "Weekly review" line. This refines the rule above, as the after-binge rules for cards (r1-10) and for the pinned note (r8-07) do.

When the record day of an open urge ends, the app MUST keep the urge with no outcome. The store MUST NOT write an outcome, `outcomeAt` or `outcomeDayKey` for it. The app MUST NOT show that urge again. The app MUST NOT show a message about an urge that ended without an outcome.

The urge screen can be on screen while the record day of its urge ends, while the app stays in the foreground. The urge screen MUST then stay on screen. The person MUST be able to save an outcome for that urge. The app MUST write the record day of the tap as `outcomeDayKey`. After the urge screen goes off the screen, the app MUST NOT show that urge again.

On read, the app MUST treat at most one urge per record day as open. When two urges with no outcome share a `startDayKey`, for example after a sync, the open urge is the one with the earliest `startedAt`. The app MUST NOT show the other urges. After the day end, the app MUST treat every urge of that record day as not open, with no outcome and no message. The store MUST NOT write an outcome, `outcomeAt` or `outcomeDayKey` for such an urge. The app MUST NOT delete it.

The store MUST write `startDayKey` when the urge starts and `outcomeDayKey` when the app saves the outcome. Each key MUST come from the moment, its UTC offset and the day start in force at that moment, as `record` states for an entry. The app MUST NOT compute either key again, after a change of the device zone or of "Day starts at". The app MUST decide whether an urge is open in the current record day by its stored `startDayKey`.

#### Scenario: The day start changes after an urge
- **WHEN** the store holds an urge with `startedAt` 03:30 on Friday 25 September and `startDayKey` Thursday 24 September, and the person then sets "Day starts at" to 03:00
- **THEN** the urge keeps `startDayKey` Thursday 24 September

#### Scenario: The day ends while the urge screen is on screen
- **WHEN** the person tapped "Urge" at 03:50 on Friday 25 September with the day start 04:00, and taps "It passed" on the same urge screen at 04:10
- **THEN** the store holds the outcome `passed` with `startDayKey` Thursday 24 September and `outcomeDayKey` Friday 25 September, and Today shows no "Urge open since" line

#### Scenario: Return after a walk
- **WHEN** the app lock is off, the person tapped "Urge" at 21:10, left the app from the urge screen at 21:13 and returns at 21:52, and the system kept the app's process
- **THEN** the urge screen shows that urge with the timer at "42:00"

#### Scenario: Return inside the lock grace period
- **WHEN** "Lock after" is "5 minutes", the person tapped "Urge" at 21:10 on Tuesday 13 October 2026, left the app from the urge screen at 21:13 without locking the device, and returns at 21:16
- **THEN** the urge screen shows at once with the timer at "06:00", and the app makes no authentication request

#### Scenario: Return after the cover
- **WHEN** "Lock after" is "At once", the person tapped "Urge" at 21:10 on Tuesday 13 October 2026, left the app from the urge screen at 21:13, returns at 21:52 and Face ID succeeds
- **THEN** the cover shows first, and after the unlock the urge screen shows that urge with the timer at "42:00"

#### Scenario: Close before leaving
- **WHEN** the app lock is off, the person tapped "Urge" at 21:10 on Tuesday 13 October 2026, tapped "Close" at 21:12, left the app at 21:13 and returns at 21:52, and the system kept the app's process
- **THEN** the app shows Today with "Urge open since 21:10" and no urge screen

#### Scenario: The app closed
- **WHEN** the app lock is off, the person tapped "Urge" at 21:10, left the app from the urge screen, the system ended the app's process, and the person opens the app at 21:30
- **THEN** the app shows Today with "Urge open since 21:10" and no urge screen, and a tap on the line shows the timer at "20:00"

#### Scenario: Return in the same record day after midnight
- **WHEN** the person tapped "Urge" at 21:10 on Thursday 24 September, tapped "Close" at 21:15, and opens the app at 02:00 on Friday 25 September
- **THEN** Today shows "Urge open since 21:10", and a tap on the line shows the timer at "4:50:00"

#### Scenario: Two open urges on one record day
- **WHEN** device A started an urge at 21:10 and device B started one at 21:15, both with the `startDayKey` Thursday 24 September and no outcome, and the person taps "Sync now" on both devices
- **THEN** Today on each device shows "Urge open since 21:10", a tap on "Urge" shows the 21:10 urge, and the 21:15 urge closes at the day end with no outcome and no message

#### Scenario: Return the next day
- **WHEN** the app lock is off, the person tapped "Urge" at 21:10 on Thursday 24 September, left the app from the urge screen, and returns at 09:00 on Friday 25 September, and the system kept the app's process
- **THEN** the app shows Today with no urge screen and no "Urge open since" line, the store keeps the urge with no outcome, no `outcomeAt` and no `outcomeDayKey`, and the app shows nothing about it

#### Scenario: Return the next day with the app lock on
- **WHEN** "Lock after" is "At once", the person tapped "Urge" at 21:10 on Tuesday 13 October 2026, left the app from the urge screen at 21:13, returns at 09:00 on Wednesday 14 October and the unlock succeeds
- **THEN** Today shows after the unlock, with no urge screen and no "Urge open since" line, and the store keeps the urge with no outcome

#### Scenario: A reminder tap while the urge screen shows
- **WHEN** the urge screen shows an urge that started at 07:20 on Monday 19 October 2026, the person taps the body of the weigh-in day reminder at 07:31, and then taps "It passed"
- **THEN** the urge screen and its timer stay until "It passed", and after it the weigh-in screen shows on Today's navigation stack

#### Scenario: A reminder tap, then "I binged"
- **WHEN** the urge screen shows an urge that started at 17:50 on Monday 19 October 2026, the person taps the body of the weekly review reminder at 18:01, then taps "I binged" and saves the entry
- **THEN** Today shows with its "Weekly review" line, and the weekly review does not open

#### Scenario: A widget while the urge screen is kept
- **WHEN** the app lock is off, the urge screen shows an urge that started at 21:10 on Tuesday 13 October 2026, the person leaves the app at 21:13, taps the Home Screen widget at 21:20 and saves "Toast"
- **THEN** the app closed the urge screen and showed the new-entry screen, and after the save Today shows the entry and "Urge open since 21:10"

#### Scenario: "Add" on a reminder while the urge screen is kept
- **WHEN** "Lock after" is "At once", the urge screen shows an urge that started at 21:10 on Tuesday 13 October 2026, the person leaves the app at 21:13, taps "Add" on the Evening snack reminder at 21:20, taps "Cancel", and the unlock succeeds
- **THEN** the app showed the empty new-entry screen with no cover and no part of the urge screen, and after the unlock Today shows "Urge open since 21:10"

### Requirement: What the toolkit never shows

The app MUST show a count of urges or outcomes only in two places. The first is the weekly review's urge part. That part reads, for example, "Urges: 3. Passed: 2.", and `weekly-review` owns that text. The second is an urge pattern sentence on the Problem solving screen, on a suggestion card, or above step 1 of a worksheet linked to that sentence. That sentence reads, for example, "4 of your 6 urges were after 20:00.", and `problem-solving` owns it in "Pattern sentences from urges". Ash ruled this on 12 October 2026 (r23-09).

The "Urge" button, the urge screen and the setup MUST NOT show how many urges the person has had. The app MUST NOT show a list of past urges. The urge screen MUST NOT show an entry, a weight value or a planned meal. The app MUST NOT show praise, a word of blame or advice after any outcome. The tone rules in `product-rules` apply to every string in the toolkit.

The clinical text of the toolkit is signed text. It is the wave line, the walk text, "Breathe", "Stop", "Breathe in", "Breathe out", the three outcome labels, the setup's title and the heading "Examples". Each of these strings MUST be a catalogue key with the prefix "urge.". `content` lists that family in "Content versions". So a change to one of them needs a new content version and the clinical reviewer's sign-off. This follows rulings r13-01 and r17-03, which put clinical guidance under the sign-off.

#### Scenario: Urge button after many urges
- **WHEN** the person has saved twelve urge outcomes
- **THEN** the "Urge" button reads "Urge" and shows no number

#### Scenario: After "I binged"
- **WHEN** the person saves the entry after "I binged", and a next planned meal exists
- **THEN** Today shows the next-planned-meal line and no other text about the urge

#### Scenario: The weekly review
- **WHEN** the weekly review builds a week with three urges, two of which passed
- **THEN** the urge part of the weekly review reads "Urges: 3. Passed: 2.", and no other screen shows those numbers

#### Scenario: An urge pattern sentence
- **WHEN** stage 4 is open and the pattern window holds six urges, four of them after 20:00
- **THEN** the Problem solving screen shows "4 of your 6 urges were after 20:00.", and the "Urge" button, the urge screen and the setup show no count

### Requirement: The weekly review counts each urge on its start day

The app MUST give the weekly review each urge with its stored `startDayKey` and its outcome. `weekly-review` owns the urge part and its text. The weekly review MUST count an urge in the week that holds its `startDayKey`. The week of `outcomeDayKey` MUST NOT change the count. An urge with no outcome MUST count as an urge. It MUST NOT count as passed. The "Passed" count holds the urges of the week with the outcome "It passed".

The weekly review freezes its counts in the Review row, as `weekly-review` states in "The week's counts are frozen in the Review row". An outcome that the person saves after the freeze MUST NOT change the frozen counts. The review screen builds its summary from the record when it opens, so the scenarios below state the frozen counts of the Review row, not the text on the screen.

#### Scenario: An urge with no outcome
- **WHEN** week 3 holds one urge with the outcome "It passed" and one urge with no outcome
- **THEN** the urge part of the review of week 3 reads "Urges: 2. Passed: 1."

#### Scenario: An outcome on the next record day
- **WHEN** an urge has the `startDayKey` Sunday 11 October 2026, the last record day of week 3, and the outcome "It passed" at 04:10 on Monday 12 October, in the first record day of week 4
- **THEN** the Review row of week 3 counts the urge in its urge count, and the Review row of week 4 does not count the urge

#### Scenario: An outcome after the freeze
- **WHEN** the person tapped "Urge" at 03:50 on Monday 12 October 2026 with the `startDayKey` Sunday 11 October, the last record day of week 3, the app built the review of week 3 at 04:00 and froze the urge count 2 and the passed count 1, and the person taps "It passed" on the same urge screen at 04:10
- **THEN** the Review row of week 3 still holds the urge count 2 and the passed count 1

### Requirement: An urge keeps its outcome when its entry changes

An urge with the outcome "I binged" holds the id of its entry in `entryId`. The entry is an entry like any other. `record` owns how the person edits or deletes it. The urge MUST keep its outcome and its `entryId` when the person edits the entry, turns its star off, changes its time or deletes it. The app MUST NOT change an urge because of a change to its entry.

When `entryId` resolves to a deleted entry or to no entry, the app MUST show nothing about the urge or the entry. The app MUST NOT show a message, and it MUST NOT ask a question. The weekly review MUST count the urge as before. Stage 4 MUST stay open, as `programme` states in "The app keeps the stage state".

#### Scenario: The star turned off later
- **WHEN** the person saved "I binged" with an entry at 21:35, and the next morning turns the star of that entry off
- **THEN** the urge keeps the outcome `binged` and the same `entryId`, and the app shows no message

#### Scenario: The entry deleted later
- **WHEN** the person saved "I binged" with an entry at 21:35, then deletes that entry
- **THEN** Today and every count hide the entry, the urge keeps the outcome `binged`, the weekly review counts the urge, and the app shows no message

#### Scenario: The only outcome's entry deleted
- **WHEN** stage 4 opened from the person's first urge outcome "I binged", and the person deletes the entry of that outcome
- **THEN** stage 4 stays open

### Requirement: The store keeps urges and the list on the device

The store MUST keep each urge as one `Session` row with the fields `startedAt`, `utcOffsetSeconds`, `startDayKey`, `outcome`, `outcomeAt`, `outcomeDayKey`, `entryId` and `changedAt`. `startDayKey` is the record day of `startedAt`. `utcOffsetSeconds` is the UTC offset at `startedAt`, in seconds, as `ItemVersion.utcOffsetSeconds` holds the offset of an entry. The app MUST compute it from the device's current time zone rules when the urge starts, as `record` states for an entry's offset. The store MUST write it with `startedAt` and MUST NOT change it. `problem-solving` reads it for the time band of an urge. Ash ruled this on 12 October 2026 (r23-09).

`outcome`, `outcomeAt`, `outcomeDayKey` and `entryId` MUST be empty until the app saves an outcome. `outcome` holds a code that "The urge outcome" states. `entryId` MUST hold a value only for the outcome `binged`. The app MUST resolve `entryId` to its entry on read.

The store MUST keep the alternatives list, the grounding exercise choice and the "Buzz at 20 minutes" choice. The grounding exercise choice MUST be a synced `Settings` row. The "Buzz at 20 minutes" choice MUST stay on the device in `Local.store`, as explicit wording and Time Sensitive do. `data-and-privacy` names their keys and defaults in "What syncs and what stays on the device".

The store MUST keep each alternatives item as one `ListItem` row of kind "alternative". The row holds its text, its `position`, its `changedAt` and a `deleted` flag. `position` is the item's place in the list. The delete moment is `changedAt`. A delete MUST write `deleted = true` and a new `changedAt` into the row. The app MUST NOT hard-delete an urge or a list item.

The app MUST hide a deleted item on every read. An edit or a move MUST write into the winning row with a later `changedAt`. When two versions of a row share an id, the app keeps the version with the later `changedAt` on read. The app MUST order the list by `position`, then by `changedAt`, as `data-and-privacy` states. The app MUST NOT read a CKRecord system date for an urge or a list item.

Urges and the list MUST have the same file protection and backup exclusion as an entry. `record` sets those.

A save can fail, for example when the device has no free storage. The app MUST then show "Could not save. Try again." under the navigation bar, as `record` does in "A save that fails". The app MUST keep what the person did, as follows:

- When the save of an urge start fails, the urge screen MUST still open, with the timer from the moment of the tap. The app MUST keep that moment in memory. It MUST try the save again at the next tap on the urge screen.
- When the save of an outcome fails, the urge screen MUST stay open, and the urge stays open. A later tap on an outcome MUST try the save again.
- When the save of a list item fails, the setup MUST keep the typed text in its field.

An urge, an outcome or a list item MUST NOT leave the device. The one exception is the person's own iCloud private database. `data-and-privacy` owns sync and Delete-all.

The app MUST NOT write a list item to the system log, an error description or a crash report. The toolkit MUST work with no network.

#### Scenario: No network
- **WHEN** the device has no network connection and the person taps "Urge"
- **THEN** the timer, the wave, the list, the exercise and the outcome controls all work

#### Scenario: The start offset
- **WHEN** the person taps "Urge" at 21:10 on Saturday 24 October 2026 in London, and the clocks go back one hour at 02:00 on Sunday 25 October
- **THEN** the store holds the urge with `utcOffsetSeconds` 3600, the offset UTC+1, before and after the change

#### Scenario: Delete a list item
- **WHEN** the person deletes "Ring Sam" at 09:00
- **THEN** the store keeps the "Ring Sam" row with `deleted = true` and `changedAt` 09:00 as its delete moment, and the urge screen and the setup show no "Ring Sam"

#### Scenario: Edit a list item on two devices
- **WHEN** device A changes "Ring Sam" to "Ring Sam or Jo" at 09:00 and device B changes it to "Text Sam" at 09:02, and the person taps "Sync now" on both devices
- **THEN** both devices show "Text Sam", the version with the later `changedAt`, and one row for the item

#### Scenario: Store error
- **WHEN** the store fails to save the list item "Ring Sam"
- **THEN** the error the store throws contains no part of "Ring Sam"

#### Scenario: A failed start
- **WHEN** the store fails to save the start of an urge when the person taps "Urge" at 21:10, and saves it when the person taps "Close" at 21:12
- **THEN** the urge screen showed the timer from 21:10 with "Could not save. Try again.", and Today shows "Urge open since 21:10"

#### Scenario: A failed outcome save
- **WHEN** the store fails to save the outcome when the person taps "It passed" at 21:28
- **THEN** the urge screen stays with its timer and shows "Could not save. Try again.", the urge stays open, and a tap on "It passed" after the store recovers saves the outcome

#### Scenario: A failed list item save
- **WHEN** the store fails to save the new item "Text Jo"
- **THEN** the setup shows "Could not save. Try again." and keeps "Text Jo" in the add field

#### Scenario: Delete-all
- **WHEN** the person uses Delete-all
- **THEN** the store holds no urge, no outcome and no list item

### Requirement: Accessibility of the urge flow

Every control in the toolkit MUST have a VoiceOver label. The "Urge" button's label MUST be "Urge". The "Close" control's label MUST be "Close". The timer MUST be one accessibility element with the label "Elapsed time". The timer's value MUST be a duration text in en_GB with minutes and seconds and no comma, for example "12 minutes 40 seconds". From one hour, the value MUST also hold hours, for example "1 hour 2 minutes 15 seconds".

The timer MUST carry the updates-frequently trait. VoiceOver focus MUST NOT move when the timer or the wave changes. `record` owns Today's reading order. From stage 3, the "Urge" button is the first element of Today's content, after the navigation bar.

The urge screen's VoiceOver order MUST be:

- "Close" and Get support, in the navigation bar
- the timer, the wave and the wave line
- the items of the list, or "Add an alternative", then "Edit list"
- the exercise
- the three outcome controls, in their visible order

When the urge screen opens, VoiceOver focus MUST move to the timer.

The wave MUST be one accessibility element with the label "Urges rise, peak and fade". Before URGE_TIMER_MINUTES the wave's value MUST read as the elapsed minutes of URGE_TIMER_MINUTES, for example "12 minutes of 20". That value shows two counts, so it MUST come from strings with one count each, as `content` requires in "Catalogue rules". The value string is "%1$@ of %2$@". The app MUST fill %1$@ from "%lld minutes" with the elapsed minutes. The app MUST fill %2$@ from "%lld" with URGE_TIMER_MINUTES. Ash ruled the one-count rule on 26 September 2026 (r13-12). From URGE_TIMER_MINUTES the wave's value MUST be "%lld minutes" with the elapsed minutes filled in, for example "42 minutes".

The setup MUST follow the same rules. Each item, each example and each "Move up" and "Move down" action MUST have a VoiceOver label. The label of an example MUST start with the example's visible text. The VoiceOver label of a visible "Move up" or "Move down" control MUST be its text, then the item's text, for example "Move up Ring Sam". This follows Ash's ruling of 26 September 2026 (r13-08). The "Grounding exercise" control MUST read its chosen value, "Breathing" or "A walk".

Each list item MUST be one accessibility element that reads the item's text. The breathing text MUST be one accessibility element with the updates-frequently trait. Its value MUST be "Breathe in" or "Breathe out". With VoiceOver on, the app MUST post the new value as an announcement at each change, as "The grounding exercise" states. The app MUST NOT move VoiceOver focus for it.

The outcome controls' labels MUST be "It passed", "I ate as planned" and "I binged". The hit-area rule in `product-rules` applies to every control in the toolkit. The input labels of each control for Voice Control MUST start with its visible text. A control with no visible text MUST have a label a person can say with Voice Control. Meaning in the toolkit MUST NOT depend on colour. Text in the toolkit MUST use system text styles. Text in the toolkit MUST scale with Dynamic Type.

An automated test MUST prove each of these rules, because an accessibility check is never a device check. The app MUST post every announcement and every VoiceOver focus move of the toolkit through one poster that a test can replace. A test MUST prove that a timer tick posts nothing. Reduce Motion MUST be an input of the urge screen's value, `UrgeScreen`. The app reads it from the system, and a UI test sets it through a launch argument. The accessibility audits MUST run on the urge screen and on the setup at the largest text size (AX5). They MUST run in light mode, in dark mode and in dark mode with Increase Contrast.

#### Scenario: The whole flow with VoiceOver
- **WHEN** a UI test walks the accessibility tree of the urge flow in order: it taps "Urge", reads the timer and the list, starts the breathing exercise and taps "It passed"
- **THEN** each element on the way has a label, the elements come in the VoiceOver order that this requirement states, and the flow ends on Today

#### Scenario: The timer with VoiceOver
- **WHEN** a person using VoiceOver reaches the timer at 12:40 elapsed
- **THEN** VoiceOver reads "Elapsed time, 12 minutes 40 seconds"

#### Scenario: The wave with VoiceOver
- **WHEN** a person using VoiceOver reaches the wave at 12:40 elapsed
- **THEN** VoiceOver reads "Urges rise, peak and fade, 12 minutes of 20"

#### Scenario: Focus stays while the timer runs
- **WHEN** a test drives the urge screen with a poster that records, and the timer passes 12:00
- **THEN** the poster records no announcement and no focus move, so VoiceOver focus stays where it was, for example on "Ring Sam"

#### Scenario: The breathing text with VoiceOver
- **WHEN** VoiceOver is on, the breathing exercise runs, and the phase changes to "Breathe out"
- **THEN** the element's value changes to "Breathe out", and the app posts one announcement "Breathe out" and no focus move

#### Scenario: Voice Control
- **WHEN** a test reads the label and the input labels of each control on the urge screen
- **THEN** each of them starts with the control's visible text, for example "It passed", so "Tap It passed" in Voice Control saves the outcome

#### Scenario: The VoiceOver order of the urge screen
- **WHEN** the person's list holds "Ring Sam" and "Shower", the exercise is "Breathing", and the person taps "Urge" with VoiceOver on
- **THEN** VoiceOver focus moves to the timer, and the order is "Close", Get support, the timer, the wave, the wave line, "Ring Sam", "Shower", "Edit list", "Breathe", "It passed", "I ate as planned" and "I binged"

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the urge screen shows the timer, a wave at most 120 points tall, the list, the exercise, the three outcome controls and "Close" without truncation

#### Scenario: The wave value from one-count strings
- **WHEN** a test fills the wave value at 1:00 elapsed and at 12:40 elapsed with URGE_TIMER_MINUTES = 20
- **THEN** the value reads "1 minute of 20" and then "12 minutes of 20", and no string the app fills holds more than one count

#### Scenario: The setup at the largest text size
- **WHEN** the person sets the largest accessibility text size and opens the setup with nine items
- **THEN** the setup shows each item, the examples, "Buzz at 20 minutes" and "Grounding exercise" without truncation

#### Scenario: The grounding control with VoiceOver
- **WHEN** a person using VoiceOver reaches "Grounding exercise" with "A walk" chosen
- **THEN** VoiceOver reads "Grounding exercise" and the value "A walk"

#### Scenario: The label of a visible "Move up"
- **WHEN** the setup is in edit mode and VoiceOver focuses the visible "Move up" control of "Ring Sam"
- **THEN** VoiceOver reads "Move up Ring Sam"

#### Scenario: The accessibility audits
- **WHEN** the accessibility audits run on the urge screen and on the setup at AX5, in light mode, in dark mode and in dark mode with Increase Contrast
- **THEN** no audit reports clipped text, a Dynamic Type fault, a contrast fault or a hit-region fault
