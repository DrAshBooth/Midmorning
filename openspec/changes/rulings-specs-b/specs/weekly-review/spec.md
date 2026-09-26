# weekly-review

## MODIFIED Requirements

### Requirement: Finish and reopen a review

The review MUST have a "Done" control that stays active at all times. "Done" MUST be a full-width button below the review's content. Get support MUST be the trailing item of the review's navigation bar, as `safeguarding` states (decision 94). Every part of the review MUST be optional. "Done" MUST save the review. "Done" MUST then close it with the system's standard dismissal.

"Done" MUST work with any answer to the self-harm item and with none. The self-harm requirement states what the store keeps when the item has no answer, and that the app asks it again. The app MUST NOT show a message, a sound, a haptic or an animation on "Done". The person MUST be able to reopen and edit a finished review until the next review becomes due.

The app MUST offer a "Reviews" list of finished reviews, newest first. The `programme` capability places the list one tap from Today. Each row shows the week number, the week's dates and the frozen starred count, for example "Week 3, 12–18 October. Starred entries: 4." The row shows two counts, so it MUST come from strings with one count each, as `content` requires in "Catalogue rules". The app MUST show "Week %1$lld, %2$@." and "Starred entries: %lld.", joined by one space. %1$lld is the week number. %2$@ is the week's date range from the en_GB interval formatter. The %lld of the second string is the frozen starred count from the Review row. With "Weekly summary" off, each row MUST read "Week %1$lld, %2$@" only, with no full stop.

The list MUST NOT show an arrow, a colour, a total or a comparison between rows. A row MUST open the review for reading. Each review has its own due day as its key, so after a restart the list can show two runs.

Today MUST NOT show the "Reviews" control until the first review becomes due. From that moment Today MUST show the control. Before the person finishes a review, the list MUST show no rows and no text about the empty list. Decision 95 sets this rule. Ash ruled it on 25 September 2026.

The app MUST save every review in the store on the device. Every Review row MUST carry its own changedAt. The `data-and-privacy` capability owns sync to the person's iCloud private database and Delete-all.

The app MUST NOT put a review answer in the system log or an error. The app MUST NOT put a review answer in a crash report. When the app is not active, the review MUST hide its text.

#### Scenario: Done with empty answers
- **WHEN** the person answers the self-harm item "No", leaves every other field empty and taps "Done"
- **THEN** the review closes as any sheet closes, with no message about the empty fields

#### Scenario: Done below the content
- **WHEN** the person opens the review of week 1
- **THEN** "Get support" is the trailing item of the navigation bar, and "Done" is a full-width button below the review's content

#### Scenario: Edit before the next review
- **WHEN** the person finished the review of week 1 on Monday and opens it again on Wednesday
- **THEN** the review shows the saved answers and lets the person edit them

#### Scenario: The Reviews list
- **WHEN** the person finished the reviews of weeks 1, 2 and 3, with frozen starred counts of 5, 6 and 4
- **THEN** the "Reviews" list shows "Week 3, 12–18 October. Starred entries: 4.", then week 2, then week 1, each with its dates and its frozen count, and no arrow, colour, total or comparison

#### Scenario: The Reviews list with the summary off
- **WHEN** "Weekly summary" is off and the person opens the "Reviews" list
- **THEN** each row shows its week and dates only, with no starred count

#### Scenario: No Reviews control before the first review
- **WHEN** the start day is Monday 28 September and the person opens Today at 20:00 on Sunday 4 October
- **THEN** Today shows no "Reviews" control

#### Scenario: The Reviews control appears
- **WHEN** the start day is Monday 28 September and the person opens Today at 07:00 on Monday 5 October
- **THEN** Today shows the "Reviews" control, and before the person finishes a review the list shows no rows and no text

#### Scenario: Store error
- **WHEN** the store fails to save a review with the answer "Evenings were hard"
- **THEN** the error the store throws contains no part of "Evenings were hard"

### Requirement: The summary built from the record

The review of week n MUST open with a summary, one plain sentence per part. The parts MUST follow the order this requirement gives. The parts are: days with an entry, starred entries, planned meals, paused days, the longest gap, urges, the weigh-in and the person's words.

The app MUST count an entry in the week of its saved record day key. The store writes that key with the entry at save, and the `record` capability owns it. The app MUST NOT compute an entry's record day again at review time. A day state row and a weigh-in row keep the key the store wrote when it created them. The review MUST read that key.

