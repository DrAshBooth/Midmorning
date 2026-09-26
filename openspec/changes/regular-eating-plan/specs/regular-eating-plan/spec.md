# regular-eating-plan

## Purpose

The plan is the person's regular eating pattern: which slots happen on a day, and at what time. The app helps the person decide when to eat, never what. Today shows the plan beside the record, so the person sees each planned meal, the entry beside it, or a gap.

## ADDED Requirements

### Requirement: The plan builder opens at stage 2

The `programme` capability opens stage 2 after RECORDED_DAYS_FOR_STAGE_2 = 5 recorded days. The app MUST offer the plan builder only when stage 2 is open. Before that, the app MUST let the person open the stage 2 cards. When stage 2 is open, Today MUST offer "Today's plan" in the current day heading's menu, as `record` states. A recorded day is a record day with at least one entry. The recorded days MUST NOT need to be consecutive.

#### Scenario: Four recorded days
- **WHEN** the person has four recorded days
- **THEN** Today shows no plan builder control, and the stage 2 cards open when the person reads ahead

#### Scenario: Five recorded days with gaps
- **WHEN** the person has entries on Monday, Tuesday, Thursday, Saturday and Sunday and no other day
- **THEN** the plan builder opens from Today through the day heading's menu

#### Scenario: A day without entries
- **WHEN** a record day has no entry
- **THEN** the day does not count as a recorded day

### Requirement: Slots and planned meals

A plan for a day holds planned meals. A planned meal is one slot with one time. There are six slots. Each slot has a kind, a label and a slot index. The kind is meal or snack.

The slot index runs from 0 to 5 in the order below. The default labels are "Breakfast", "Mid-morning", "Lunch", "Mid-afternoon", "Evening meal" and "Evening snack". "Breakfast", "Lunch" and "Evening meal" are meals. "Mid-morning", "Mid-afternoon" and "Evening snack" are snacks. A planned meal MUST hold a slot and a time and nothing else.

The person can rename a slot's label in the plan builder. The rename requirement defines the control. A label MUST hold at most 20 characters. A label MUST NOT be "Midmorning", in any letter case. The `product-rules` capability owns the product name rule.

A rename MUST NOT change the slot's kind or its slot index. A slot's label MUST apply wherever the app shows that slot. The app MUST show a slot by its label. The `reminders` capability uses the label in a reminder with explicit wording on. The reminder userInfo and the widget snapshot MUST carry the slot index, never the label.

A day MUST hold each slot at most once. The app MUST keep a planned meal's time to the minute, inside the record day. The app MUST order the planned meals of a day by time. The app MUST NOT ask what the person eats at a planned meal.

The record day starts at the "Day starts at" time that the `settings` capability owns. `ProgrammeConstants` holds its default, DEFAULT_DAY_START_HOUR = 4. The setting is append-only rows, each with an hour and an `effectiveFromDayKey`. This capability MUST apply each row from its `effectiveFromDayKey` wherever it uses the record day.

#### Scenario: A slot placed twice
- **WHEN** a day has Lunch at 13:00 and the person places Lunch at 13:30
- **THEN** the day has one Lunch, at 13:30

#### Scenario: Slots out of their usual order
- **WHEN** a day has Evening meal at 16:30 and Mid-afternoon at 17:00
- **THEN** the app shows Evening meal above Mid-afternoon

#### Scenario: A planned meal after midnight
- **WHEN** "Day starts at" is 04:00 and the person sets Evening snack to 00:30 on Friday's plan
- **THEN** the app keeps it in Friday's record day, at 00:30 on Saturday's calendar date

#### Scenario: A later day start
- **WHEN** "Day starts at" is 05:00 and the person sets Evening snack to 04:30 on Friday's plan
- **THEN** the app keeps it in Friday's record day, at 04:30 on Saturday's calendar date

#### Scenario: A renamed slot keeps its kind and index
- **WHEN** the person renames "Mid-morning" to "Elevenses"
- **THEN** the slot is still a snack with the slot index 1, and Today shows "Elevenses" on its row

### Requirement: Place slots in the plan builder

The plan builder MUST show one button per slot that is not on the day. The button's label MUST be the slot's label. One tap on the button MUST place the slot on the day. When the person places a slot, the app MUST give it the slot's default time. The default times belong to the slot, whatever its label. They are Breakfast 08:00, Mid-morning 10:30, Lunch 13:00, Mid-afternoon 16:00, Evening meal 19:00 and Evening snack 21:00.

Each planned meal in the builder MUST show a time control labelled "%@ time". The app fills it with the slot's label, for example "Lunch time". Each planned meal MUST show a control "Remove %@", filled with the slot's label, for example "Remove Lunch". The builder MUST NOT need a drag for any action.

The builder MUST show the gap between each planned meal and the next as a duration "%@". The app MUST fill the duration through the en_GB formatter, for example "2 hours 30 minutes" or "3 hours". When the day is a fasting day, the builder MUST show no gap for that day. The `record` capability owns the fasting state. The builder MUST NOT show a message about the fasting day.

