# weekly-review

## Purpose

The weekly review is the app's plain account of the week, built from the record, followed by the person's own reflection. Every seven days from the start day the app builds one review. In week WEEK_OF_TAKING_STOCK, counted from the record day stage 2 opened, the review grows into taking stock. The review states what happened and what changed, and never a score.

## ADDED Requirements

### Requirement: When a weekly review is due

The `programme` capability owns week counting. This spec uses its result: week n starts on the start day plus 7 × (n − 1) days and holds seven record days. The review of week n MUST become due at the first day start of week n + 1. The review of week n MUST stay due until the review of week n + 1 becomes due.

While a review is due and not finished, Today MUST show the line "Weekly review". The line sits in the Today stack that `record` defines. A tap on that line MUST open the review.

The `reminders` capability owns the weekly review reminder. Once the next review is due, the app MUST NOT show text about an unfinished earlier review. After the finish that `staying-on-track` defines, a review MUST NOT become due. The `staying-on-track` capability owns the reduced cadence and the check-ins after the finish. Every part of the review MUST work with no network.

#### Scenario: The first review
- **WHEN** the start day is Monday 28 September
- **THEN** the review of week 1 becomes due at 04:00 on Monday 5 October and covers Monday 28 September to Sunday 4 October

#### Scenario: Today while a review is due
- **WHEN** the review of week 1 is due and not finished and the person opens Today
- **THEN** Today shows the line "Weekly review" in the Today stack

#### Scenario: A review left unfinished
- **WHEN** the person does not finish the review of week 1 and the review of week 2 becomes due
- **THEN** Today shows "Weekly review" for week 2 and no text about week 1

#### Scenario: After the finish
- **WHEN** the person finished the programme on Wednesday 2 December and Monday 7 December begins
- **THEN** no review becomes due and Today shows no "Weekly review" line

#### Scenario: No network
- **WHEN** the device has no network connection
- **THEN** the app builds the review and saves the person's answers

### Requirement: Finish and reopen a review

The review MUST have a "Done" control that stays active at all times. Every part of the review MUST be optional. "Done" MUST save the review. "Done" MUST then close it with the system's standard dismissal.

"Done" MUST work with any answer to the self-harm item and with none. The self-harm requirement states what the store keeps when the item has no answer, and that the app asks it again. The app MUST NOT show a message, a sound, a haptic or an animation on "Done". The person MUST be able to reopen and edit a finished review until the next review becomes due.

The app MUST offer a "Reviews" list of finished reviews, newest first. The `programme` capability places the list one tap from Today. Each row MUST read "Week %1$lld, %2$@. Starred entries: %3$lld." The second placeholder is the week's date range from the en_GB interval formatter. The third is the frozen starred count from the Review row, for example "Week 3, 12–18 October. Starred entries: 4." With "Weekly summary" off, each row MUST read "Week %1$lld, %2$@" only.

The list MUST NOT show an arrow, a colour, a total or a comparison between rows. A row MUST open the review for reading. Each review has its own due day as its key, so after a restart the list can show two runs.

The app MUST save every review in the store on the device. Every Review row MUST carry its own changedAt. The `data-and-privacy` capability owns sync to the person's iCloud private database and Delete-all.

The app MUST NOT put a review answer in the system log or an error. The app MUST NOT put a review answer in a crash report. When the app is not active, the review MUST hide its text.

#### Scenario: Done with empty answers
- **WHEN** the person answers the self-harm item "No", leaves every other field empty and taps "Done"
- **THEN** the review closes as any sheet closes, with no message about the empty fields

#### Scenario: Edit before the next review
- **WHEN** the person finished the review of week 1 on Monday and opens it again on Wednesday
- **THEN** the review shows the saved answers and lets the person edit them

#### Scenario: The Reviews list
- **WHEN** the person finished the reviews of weeks 1, 2 and 3, with frozen starred counts of 5, 6 and 4
- **THEN** the "Reviews" list shows "Week 3, 12–18 October. Starred entries: 4.", then week 2, then week 1, each with its dates and its frozen count, and no arrow, colour, total or comparison

