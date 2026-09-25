# staying-on-track

## Purpose

Staying on track is the last stage. From week 10 the person writes a maintenance plan and finishes the programme when they choose. After the finish the app moves to a reduced cadence with check-ins at CHECK_IN_WEEKS = 4, 8 and 12 weeks. A lapse is a lapse: the app shows the maintenance plan and resets nothing. `programme` owns "Start week 1 again", which keeps the person's work; a check-in offers "Restart the programme?" as a shortcut to it.

## ADDED Requirements

### Requirement: The stage opens at week 10

The `programme` capability opens the stage's tools at WEEK_OF_STAYING_ON_TRACK = 10. `programme` counts that week from the record day on which stage 2 opens, not from the start day. The app MUST show the stage's cards before the stage opens, because the app never blocks reading ahead. The `content` capability owns the cards. From the opening, the staying on track screen MUST show the maintenance plan and the "Finish the programme" control. Before the opening the screen MUST NOT show either.

#### Scenario: Week 10 starts
- **WHEN** stage 2 opened on Monday 5 October and the current record day is Monday 7 December
- **THEN** the staying on track screen shows the cards, the maintenance plan and "Finish the programme"

#### Scenario: Counted from stage 2, not from the start day
- **WHEN** the start day is Monday 28 September, stage 2 opened on Monday 12 October and the current record day is Monday 7 December
- **THEN** the screen shows the cards and no maintenance plan and no "Finish the programme"

#### Scenario: Before the opening
- **WHEN** the person opens the staying on track screen in week 7
- **THEN** the screen shows the cards and no maintenance plan and no "Finish the programme"

#### Scenario: A person who reads ahead
- **WHEN** the person opens the staying on track screen in week 2
- **THEN** the app shows the cards in full and blocks nothing

### Requirement: The maintenance plan

The maintenance plan MUST have four questions, each with a free-text answer. The questions are "What helped most?", "What are your early warning signs?", "What will you do at the first slip?" and "Is there anyone you could tell, if you wanted to?". Every answer MUST be optional. Every answer MUST accept an empty text.

The app MUST let the person edit any answer at any time. The app MUST NOT show a placeholder, an example answer or a count of answered questions. The app MUST NOT show the plan as incomplete.

When the person taps "Save", the app MUST close the screen with the system's standard dismissal and show no message. The `content` capability owns the text of the four questions. The maintenance plan is one synced row with its own `changedAt`. An edit MUST write into the winning row. The `data-and-privacy` capability owns the conflict rule.

#### Scenario: Answer one question
- **WHEN** the person types "Eating breakfast even when I didn't want to" under "What helped most?" and saves
- **THEN** the maintenance plan shows that text under "What helped most?" and the other three questions with no text and no label about them

#### Scenario: Edit an answer
- **WHEN** the person opens "Is there anyone you could tell, if you wanted to?" and changes "Sam" to "Sam or my sister"
- **THEN** the maintenance plan shows "Sam or my sister" under "Is there anyone you could tell, if you wanted to?"

#### Scenario: Empty plan
- **WHEN** the person opens the maintenance plan with no answers
- **THEN** the screen shows the four questions and nothing about the absence of answers

#### Scenario: Save with all answers empty
- **WHEN** the person opens the maintenance plan, types nothing and saves
- **THEN** the screen closes with no message and the app draws no conclusion

### Requirement: The finish

The finish is the moment the person taps "Finish" on the finish screen. The app MUST offer "Finish the programme" on the staying on track screen from the stage opening. The finish MUST NOT depend on the maintenance plan having any answer. "Finish the programme" MUST open the finish screen.

The finish screen MUST show the text "Morning and evening reminders stop. The record stays. A check-in comes at %1$lld, %2$lld and %3$lld weeks." The three counts enter from CHECK_IN_WEEKS. The screen MUST ask "Keep the planned meal reminders?" with "Keep them" and "Turn them off".

The screen's confirm control MUST be "Finish" and its cancel control MUST be "Cancel". "Finish" MUST stay active. On a tap on "Finish" with the question unanswered, the app MUST move VoiceOver focus to the question. The app MUST then show "Please answer this one." under the question. The app MUST NOT set `finishDate` on that tap. The app MUST NOT show a badge, a certificate, a total, a count of weeks or praise at the finish.