When a planned meal's time is inside quiet hours, the builder MUST show "This time is in quiet hours. The reminder will not be sent." under it. The builder MUST keep the planned meal. The `reminders` capability defines quiet hours and shows the same string on the settings screen.

The builder MUST save with "Save". The builder MUST discard with "Cancel". Save MUST be quiet, with no confirmation, message or sound. The builder MUST NOT hide Get support. "Cancel" MUST be the leading item of the navigation bar. Get support MUST be the trailing item. "Save" MUST be a full-width button below the planned meals. The `safeguarding` capability owns the side of Get support (decision 94).

#### Scenario: Place a slot
- **WHEN** the person taps "Breakfast" in the builder on an empty day
- **THEN** the day has Breakfast at 08:00, and the builder hides the "Breakfast" button

#### Scenario: Place a renamed slot
- **WHEN** the person renamed "Mid-morning" to "Elevenses" and taps "Elevenses" in the builder
- **THEN** the day has Elevenses at 10:30, and the builder shows "Elevenses time" and "Remove Elevenses"

#### Scenario: Place the evening snack
- **WHEN** the person taps "Evening snack" in the builder
- **THEN** the day has Evening snack at 21:00

#### Scenario: Change a time
- **WHEN** the person sets "Breakfast time" from 08:00 to 07:15 and taps "Save"
- **THEN** the day has Breakfast at 07:15, and the builder closes with no message

#### Scenario: Remove a planned meal
- **WHEN** the person taps "Remove Lunch" on a day with Lunch at 13:00 and taps "Save"
- **THEN** the day has no Lunch, and the builder shows the "Lunch" button again

#### Scenario: Gap shown between planned meals
- **WHEN** a day has Lunch at 13:00 and Mid-afternoon at 16:00
- **THEN** the builder shows "3 hours" between them

#### Scenario: No gap on a fasting day
- **WHEN** the person turned on "Fasting today" and opens "Today's plan" with Lunch at 13:00 and Evening meal at 19:00
- **THEN** the builder shows both planned meals, no gap between them and no message about the fast

#### Scenario: A planned meal inside quiet hours
- **WHEN** quiet hours run from 22:00 to 07:00 and the person places Evening snack at 22:30
- **THEN** the builder shows "This time is in quiet hours. The reminder will not be sent." under Evening snack and keeps the planned meal

#### Scenario: Save below the planned meals
- **WHEN** the person opens "Today's plan" in the builder
- **THEN** "Cancel" is the leading item of the navigation bar, "Get support" is the trailing item, and "Save" is a full-width button below the planned meals

### Requirement: Rename a slot in the plan builder

Each planned meal in the builder MUST show a control "Rename". Its VoiceOver label MUST be "Rename %@", filled with the slot's label, for example "Rename Lunch". "Rename" MUST open a text field that holds the current label, with "Save" and "Cancel". The field MUST accept at most 20 characters. The field MUST NOT accept a 21st character.

When the person saves an empty field, the app MUST restore the slot's default label. When the text is "Midmorning", in any letter case, the app MUST keep the field open. The app MUST then show "That is the app's name. Choose another word." under the field.

The store MUST keep each label as the Settings row `slot.label.<index>`, one row per slot index. Settings rows are one row per key with a `changedAt`, as the `data-and-privacy` capability states. On read, the app keeps the row with the later `changedAt`. A saved label MUST apply at once wherever the app shows that slot. Those places are the templates, every day's plan and every planned meal row on Today.

A rename MUST NOT change the slot's kind, its slot index, its default time or its time on any day. A rename MUST NOT set a day's plan. A rename MUST NOT write to a Template row. A rename is not an edit of a day's plan for the morning plan reminder that the `reminders` capability defines.

#### Scenario: Rename a slot
- **WHEN** the person taps "Rename" on Mid-morning, types "Elevenses" and taps "Save"
- **THEN** the builder shows "Elevenses" in place of "Mid-morning", and Today shows "Elevenses" on that row

#### Scenario: Twenty-one characters
- **WHEN** the person types "Second breakfast time" into the field
- **THEN** the field holds "Second breakfast tim" and accepts no more

#### Scenario: The product name
- **WHEN** the person types "midmorning" and taps "Save"
- **THEN** the field stays open with "That is the app's name. Choose another word." under it, and the label does not change

#### Scenario: An empty label
- **WHEN** the person clears the field on a slot labelled "Elevenses" and taps "Save"
- **THEN** the slot's label is "Mid-morning" again

#### Scenario: A rename is not a plan edit
- **WHEN** a template exists and the person renames "Evening snack" to "Supper" on Tuesday without an edit to Tuesday's plan
- **THEN** Tuesday's plan is unchanged, Tuesday is not a set day, and no morning plan reminder fires on Wednesday