#### Scenario: The Reviews list with the summary off
- **WHEN** "Weekly summary" is off and the person opens the "Reviews" list
- **THEN** each row shows its week and dates only, with no starred count

#### Scenario: Store error
- **WHEN** the store fails to save a review with the answer "Evenings were hard"
- **THEN** the error the store throws contains no part of "Evenings were hard"

### Requirement: The summary built from the record

The review of week n MUST open with a summary, one plain sentence per part. The parts MUST follow the order this requirement gives. The parts are: days with an entry, starred entries, planned meals, paused days, the longest gap, urges, the weigh-in and the person's words.

The app MUST count an entry in the week of its saved record day key. The store writes that key with the entry at save, and the `record` capability owns it. The app MUST NOT compute an entry's record day again at review time. A day state row and a weigh-in row keep the key the store wrote when it created them. The review MUST read that key.

Every count in a summary string MUST enter through a %lld placeholder with the plural forms that `content` defines. Every duration, weekday and time MUST enter through a %@ placeholder from the en_GB formatter. The `content` capability owns the catalogue rules.

The days part MUST read "Days with an entry: %lld.". The count is the number of record days in week n with at least one entry. A "didn't record" day with an entry counts. Every review MUST open with the days part, before the starred part. The days part is a count of days, not of entries.

The starred part MUST read "Starred entries: %1$lld this week, %2$lld last week." with the starred counts of week n and week n − 1. In the review of week 1, the starred part MUST read "Starred entries: %lld this week."

The plan part MUST read "Planned meals with an entry beside them: %lld." The number is the planned meals of week n with an entry beside them. The app MUST NOT show the total of planned meals in the plan part. The app MUST NOT show a count of skipped planned meals. The `regular-eating-plan` capability owns the plan beside the record and the "Skipped" answer. The `problem-solving` capability reads that answer for its missed-slot groups. When week n has no planned day, the app MUST leave the plan part out.

The paused part MUST read "Paused days: %lld." with the count of record days in week n with the state "paused". The `record` capability owns that state. When week n has no paused day, the app MUST leave the paused part out.

The longest gap on a recorded day is the longest time between two consecutive entries, by entry time. The app MUST group entries into days by their saved record day key. The gap part MUST read "Longest gap between entries: %1$@, on %2$@, from %3$@ to %4$@." for the largest such gap in week n. The placeholders are the duration, the weekday name and the two entry times, each from the en_GB formatter. When no recorded day in week n counts a gap, the app MUST leave the gap part out.

The app MUST leave out a record day the person set as "didn't record". The app MUST leave out a record day with the state fasting. A fasting day counts no gap. The app MUST leave out a record day with fewer than two entries. The `record` capability owns the "didn't record" state and the fasting state.

The urge part MUST read "Urges: %1$lld. Passed: %2$lld." The first number is the count of urges in week n. The second is the count with the outcome "It passed". The `urge-toolkit` capability owns urges and urge outcomes. When week n has no urge, the app MUST leave the urge part out.

The weigh-in part MUST read "Weigh-in: done on %@." with the weekday name from the en_GB formatter. When week n has no done weigh-in, the app MUST leave the weigh-in part out. The review MUST NOT state that no weigh-in happened. The app MUST NOT show a weight value in the review. The `weigh-in` capability owns the weigh-in.

When the person chose "I won't be weighing", the app MUST leave the weigh-in part out. The part MUST stay out of every review and check-in until the person chooses a weigh-in day. The `onboarding` capability owns that choice.

The words part MUST read "Your words this week: %@." The placeholder holds the close-the-day words of week n in record day order. The app joins them with a comma and a space. The `reminders` capability owns the close-the-day screen and its word. The app MUST NOT add, reorder or change a word. A day with an empty word adds nothing. When week n has no close-the-day word, the app MUST leave the words part out.

At a check-in, the summary MUST cover the 7 record days before the check-in. At a check-in, the starred part MUST take the form of the week 1 review, with no last-week count. The `staying-on-track` capability owns the check-in and its window. When that window holds no entry, the summary MUST follow `staying-on-track`: "Starred entries: 0." and no other part.