On "Finish" the app MUST write the current record day to the `finishDate` Settings key. `record` computes the current record day from the device zone and the current day start. The app MUST keep the answer to the question as its own Settings key beside `finishDate`. A Settings key is one synced row (key, value, changedAt), and the app keeps the later `changedAt`, as `data-and-privacy` defines. The app MUST NOT write to any device reminder switch at the finish.

#### Scenario: Finish in week 10
- **WHEN** the person taps "Finish the programme" on Wednesday 9 December in week 10, picks "Keep them" and taps "Finish"
- **THEN** the app sets `finishDate` to Wednesday 9 December and moves to the reduced cadence with the planned meal reminders on

#### Scenario: Finish with an empty maintenance plan
- **WHEN** the person taps "Finish the programme" with no answer in the maintenance plan
- **THEN** the app opens the finish screen and shows no text about the maintenance plan

#### Scenario: Finish with the question unanswered
- **WHEN** the person taps "Finish" without answering "Keep the planned meal reminders?"
- **THEN** VoiceOver focus moves to the question, "Please answer this one." appears under it, and `finishDate` stays empty

#### Scenario: Cancel on the finish screen
- **WHEN** the person opens the finish screen and taps "Cancel"
- **THEN** nothing changes and `finishDate` stays empty

#### Scenario: The finish screen
- **WHEN** the finish screen appears
- **THEN** it shows the text above with 4, 8 and 12, the question, "Finish" and "Cancel", and no badge, certificate, total or praise

### Requirement: The week-13 card

At the start of week 13 with no finish, the app MUST show one card. The card sits in the Today card slot that `record` defines. The card is "Week %lld is done. Finish the programme?" with "Finish…" and "Close". The number is the programme's last week, 12, from `ProgrammeConstants`.

"Finish…" MUST open the finish screen. The `programme` capability counts week 13 from the start day. When the stage opens after week 13 begins, the app MUST show the card when the stage opens.

On "Finish…" or "Close" the app MUST write a card answer row in Record.store. The row holds the card id, the answer and the moment. `data-and-privacy` owns the row. When a card answer row for this card exists on any device, the app MUST NOT show the card.

While the first import after sync turns on is running, the app MUST NOT show the card. The card MUST NOT appear on a Today load that follows a starred entry in the same record day. The same applies after an "I binged" outcome. The card then waits for the next record day.

#### Scenario: Week 13 with no finish
- **WHEN** the start day is Monday 28 September, the stage is open and the current record day becomes Monday 21 December with no finish
- **THEN** the Today card slot shows "Week 12 is done. Finish the programme?" once, with "Finish…" and "Close"

#### Scenario: Close
- **WHEN** the person taps "Close" at week 13 and opens the app in week 15
- **THEN** Today shows no card about the finish and "Finish the programme" stays on the staying on track screen

#### Scenario: Answered on another device
- **WHEN** the person taps "Close" on one device and a second device syncs the card answer row
- **THEN** the second device shows no card about the finish

#### Scenario: A starred entry on the day the card is due
- **WHEN** the person saves a starred entry at 09:00 on Monday 21 December and opens Today at 09:05
- **THEN** the card slot shows no card about the finish, and the card appears from Tuesday 22 December

#### Scenario: The stage opens after week 13 begins
- **WHEN** the start day is Monday 28 September and stage 2 opened on Monday 26 October
- **THEN** Today shows no card on Monday 21 December, and the card appears on Monday 28 December when the stage opens

### Requirement: The reduced cadence

From the finish the app MUST move to the reduced cadence. The `reminders` capability owns every reminder type and its switch. In the reduced cadence the scheduler MUST NOT schedule the morning plan reminder or the midday reminder. The scheduler MUST NOT schedule the close-the-day reminder or the weigh-in day reminder. The scheduler MUST schedule the planned meal reminders only when the person's finish answer is "Keep them".

The weekly review MUST NOT become due after the finish. The scheduler MUST NOT schedule the weekly review reminder after the finish. The `weekly-review` capability owns when a review is due.

Each device MUST compute its effective reminders from its switches, `finishDate` and the Settings keys beside it. The app MUST NOT write to a device switch because of the finish. The settings screen MUST show each reminder type that the finish turns off as off. When the person turns one of them on, the app MUST keep that choice as a Settings key beside `finishDate`. Every device MUST then schedule that reminder type from that day.