### Requirement: The soft rules show and ask

Regular eating is 3 meals and 2 or 3 snacks a day, with no awake gap over MAX_AWAKE_GAP_HOURS. `ProgrammeConstants` holds MAX_AWAKE_GAP_HOURS = 4. A gap is the time from a planned meal to the next planned meal on the same day. The app MUST NOT count the time before the first planned meal or after the last. A gap of exactly 4 hours MUST NOT break the gap rule.

When a saved day or template breaks a soft rule, the app MUST show one line per broken rule. Each line MUST be its own paragraph. On a fasting day the app MUST NOT show the gap line for that day. The meal line still applies. The app MUST show all lines together, once, above the controls.

The meal line is the catalogue entry "This day has %1$@ and %2$@. Three meals and two or three snacks keep the gaps short. Save anyway?". The first placeholder is the meal count and the second is the snack count. The app MUST fill each count from a plural form with zero, one and other: "no meals", "1 meal", "%lld meals"; "no snacks", "1 snack", "%lld snacks". The app MUST count slot kinds, never labels. A renamed slot keeps its kind.

The gap line is the catalogue entry "%1$@ between %2$@ at %3$@ and %4$@ at %5$@.". The placeholders are the gap as a duration, the earlier slot's label, its time, the later slot's label and its time. The app MUST fill the duration and each time through the en_GB formatter. For example: "4 hours 30 minutes between Lunch at 12:30 and Evening meal at 17:00."

The controls MUST be "Save anyway" and "Go back". The builder's own "Cancel" discards the edit, as "Place slots in the plan builder" states. Here "Cancel" would mean the opposite, so the controls are "Save anyway" and "Go back". When the lines appear, VoiceOver focus MUST move to the first line.

When the person taps "Save anyway", the app MUST save the day as it is. When the person taps "Go back", the app MUST return to the builder with the day unchanged. The app MUST NOT block a save. The app MUST NOT show a line when the day meets every soft rule.

#### Scenario: Too few meals and snacks
- **WHEN** the person saves a day with Breakfast, Lunch and Mid-afternoon only
- **THEN** the app shows "This day has 2 meals and 1 snack. Three meals and two or three snacks keep the gaps short. Save anyway?" with "Save anyway" and "Go back"

#### Scenario: Save anyway
- **WHEN** the app shows the meal line and the person taps "Save anyway"
- **THEN** the app saves the day with 2 meals and 1 snack and shows no further message

#### Scenario: No meals at all
- **WHEN** the person saves a day with Mid-morning and Mid-afternoon only
- **THEN** the meal line reads "This day has no meals and 2 snacks. Three meals and two or three snacks keep the gaps short. Save anyway?"

#### Scenario: Go back
- **WHEN** the app shows the meal line and the person taps "Go back"
- **THEN** the builder shows the day unchanged, and the store holds the day as it was before

#### Scenario: A gap over four hours
- **WHEN** the person saves a day with Lunch at 12:30 and Evening meal at 17:00 and nothing between them
- **THEN** the app shows "4 hours 30 minutes between Lunch at 12:30 and Evening meal at 17:00." with "Save anyway" and "Go back"

#### Scenario: Two broken rules
- **WHEN** the person saves a day with Breakfast at 08:00 and Lunch at 13:00 only, with VoiceOver on
- **THEN** the app shows the meal line and the gap line as two paragraphs, and VoiceOver focus moves to the meal line

#### Scenario: A gap of exactly four hours
- **WHEN** the person saves a day with Lunch at 13:00 and Evening meal at 17:00 and nothing between them
- **THEN** the app saves the day and shows no line

#### Scenario: A renamed slot counts by its kind
- **WHEN** the person renamed "Mid-afternoon" to "Cake" and saves a day with Breakfast, Lunch and Cake only
- **THEN** the app shows "This day has 2 meals and 1 snack. Three meals and two or three snacks keep the gaps short. Save anyway?"

#### Scenario: A long gap on a fasting day
- **WHEN** the person turned on "Fasting today" and saves "Today's plan" with Lunch at 12:30 and Evening meal at 17:00 and nothing between them
- **THEN** the app shows no gap line, and the meal line applies as on any day

#### Scenario: A day that meets every rule
- **WHEN** the person saves a day with the six slots at their default times
- **THEN** the app saves the day and shows no line

### Requirement: Weekday and weekend templates

The app MUST keep a weekday template and a weekend template. The weekday template applies to a record day that starts on Monday to Friday. The weekend template applies to a record day that starts on Saturday or Sunday. The builder MUST edit them under "Weekday plan" and "Weekend plan". The weekday plan MUST offer a "Copy to weekend plan" control.

A record day's plan starts as a copy of its template. The app MUST make the copy lazily, on activation, for every record day that started since the last copy. This copy is part of the materialisation of an elapsed record day, as the `reminders` capability describes. Materialisation writes the copy as a Day row under the record day key. The Day row keeps the window constants of that moment.