#### Scenario: A full week
- **WHEN** week 3 has 6 days with an entry, 4 starred entries, week 2 had 6, 26 of 30 planned meals had an entry beside them, Thursday was paused, the longest gap was 12:40 to 19:00 on Tuesday, 3 urges of which 2 passed, the weigh-in was on Wednesday, and the close-the-day words were "tired", "ok" and "flat"
- **THEN** the review shows "Days with an entry: 6.", "Starred entries: 4 this week, 6 last week.", "Planned meals with an entry beside them: 26.", "Paused days: 1.", "Longest gap between entries: 6 hours 20 minutes, on Tuesday, from 12:40 to 19:00.", "Urges: 3. Passed: 2.", "Weigh-in: done on Wednesday." and "Your words this week: tired, ok, flat.", in that order

#### Scenario: The first review
- **WHEN** week 1 has 4 days with an entry, 5 starred entries, no plan, no paused day, no urge, no weigh-in and no close-the-day word
- **THEN** the review shows "Days with an entry: 4." and "Starred entries: 5 this week.", and no plan, paused, urge, weigh-in or words part

#### Scenario: A skipped planned meal
- **WHEN** week 3 has 30 planned meals, 27 with an entry beside them, and lunch on Tuesday has the answer "Skipped"
- **THEN** the plan part reads "Planned meals with an entry beside them: 27." and shows no "of 30" and no skipped count

#### Scenario: Words in the person's order
- **WHEN** the close-the-day words of week 2 are "flat" on Monday, nothing on Tuesday to Saturday, and "Better" on Sunday
- **THEN** the words part reads "Your words this week: flat, Better." with the words as typed

#### Scenario: An entry after midnight
- **WHEN** week 1 runs from Monday 28 September to Sunday 4 October, and an entry saved at 01:30 on Monday 5 October carries the record day key Sunday 4 October
- **THEN** the review of week 1 counts that entry and the review of week 2 does not

#### Scenario: A "didn't record" day
- **WHEN** Thursday has the "didn't record" state and has one entry at 08:00 and one at 20:00
- **THEN** the app leaves Thursday out of the longest gap

#### Scenario: A fasting day
- **WHEN** Wednesday has the state fasting and has one entry at 08:00 and one at 20:00
- **THEN** the app leaves Wednesday out of the longest gap and shows no text about the fasting day

#### Scenario: I won't be weighing
- **WHEN** the person chose "I won't be weighing" at onboarding and opens the review of week 2, then the check-in of week 4
- **THEN** neither summary shows a weigh-in part, and neither shows text about weighing

#### Scenario: Zero starred entries
- **WHEN** week 4 has no starred entries and week 3 had 2
- **THEN** the review shows "Starred entries: 0 this week, 2 last week." and no other word about it

#### Scenario: A check-in
- **WHEN** the person opens a check-in with 4 starred entries in the 7 record days before it
- **THEN** the summary shows "Starred entries: 4 this week." and no last-week count

#### Scenario: A check-in with no entries
- **WHEN** the person opens a check-in and the 7 record days before it hold no entry
- **THEN** the summary shows "Starred entries: 0." and no plan, gap, urge or weigh-in part, as `staying-on-track` defines

### Requirement: The week's counts are frozen in the Review row

The natural key of a review is the date key of its due day, the start day plus 7n. The app MUST NOT key a review by its week number. The `data-and-privacy` capability owns the Review row, its sync and the winning row rule.

When the app first builds the review of week n, it MUST write the week's counts. It MUST write them into the Review row for that key. The counts are the days-with-an-entry count, the starred count, the plan count, the paused-days count and the two urge counts. The "Reviews" list reads the frozen starred count for its rows.

After that moment the counts in the row MUST NOT change. An entry the person edits or deletes later MUST NOT change the row. The `safeguarding` capability reads the frozen starred counts for the deterioration rule. The app MUST write the counts whether or not the person opens the review.

