# weigh-in

## Purpose

The weigh-in is the one number the programme asks for each week. On the weigh-in day the app asks for one number, then shows a four-week rolling average as a line. The screen treats a weekly number as something to save, not something to watch. Only `safeguarding` reads the trend. Weighing is optional: a person who chose "I won't be weighing" can pick a weigh-in day later from this screen.

## ADDED Requirements

### Requirement: The weigh-in day

The weigh-in day is the weekday the person picked at onboarding, or none when the person chose "I won't be weighing". `onboarding` owns that choice. The weigh-in day MUST sync between the person's devices. `data-and-privacy` lists it as a shared setting.

The store MUST keep it as one settings row with a key, a value and a `changedAt`. When two devices set it, the app keeps the row with the later `changedAt`. The app MUST treat the weigh-in day as the record day whose calendar date falls on that weekday. `record` defines the record day and its day start.

The app MUST let the person change the weigh-in day from the weigh-in screen. The control's label MUST be "Weigh-in day". The setting in the settings screen MUST carry the same label, "Weigh-in day". `reminders` owns the switch "Weigh-in day reminder".

A change MUST take effect at once. The app MUST NOT show a message about the change. `reminders` owns the weigh-in day reminder and its default time of 07:30.

With no weigh-in day, the weigh-in screen MUST show "Choose a weigh-in day" with the seven weekdays as one-tap choices. The screen MUST then show no weight input and no refusal text. `reminders` MUST NOT schedule a weigh-in day reminder while no weigh-in day exists. `weekly-review` and `staying-on-track` MUST leave the weigh-in part out of every review and check-in while no weigh-in day exists. A tap on a weekday MUST set the weigh-in day at once, with no message. The app MUST then treat the screen as it does after any change of the weigh-in day.

#### Scenario: Weigh-in after midnight on the weigh-in day
- **WHEN** the weigh-in day is Monday and the person saves a weigh-in at 01:00 on Tuesday 29 September
- **THEN** the store writes the record day key Monday 28 September with the weigh-in

#### Scenario: Weigh-in before the day start on the weigh-in day
- **WHEN** the weigh-in day is Monday, the day start is 04:00, and the person opens the weigh-in screen at 02:00 on Monday 28 September
- **THEN** the app treats the moment as Sunday 27 September and shows no weight input

#### Scenario: No weigh-in day
- **WHEN** the person chose "I won't be weighing" at onboarding and opens the weigh-in screen on any day
- **THEN** the screen shows "Choose a weigh-in day" with the seven weekdays, no weight input, no refusal text and no chart

#### Scenario: Choose a weigh-in day later
- **WHEN** the person has no weigh-in day and taps "Friday" under "Choose a weigh-in day" on Wednesday 30 September
- **THEN** the screen shows "Weigh-in day" as Friday, the app accepts a weigh-in on Friday 2 October, and `reminders` schedules the weigh-in day reminder on Friday at 07:30

#### Scenario: No reminder without a weigh-in day
- **WHEN** the person has no weigh-in day
- **THEN** the pending notification requests hold no weigh-in day reminder

#### Scenario: The weigh-in day syncs
- **WHEN** the person has sync on and chooses Friday under "Choose a weigh-in day" on device A
- **THEN** device B shows "Weigh-in day" as Friday after its next sync

#### Scenario: Two devices set the weigh-in day
- **WHEN** device A sets Friday at 09:00 and device B sets Tuesday at 09:05, both offline, and both then sync
- **THEN** both devices show "Weigh-in day" as Tuesday, the row with the later `changedAt`

#### Scenario: Change the weigh-in day
- **WHEN** the person has no weigh-in in the last six days and changes the weigh-in day from Monday to Friday on Wednesday 30 September
- **THEN** the screen shows "Weigh-in day" as Friday and the app accepts a weigh-in on Friday 2 October

#### Scenario: The reminder follows the weigh-in day
- **WHEN** the person changes the weigh-in day from Monday to Friday
- **THEN** `reminders` schedules the weigh-in day reminder on Friday at its set time, 07:30 by default

### Requirement: The app accepts a weight on the weigh-in day only