The record, the plan, the Urge button and the weigh-in on its day MUST stay open. The worksheets, the modules and every card MUST stay open. The app MUST NOT end the reduced cadence. Only a restart by the person ends it.

#### Scenario: The morning after the finish
- **WHEN** the person finished on Wednesday 9 December and Thursday 10 December begins
- **THEN** the scheduler sends no morning plan reminder, no midday reminder and no close-the-day reminder

#### Scenario: A second device
- **WHEN** the person finished on one device and a second device on the same iCloud account syncs the `finishDate` key
- **THEN** the second device schedules no morning plan reminder, midday reminder or close-the-day reminder, and its switches are unchanged

#### Scenario: Turn the close-the-day reminder on again
- **WHEN** the person turns on the close-the-day reminder in the reduced cadence
- **THEN** the scheduler sends the close-the-day reminder at its usual time from that day, and the app does not write the device switch

#### Scenario: Planned meal reminders kept
- **WHEN** the person chose "Keep them" at the finish and the lunch planned meal is at 13:00
- **THEN** the scheduler sends the 13:00 reminder as before

#### Scenario: No weekly review after the finish
- **WHEN** the person finished on Wednesday 9 December and the next review day comes
- **THEN** no weekly review becomes due, the Today stack shows no "Weekly review" line, and the scheduler sends no weekly review reminder

#### Scenario: Weigh-in day in the reduced cadence
- **WHEN** the weigh-in day comes in the reduced cadence
- **THEN** the scheduler sends no weigh-in day reminder and the weigh-in screen accepts a weigh-in on that day

### Requirement: Check-ins at 4, 8 and 12 weeks after the finish

The app MUST schedule three check-ins, at CHECK_IN_WEEKS = 4, 8 and 12 weeks after `finishDate`. That is 28, 56 and 84 days. The store MUST key a check-in by the date key of its due day. That is `finishDate` plus 28, 56 or 84 days. A completed check-in is one synced row under that key with its own `changedAt`.

The app MUST NOT delete a check-in row. On read the app MUST ignore a check-in row with a date key later than the current record day. A check-in MUST open at the day start on its record day. A check-in MUST stay open until the person completes it or until the next check-in opens. The third check-in MUST stay open for 7 record days.

While a check-in is open, the Today stack that `record` defines MUST show one line, "Check-in", like the "Weekly review" line. A tap on the line MUST open the check-in.

A check-in reminder is a reminder type, "Check-in", that `reminders` owns. Its switch has the label "Check-in" and is on by default. The scheduler MUST schedule one check-in reminder per check-in, at the weekly review time on the check-in's record day. With explicit wording on, the reminder's title MUST be "Check-in". With explicit wording off, the reminder MUST use the discreet default text `reminders` defines. The reminder MUST respect quiet hours and the daily cap that `reminders` defines.

A check-in the person does not complete MUST get no second reminder. After the third check-in the app MUST schedule no further check-in.

#### Scenario: The three check-ins
- **WHEN** `finishDate` is Wednesday 9 December
- **THEN** the first check-in opens at 04:00 on Wednesday 6 January, the second on Wednesday 3 February and the third on Wednesday 3 March

#### Scenario: The Today line
- **WHEN** the first check-in is open and the person opens Today
- **THEN** the Today stack shows "Check-in" where `record` places the "Weekly review" line, and a tap opens the check-in

#### Scenario: One reminder
- **WHEN** the first check-in opens, the weekly review time is 18:00 and explicit wording is on
- **THEN** the scheduler sends one reminder titled "Check-in" at 18:00 on Wednesday 6 January and no other reminder for it

#### Scenario: The switch is off
- **WHEN** the person turns off "Check-in" in the settings screen
- **THEN** the scheduler schedules no check-in reminder, and the check-in still opens on its day with its Today line

#### Scenario: A missed check-in
- **WHEN** the person does not complete the first check-in by Wednesday 3 February
- **THEN** the app replaces it with the second check-in and shows no text about the first

#### Scenario: After the third check-in
- **WHEN** the person completes the third check-in on Wednesday 3 March
- **THEN** the app schedules no further check-in and no further check-in reminder