The app MUST freeze the review of week n only after its due moment by the device clock. A device with sync on MUST also wait until its last sync moment is later than the due moment. The `data-and-privacy` capability owns the last sync moment. The Review row MUST carry its freeze moment. When one key has more than one row, the app MUST read the row with the earliest freeze moment. Every edit to the review MUST write into that row.

A Review row whose due moment or freeze moment is later than the device clock is future-dated. The app MUST ignore a future-dated row on read. The app MUST NOT delete a row because of the device clock.

When the device clock moves back past a frozen review's due moment, that row is future-dated until the clock passes the due moment again. The app MUST build the row again when the review becomes due. On read, the app MUST keep the row with the earliest freeze moment. The `programme` and `data-and-privacy` capabilities state the same guard for saved openings and check-in dates.

#### Scenario: An entry deleted after the review is built
- **WHEN** the review of week 3 holds a starred count of 6 and the person deletes a starred entry from week 3
- **THEN** the Review row for week 3 keeps 6

#### Scenario: A review the person never opens
- **WHEN** the review of week 2 becomes due and the person never opens it
- **THEN** the Review row for week 2 holds the starred count of week 2

#### Scenario: The device clock moves back
- **WHEN** the Review row for week 3 is frozen and the device clock moves back to Wednesday 14 October, before the review of week 3 became due
- **THEN** the app ignores the row for week 3 on read, does not delete it, and builds the row again at 04:00 on Monday 19 October; on read, the app keeps the row with the earliest freeze moment

#### Scenario: A row with a due moment far ahead
- **WHEN** the device clock reads Monday 12 October and the store holds a Review row with a due moment of Monday 2 November
- **THEN** the app ignores the row on read and does not delete it

#### Scenario: Sync behind the due moment
- **WHEN** sync is on, the review of week 3 becomes due at 04:00 on Monday 19 October, and the device's last sync moment is 22:00 on Sunday 18 October
- **THEN** the device does not freeze the review until a sync completes after 04:00 on Monday 19 October

#### Scenario: Two devices freeze the same review
- **WHEN** two devices freeze the review due on Monday 19 October, one at 04:00 and one at 09:00, and the rows sync
- **THEN** the app keeps the row frozen at 04:00 on read, and an edit to the review on either device writes into that row

#### Scenario: Keyed by the due day
- **WHEN** the person restarts the programme on Monday 4 January and the store holds the first run's Review rows
- **THEN** the store keeps the first run's rows, the second run's reviews use their own due-day keys, and the "Reviews" list can show both runs

### Requirement: The deterioration rule at the review

At each review the app MUST apply the deterioration rule to the frozen starred counts of the last four weeks. The `safeguarding` capability defines the rule and DETERIORATION_WEEKS = 3. The rule fires when each of the last three counts exceeds the count before it. The latest count MUST also be at least 4 and at least twice the first of the four.

When the rule fires, the app MUST show the GP suggestion page that `safeguarding` defines. The plan and its reminders MUST stay on. The app MUST show the page at most once per review.

#### Scenario: Three rising weeks
- **WHEN** the frozen starred counts of weeks 2 to 5 are 2, 3, 4 and 5 and the person opens the review of week 5
- **THEN** the app shows the GP suggestion page once, and the plan and its reminders stay on

#### Scenario: Rising but small
- **WHEN** the frozen starred counts of weeks 2 to 5 are 0, 1, 2 and 3
- **THEN** the app shows no GP suggestion page

#### Scenario: Rising but not doubled
- **WHEN** the frozen starred counts of weeks 2 to 5 are 4, 5, 6 and 7
- **THEN** the app shows no GP suggestion page

### Requirement: The weekly summary is opt-out

The app MUST offer a switch named "Weekly summary" in the settings screen, on by default. The `product-rules` capability states the "The person can put it down" rule. When the switch is off, the review MUST show no summary part. When the switch is off, the reflection questions and the one thing to change MUST stay as they are. The self-harm item and "I'm getting worse" MUST also stay as they are.

When the switch is off, the app MUST still write the week's counts into the Review row. When the switch is off, the "Reviews" list rows MUST show week and dates only. When the person turns the switch on again, the next review MUST show the summary.