On the weigh-in day the weigh-in screen MUST show the weight input and "Save". The app MUST accept at most one weigh-in per weigh-in day. The app MUST NOT accept a weigh-in less than six days after the last one. On any other day the screen MUST NOT show the weight input.

On any other day the screen MUST show the refusal text in the body text style. The refusal text MUST be "Your weigh-in day is %1$@. The app asks once a week, because day-to-day numbers move on their own. Next: %2$@." The app MUST fill %1$@ with the weigh-in day's name. The app MUST fill %2$@ with the date of the next day it accepts a weigh-in. Both values MUST come from the en_GB formatter.

The refusal text MUST have no icon and no colour. The app MUST NOT accept a weight from any other screen, widget, notification action or App Intent. For 10 minutes after "Save", the person MUST be able to change the number. After those 10 minutes the app MUST fix the number. After that, the app MUST NOT let the person change or add a weigh-in for that day.

#### Scenario: On the weigh-in day
- **WHEN** the weigh-in day is Monday and the person opens the weigh-in screen at 08:00 on Monday 28 September
- **THEN** the screen shows the weight input, the unit control and "Save"

#### Scenario: On another day
- **WHEN** the weigh-in day is Monday and the person opens the weigh-in screen on Thursday 24 September
- **THEN** the screen shows no weight input and the text "Your weigh-in day is Monday. The app asks once a week, because day-to-day numbers move on their own. Next: Monday 28 September."

#### Scenario: Change the number within 10 minutes
- **WHEN** the person saved 68.6 kg at 08:00 on Monday 28 September and opens the screen again at 08:05 that day
- **THEN** the screen shows 68.6 kg in the input, the person can change it to 66.8 kg and save, and the store holds one weigh-in for that day

#### Scenario: The number is fixed after 10 minutes
- **WHEN** the person saved 68.6 kg at 08:00 on Monday 28 September and opens the screen again at 08:15 that day
- **THEN** the screen shows the chart and no weight input, and the Monday weigh-in stays 68.6 kg

#### Scenario: The weigh-in day ended
- **WHEN** the person saved a weigh-in on Monday 28 September and opens the screen at 10:00 on Tuesday 29 September
- **THEN** the screen shows no weight input, the Monday weigh-in cannot change, and the refusal text ends "Next: Monday 5 October."

#### Scenario: Weigh-in day changed within six days of the last weigh-in
- **WHEN** the person saved a weigh-in on Monday 28 September, changed the weigh-in day to Friday, and opens the screen on Friday 2 October
- **THEN** the screen shows no weight input and the refusal text "Your weigh-in day is Friday. The app asks once a week, because day-to-day numbers move on their own. Next: Friday 9 October."

### Requirement: The number and its unit

The app MUST let the person enter the weight in kilograms or in stone and pounds. The unit control MUST offer "kg" and "st lb". The default unit MUST be "kg". The person MUST be able to change the unit at any time from the weigh-in screen. A unit change MUST change the display of every weigh-in, the chart and the explanation. A unit change MUST NOT change any saved value.

With the unit "st lb" the app MUST show every value to the nearest whole pound. That rule covers the chart, its axis, the rolling average and the weigh-in page in an export.

The app MUST accept kilograms to one decimal place. The app MUST accept stone as a whole number and pounds as a whole number from 0 to 13. The pounds input MUST NOT accept a decimal. The app MUST accept any weight of 30 kg or more, and the same in stone and pounds. The app MUST NOT set an upper bound.

When the number is below 30 kg, the app MUST show "That number is outside the range the app accepts. Check it and try again." The app MUST NOT save that number. The store MUST keep each weigh-in as kilograms to two decimal places, with the unit the person used.

The weight input MUST open empty. The app MUST NOT show the previous weigh-in as a starting value. The app MUST NOT offer a slider or a suggested number.

#### Scenario: Kilograms
- **WHEN** the person types 66.8 with the unit "kg" and saves
- **THEN** the store keeps 66.80 kg with the unit "kg"

#### Scenario: Stone and pounds
- **WHEN** the person enters 10 st 7 lb with the unit "st lb" and saves
- **THEN** the store keeps 66.68 kg with the unit "st lb"

#### Scenario: Below the range
- **WHEN** the person types 6.8 with the unit "kg" and taps "Save"
- **THEN** the app shows "That number is outside the range the app accepts. Check it and try again." and saves nothing