Materialisation MUST NOT create a Day row for a key that already exists after import. Materialisation MUST write no `changedAt`.

A change to a template MUST apply to record days that start after the change. A change to a template MUST NOT change the current record day's plan. A change to a template is not an edit of a day's plan. A change to a template MUST NOT set any day's plan. The morning plan reminder that the `reminders` capability defines does not fire for it.

#### Scenario: A weekend record day
- **WHEN** "Day starts at" is 04:00 and the current time is 01:00 on Sunday 27 September
- **THEN** the current record day is Saturday 26 September and its plan comes from the weekend template

#### Scenario: A template change during the day
- **WHEN** the person changes the weekday template at 15:00 on Tuesday
- **THEN** Tuesday's plan does not change, and Wednesday's plan comes from the changed template

#### Scenario: Copy to the weekend
- **WHEN** the person taps "Copy to weekend plan" on a weekday plan with six planned meals
- **THEN** the weekend template holds the same six planned meals at the same times

#### Scenario: Three days without opening the app
- **WHEN** the person last opened the app at 20:00 on Monday and opens it at 09:00 on Thursday
- **THEN** the app copies the templates onto Tuesday, Wednesday and Thursday, and Tuesday and Wednesday are not planned days

### Requirement: Edit tonight for tomorrow, or this morning for today

The builder MUST let the person edit the current record day's plan under "Today's plan". The builder MUST let the person edit the next record day's plan under "Tomorrow's plan". An edit to a day MUST change that day only. An edit to a day MUST NOT change its template. "Save" on an edit sets that day's plan, as the planned day requirement states.

On the current day, the builder MUST let the person change or delete an unanswered planned meal. An unanswered planned meal has no matched entry and no "Skipped" answer. A planned meal with a matched entry or a "Skipped" answer MUST stay as it is.

#### Scenario: Tonight for tomorrow
- **WHEN** the person opens "Tomorrow's plan" at 22:00 on Thursday and moves Lunch to 14:00
- **THEN** Friday's plan has Lunch at 14:00, and the weekday template is unchanged

#### Scenario: This morning for today
- **WHEN** the person opens "Today's plan" at 07:30 on Friday and moves Lunch to 13:30
- **THEN** Friday's plan has Lunch at 13:30, and Saturday's plan is unchanged

#### Scenario: A planned meal with an entry
- **WHEN** an entry at 13:10 matches Lunch at 13:00 and the person opens "Today's plan" at 14:00
- **THEN** Lunch stays as it is, and the person can change Evening meal

#### Scenario: Tomorrow after midnight
- **WHEN** the person opens "Tomorrow's plan" at 01:00 on Saturday 26 September
- **THEN** the builder edits the record day of Saturday 26 September

### Requirement: A planned day

A planned day is a record day that is not paused and meets one of two conditions. Its plan comes from its template and the day has at least one entry. Or the day is a set day. This is the one definition of a planned day. Every other capability refers to it. A set day is a record day whose plan the person sets.

The person sets a record day's plan in one way. The person taps "Save" on an edit in "Today's plan" or "Tomorrow's plan" for that day. A set day MUST be a planned day whether or not it has an entry. A record day whose plan comes from its template and that has no entry MUST NOT be a planned day. An entry counts wherever its time falls in the record day. The entry MUST NOT need to sit inside a planned meal's window.

A "Skipped" answer, from a reminder or from the prompt, MUST NOT set a day's plan. The day is a planned day when it also has an entry. A snooze MUST NOT set a day's plan.

A paused day MUST NOT be a planned day. A paused day MUST NOT break a run of consecutive planned days. A fasting day MUST be a planned day when it meets the rules above. The `record` capability owns the fasting state.

A record day with a plan that has not started is not a planned day. A reader MUST take a record day's set state from its set event row. A reader MUST take the entry condition from the day's entries at read time. Materialisation MUST NOT write a set event row.

The store MUST write a day's plan as a Day row under that day's record day key. The store MUST write each answer as an Answer row, keyed by the record day key and the slot index. The store MUST write the set state as one event row: the record day key, `setAt` and `setBy`. The presence of that row on any device means set. The store MUST NOT delete a set event row.

When the store creates a row, it MUST write the key from the day start row in force. The `record` capability defines the record day key. A row MUST keep its key after a change to "Day starts at". Every reader of a planned day MUST use the key on the row. A reader MUST NOT compute the day again.

The `programme` capability counts planned days toward DAYS_ON_PLAN_FOR_STAGE_3 = 7. The `programme` capability adds one condition for that count: the day is also a recorded day. Planned days MUST NOT need to be consecutive for that count. The `programme` capability also opens stage 3 after RECORD_DAYS_FOR_STAGE_3_FALLBACK = 14 record days from stage 2's opening, whichever comes first.