#### Scenario: Two finishes
- **WHEN** the person finished on Wednesday 9 December, restarted on Friday 15 January and finished again on Wednesday 7 April
- **THEN** the store keys the first check-in of the second finish Wednesday 5 May, the rows of the first run stay in the store, and the app ignores them on read

### Requirement: What a check-in asks

A check-in MUST show the summary, the three reflection questions and the self-harm item. The `weekly-review` capability owns the summary and the reflection questions. The summary MUST cover the 7 record days before the check-in. The summary MUST read each entry's stored record day key, as `record` defines.

The summary MUST NOT compare those days with any earlier week. The summary MUST NOT contain "last week". When the onboarding choice is "I won't be weighing", the check-in MUST leave out the weigh-in part. The `onboarding` capability owns that choice, and the choice syncs.

When those 7 record days have no entry, the summary MUST read "Starred entries: %lld." with 0. It MUST omit every other part. The `safeguarding` capability owns the self-harm item, its two steps and what follows each answer. The app MUST NOT turn off or cancel any reminder because of an answer to the self-harm item.

The store MUST keep only `selfHarmAnswered` for the check-in, never the answer. It is true with any answer, and false when the person completes the check-in with the item unanswered. The next check-in then asks again; `safeguarding` states that rule.

After the self-harm item, the check-in MUST ask "Restart the programme?" with "Restart" and "Not now". "Restart" is a shortcut to the "Start week 1 again" control that `programme` defines. The check-in MUST ask it only when there is no restart since the finish. The store MUST keep the latest restart moment as a Settings key. The restart MUST NOT clear that key. When that moment is later than `finishDate`, the check-in MUST omit the question.

"Done" MUST complete the check-in with any answer or none. The app MUST NOT move focus to an unanswered question or show a count of questions left. The check-in MUST NOT show a badge, a score or praise.

#### Scenario: A check-in with entries
- **WHEN** the person opens the first check-in with 4 recorded days in the last 7
- **THEN** the check-in shows the summary for those 7 days with no comparison to an earlier week, the three reflection questions, the self-harm item and "Restart the programme?"

#### Scenario: A check-in with no entries
- **WHEN** the person opens the first check-in with no entry in the last 7 record days
- **THEN** the check-in shows "Starred entries: 0." as the whole summary, then the questions, the self-harm item and "Restart the programme?"

#### Scenario: No weigh-in day chosen
- **WHEN** the person chose "I won't be weighing" at onboarding and opens the first check-in
- **THEN** the check-in shows the summary without its weigh-in part, the three reflection questions, the self-harm item and "Restart the programme?", and no text about weighing

#### Scenario: The self-harm item at a check-in
- **WHEN** the person answers "Yes" to the first step of the self-harm item and "No" to the second
- **THEN** the check-in shows the support sheet inline as `safeguarding` defines it, continues to "Restart the programme?", and the planned meal reminders stay on

#### Scenario: Self-harm Yes then Yes at a check-in
- **WHEN** the person answers "Yes" to the first step of the self-harm item and "Yes" to the second
- **THEN** the app shows the not-right-now page with the self-harm reason, as at a weekly review

#### Scenario: Not now
- **WHEN** the person taps "Not now" at the first check-in
- **THEN** the check-in closes, the reduced cadence continues and the second check-in stays scheduled

#### Scenario: Done with the self-harm item unanswered
- **WHEN** the person answers the reflection questions, leaves the self-harm item unanswered and taps "Done"
- **THEN** the check-in completes, its row holds `selfHarmAnswered: false`, and the next check-in asks the item

#### Scenario: Restart from a check-in
- **WHEN** the person taps "Restart" at the first check-in
- **THEN** the app opens the start-day choice that "Start week 1 again" opens, as `programme` defines, after the re-screen when the 84-record-day rule in `safeguarding` applies

#### Scenario: A restart since the finish
- **WHEN** a check-in opens and the store holds a restart moment later than `finishDate`
- **THEN** the check-in shows the summary, the questions and the self-harm item, and no "Restart the programme?"

#### Scenario: A finish after a restart
- **WHEN** the person restarted on Friday 15 January, finished again on Wednesday 7 April and the first check-in of that finish opens
- **THEN** the check-in asks "Restart the programme?"

### Requirement: What a restart does to the finish