#### Scenario: No upper bound
- **WHEN** the person types 312.4 with the unit "kg" and taps "Save"
- **THEN** the store keeps 312.40 kg with the unit "kg" and the app shows no message

#### Scenario: Unit change after weigh-ins
- **WHEN** the person has a weigh-in of 66.80 kg and changes the unit to "st lb"
- **THEN** the chart shows that weigh-in as 10 st 7 lb and the store still holds 66.80 kg

#### Scenario: Whole pounds on display
- **WHEN** the person has a weigh-in of 66.40 kg and the unit is "st lb"
- **THEN** the screen shows that weigh-in as 10 st 6 lb and no decimal pound

#### Scenario: Whole pounds on input
- **WHEN** the unit is "st lb" and the person enters the pounds
- **THEN** the pounds input accepts a whole number from 0 to 13 and offers no decimal

#### Scenario: Empty input
- **WHEN** the person opens the weigh-in screen on the weigh-in day before saving
- **THEN** the weight input holds no number

### Requirement: The rolling average

For each weigh-in, the app MUST compute a rolling average. The average is the mean of that weigh-in and every weigh-in in the 27 days before its day. That window is ROLLING_AVERAGE_WEEKS = 4 weeks. `programme` holds the constant in `ProgrammeConstants`. The app MUST compute the average from the saved kilogram values. The app MUST use only the weigh-ins that exist in the window.

The app MUST NOT fill a missing week with an estimate, the previous value or zero. For display, the app MUST round the average to one decimal place in kilograms, or to the nearest whole pound.

#### Scenario: Four weeks of weigh-ins
- **WHEN** the weigh-ins are 66.8 kg on 28 September, 66.2 kg on 5 October, 67.1 kg on 12 October and 66.4 kg on 19 October
- **THEN** the rolling average at 19 October is 66.6 kg

#### Scenario: The window moves
- **WHEN** the person adds 66.0 kg on 26 October to the four weigh-ins above
- **THEN** the rolling average at 26 October is 66.4 kg and the 28 September weigh-in is outside the window

#### Scenario: First weigh-in
- **WHEN** the person saves the first weigh-in, 66.8 kg
- **THEN** the rolling average at that weigh-in is 66.8 kg

#### Scenario: A missing week
- **WHEN** the weigh-ins are 66.8 kg on 28 September, 66.2 kg on 5 October, none on 12 October and 66.4 kg on 19 October
- **THEN** the rolling average at 19 October is the mean of three values, 66.5 kg

#### Scenario: A gap of five weeks
- **WHEN** the weigh-ins are 66.2 kg on 5 October and 65.9 kg on 9 November, with none between
- **THEN** the rolling average at 9 November is 65.9 kg

### Requirement: The chart

When at least one weigh-in exists, the weigh-in screen MUST show a chart on every day. The chart MUST show a line through the rolling averages, one per weigh-in, in date order. The chart MUST show every weigh-in as a point.

Each point MUST be at least 6 points across and in the secondary text colour. Each point MUST contrast with the chart's background at 3:1 or more. That contrast MUST hold in light mode, in dark mode and with Increase Contrast on. The line MUST use the primary text colour. The chart MUST use no other colour.

A point MUST NOT carry a label. The vertical axis MUST show at most three values, in the person's unit. The horizontal axis MUST show at most one label per month. The chart MUST show every weigh-in in the programme. The chart MUST NOT show a target line, a goal, a band, a BMI or an arrow. The chart MUST NOT show a change between weigh-ins.

With one weigh-in the chart MUST show one point and no line. Across a missing week the line MUST join the two neighbouring averages, with no point for the missing week.

#### Scenario: Twelve weigh-ins
- **WHEN** the person has twelve weigh-ins and opens the weigh-in screen
- **THEN** the chart shows a line through twelve rolling averages, twelve points at least 6 points across in a lighter tone than the line, and no label on any point

#### Scenario: Point contrast
- **WHEN** the device is in dark mode with Increase Contrast on and the chart shows
- **THEN** each point contrasts with the chart's background at 3:1 or more

#### Scenario: One weigh-in
- **WHEN** the person has one weigh-in of 66.8 kg
- **THEN** the chart shows one point and no line