#### Scenario: Switch off
- **WHEN** the person turns "Weekly summary" off and opens the review of week 3
- **THEN** the review opens with "What did you notice this week?" and shows no summary part

#### Scenario: Switch off, safeguarding still counts
- **WHEN** "Weekly summary" is off and week 3 has 6 starred entries
- **THEN** the Review row for week 3 holds 6 as the starred count

#### Scenario: Switch on again
- **WHEN** the person turns "Weekly summary" on and opens the review of week 4
- **THEN** the review opens with the summary

### Requirement: Three reflection questions

After the summary the review MUST ask three questions, in this order: "What did you notice this week?", "What made things harder?" and "What helped?" Each question MUST have one free-text field. The app MUST NOT show a placeholder in a field. The app MUST ask the same three questions every week. The app MUST take the questions from bundled text that the clinical reviewer signed off. The app MUST save the answers with the review.

#### Scenario: The three questions
- **WHEN** the person opens the review of week 2 with "Weekly summary" on
- **THEN** the review shows the summary, then "What did you notice this week?", "What made things harder?" and "What helped?", each with an empty field

#### Scenario: Answer one question
- **WHEN** the person types "Evenings were hard" under "What made things harder?" and taps "Done"
- **THEN** the store keeps "Evenings were hard" with the review of week 2 and the other two answers empty

#### Scenario: Same questions each week
- **WHEN** the person opens the review of week 5
- **THEN** the review asks the same three questions as the review of week 2

### Requirement: The one thing to change and the pinned note

After the reflection questions the review MUST ask "What's the one thing to change next week?" with one free-text field. The pinned note is the text of that field. Today shows it as the person's own text. The pinned note is not a message from the app. When the person taps "Done" with text in that field, Today MUST show the text as the pinned note.

Today MUST show the pinned note in the place the Today stack that `record` defines gives it. Today MUST show it in the same text style as an entry's What. Today MUST show a pin glyph in the text colour beside it. The app MUST NOT add a label, a colour or any other word to the pinned note.

The pinned note MUST stay on Today until the person taps "Done" on the next review. The next review's field MUST start empty. When the next review's field has text on "Done", that text MUST replace the pinned note. When the next review's field is empty on "Done", Today MUST show no pinned note. A tap on the pinned note MUST open its text for editing. When the person clears the text, Today MUST show no pinned note.

The app MUST NOT ask whether the person did the one thing. When the app is not active, Today MUST hide the pinned note.

#### Scenario: A pinned note appears
- **WHEN** the person types "Eat lunch at work" in the one thing field and taps "Done"
- **THEN** Today shows "Eat lunch at work" with a pin glyph, in the pinned note's place in the Today stack

#### Scenario: The next review replaces it
- **WHEN** the pinned note is "Eat lunch at work" and the person taps "Done" on the next review with "Plan the evening snack" in the field
- **THEN** Today shows "Plan the evening snack" and not "Eat lunch at work"

#### Scenario: The next review leaves it empty
- **WHEN** the pinned note is "Eat lunch at work" and the person taps "Done" on the next review with the field empty
- **THEN** Today shows no pinned note

#### Scenario: Edit from Today
- **WHEN** the person taps the pinned note, changes it to "Eat lunch by 13:00" and closes it
- **THEN** Today shows "Eat lunch by 13:00"

### Requirement: The self-harm item at the review

Every review MUST ask the self-harm item in two steps. The `safeguarding` capability owns the wording and what follows each answer. This spec places the item. Step 1 MUST ask "Over the last two weeks, have you had thoughts that you'd be better off dead, or of hurting yourself?" Step 1 MUST offer the answers "No", "Yes" and "I'd rather not say". When the person answers "Yes" at step 1, the app MUST ask step 2 with the wording that `safeguarding` defines. Step 2 MUST offer the answers "No" and "Yes".

When step 1 is "No" or "I'd rather not say", the review MUST continue with no other response. When step 1 is "Yes" and step 2 is "No", the app MUST show the support sheet inline. The inline sheet MUST open with "That deserves a person. Samaritans are there any time, on 116 123." The review MUST then continue. When step 2 is "Yes", the app MUST save the review's other answers. The app MUST then show the not-right-now page. The `safeguarding` capability owns the support sheet and the not-right-now page.