#### Scenario: Save an edit to today's plan
- **WHEN** the person moves Lunch to 13:30 in "Today's plan" at 07:40 and taps "Save"
- **THEN** the current record day is a set day and a planned day, and the store holds its set event row

#### Scenario: An entry on a template day
- **WHEN** Friday's plan comes from the template and the person saves an entry at 10:15 on Friday that matches no planned meal
- **THEN** Friday is a planned day

#### Scenario: A set day without an entry
- **WHEN** the person saves "Tomorrow's plan" for Friday at 22:00 on Thursday and saves no entry on Friday
- **THEN** Friday is a planned day, and the `programme` capability does not count it toward stage 3

#### Scenario: A day the person did not touch
- **WHEN** Friday's plan comes from the template, and the person saved no entry and saved no edit for Friday
- **THEN** Friday is not a planned day

#### Scenario: A "Skipped" answer only
- **WHEN** Friday's plan comes from the template, the person taps "Skipped" on the Lunch reminder, and Friday has no entry
- **THEN** Friday is not a planned day

#### Scenario: A snooze only
- **WHEN** the person taps "Remind me in 15 minutes" on the Lunch reminder and does nothing else with Friday's plan
- **THEN** Friday is not a planned day

#### Scenario: A paused day in a run
- **WHEN** Monday to Wednesday are planned days, Thursday is paused, and Friday to Sunday are planned days
- **THEN** the run of consecutive planned days is six days long, and Thursday is not a planned day

#### Scenario: A fasting day on the plan
- **WHEN** the person saves an edit in "Today's plan" on Wednesday at 07:00 and turns on "Fasting today" at 07:05
- **THEN** Wednesday is a planned day

#### Scenario: A day start change keeps the key
- **WHEN** Friday's Day row holds the record day key Friday 2 October, and the person sets "Day starts at" to 05:00 on Saturday
- **THEN** the row keeps the key Friday 2 October, and Friday stays a planned day

#### Scenario: The set event row from another device
- **WHEN** the person saves "Tomorrow's plan" for Friday on one device, and Friday's set event row syncs to a second device
- **THEN** the second device shows Friday as a planned day and writes no row of its own

#### Scenario: Seven planned days over ten record days
- **WHEN** seven of the last ten record days are planned days and recorded days
- **THEN** the `programme` capability counts seven planned days toward the stage 3 gate

### Requirement: The window of a planned meal

The window of a planned meal starts PLANNED_MEAL_WINDOW_BEFORE_MINUTES = 60 minutes before its time. It ends PLANNED_MEAL_WINDOW_AFTER_MINUTES = 90 minutes after its time. The window includes its start and excludes its end. The Day row keeps both constants from its materialisation. The app MUST compute a day's windows from the constants on its Day row.

The app MUST compute the day's windows in this order. The app MUST sort the day's planned meals by time. For each adjacent pair whose windows overlap, the app MUST end the earlier window at the midpoint between their times. The app MUST start the later window at that same midpoint. The app MUST then clip every window to the record day. The record day's bounds come from the "Day starts at" setting.

The app MUST match the earliest entry by time inside the window to the planned meal. An entry MUST match at most one planned meal. A "That was it" answer MUST match its entry to the planned meal, as the missed planned meal prompt defines. A "That was it" match MUST come before the window matching. The app MUST compute the matching again when the person creates, edits or deletes an entry, or changes the plan.

When an entry matches a planned meal that has a "Skipped" answer, the app keeps the matched entry on read. The app MUST NOT change the Answer row for that. A planned meal is missed when its window ends with no matched entry and no "Skipped" answer.

#### Scenario: An entry inside the window
- **WHEN** Lunch is at 13:00 and the person saves an entry with the time 13:10
- **THEN** the entry matches Lunch

#### Scenario: Two entries inside the window
- **WHEN** Lunch is at 13:00 and the person saves entries with the times 13:40 and 12:30
- **THEN** the 12:30 entry matches Lunch and the 13:40 entry matches nothing

#### Scenario: Overlapping windows
- **WHEN** Lunch is at 13:00 and Mid-afternoon is at 14:30
- **THEN** the Lunch window runs from 12:00 to 13:45 and the Mid-afternoon window runs from 13:45 to 16:00

#### Scenario: Three planned meals 30 minutes apart
- **WHEN** Lunch is at 13:00, Mid-afternoon is at 13:30 and Evening meal is at 14:00
- **THEN** the windows run from 12:00 to 13:15, from 13:15 to 13:45 and from 13:45 to 15:30

#### Scenario: A window clipped to the record day
- **WHEN** "Day starts at" is 04:00, Breakfast is at 04:30 and Evening snack is at 03:00
- **THEN** the Breakfast window runs from 04:00 to 06:00 and the Evening snack window runs from 02:00 to 04:00 at the end of the record day

#### Scenario: A window clipped to a later day start
- **WHEN** "Day starts at" is 05:00 and Breakfast is at 05:30
- **THEN** the Breakfast window runs from 05:00 to 07:00