#### Scenario: A missing week on the chart
- **WHEN** the person has weigh-ins on 28 September, 5 October and 19 October, and none on 12 October
- **THEN** the chart shows three points, and the line joins the 5 October average to the 19 October average

#### Scenario: No weigh-in yet
- **WHEN** the person has no weigh-in and opens the screen on a day that is not the weigh-in day
- **THEN** the screen shows the refusal text and no chart

#### Scenario: No weigh-in day and no weigh-in
- **WHEN** the person has no weigh-in day and no weigh-in, and opens the screen
- **THEN** the screen shows "Choose a weigh-in day" and no chart

### Requirement: The one-line explanation

Whenever the screen shows the chart, it MUST show one sentence under the chart in the body text style. With the unit "kg" the sentence MUST be "Weekly swings of a kilo or two are normal and mean nothing on their own." With the unit "st lb" the sentence MUST be "Weekly swings of two or three pounds are normal and mean nothing on their own." The screen MUST show no other text about the trend.

#### Scenario: Explanation in kilograms
- **WHEN** the unit is "kg" and the screen shows the chart
- **THEN** the sentence under the chart reads "Weekly swings of a kilo or two are normal and mean nothing on their own."

#### Scenario: Explanation in stone and pounds
- **WHEN** the unit is "st lb" and the screen shows the chart
- **THEN** the sentence under the chart reads "Weekly swings of two or three pounds are normal and mean nothing on their own."

#### Scenario: After a save
- **WHEN** the person saves a weigh-in 1.4 kg below the previous one
- **THEN** the screen shows the same sentence and no other text about the change

### Requirement: What the weigh-in never shows

The weigh-in screen MUST NOT show a goal weight, a target line, a BMI or an arrow. The screen MUST NOT show a difference between two weigh-ins. The screen MUST NOT use the words "up", "down", "lost" or "gained" about weight. The screen MUST NOT compare the person to any other person or to a norm. The screen MUST NOT count weigh-ins or missed weigh-ins.

Save MUST be quiet. On save the app MUST NOT add a confirmation, a message, a sound or a haptic. On save the app MUST NOT add a colour change or an animation. The system's standard control update is not an addition. The never list in `product-rules` applies to the whole screen.

#### Scenario: Save a lower number
- **WHEN** the person saves 66.0 kg after a rolling average of 66.6 kg
- **THEN** the chart shows the new point and the new average, and the screen shows no message, arrow or difference

#### Scenario: Save a higher number
- **WHEN** the person saves 67.9 kg after a rolling average of 66.6 kg
- **THEN** the chart shows the new point and the new average, and the screen shows no message, arrow or difference

#### Scenario: A glance at the weigh-in screen
- **WHEN** a person sees the weigh-in screen
- **THEN** they see one line, its points, at most three axis values and one sentence, and no goal, BMI or colour

### Requirement: A missed weigh-in day

When the weigh-in day passes with no weigh-in, the app MUST save nothing. The app MUST show nothing about it on any screen. The app MUST NOT ask the person to weigh on a later day. The app MUST NOT show a message about the missed week on the weigh-in screen.

The app MUST make the status of each week's weigh-in, done or not done, available to `weekly-review`. `weekly-review` owns how it shows that status. `reminders` owns the weigh-in day reminder.

With no weigh-in day, no week has a missed weigh-in. The app MUST then report to `weekly-review` and `staying-on-track` that no weigh-in day exists. Those capabilities leave the weigh-in part out of the review or the check-in.

#### Scenario: One skipped week
- **WHEN** the weigh-in day is Monday and Monday 5 October passes with no weigh-in
- **THEN** the app shows nothing about it, and on Monday 12 October the screen shows the weight input as usual

#### Scenario: Two skipped weeks
- **WHEN** Monday 5 October and Monday 12 October pass with no weigh-in
- **THEN** the app shows nothing about it, and on Monday 19 October the screen shows the weight input as usual

#### Scenario: The weekly review reads the status
- **WHEN** the weekly review builds the week of 5 October
- **THEN** the store reports that the week has no weigh-in, and the weigh-in screen shows nothing about it