`programme` owns the restart. That covers the "Start week 1 again" control on the Programme screen and the start-day choice with "Today", "Tomorrow" and "Cancel". It also covers what a restart keeps and how the engine treats the stage 5 opening after it. `safeguarding` owns the re-screen that runs more than 84 record days after the last screening. A check-in's "Restart" opens the same control. This capability states what a restart does to the finish and the check-ins, whichever way the person opens it.

The restart MUST keep the maintenance plan, the weigh-ins and every completed check-in row. The restart MUST write an empty value to the `finishDate` key and to each Settings key beside it. The restart MUST write the restart moment to its Settings key, before or after the finish. Every device keeps the later `changedAt`, so every device keeps the restart's writes over the finish's.

The app MUST NOT write to a device reminder switch at the restart. Each device MUST then compute its reminders from its own switches. The scheduler MUST cancel every pending check-in reminder. The app MUST close any open check-in.

#### Scenario: Restart after the finish
- **WHEN** the person finished on Wednesday 9 December, taps "Start week 1 again" on Friday 15 January and picks "Today"
- **THEN** the `finishDate` key is empty, the restart moment is Friday 15 January, the maintenance plan and the check-in rows are unchanged, and the new start day follows `programme`'s rule

#### Scenario: Cancel
- **WHEN** the person taps "Start week 1 again" after the finish and then "Cancel"
- **THEN** the start day, `finishDate` and the check-ins are unchanged, and the reduced cadence continues

#### Scenario: Reminders after a restart
- **WHEN** the switch for the morning plan reminder is on before the finish and the person restarts on Friday 15 January
- **THEN** the scheduler sends the morning plan reminder from the new start day, and the app never writes the switch

#### Scenario: An open check-in at the restart
- **WHEN** the first check-in is open with its reminder pending at 18:00 and the person restarts at 10:00
- **THEN** the check-in closes, the scheduler holds no check-in reminder, and the Today stack shows no "Check-in" line

#### Scenario: Restart before the finish
- **WHEN** the person taps "Start week 1 again" in week 8 with no finish and picks "Today"
- **THEN** the app writes the restart moment, `finishDate` stays empty and the app schedules no check-in

### Requirement: A lapse is a lapse

From the stage opening, a starred entry or the urge outcome "I binged" is a lapse. The rule is the same before and after the finish. The app MUST NOT show anything at the moment the person saves the entry or the outcome. The app MUST show one maintenance plan card in the Today card slot that `record` defines. The card MUST show "What will you do at the first slip?" with its answer first.

The card MUST offer "Open" and "Close". "Open" MUST open the maintenance plan. The lapse's record day MUST be the stored record day key of the starred entry or the urge outcome. The app MUST show the card from the time of the next planned meal on that record day.

When that record day has no later planned meal, the app MUST show the card from the next day start. The app MUST keep the card until the person answers it or the following record day ends. The app MUST show one card per lapse. While the card shows, a further lapse MUST NOT add a second card. The app MUST NOT send a notification about the lapse.

On "Open" or "Close" the app MUST write a card answer row in Record.store. The row holds the card id with the lapse's record day, the answer and the moment. `data-and-privacy` owns the row. When a card answer row for that lapse exists on any device, the app MUST NOT show the card. While the first import after sync turns on is running, the app MUST NOT show the card.

The app MUST NOT reset the start day, `finishDate` or the check-ins. The app MUST NOT reset the plan, the maintenance plan or any list. The app MUST NOT show the word "relapse", a count of lapses or any text about a run of days.

#### Scenario: A starred entry in the afternoon
- **WHEN** the person saves a starred entry at 14:10 on Tuesday 5 January and the next planned meal is Mid-afternoon at 16:00
- **THEN** the app shows nothing at 14:10, and from 16:00 the Today card slot shows the maintenance plan card with the first-slip answer first

#### Scenario: A starred entry late at night
- **WHEN** the person saves a starred entry at 23:00 on Tuesday 5 January with no later planned meal that record day
- **THEN** the Today card slot shows the maintenance plan card from 04:00 on Wednesday 6 January until the end of Thursday 7 January

#### Scenario: An "I binged" outcome before the finish
- **WHEN** the person saves the urge outcome "I binged" in week 11 with no finish
- **THEN** the app treats it as a lapse in the same way as a starred entry, and the stage state does not change