Every count in a summary string MUST enter through a %lld placeholder with the plural forms that `content` defines. Every duration, weekday and time MUST enter through a %@ placeholder from the en_GB formatter. The `content` capability owns the catalogue rules. The starred part with a last-week count and the urge part each show two counts. So each of them MUST come from strings with one count each, as the catalogue rules require. This requirement names those strings.

The days part MUST read "Days with an entry: %lld.". The count is the number of record days in week n with at least one entry. A "didn't record" day with an entry counts. Every review MUST open with the days part, before the starred part. The days part is a count of days, not of entries.

The starred part shows the starred counts of week n and week n − 1, for example "Starred entries: 4 this week, 6 last week." The app MUST show "Starred entries: %1$@, %2$@." The app MUST fill %1$@ from "%lld this week", with the starred count of week n. The app MUST fill %2$@ from "%lld last week", with the starred count of week n − 1. In the review of week 1, the starred part MUST read "Starred entries: %lld this week."

The plan part MUST read "Planned meals with an entry beside them: %lld." The number is the planned meals of week n with an entry beside them. The app MUST NOT show the total of planned meals in the plan part. The app MUST NOT show a count of skipped planned meals. The `regular-eating-plan` capability owns the plan beside the record and the "Skipped" answer. The `problem-solving` capability reads that answer for its missed-slot groups. When week n has no planned day, the app MUST leave the plan part out.

The paused part MUST read "Paused days: %lld." with the count of record days in week n with the state "paused". The `record` capability owns that state. When week n has no paused day, the app MUST leave the paused part out.

The longest gap on a recorded day is the longest time between two consecutive entries, by entry time. The app MUST group entries into days by their saved record day key. The gap part MUST read "Longest gap between entries: %1$@, on %2$@, from %3$@ to %4$@." for the largest such gap in week n. The placeholders are the duration, the weekday name and the two entry times, each from the en_GB formatter. When no recorded day in week n counts a gap, the app MUST leave the gap part out.

The app MUST leave out a record day the person set as "didn't record". The app MUST leave out a record day with the state fasting. A fasting day counts no gap. The app MUST leave out a record day with fewer than two entries. The `record` capability owns the "didn't record" state and the fasting state.

The urge part MUST read "Urges: %lld." and "Passed: %lld.", joined by one space, for example "Urges: 3. Passed: 2." The first count is the count of urges in week n. The second is the count with the outcome "It passed". The `urge-toolkit` capability owns urges and urge outcomes. When week n has no urge, the app MUST leave the urge part out.

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

### Requirement: Week-1 answers

The week-1 answers are the person's answers to three questions the app asks only in the review of week 1. The questions MUST come after the summary and before the reflection questions. The questions are: "What do you want to be different by week 12?", "What is hardest at the moment?" and "When are the hardest times of day?" Each question MUST have one free-text field.

Each question MUST be optional. The app MUST save the week-1 answers with the review of week 1. The app MUST NOT ask these questions in any later review except taking stock.

In every week, week 1 included, the app MUST save the answers so far when the person takes one of two routes before "Done". The first route is a tap on "I'm getting worse". The second route is the self-harm route: "Yes" at step 1 and "Yes" at step 2. The requirements "I'm getting worse" and "The self-harm item at the review" state each save. So the store can hold week-1 answers from a review of week 1 with no "Done". When the person never taps "Done" in the review of week 1 and takes neither route, no week-1 answers exist. Ash ruled this on 26 September 2026 (r13-17).

#### Scenario: The review of week 1
- **WHEN** the person opens the review of week 1
- **THEN** the review shows the summary, then "What do you want to be different by week 12?", "What is hardest at the moment?" and "When are the hardest times of day?", then the reflection questions

#### Scenario: The review of week 2
- **WHEN** the person opens the review of week 2
- **THEN** the review shows no week-1 question

#### Scenario: Week 1 review never finished
- **WHEN** the person never taps "Done" on the review of week 1, and takes neither the "I'm getting worse" route nor the self-harm route in it
- **THEN** the store holds no week-1 answers

#### Scenario: Getting worse in week 1
- **WHEN** the person types "Evenings" under "When are the hardest times of day?" in the review of week 1, and taps "I'm getting worse" before "Done"
- **THEN** the store keeps "Evenings" with the review of week 1

#### Scenario: The self-harm route in week 1
- **WHEN** the person types "Evenings" under "When are the hardest times of day?" in the review of week 1, then answers step 1 "Yes" and step 2 "Yes"
- **THEN** the store keeps "Evenings" with the review of week 1, and the app shows the not-right-now page