#### Scenario: The weekly review with no weigh-in day
- **WHEN** the person has no weigh-in day and the weekly review builds the week of 5 October
- **THEN** the store reports that no weigh-in day exists, and the review shows no weigh-in part

### Requirement: The weigh-in stays off Today, widgets and notifications

Today MUST NOT show a weight value, the rolling average, the weigh-in status or the word "weight". A widget MUST NOT show a weight value, the rolling average, the weigh-in status or the word "weight". A notification MUST NOT carry a weight value. `reminders` owns the weigh-in day reminder's text. When the app is not active, the weigh-in screen MUST hide every weight value and the chart. The app MUST NOT index a weigh-in in Spotlight, donate it to Siri or place it in an NSUserActivity.

#### Scenario: Today on the weigh-in day
- **WHEN** the person opens Today on Monday 28 September
- **THEN** Today shows the record and no text about the weigh-in

#### Scenario: A widget
- **WHEN** a Midmorning widget is on the Lock Screen or the Home Screen
- **THEN** the widget shows no weight value and no word about weight

#### Scenario: App switcher
- **WHEN** the person opens the app switcher while the weigh-in screen shows the chart
- **THEN** the app's snapshot shows no weight value and no chart

### Requirement: The trend feeds safeguarding

The app MUST make every weigh-in, with its date and its kilogram value, and every rolling average available to `safeguarding`. `safeguarding` owns the underweight check and defines its Rules A, B and C. Rule A shows the not-right-now page. Rules B and C show the GP suggestion page, and the plan and its reminders stay on. `safeguarding` owns both pages and their text.

The weigh-in screen MUST NOT judge the trend. The weigh-in screen MUST NOT show any message from the check. `safeguarding` MUST run the underweight check only when at least one weigh-in exists. With no weigh-in day and no weigh-in, the check MUST NOT run.

#### Scenario: The rolling average falls
- **WHEN** the rolling average falls across four weigh-ins
- **THEN** `safeguarding` reads the weigh-ins and averages, and the weigh-in screen shows the chart and the explanation and nothing else

#### Scenario: Rule A applies after a weigh-in
- **WHEN** the person saves a weigh-in and `safeguarding` finds that Rule A applies
- **THEN** `safeguarding` shows the not-right-now page, and the weigh-in screen itself adds no text, colour or icon

#### Scenario: Rule B or Rule C applies after a weigh-in
- **WHEN** the person saves a weigh-in and `safeguarding` finds that Rule B or Rule C applies
- **THEN** `safeguarding` shows the GP suggestion page, the plan and its reminders stay on, and the weigh-in screen itself adds no text, colour or icon

#### Scenario: No weigh-in, no check
- **WHEN** the person has no weigh-in day and no weigh-in, and opens the app on any day
- **THEN** the underweight check does not run, and no page from the check shows

### Requirement: The store keeps the weigh-in on the device and away from HealthKit

The store MUST keep each weigh-in as one row. The row holds its record day key, its kilogram value, its unit, its `savedAt` and its `changedAt`. The record day key is the weigh-in's natural key. `savedAt` is the moment of the first save and MUST NOT change. A change within the 10 minutes MUST write into the same row with a later `changedAt`. When two versions share a key, the app MUST read the version with the later `changedAt`.

The app MUST NOT read a CKRecord system date for a weigh-in. Only Delete-all deletes a weigh-in row. The store MUST write the record day key at save. The key MUST be the current record day at the save moment. That day comes from the device zone and the day start in force.

A weigh-in MUST NOT change record day after save. Every reader of a weigh-in MUST use the saved key. `record` defines the record day and the day start.

The weigh-in MUST have the same file protection and backup exclusion as an entry. `record` sets those. A weight value MUST NOT leave the device except to the person's own iCloud private database. `data-and-privacy` owns sync and Delete-all.

The app MUST NOT write a weight value to the system log, an error description or a crash report. The weigh-in MUST work with no network.

The app MUST NOT read from or write to HealthKit. The app MUST NOT request the HealthKit entitlement. The app MUST NOT offer a HealthKit switch.

#### Scenario: The record day key is written at save
- **WHEN** the person saves a weigh-in at 08:00 on Monday 28 September with the day start at 04:00
- **THEN** the store writes the record day key Monday 28 September with the weigh-in