#### Scenario: An entry at the window's end
- **WHEN** Lunch is at 13:00 and the person saves an entry with the time 14:30
- **THEN** the entry matches nothing

#### Scenario: A matched entry deleted
- **WHEN** an entry at 13:10 matches Lunch at 13:00 and the person deletes it at 15:00
- **THEN** Lunch has no matched entry and is missed

#### Scenario: An entry after "Skipped"
- **WHEN** the person answered "Skipped" for Lunch at 13:00 and then saves an entry at 13:20
- **THEN** the entry matches Lunch, every reader shows the entry beside Lunch, and the Answer row still holds "Skipped"

### Requirement: Today shows the plan beside the record

From stage 2, Today MUST show the current record day's planned meals in the column. Today MUST place them in time order with the entries. The `programme` capability makes Today the app's first screen from stage 2. A planned meal row MUST show the slot label and the planned time. When an entry matches the planned meal, the row MUST show the entry's time, What and star beside the slot. When the window has not ended and no entry matches, the row MUST show the slot and the time only.

With the answer "Skipped" and no matched entry, the row MUST show the slot, the time and "Skipped". An entry that matches nothing MUST appear as a plain entry row. When Today shows the previous record day expanded, Today MUST show that day's planned meals the same way. A planned meal row MUST have the same background, height, spacing and text style as an entry row. Today MUST NOT show a tick, a cross, a colour, a count or a percentage for any planned meal. Today MUST NOT show a count of planned meals with an entry, on any day.

#### Scenario: A matched planned meal
- **WHEN** an entry at 13:10 with What "Toast and tea" matches Lunch at 13:00
- **THEN** Today shows one row with "Lunch", "13:00", "13:10" and "Toast and tea"

#### Scenario: A planned meal still to come
- **WHEN** the current time is 15:00 and Evening meal is at 19:00 with no matched entry
- **THEN** Today shows a row with "Evening meal" and "19:00" and nothing else

#### Scenario: A skipped planned meal
- **WHEN** the person answered "Skipped" for Lunch at 13:00
- **THEN** Today shows a row with "Lunch", "13:00" and "Skipped", at the same visual weight as an entry row

#### Scenario: Skipped, then an entry matches
- **WHEN** the person answered "Skipped" for Lunch at 13:00 and then saves an entry at 13:20 with What "Soup"
- **THEN** Today shows one row with "Lunch", "13:00", "13:20" and "Soup", and no "Skipped"

#### Scenario: An entry outside every window
- **WHEN** the person saves an entry at 14:45 and no window contains 14:45
- **THEN** Today shows the entry as a plain entry row between the rows around it

### Requirement: A missed planned meal gets one prompt

When a planned meal is missed, Today MUST show one missed planned meal prompt on its row. The prompt MUST read "Skipped, or not recorded yet?" with "Skipped" and "Add it". "Add it" MUST open the new-entry screen with the time set to the planned meal's time. "Skipped" MUST set the planned meal as skipped. The app MUST show the prompt at most once per planned meal. The app MUST NOT send a notification for the prompt.

Today MUST show at most one missed planned meal prompt on a record day at any moment. The prompt MUST sit on the latest missed planned meal. When a later planned meal becomes missed and the prompt is unanswered, the prompt MUST move to it. Every earlier missed planned meal's row MUST show the slot and the time only. Today MUST NOT show a second prompt on an earlier missed planned meal after the person answers. "Skipped", "Add it" and "That was it" MUST be visible buttons at least 44 points tall, with 8 points between them.

A candidate entry matches no planned meal. Its time is after this planned meal's time and before the next planned meal's time. When the day has no later planned meal, a candidate entry's time is before the end of the record day. When a candidate entry exists, the prompt MUST be the catalogue entry "Skipped, or was that %@?". The app MUST fill the placeholder with the earliest candidate entry's time through the en_GB formatter, for example "Skipped, or was that 14:45?".

This form MUST offer "Skipped" and "That was it". "That was it" MUST match that entry to the planned meal. This form MUST NOT offer "Add it". When the entry also sits inside a later planned meal's window, the earlier planned meal MUST keep the entry. The app MUST then compute the later planned meal's matching again without that entry.

A later entry is an entry that matches a later planned meal, or has a time at or after the next planned meal's time. The app MUST NOT show the prompt when the day has a later entry. The app MUST NOT show the prompt when the window ends inside quiet hours. The app MUST NOT show the prompt when the person answered "Skipped" from the reminder.

When the record day ends with the prompt unanswered, the app MUST hide the prompt. The row MUST then show the slot and the time only. The app MUST NOT show any second message about the missed planned meal.

#### Scenario: The window ends with no entry
- **WHEN** Lunch is at 13:00, no entry matches it, and the current time reaches 14:30
- **THEN** Today shows "Skipped, or not recorded yet?" on the Lunch row with "Skipped" and "Add it"