"Done" MUST stay active with any answer and with no answer. When the person taps "Done" with step 1 unanswered, the app MUST save and close the review. The flow is the same as with an answer. The app MUST show no message about the item. The store MUST keep `selfHarmAnswered: false` for the review. When the person opens that review again, or the next review, the app MUST ask the item again.

When step 1 has an answer, the store MUST keep `selfHarmAnswered: true` for the review. The store MUST NOT keep the answer to either step. The app MUST NOT cancel, pause or turn off a reminder because of any answer to this item. The `reminders` capability owns the switches that pause reminders.

When the person reopens a finished review that holds `selfHarmAnswered: true`, the app MUST NOT ask the item again. The review MUST show the item as answered. `staying-on-track` places the same item, as this requirement defines it, in every check-in.

#### Scenario: Answer No
- **WHEN** the person answers step 1 "No" and taps "Done"
- **THEN** the review closes as any sheet closes, and the store keeps `selfHarmAnswered: true` and no answer

#### Scenario: I'd rather not say
- **WHEN** the person answers step 1 "I'd rather not say"
- **THEN** the review continues, "Done" is available, and the app shows no other response

#### Scenario: Yes, then No
- **WHEN** the person answers step 1 "Yes" and step 2 "No"
- **THEN** the app shows the support sheet inline, opening with "That deserves a person. Samaritans are there any time, on 116 123.", the review continues, "Done" is available and every reminder stays as it was

#### Scenario: Yes, then Yes
- **WHEN** the person types "Evenings were hard" under "What made things harder?", answers step 1 "Yes" and step 2 "Yes"
- **THEN** the store keeps "Evenings were hard" with the review, the app shows the not-right-now page, and every reminder stays as it was

#### Scenario: Done with no answer
- **WHEN** the person has not answered step 1 and taps "Done"
- **THEN** the review saves and closes as any sheet closes, with no message, and the store keeps `selfHarmAnswered: false`

#### Scenario: Asked again
- **WHEN** the review of week 2 holds `selfHarmAnswered: false` and the person opens the review of week 2 again, or the review of week 3
- **THEN** the review asks step 1 again

### Requirement: "I'm getting worse"

Every review MUST show a button labelled "I'm getting worse" after the self-harm item. The button MUST be optional. The app MUST NOT show it as a switch, or as a question with a "No" answer. The app MUST NOT add a line that explains the button or asks why.

When the person taps the button, the app MUST act at once. The app MUST save the review's answers so far. The app MUST then show the GP suggestion page that `safeguarding` defines.

The page's control is "Done". The plan and its reminders MUST stay on. When the page closes, the review MUST show again with its answers. The `safeguarding` capability owns the page, the GP paragraph and the export offer.

#### Scenario: Tap it
- **WHEN** the person taps "I'm getting worse"
- **THEN** the store keeps the answers so far, the app shows the GP suggestion page at once, and the plan and its reminders stay on

#### Scenario: Back to the review
- **WHEN** the person taps "Done" on the GP suggestion page
- **THEN** the review shows again with its answers and "Done" is available

#### Scenario: Leave it alone
- **WHEN** the person does not tap "I'm getting worse" and taps "Done"
- **THEN** the review closes with no text about the button

#### Scenario: Nothing around it
- **WHEN** the person reads the end of the review
- **THEN** the person sees "I'm getting worse" as one button and no sentence above or below it

### Requirement: Week-1 answers

The week-1 answers are the person's answers to three questions the app asks only in the review of week 1. The questions MUST come after the summary and before the reflection questions. The questions are: "What do you want to be different by week 12?", "What is hardest at the moment?" and "When are the hardest times of day?" Each question MUST have one free-text field.

Each question MUST be optional. The app MUST save the week-1 answers with the review of week 1. The app MUST NOT ask these questions in any later review except taking stock. When the person never finishes the review of week 1, no week-1 answers exist.