#### Scenario: A change writes into the same row
- **WHEN** the person saved 68.6 kg at 08:00 on Monday 28 September and changes it to 66.8 kg at 08:05
- **THEN** the store holds one row for that record day key with 66.80 kg, `savedAt` 08:00 and `changedAt` 08:05

#### Scenario: Two devices save the same weigh-in day
- **WHEN** device A saved 68.6 kg at 08:00 and device B saved 68.4 kg at 08:03 for the record day key Monday 28 September, and both then sync
- **THEN** every device shows 68.4 kg for that day, the version with the later `changedAt`, and the chart shows one point for the day

#### Scenario: The day start changes after a save
- **WHEN** a weigh-in holds the record day key Monday 28 September and the person later sets the day start to 09:00
- **THEN** the weigh-in keeps the key Monday 28 September, and the chart and the export read that key

#### Scenario: The device zone changes after a save
- **WHEN** a weigh-in holds the record day key Monday 28 September and the device later changes time zone
- **THEN** the weigh-in keeps the key Monday 28 September

#### Scenario: No network
- **WHEN** the device has no network connection on the weigh-in day
- **THEN** the person can save a weigh-in and see the chart

#### Scenario: Store error
- **WHEN** the store fails to save a weigh-in of 66.8 kg
- **THEN** the error the store throws contains no weight value

#### Scenario: The Health app
- **WHEN** the person saves a weigh-in and opens the Health app
- **THEN** the Health app shows no weight from Midmorning and the app has asked for no Health permission

#### Scenario: Delete-all
- **WHEN** the person uses Delete-all
- **THEN** the store holds no weigh-in and the weigh-in screen shows no chart

### Requirement: The weigh-in page in an export

`export` owns the export and the choice to include weigh-ins. That choice MUST be off until the person turns it on. When the person includes weigh-ins, the export MUST add one page. That page MUST list each weigh-in in the date range with its date and its value in the person's unit. The page MUST NOT show a rolling average, a BMI, a goal, a difference between weigh-ins or a chart. When the person does not include weigh-ins, the export MUST hold no weight value.

#### Scenario: Weigh-ins included
- **WHEN** the person exports 28 September to 26 October with weigh-ins included and the unit "kg"
- **THEN** the export has one weigh-in page with five rows, each with a date and a value in kg, and no rolling average

#### Scenario: Weigh-ins not included
- **WHEN** the person exports 28 September to 26 October without weigh-ins
- **THEN** the export holds no weight value

### Requirement: Accessibility of the weigh-in

Every control on the weigh-in screen MUST have a VoiceOver label. The weight input's label MUST be "Weight". The unit control's label MUST be "Unit". The weigh-in day control's label MUST be "Weigh-in day". With no weigh-in day, "Choose a weigh-in day" MUST be a heading. Each weekday choice MUST have the weekday's name as its label.

The chart MUST be one accessibility element with the label "Rolling average". The chart MUST provide the system audio graph so a person using VoiceOver can explore the line.

The line and the points MUST differ by shape and tone, not by colour alone. Text on the weigh-in screen MUST use system text styles. That text MUST scale with Dynamic Type. A control with no visible text MUST have a label a person can say with Voice Control. The hit-area rule in `product-rules` applies to every control on the screen.

#### Scenario: VoiceOver on the weigh-in day
- **WHEN** a person using VoiceOver opens the weigh-in screen on the weigh-in day
- **THEN** VoiceOver reads "Weight", "Unit", "Save" and "Weigh-in day", and the person can save a weigh-in without sight

#### Scenario: VoiceOver on the chart
- **WHEN** a person using VoiceOver reaches the chart
- **THEN** VoiceOver reads "Rolling average" and offers the audio graph

#### Scenario: VoiceOver with no weigh-in day
- **WHEN** a person using VoiceOver opens the weigh-in screen with no weigh-in day
- **THEN** VoiceOver reads "Choose a weigh-in day, heading", then "Monday" to "Sunday", and a double tap on "Friday" sets the weigh-in day

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the weigh-in screen shows the refusal text, the input and the controls without truncation

#### Scenario: Voice Control
- **WHEN** a person using Voice Control says "Show names" on the weigh-in screen
- **THEN** every control shows a name, and "Tap Save" saves the weigh-in