#### Scenario: Add it
- **WHEN** the person taps "Add it" on the Lunch prompt at 15:00
- **THEN** the new-entry screen opens with the time 13:00 and the keyboard in What

#### Scenario: An unmatched entry after the window
- **WHEN** the current time is 15:00, Lunch at 13:00 is missed, Mid-afternoon is at 16:00, and an entry at 14:45 matches nothing
- **THEN** Today shows "Skipped, or was that 14:45?" on the Lunch row with "Skipped" and "That was it"

#### Scenario: Two missed planned meals
- **WHEN** the current time is 18:00, Lunch at 13:00 and Mid-afternoon at 16:00 are both missed, and the day has no other entry
- **THEN** Today shows the prompt on the Mid-afternoon row only, and the Lunch row shows "Lunch" and "13:00"

#### Scenario: The prompt moves to a later missed planned meal
- **WHEN** the Lunch prompt is unanswered at 17:00, Mid-afternoon at 16:00 has no matched entry, and the time reaches 17:30
- **THEN** the prompt moves to the Mid-afternoon row, and the Lunch row shows "Lunch" and "13:00"

#### Scenario: An answered prompt, then an earlier missed planned meal
- **WHEN** the person answered the Mid-afternoon prompt with "Skipped" and Lunch at 13:00 is also missed
- **THEN** the Lunch row shows "Lunch" and "13:00" and no prompt

#### Scenario: A later entry
- **WHEN** Lunch at 13:00 is missed, an entry at 16:05 matches Mid-afternoon at 16:00, and the person opens Today at 20:00
- **THEN** Today shows the Lunch row with "Lunch" and "13:00" and no prompt

#### Scenario: The window ends inside quiet hours
- **WHEN** quiet hours run from 22:00 to 07:00, Evening snack is at 21:00 and no entry matches it by 22:30
- **THEN** Today shows the Evening snack row with "Evening snack" and "21:00" and no prompt

#### Scenario: Skipped from the reminder
- **WHEN** the person tapped "Skipped" on the Lunch reminder at 13:05
- **THEN** Today shows the Lunch row with "Skipped" and no prompt

#### Scenario: Unanswered at the end of the day
- **WHEN** "Day starts at" is 04:00, the day has an entry at 08:00, the Lunch prompt is unanswered, the current time reaches 04:00 the next day, and the person expands the previous record day
- **THEN** the previous day's Lunch row shows "Lunch" and "13:00" only

### Requirement: The next-planned-meal line

The next planned meal is the earliest planned meal with a time later than the moment in question. When the day has none, the next planned meal is the first planned meal of the next record day's plan or template. The next-planned-meal line is the catalogue entry "%1$@ at %2$@ still happens.", filled with the next planned meal's label and its time through the en_GB formatter, for example "Evening meal at 19:00 still happens.". Today MUST show the line on the next planned meal's row. When the next planned meal is on the next record day, its row is not on Today. Today MUST then show the line as the last row of the current day section. The line MUST use the text style of a planned meal row. When no next planned meal exists, the app MUST show no line.

When the person answers "Skipped" on the missed planned meal prompt, Today MUST show the line at once. When the person answers "Skipped" on a planned meal reminder, the app applies the queued skip later. It does so when protected data becomes available, as the `reminders` capability states. Today MUST then show the line the first time Today appears after that.

When the person saves a starred entry, the new-entry screen MUST show nothing about it. Today MUST show the line from the next time Today appears after that save. The next planned meal after a starred entry MUST NOT be the planned meal the entry matches. The line MUST stay until the next planned meal matches an entry, the person answers it, or its window ends.

The `urge-toolkit` capability shows the same line after an "I binged" outcome, by the same rule. The app MUST NOT show any string that asks the person to eat more or less next time. The app MUST NOT show any string that asks the person to move or skip the next planned meal.

#### Scenario: Skip lunch
- **WHEN** the person answers "Skipped" on the Lunch prompt at 13:00 and Mid-afternoon is at 16:00
- **THEN** Today shows "Mid-afternoon at 16:00 still happens." on the Mid-afternoon row at once

#### Scenario: Skip lunch from the reminder
- **WHEN** the person taps "Skipped" on the Lunch reminder at 13:05, Mid-afternoon is at 16:00, and Today next appears at 13:40
- **THEN** Today shows "Mid-afternoon at 16:00 still happens." on the Mid-afternoon row

#### Scenario: Skip the last planned meal of the day
- **WHEN** the person answers "Skipped" for Evening snack at 21:00 and the next day's template has Breakfast at 08:00
- **THEN** Today shows "Breakfast at 08:00 still happens." as the last row of the current day section

#### Scenario: A starred entry between planned meals
- **WHEN** the person saves a starred entry at 14:45, no window contains 14:45, Mid-afternoon is at 16:00, and Today appears at 14:46
- **THEN** the new-entry screen showed no line, and Today shows "Mid-afternoon at 16:00 still happens." on the Mid-afternoon row