#### Scenario: A lapse with an empty first-slip answer
- **WHEN** the person saves a starred entry after the finish and "What will you do at the first slip?" has no answer
- **THEN** the card shows "What will you do at the first slip?" with no text, and no text about the empty answer

#### Scenario: Two lapses in one day
- **WHEN** the person saves starred entries at 14:10 and at 20:30 on Tuesday 5 January
- **THEN** the Today card slot shows one maintenance plan card, and the check-in dates do not change

#### Scenario: Open the card
- **WHEN** the person taps "Open" on the maintenance plan card on Tuesday 5 January
- **THEN** the maintenance plan opens, the app writes a card answer row for that lapse, and the card slot shows no maintenance plan card afterwards

#### Scenario: Answered on another device
- **WHEN** the person taps "Close" on the card on one device and a second device syncs the card answer row
- **THEN** the second device shows no maintenance plan card for that lapse

### Requirement: Stay in the reduced cadence without end

The app MUST let the person stay in the reduced cadence for any length of time. After the third check-in the app MUST NOT ask about the finish, the restart or the programme again. The app MUST keep the maintenance plan open at any later time. `programme` keeps "Start week 1 again" on the Programme screen at all times after onboarding. The app MUST NOT archive, hide or expire the record, the plan, the lists or the worksheets.

#### Scenario: A year later
- **WHEN** the person opens the app 52 weeks after the finish
- **THEN** the app shows the record, the plan, the maintenance plan and, on the Programme screen, "Start week 1 again", and asks nothing

#### Scenario: Restart a year later
- **WHEN** the person taps "Start week 1 again" 52 weeks after the finish and picks "Today"
- **THEN** the app runs the re-screening that `safeguarding` defines first, because more than 84 record days have passed since the last screening, then week 1 begins that day with the plan, the lists and the worksheets kept

### Requirement: The stage's data stays in the store

The app MUST keep the maintenance plan and the completed check-ins in Record.store as synced rows. The app MUST keep `finishDate`, the finish answers beside it and the restart moment as Settings keys. Every synced row of the stage carries its own `changedAt` and, where the person can delete it, a `deleted` flag with a moment. The app MUST NOT hard-delete any of them. The app MUST keep the card answer rows for the week-13 card and the maintenance plan card in Record.store.

`finishDate`, the keys beside it and the restart moment MUST sync as the `data-and-privacy` table says. The store MUST give them the record's protection. The app MUST NOT put maintenance plan text in a notification, a log or an error. The app MUST hide maintenance plan text when the app is not active.

The `data-and-privacy` capability owns sync to the person's private iCloud and Delete-all. Delete-all MUST delete the maintenance plan, `finishDate`, the keys beside it and the restart moment. Delete-all MUST also delete the card answer rows and the check-ins.

#### Scenario: App switcher
- **WHEN** the person opens the App Switcher while the maintenance plan is on screen
- **THEN** the app's snapshot shows no maintenance plan text

#### Scenario: No network
- **WHEN** the device has no network connection
- **THEN** the person can write the maintenance plan, finish, complete a check-in and restart

#### Scenario: Store error
- **WHEN** the store fails to save the answer "Sam or my sister"
- **THEN** the error the store throws contains no part of that text

#### Scenario: A finish and a restart on two devices
- **WHEN** one device finishes on Wednesday 9 December, a second device offline restarts on Thursday 10 December, and both sync
- **THEN** every device reads the `finishDate` key as empty and the restart moment as Thursday 10 December, because each device keeps the later `changedAt`

### Requirement: Accessibility of the stage

Every control in the stage MUST have a VoiceOver label. Every control MUST meet the hit-area rule that `product-rules` defines. This covers the staying on track screen, the finish screen, a check-in, the cards and the maintenance plan. Each maintenance plan question with its answer MUST be one accessibility element.

Its label MUST hold the question, then the answer when not empty, with a comma and a space between. Every text MUST scale with Dynamic Type. Meaning MUST NOT depend on colour alone.

#### Scenario: Label of an answered question
- **WHEN** VoiceOver reads "Is there anyone you could tell, if you wanted to?" with the answer "Sam or my sister"
- **THEN** it reads "Is there anyone you could tell, if you wanted to?, Sam or my sister"

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the maintenance plan, the finish screen and a check-in show all text without truncation