#### Scenario: The review of week 1
- **WHEN** the person opens the review of week 1
- **THEN** the review shows the summary, then "What do you want to be different by week 12?", "What is hardest at the moment?" and "When are the hardest times of day?", then the reflection questions

#### Scenario: The review of week 2
- **WHEN** the person opens the review of week 2
- **THEN** the review shows no week-1 question

#### Scenario: Week 1 review never finished
- **WHEN** the person never taps "Done" on the review of week 1
- **THEN** the store holds no week-1 answers

### Requirement: Taking stock

The `programme` capability opens stage 5 in week WEEK_OF_TAKING_STOCK = 6, counted from the record day stage 2 opened. The first review that becomes due on or after the day stage 5 opens MUST grow into taking stock. Taking stock MUST add three parts after the summary and before the reflection questions. The parts are progress against the week-1 answers, the questionnaire, and the module recommendation.

Before the week-1 questions, the app MUST show "Starred entries: %1$lld in week 1, %2$lld in week %3$lld." with the two counts and the review's week number. For each week-1 question, the app MUST show the question and the week-1 answer under it. The app MUST then show an empty field with the heading "And now?".

When no week-1 answers exist, the app MUST ask the three questions with empty fields. The app MUST show no text about the missing answers. Taking stock is one session. When the next review is due before the person finishes taking stock, the "Reviews" list MUST keep the taking-stock row. That row MUST open taking stock until the person finishes it. The next review MUST then be a plain review.

The `programme` capability owns the restart. A restart does not delete the stage 5 opening row. The engine ignores a stage 5 opening earlier than the restart moment. Stage 5 then opens again by the programme's rule from the new start. When stage 5 opens again, the first review due on or after that day MUST grow into taking stock again.

#### Scenario: Taking stock opens
- **WHEN** the start day is Monday 28 September, stage 2 opened on Tuesday 6 October, and the person opens the review that became due on Monday 16 November
- **THEN** the review of week 7 shows the summary, then "Starred entries: 9 in week 1, 4 in week 7.", then the week-1 questions with the week-1 answers, then the questionnaire

#### Scenario: A week-1 answer shown again
- **WHEN** the week-1 answer to "What is hardest at the moment?" was "Evenings after work"
- **THEN** taking stock shows "What is hardest at the moment?", then "Evenings after work", then "And now?" with an empty field

#### Scenario: No week-1 answers
- **WHEN** the person never finished the review of week 1 and opens taking stock
- **THEN** taking stock shows the three questions with empty fields and no text about week 1 answers

#### Scenario: Taking stock left unfinished
- **WHEN** the person does not finish taking stock in the review of week 7 and the review of week 8 becomes due
- **THEN** the "Reviews" list shows a row that opens taking stock, and the review of week 8 has no taking stock part

#### Scenario: After a restart
- **WHEN** the person finished taking stock in the first run, restarted the programme, and `programme` opens stage 5 again on Monday 8 February
- **THEN** the first review that becomes due on or after Monday 8 February grows into taking stock again

### Requirement: The taking stock questionnaire and the module recommendation

The questionnaire MUST ask five questions, each with the answers "Not at all", "Some days" and "Most days". The questions are: "Do you have rules about what you can eat, or how much?", "Are there foods you avoid?", "Do you check your body in mirrors or by touch, or weigh yourself more than once a week?", "Do you avoid mirrors, photos or some clothes?" and "Do you have days when a bad feeling about your body takes over?" Each question MUST be optional. The app MUST treat an unanswered question as "Not at all" for the recommendation.

The app MUST recommend Food rules when question 1 or 2 has "Some days" or "Most days". Food rules is the person-facing name of the dieting module. Body image is the person-facing name of the body image module. Each module capability keeps its directory name. The app MUST recommend Body image when question 3, 4 or 5 has "Some days" or "Most days".

The recommendation MUST read one of: "From your answers, Food rules is the one to open first.", "From your answers, Body image is the one to open first.", "From your answers, both modules apply. Start with either." or "From your answers, neither module stands out. Both are open if you want them." A recommendation string MUST NOT contain "feeling fat". Under the recommendation, the app MUST show two controls, "Open Food rules" and "Open Body image", whatever the recommendation.