#### Scenario: A starred entry that matches a planned meal
- **WHEN** the person saves a starred entry at 13:10 that matches Lunch at 13:00, Mid-afternoon is at 16:00, and Today next appears at 13:11
- **THEN** Today shows "Mid-afternoon at 16:00 still happens." on the Mid-afternoon row, and nothing on the Lunch row

#### Scenario: The next planned meal arrives
- **WHEN** Today shows "Mid-afternoon at 16:00 still happens." and the person saves an entry at 16:05
- **THEN** the entry matches Mid-afternoon and Today hides the line

#### Scenario: The window ends
- **WHEN** Today shows "Mid-afternoon at 16:00 still happens." and the current time reaches 17:30 with no matched entry
- **THEN** Today hides the line, and the missed planned meal prompt applies

### Requirement: The plan's data stays on the device

The store MUST keep the Template rows, the six `slot.label.<index>` Settings rows and each Day row in `Record.store`. The store MUST keep each day's set event row and each Answer row there too. The store MUST keep them with the same file protection and backup exclusion as entries.

Every one of those rows carries its own `changedAt`. On read, the app keeps the row with the later `changedAt`. The app MUST NOT hard-delete any of those rows. Only Delete-all deletes them, with the whole store directory.

The synced Answer row MUST NOT carry the snooze count. `Local.store` keeps the snooze count, keyed by the record day key and the slot index. The app MUST NOT save the window matching. The app MUST compute it from the entries, the plan and the answers.

Plan data MUST NOT leave the device except to the person's own iCloud private database, when sync is on. Delete-all MUST delete the templates, the slot labels and every day's plan. The app MUST NOT put a planned meal's time, a slot label or an answer in an error report.

#### Scenario: Close and open the app
- **WHEN** the person saves a weekday template, closes the app and opens it again
- **THEN** the weekday template is unchanged

#### Scenario: No network
- **WHEN** the device has no network connection
- **THEN** the person can edit the plan and see it on Today

#### Scenario: Delete-all
- **WHEN** the person taps Delete-all
- **THEN** the store holds no Template row, no Day row and no `slot.label.<index>` row, and the default labels apply

#### Scenario: A rename on two devices
- **WHEN** one device renames "Mid-morning" to "Elevenses" at 10:00 and another renames it to "Brunch" at 10:05, and both sync
- **THEN** both devices show "Brunch", and no Template row changed on either device

### Requirement: Accessibility of the plan

Each planned meal row on Today MUST be one accessibility element. The row's label MUST hold the slot label, then the planned time. It MUST then hold the matched entry's label when an entry matches. When no entry matches and the answer is "Skipped", it MUST hold "Skipped" instead.

When the row shows the missed planned meal prompt, the label MUST hold the prompt text after the time. A comma and a space MUST separate the parts. The prompt's buttons MUST also be VoiceOver custom actions on the row: "Skipped" and "Add it", or "Skipped" and "That was it".

Every control in the plan builder MUST have a VoiceOver label. The slot buttons, the time controls and the "Remove %@" controls MUST carry the labels the builder requirement names. The rename controls MUST carry the labels the rename requirement names. Text in the plan builder and on planned meal rows MUST use system text styles. Text in the plan builder and on planned meal rows MUST scale with Dynamic Type. A planned meal's state MUST NOT depend on colour alone.

#### Scenario: Label of a matched planned meal
- **WHEN** VoiceOver reads the Lunch row with a starred entry at 13:10 and What "Toast and tea"
- **THEN** it reads "Lunch, 13:00, 13:10, Toast and tea, felt like a binge"

#### Scenario: Label of a skipped planned meal
- **WHEN** VoiceOver reads the Lunch row after the person answered "Skipped"
- **THEN** it reads "Lunch, 13:00, Skipped"

#### Scenario: Label of a planned meal without an entry
- **WHEN** VoiceOver reads the Evening meal row with no matched entry and no answer
- **THEN** it reads "Evening meal, 19:00"

#### Scenario: Label of a planned meal with the prompt
- **WHEN** VoiceOver reads the Lunch row while it shows "Skipped, or not recorded yet?"
- **THEN** it reads "Lunch, 13:00, Skipped, or not recorded yet?" and offers the custom actions "Skipped" and "Add it"

#### Scenario: Labels in the builder
- **WHEN** VoiceOver reads a builder day with Lunch at 13:00 and no Breakfast
- **THEN** it reads a button "Breakfast", a time control "Lunch time" with the value "13:00", a button "Rename Lunch" and a button "Remove Lunch"

#### Scenario: Label of a renamed planned meal
- **WHEN** VoiceOver reads the row of a slot renamed "Elevenses" at 10:30 with no matched entry
- **THEN** it reads "Elevenses, 10:30"

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the plan builder and Today show every planned meal without truncation