When the person taps either control, the app MUST save the answers. The app MUST then complete the taking stock session. The app MUST then open that module. The app MUST NOT show a sum of the answers. The store MUST keep the five answers and the recommendation. The `dieting-module` and `body-image-module` capabilities own the module screens.

#### Scenario: Food rules only
- **WHEN** the person answers question 1 "Most days" and the other four "Not at all"
- **THEN** the review shows "From your answers, Food rules is the one to open first.", then "Open Food rules" and "Open Body image"

#### Scenario: Body checking and a bad feeling about the body
- **WHEN** the person answers question 3 "Some days", question 5 "Most days" and the others "Not at all"
- **THEN** the review shows "From your answers, Body image is the one to open first."

#### Scenario: Both
- **WHEN** the person answers question 2 "Some days" and question 4 "Some days"
- **THEN** the review shows "From your answers, both modules apply. Start with either."

#### Scenario: Neither
- **WHEN** the person leaves all five questions unanswered
- **THEN** the review shows "From your answers, neither module stands out. Both are open if you want them.", then "Open Food rules" and "Open Body image"

#### Scenario: Open the other module
- **WHEN** the recommendation names Food rules and the person taps "Open Body image"
- **THEN** the app saves the answers, completes the taking stock session and opens the body image module

### Requirement: What the review never shows

The review MUST NOT show a score, a rating, a grade or a percentage. The review MUST NOT compare the week to a "good" week, a target or other people. The review MUST NOT praise, cheer or thank the person. The review MUST NOT add an adjective, an arrow, a trend word or a colour to any number.

The review MUST NOT show a streak, a badge or a count of entries other than the starred count. The days part counts days, not entries. The review MUST NOT show a weight value. The `product-rules` capability states the never list and the tone rules. The app MUST NOT put review content in a reminder.

#### Scenario: Fewer starred entries
- **WHEN** week 4 has 2 starred entries and week 3 had 6
- **THEN** the review shows "Starred entries: 2 this week, 6 last week." and no other word about the two numbers

#### Scenario: More starred entries
- **WHEN** week 4 has 8 starred entries and week 3 had 3
- **THEN** the review shows "Starred entries: 8 this week, 3 last week." and no other word about the two numbers

#### Scenario: Every planned meal with an entry
- **WHEN** all 30 planned meals of week 4 have an entry beside them
- **THEN** the review shows "Planned meals with an entry beside them: 30." and no praise, badge or streak

#### Scenario: No planned meal with an entry
- **WHEN** 0 of 25 planned meals of week 4 have an entry beside them and 12 have the answer "Skipped"
- **THEN** the review shows "Planned meals with an entry beside them: 0.", no skipped count, and no other word about it

### Requirement: Accessibility of the review

Each summary sentence MUST be one accessibility element whose label is the sentence text. The label of each free-text field MUST be its question. The self-harm item, "I'm getting worse", the questionnaire answers and "Done" MUST each have a VoiceOver label. The "I'm getting worse" button MUST have the VoiceOver hint "Opens a page about seeing your GP." A chosen questionnaire answer MUST NOT depend on colour alone.

The pinned note on Today MUST be one accessibility element whose label is its text. Text in the review, taking stock and the pinned note MUST use system text styles. That text MUST scale with Dynamic Type.

#### Scenario: VoiceOver reads the summary
- **WHEN** VoiceOver reads the first summary sentence of a week with 5 days with an entry
- **THEN** it reads "Days with an entry: 5." and nothing else for that element

#### Scenario: VoiceOver on the pinned note
- **WHEN** VoiceOver reads the pinned note "Eat lunch at work"
- **THEN** it reads "Eat lunch at work"

#### Scenario: VoiceOver on "I'm getting worse"
- **WHEN** VoiceOver focuses "I'm getting worse"
- **THEN** it reads the label "I'm getting worse", the button trait, and the hint "Opens a page about seeing your GP."

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the review and taking stock show all text without truncation
