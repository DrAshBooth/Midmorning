# reminders

## Purpose

A reminder is a notification the app schedules. Reminders hold the structure of the day for the person. They cover each planned meal, the morning plan, midday, the close of the day, the weigh-in day and the weekly review. They also cover a worksheet review and a check-in. Every reminder is discreet by default, capped, silent inside quiet hours, and switchable one type at a time.

## ADDED Requirements

### Requirement: Worksheet review and check-in reminders

The `problem-solving` capability asks the scheduler for one worksheet review reminder per worksheet, on the review day of that worksheet. That capability sets the review day. The reminder's time is the "Weekly review time", which defaults to 18:00. The `staying-on-track` capability asks for a check-in reminder at CHECK_IN_WEEKS = 4, 8 and 12 weeks after the finish, at the weekly review time. The scheduler MUST schedule both types under their own switches, "Worksheet review" and "Check-in". The scheduler MUST hold each as a far single reminder outside the rolling horizon.

A tap on a worksheet review reminder MUST open that worksheet at step 6, "How did it go?", as a sheet over Today. A tap on a check-in reminder MUST open the check-in. "A tap on a reminder opens its screen from Today" states what happens when another screen shows. Both types MUST use the discreet text by default. Their explicit titles MUST be "Worksheet review" and "Check-in". In the drop order, both types MUST sit with the other capabilities' reminders. When the scheduler drops one for the cap, it MUST move to the next record day. A check-in reminder moves only for the cap.

Each far single reminder MUST carry the id of its item. The item of a worksheet review reminder is the worksheet, and its id is the id of the worksheet row. The item of a check-in reminder is the check-in, and its id is the date key of its due day, as `staying-on-track` states. The request id MUST be the type and the item's id, for example "worksheetReview.<worksheet id>" or "checkIn.<due day key>". The userInfo MUST hold three keys: `kind`, `dayKey` and `itemId`. `dayKey` is the record day key of the day on which the reminder fires, and `itemId` is the item's id. The app MUST read the item from `itemId` when the person taps the reminder. The app MUST also read `itemId` when it takes a delivered reminder of that item off Notification Centre. So two worksheet review reminders on one record day have two request ids, and each tap opens its own worksheet.

The scheduler MUST read the current "Weekly review time" each time it computes the schedule. So a change of that time moves each worksheet review reminder that has not fired to the new time. The scheduler MUST place a worksheet review reminder on the first record day, from its review day, on which the pipeline keeps it. So when quiet hours, a paused day or the cap drop it on a record day, it moves to the next record day. There the scheduler places it at the "Weekly review time". The steps of the pipeline then apply on that day again. A paused day is a record day on which the person tapped "Pause for today". That tap makes the rest of the record day a paused day. The scheduler MUST NOT place the reminder at a moment that has passed. Ash ruled this on 12 October 2026 (r23-04).

A review day can be after the last day of the rolling horizon. Until it is inside the horizon, the scheduler MUST apply only steps 1, 2 and 7 of "The scheduler pipeline" to the reminder. The scheduler MUST apply every step from the first computation in which the review day is inside the horizon.

The move has a bound, so that nothing loops. A worksheet review reminder can fire only on its review day or on one of the REMINDER_HORIZON_DAYS record days after it. The bound MUST NOT change when the background refresh task extends the horizon. When the pipeline drops the reminder on each of those days, the reminder does not fire, and the scheduler MUST NOT move it further. Quiet hours are the same on every record day. So when the "Weekly review time" is inside quiet hours, the scheduler MUST NOT place the reminder on any day, and it does not fire. Quiet hours move a worksheet review reminder only when the same-minute shift of step 6 moved it into quiet hours.

While `remindersPausedAt` is set, step 2 drops the worksheet review reminder on every day, as it drops every reminder. When the person turns reminders on again, the scheduler places the reminder by the rules above. So it fires on the first record day inside the bound whose "Weekly review time" has not passed.

The scheduler MUST hold at most one pending worksheet review reminder per worksheet. The reminder fires at most once. The app MUST keep, in `Local.store`, the moment of the pending worksheet review reminder of each worksheet. Each computation MUST replace that moment with the moment that it places, or clear it when it places none. A kept moment that has passed means that the reminder fired at that moment. The app MUST then keep that moment, and the scheduler MUST NOT place the reminder again. Each device keeps its own moments, because each device sends its own reminders.

#### Scenario: A worksheet review reminder
- **WHEN** the person taps "Done" with text in step 5 on Monday 5 October, the "Weekly review time" is 18:00, and the `problem-solving` capability sets the review day Monday 12 October
- **THEN** the reminder fires at 18:00 on Monday 12 October, reads "Midmorning, 18:00", and a tap opens that worksheet at "How did it go?" as a sheet over Today

#### Scenario: The ids of a worksheet review reminder
- **WHEN** the scheduler places the worksheet review reminder of a worksheet for 18:00 on Saturday 17 October 2026
- **THEN** its request id is "worksheetReview." followed by the worksheet's id, and its userInfo holds `kind`, the `dayKey` of Saturday 17 October and the worksheet's id as `itemId`, and nothing else

#### Scenario: Two worksheet reviews on one record day
- **WHEN** two worksheets have the review day Saturday 17 October 2026, the "Weekly review time" is 18:00, and that day has no other reminder except the planned meal reminders
- **THEN** the reminder of the worksheet that started first fires at 18:00 and the other fires at 18:05, each with its own request id and `itemId`, and a tap on each opens its own worksheet at "How did it go?"

#### Scenario: A review day after the horizon
- **WHEN** the current record day is Monday 19 October 2026, the "Weekly review time" is 18:00, and a worksheet's review day is Saturday 31 October
- **THEN** the scheduler holds that worksheet review reminder for 18:00 on Saturday 31 October, and it applies the cap and the same-minute shift to it only from the first computation in which Saturday 31 October is inside the horizon

#### Scenario: Reminders paused on the review day
- **WHEN** `remindersPausedAt` is set at 10:00 on Saturday 17 October 2026, the review day of a worksheet, the person taps "Turn reminders on" at 09:00 on Monday 19 October, and those days have no other reminder except the planned meal reminders
- **THEN** no worksheet review reminder fires on Saturday 17 October or Sunday 18 October, and it fires at 18:00 on Monday 19 October

#### Scenario: The weekly review time changes
- **WHEN** a worksheet's review day is Saturday 17 October 2026, and on Thursday 15 October the person changes the "Weekly review time" from 18:00 to 19:30
- **THEN** the worksheet review reminder fires at 19:30 on Saturday 17 October

#### Scenario: A worksheet review on a paused day
- **WHEN** a worksheet's review day is Saturday 17 October 2026, and the person taps "Pause for today" at 14:00 that day
- **THEN** no worksheet review reminder fires on Saturday 17 October, and it fires at 18:00 on Sunday 18 October

#### Scenario: A worksheet review on the weekly review day
- **WHEN** the weekly review reminder and a worksheet review reminder are both due at 18:00 on Monday 19 October 2026, and that day has no other reminder except the planned meal reminders
- **THEN** the weekly review reminder fires at 18:00, and the worksheet review reminder moves five minutes later and fires at 18:05, as "Two reminders never share a minute" states

#### Scenario: A shift into quiet hours
- **WHEN** the "Weekly review time" is 21:55, quiet hours run from 22:00 to 07:00, the weekly review reminder and a worksheet review reminder are both due on Monday 19 October 2026, and that day has no other reminder except the planned meal reminders
- **THEN** the weekly review reminder fires at 21:55, the worksheet review reminder moves to 22:00 and quiet hours drop it, and it fires at 21:55 on Tuesday 20 October

#### Scenario: The weekly review time inside quiet hours
- **WHEN** quiet hours run from 17:00 to 07:00, the "Weekly review time" is 18:00, and a worksheet's review day is Saturday 17 October 2026
- **THEN** no worksheet review reminder fires for that worksheet on Saturday 17 October or on any later day

#### Scenario: No second reminder after it fires
- **WHEN** the worksheet review reminder of a worksheet fired at 18:00 on Saturday 17 October 2026, and at 19:00 the person changes the "Weekly review time" to 20:00
- **THEN** no second worksheet review reminder fires for that worksheet

#### Scenario: A check-in reminder
- **WHEN** the person finished on Sunday 20 December and the weekly review time is 18:00
- **THEN** a check-in reminder fires at 18:00 on Sunday 17 January, and a tap opens the check-in

#### Scenario: Check-in off
- **WHEN** "Check-in" is off
- **THEN** no check-in reminder fires, and the Today line "Check-in" still appears as the `staying-on-track` capability defines

### Requirement: Time Sensitive is opt-in

The Reminders group MUST show a switch "Break through Focus for planned meals" that defaults to off. That switch is the Time Sensitive setting. The app MUST hold the entitlement `com.apple.developer.usernotifications.time-sensitive`.

With the switch on, planned meal reminders MUST use the Time Sensitive interruption level. With the switch off, planned meal reminders MUST use the active interruption level. Every other reminder type MUST use the active interruption level. Quiet hours MUST apply to a Time Sensitive reminder as to any other.

#### Scenario: Default
- **WHEN** "Break through Focus for planned meals" is off and a Focus is on
- **THEN** the Lunch reminder uses the active interruption level, and the Focus decides its delivery

#### Scenario: Opted in
- **WHEN** "Break through Focus for planned meals" is on and a Focus that allows Time Sensitive notifications is on
- **THEN** iOS delivers the Lunch reminder as Time Sensitive

#### Scenario: Opted in during quiet hours
- **WHEN** "Break through Focus for planned meals" is on and Evening snack is at 22:30 inside quiet hours
- **THEN** no reminder fires for Evening snack

## MODIFIED Requirements

### Requirement: A tap on a reminder opens its screen from Today

When the person taps the body of a reminder, the app MUST first remove every screen from Today's navigation stack. The app MUST then open the screen of that reminder. The requirement of each reminder type names its screen, for example Today, "Today's plan", the close-the-day screen, the weigh-in screen or the weekly review. The weigh-in screen and the weekly review open on Today's navigation stack, so their back control MUST go back to Today.

When the new-entry screen shows unsaved input, the app MUST keep that screen and its input in front. Unsaved input is text in What or Context, a chosen Where, a typed place or the star. The app MUST open the screen of the reminder only after the new-entry screen closes.

A tap MUST NOT close a safeguarding page or a screen that holds answers. While the not-right-now page or the GP suggestion page shows, the app MUST keep the page in front. The app MUST open the screen of the reminder only after the person taps "Done" on the page. While the weekly review, the check-in, the restart re-screen or the weigh-in screen is open, the app MUST keep that screen. The app MUST open the screen of the reminder only after the person leaves that screen. When that screen is the screen of the reminder, the app MUST keep it and MUST NOT open it a second time. Ash ruled this on 11 October 2026 (r22-01).

A sheet of Today is the new-entry screen, the edit screen, the close-the-day screen, "Today's plan", the urge screen or a worksheet. While a sheet of Today shows, the app MUST keep the sheet in front. The app MUST open the screen of the reminder only after the sheet closes. A new-entry screen with no unsaved input MUST close first, and the screen of the reminder then opens. When the sheet is the screen of the reminder, the app MUST keep it, with its input, and MUST NOT open it a second time. So the midday reminder over a new-entry screen opens no second new-entry screen. The "Get support" sheet on Today stays in front, and the screen of the reminder opens under it. A sheet that a screen on Today's navigation stack shows closes with that screen, except the restart re-screen and a worksheet. Ash ruled on 11 October 2026 that the app keeps this build (r22-02).

The urge screen is a sheet of Today, as `urge-toolkit` states. So a tap MUST NOT close the urge screen or a screen that the person opened from it. The app MUST open the screen of the reminder only after the urge screen closes, with "Close" or with an outcome. This follows Ash's rulings of 11 October 2026 on the sheets of Today (r22-02) and of 12 October 2026 on the urge screen (r23-02).

After the outcome "I binged", the app MUST NOT open the screen of a reminder that waited for the urge screen. The app MUST drop that route and show Today. A line on Today that belongs to the reminder stays, for example the "Weekly review" line. So the moment after a binge stays quiet, as the holds after a binge in `record` keep it quiet (r1-10, r8-07).

A worksheet keeps a waiting route in the same way, over Today or over the Problem solving screen. While a worksheet shows, the app MUST keep it in front, with its text. The app MUST open the screen of the reminder only after the worksheet closes. When the reminder is the worksheet review reminder of the worksheet on screen, the app MUST keep that worksheet and MUST show its step 6. The app MUST NOT open that worksheet a second time. A worksheet holds the person's answers, so this follows Ash's ruling of 11 October 2026 on screens with answers (r22-01).

This requirement applies only to a tap on the body of a reminder. It does not change "Add", "Skipped" or the snooze action. While the app is locked, `app-lock` governs "Add", as its requirement "A new entry before authentication" states. Ash ruled this on 9 October 2026 (r20-01).

#### Scenario: A tap while another screen shows
- **WHEN** the person opens "Programme" from Today, goes to the Home Screen and taps the body of the Lunch reminder
- **THEN** Today shows, and Today's navigation stack holds no other screen

#### Scenario: A tap on the weigh-in day reminder while another screen shows
- **WHEN** the person opens "Programme" from Today, goes to the Home Screen and taps the body of the weigh-in day reminder
- **THEN** the weigh-in screen shows, and a tap on its back control shows Today, not "Programme"

#### Scenario: A tap over a new entry with a draft
- **WHEN** the new-entry screen shows "Toast and" in What, the person taps the body of the weigh-in day reminder, and then taps "Save"
- **THEN** the new-entry screen and "Toast and" stay in front until the save, and after the save the weigh-in screen shows on Today's navigation stack

#### Scenario: A tap over a new entry with only the star
- **WHEN** the new-entry screen shows no text and the star is on, the person taps the body of the weigh-in day reminder, and then taps "Cancel"
- **THEN** the new-entry screen and the star stay in front until "Cancel", and after it the weigh-in screen shows on Today's navigation stack

#### Scenario: A tap over an empty new entry
- **WHEN** the new-entry screen shows no input and the person taps the body of the weigh-in day reminder
- **THEN** the new-entry screen closes, and the weigh-in screen shows on Today's navigation stack

#### Scenario: The midday reminder over a new entry
- **WHEN** the new-entry screen shows "Jam" in What, the person taps the body of the midday reminder, and then taps "Save"
- **THEN** the new-entry screen and "Jam" stay in front until the save, and after the save Today shows with no second new-entry screen

#### Scenario: A tap while the close-the-day screen shows
- **WHEN** the close-the-day screen shows and the person taps the body of the weigh-in day reminder, and then taps "Done"
- **THEN** the close-the-day screen stays until "Done", and after it the weigh-in screen shows on Today's navigation stack

#### Scenario: A tap while the GP suggestion page shows
- **WHEN** the weekly review shows the GP suggestion page and the person taps the body of the Lunch reminder
- **THEN** the GP suggestion page stays with its "Done", and after "Done" the weekly review shows

#### Scenario: A tap while the not-right-now page shows
- **WHEN** the weekly review shows the not-right-now page with "Samaritans are there any time, on 116 123. If you are in danger now, call 999." and the person taps the body of the weigh-in day reminder
- **THEN** the page and its text stay until "Done", the weekly review shows after "Done", and the weigh-in screen shows on Today's navigation stack after the person leaves the review

#### Scenario: A tap while the weekly review holds answers
- **WHEN** the weekly review shows "Work was busy" in "What made things harder?" and the person taps the body of the Lunch reminder
- **THEN** the weekly review and "Work was busy" stay, and after "Done" on the review only Today shows

#### Scenario: A tap while the restart re-screen shows
- **WHEN** the restart re-screen shows over "Programme" and the person taps the body of the Lunch reminder
- **THEN** the re-screen and its answers stay, and after the person leaves the re-screen, Today shows with no other screen on its navigation stack

#### Scenario: The weigh-in day reminder on the weigh-in screen
- **WHEN** the weigh-in screen shows "62.5" in its weight field and the person taps the body of the weigh-in day reminder
- **THEN** the weigh-in screen and "62.5" stay, no second weigh-in screen opens, and after "Back" Today shows

#### Scenario: A tap while the urge screen shows
- **WHEN** the urge screen shows an urge that started at 21:30 on Tuesday 13 October 2026, the person taps the body of the close-the-day reminder at 21:46, and then taps "It passed"
- **THEN** the urge screen stays until "It passed", and after it the close-the-day screen shows

#### Scenario: A tap while the urge screen shows, then "Close"
- **WHEN** the urge screen shows an urge that started at 17:50 on Monday 19 October 2026, the person taps the body of the weekly review reminder at 18:01, and then taps "Close"
- **THEN** the urge screen stays until "Close", the urge stays open, and after "Close" the weekly review shows on Today's navigation stack

#### Scenario: A tap while the urge screen shows, then "I binged"
- **WHEN** the urge screen shows an urge that started at 17:50 on Monday 19 October 2026, the person taps the body of the weekly review reminder at 18:01, then taps "I binged" and saves the entry at 18:04
- **THEN** the weekly review does not open, Today shows, and Today still shows the "Weekly review" line

#### Scenario: A tap while a worksheet shows
- **WHEN** a worksheet shows over the Problem solving screen with "Evenings after a missed lunch" in step 1, the person taps the body of the weekly review reminder at 18:01 on Monday 19 October 2026, and then taps "Done"
- **THEN** the worksheet and its text stay in front until "Done", and after it the weekly review shows on Today's navigation stack

#### Scenario: The review reminder of the worksheet on screen
- **WHEN** a worksheet shows at step 2, and the person taps the body of the worksheet review reminder of that worksheet
- **THEN** the same worksheet stays with its text and shows step 6, "How did it go?", and no second worksheet opens

### Requirement: Reminder types and their switches

There are eight reminder types. Six are the app's own: the planned meal, morning plan, midday, close-the-day, weigh-in day and weekly review reminders. Two come from other capabilities: the worksheet review reminder and the check-in reminder. The Reminders group on the settings screen MUST show a switch for each type under "Which reminders". The `settings` capability lays out that group.

The switch labels are "Planned meals", "Set today's plan", "Midday reminder", "Close the day", "Weigh-in day reminder", "Weekly review", "Worksheet review" and "Check-in". Every switch MUST default to on.

Each switch is a device setting in `Local.store`, as the `data-and-privacy` capability states. The Reminders group MUST show "Each device sends its own reminders." under the switches. When a switch is off, the scheduler MUST cancel every pending reminder of that type. The scheduler MUST schedule none of that type while the switch is off. The same scheduler MUST schedule every reminder that another capability asks for.

When the person has not granted notification permission, the scheduler MUST schedule nothing. Every switch MUST then stay on. Every switch MUST have a VoiceOver label. Text in the Reminders group MUST scale with Dynamic Type.

When notification permission is not determined, the Reminders group MUST show "Reminders need notification permission." with a control "Allow notifications". That control MUST make the system permission request. Today MUST then show the line "Allow notifications to get reminders." under the current day heading. A tap on that line MUST make the system permission request.

The `record` capability owns the slot. This capability owns the rule. When the person grants permission, the app MUST hide the line. The app MUST then compute the schedule.

When permission is denied, the Reminders group MUST show "Notifications are off in iOS Settings. The plan still shows on Today, and the Home Screen widget can show your next planned time." It MUST show that text with a control that opens the iOS Settings app and a control "Show me the widget". "Show me the widget" MUST open a page that shows the Home Screen widget and how to add it.

When permission is denied and any switch is on, Today MUST show a line under the current day heading. The line reads "Notifications are off in iOS Settings.". That line MUST be a control that opens the iOS Settings app. After the person taps the line once, the app MUST hide it while permission stays denied. Only the Reminders group then shows the state.

The app MUST keep that tap as a device flag in `Local.store`. From stage 2 with permission denied, the `widgets-and-intents` capability defaults "Show next planned time" to on, and the stage 2 opening card names the widget.

#### Scenario: Turn off planned meal reminders
- **WHEN** the person turns off "Planned meals" at 10:00 with Lunch at 13:00 pending
- **THEN** the scheduler cancels the 13:00 reminder, and the close-the-day reminder still fires at 21:45

#### Scenario: Permission not determined
- **WHEN** the person has not answered the system permission request and opens the Reminders group
- **THEN** the scheduler schedules nothing, every switch stays on, and the group shows "Reminders need notification permission." with "Allow notifications", and a tap on it makes the system permission request

#### Scenario: The line before permission
- **WHEN** notification permission is not determined and the person opens Today
- **THEN** Today shows "Allow notifications to get reminders." under the current day heading, and a tap makes the system permission request

#### Scenario: Permission granted from the line
- **WHEN** the person taps "Allow notifications to get reminders.", allows notifications in the system permission request, and today's plan has Lunch at 13:00
- **THEN** Today hides the line, and the scheduler schedules the 13:00 reminder

#### Scenario: Permission denied
- **WHEN** the person declined notification permission
- **THEN** the scheduler schedules nothing, every switch stays on, and the Reminders group shows "Notifications are off in iOS Settings. The plan still shows on Today, and the Home Screen widget can show your next planned time." with "Show me the widget"

#### Scenario: The line on Today
- **WHEN** the person declined notification permission and opens Today
- **THEN** Today shows "Notifications are off in iOS Settings." under the current day heading, and a tap opens the iOS Settings app

#### Scenario: The line after one tap
- **WHEN** the person tapped "Notifications are off in iOS Settings." on Today once and opens Today again with permission still denied
- **THEN** Today shows no line, and the Reminders group still shows the state with its iOS Settings control

#### Scenario: Turn a type back on
- **WHEN** the person turns "Planned meals" on at 10:00 with Lunch at 13:00 in today's plan
- **THEN** the scheduler schedules the 13:00 reminder

#### Scenario: Worksheet review off
- **WHEN** "Worksheet review" is off and the person saves a worksheet
- **THEN** the scheduler schedules no worksheet review reminder

#### Scenario: Two devices
- **WHEN** the person turns off "Midday reminder" on one device
- **THEN** the other device still sends the midday reminder, and both show "Each device sends its own reminders."

### Requirement: A reminder for every planned meal

The scheduler MUST schedule one reminder at the time of each planned meal in every record day inside the horizon. The scheduling requirement defines the horizon. For a record day the app has not materialised, the scheduler MUST use the day's template. When a day's plan changes, the scheduler MUST schedule that day's planned meal reminders again.

When an entry matches a planned meal before its time, the scheduler MUST cancel that reminder. When an entry matches a planned meal after its reminder's delivery, the app MUST take that reminder off Notification Centre. The delivered-reminders requirement states when else the app takes one off. The `regular-eating-plan` capability defines the window and the matching.

#### Scenario: A planned meal at its time
- **WHEN** today's plan has Lunch at 13:00
- **THEN** a reminder fires at 13:00

#### Scenario: The plan changes
- **WHEN** the person moves Lunch from 13:00 to 13:30 at 09:00
- **THEN** the scheduler cancels the 13:00 reminder, and a reminder fires at 13:30

#### Scenario: An entry before the time
- **WHEN** the person saves an entry at 12:40 that matches Lunch at 13:00
- **THEN** no reminder fires at 13:00

#### Scenario: An entry after the reminder
- **WHEN** the Lunch reminder fired at 13:00 and the person saves an entry at 13:20 that matches Lunch
- **THEN** the app takes the delivered reminder off Notification Centre

#### Scenario: A day beyond tomorrow
- **WHEN** the current day is Monday and the weekday template has Lunch at 13:00
- **THEN** the scheduler holds a Lunch reminder at 13:00 for Wednesday from the template

### Requirement: Actions on a planned meal reminder

A planned meal reminder MUST offer three actions, in this order: the snooze action, "Add" and "Skipped". The snooze action's title is the catalogue entry "Remind me in %lld minutes", filled from SNOOZE_MINUTES, which the "Remind me again in" setting chooses. The reminder MUST offer the same three actions whatever the explicit wording setting.

"Add" MUST open the new-entry screen with the keyboard in What. The time MUST default to the moment the screen opens, as for any new entry. "Add it" on the missed planned meal prompt keeps the planned meal's time, as `regular-eating-plan` states. The `app-lock` capability governs "Add" while the app is locked. "Skipped" MUST set the planned meal as skipped without opening the app. "Skipped" writes an Answer row keyed by the record day key and the slot index, with its own `changedAt`, as `regular-eating-plan` defines. The snooze action MUST snooze the reminder, as the snooze requirement defines. A tap on the reminder itself MUST open Today.

The app MUST register "Skipped" with the authentication-required option, because it writes the record. On a locked device, iOS MUST ask for the device unlock before "Skipped" runs. The app MUST register "Add" with the foreground option, because it opens the app. A foreground action needs the device unlocked, so iOS asks for the device unlock before "Add" opens the app. The app MUST register the snooze action with neither option. The snooze action MUST NOT require the person to unlock the device.

Every planned meal reminder MUST carry a userInfo with seven keys. The keys are the record day key, the slot index, the planned time and the next planned meal's time. Then come the snooze count, quiet hours and the snooze length. The record day key is the key that `record` defines. The userInfo MUST hold the slot index, never a label. The userInfo MUST hold nothing else.

The notification action handler MUST read the userInfo. The handler MUST NOT open the store. The handler MUST write the action to the action queue file. The `widgets-and-intents` capability defines the queue file and its protection class. The app MUST apply the queue to the store when protected data becomes available. The app MUST then compute the schedule again.

#### Scenario: Add
- **WHEN** the person taps "Add" on the 13:00 Lunch reminder at 13:20
- **THEN** the new-entry screen opens with the time 13:20, not 13:00, and the keyboard in What

#### Scenario: The three actions
- **WHEN** "Say what each reminder is for" is off, "Remind me again in" is "15 minutes", and the Lunch reminder fires
- **THEN** the reminder offers "Remind me in 15 minutes", "Add" and "Skipped", in that order

#### Scenario: The three actions with explicit wording on
- **WHEN** "Say what each reminder is for" is on, "Remind me again in" is "30 minutes", and the Lunch reminder fires
- **THEN** the reminder offers "Remind me in 30 minutes", "Add" and "Skipped", in that order

#### Scenario: Skipped
- **WHEN** the person taps "Skipped" on the Lunch reminder at 13:05 and Mid-afternoon is at 16:00
- **THEN** Lunch is skipped, the app does not open, and Today shows "Mid-afternoon at 16:00 still happens." the first time it appears after that

#### Scenario: Skipped from the Lock Screen
- **WHEN** the device is locked and the person taps "Skipped" on the Lunch reminder
- **THEN** iOS asks for the device unlock, the handler then writes the action to the queue, and the app does not open

#### Scenario: A snooze from the Lock Screen
- **WHEN** the device is locked and the person taps "Remind me in 15 minutes" on the Lunch reminder
- **THEN** iOS asks for no unlock, and the handler schedules the snoozed reminder from the userInfo

#### Scenario: Add from the Lock Screen
- **WHEN** the device is locked and the person taps "Add" on the 13:00 Lunch reminder at 13:10
- **THEN** iOS asks for the device unlock, and the app then opens the new-entry screen with the time 13:10, as the `app-lock` capability governs

#### Scenario: The slot index in the userInfo
- **WHEN** the person renamed "Lunch" to "Dinner" and the scheduler schedules that slot's reminder
- **THEN** the userInfo holds the slot index 2 and no label

#### Scenario: A tap on the reminder
- **WHEN** the person taps the body of the Lunch reminder
- **THEN** Today opens

### Requirement: Snooze a reminder

The snooze action MUST schedule the same reminder again after the snooze length. The Reminders group MUST show the setting "Remind me again in" with two options, "15 minutes" and "30 minutes". The setting MUST default to "15 minutes". Each option is the catalogue entry "%lld minutes" filled with its value.

The snooze action's title MUST be the one catalogue entry "Remind me in %lld minutes", filled with SNOOZE_MINUTES through a plural form. `ProgrammeConstants` holds SNOOZE_MINUTES = 15 or 30 and MAX_SNOOZES = 2. A snoozed reminder MUST show the same text and the same actions. The handler MUST schedule the snoozed reminder from the userInfo alone, with the snooze count plus one.

One pure function `SnoozeDecision.decide(userInfo:now:)` MUST hold every snooze rule. The function MUST return either a moment to schedule at or a drop. The handler and the scheduler MUST both call that function. The handler and the scheduler MUST NOT hold a snooze rule of their own.

The function MUST allow at most MAX_SNOOZES snoozes of one reminder. The function MUST drop a snooze that would fire inside quiet hours. The function MUST drop a snooze that would fire at or after the next planned meal's time.

A snooze MUST NOT count toward the cap. A snooze MUST NOT set a day's plan. The handler MUST write the snooze count to the action queue. The app MUST apply it to `Local.store`, keyed by the record day key and the slot index. The synced Answer row MUST NOT carry the snooze count.

#### Scenario: Remind me in 15 minutes
- **WHEN** the person taps "Remind me in 15 minutes" on the 13:00 Lunch reminder with "Remind me again in" at "15 minutes"
- **THEN** the same reminder fires at 13:15

#### Scenario: The thirty-minute title
- **WHEN** "Remind me again in" is "30 minutes" and the person taps "Remind me in 30 minutes" on the 13:00 Lunch reminder
- **THEN** the same reminder fires at 13:30

#### Scenario: A third snooze
- **WHEN** the person taps "Remind me in 15 minutes" on the Lunch reminder at 13:00, at 13:15 and at 13:30
- **THEN** the reminder does not fire again

#### Scenario: A snooze past the next planned meal
- **WHEN** the person taps "Remind me in 15 minutes" at 15:50 with Mid-afternoon at 16:00
- **THEN** the handler drops the snooze, and the Mid-afternoon reminder fires at 16:00

#### Scenario: A snooze into quiet hours
- **WHEN** quiet hours start at 22:00 and the person taps "Remind me in 15 minutes" on the 21:00 Evening snack reminder at 21:50
- **THEN** the handler drops the snooze, and no reminder fires at 22:05

#### Scenario: The pure function
- **WHEN** a test calls `SnoozeDecision.decide(userInfo:now:)` with a snooze count of 1, a snooze length of 15, quiet hours 22:00 to 07:00, a next planned meal at 16:00 and now at 13:15
- **THEN** the function returns 13:30, and the same call with a snooze count of 2 returns a drop

#### Scenario: A snooze survives a restart
- **WHEN** the person taps "Remind me in 15 minutes" once at 13:00 and restarts the device at 13:05
- **THEN** `Local.store` holds a snooze count of one under the record day key and the slot index 2, the Answer row holds none, and the reminder fires at 13:15

### Requirement: Discreet text by default

Every reminder MUST have an empty title. The body MUST be the catalogue entry "%@", for example "13:00". The app fills it with the reminder's time through the en_GB formatter, in the 24-hour clock. The body MUST hold nothing else. iOS then shows the app name once, so the reminder reads "Midmorning, 13:00".

The Reminders group MUST show a switch "Say what each reminder is for" that defaults to off. That switch is the explicit wording setting. This capability calls its state "explicit wording". The app MUST write the explicit wording flag into the widget snapshot, as the `widgets-and-intents` capability states.

With explicit wording on, the title MUST name the reminder. The body MUST still be the time. The explicit titles are the slot's label for a planned meal, "Set today's plan", "Anything to record from this morning?", "Close the day", "Weigh-in day", "Weekly review", "Worksheet review" and "Check-in". The slot's label is the person's label for that slot, or the default. The label is the Settings row `slot.label.<index>` that the `regular-eating-plan` capability owns, with the slot index. The app MUST compute the title in the app process, from the slot index, when it schedules the reminder.

Every reminder MUST play the system default sound, whatever the explicit wording setting. The person can turn that sound off for the app in the iOS Settings app.

The `product-rules` capability lists what a notification never shows. The app MUST NOT show a number on the app icon.

#### Scenario: A discreet planned meal reminder
- **WHEN** Lunch is at 13:00 and "Say what each reminder is for" is off
- **THEN** the reminder has an empty title and the body "13:00", and the notification shows "Midmorning" once

#### Scenario: An explicit planned meal reminder
- **WHEN** Mid-morning is at 10:30 and "Say what each reminder is for" is on
- **THEN** the reminder has the title "Mid-morning" and the body "10:30"

#### Scenario: An explicit reminder for a renamed slot
- **WHEN** the person renamed "Mid-morning" to "Elevenses", the slot is at 10:30, and "Say what each reminder is for" is on
- **THEN** the reminder has the title "Elevenses" and the body "10:30"

#### Scenario: A renamed slot with explicit wording off
- **WHEN** the person renamed "Mid-morning" to "Elevenses" and "Say what each reminder is for" is off
- **THEN** the reminder has an empty title and the body "10:30"

#### Scenario: An explicit close-the-day reminder
- **WHEN** "Say what each reminder is for" is on and the close-the-day time is 21:45
- **THEN** the reminder has the title "Close the day" and the body "21:45"

#### Scenario: An explicit check-in reminder
- **WHEN** "Say what each reminder is for" is on and a check-in reminder fires at 18:00
- **THEN** the reminder has the title "Check-in" and the body "18:00"

#### Scenario: The reminder sound
- **WHEN** "Say what each reminder is for" is off and the scheduler schedules the 13:00 Lunch reminder and the 21:45 close-the-day reminder
- **THEN** both reminders carry the system default sound

#### Scenario: The app icon
- **WHEN** three reminders fired today and the person has not opened the app
- **THEN** the app icon shows no number

### Requirement: Delivered reminders are grouped and removed

Every reminder MUST carry the same thread identifier, so Notification Centre groups them as one thread. The app MUST take a delivered planned meal reminder off Notification Centre when its window ends. The app MUST take every delivered reminder off Notification Centre at the end of the record day. The record day ends at the "Day starts at" time that the `settings` capability owns.

The app MUST take every delivered reminder off Notification Centre at launch. At launch, the app MUST read the delivered reminders before it takes them off. The morning plan requirement uses that reading for its unanswered count. The silent-days requirement uses it for its silent-day count.

#### Scenario: One thread
- **WHEN** the Breakfast reminder and the Lunch reminder are both in Notification Centre
- **THEN** Notification Centre shows them as one group

#### Scenario: The window ends
- **WHEN** the Lunch reminder fired at 13:00, no entry matched Lunch, and the time reaches 14:30
- **THEN** the app takes the delivered Lunch reminder off Notification Centre

#### Scenario: The end of the record day
- **WHEN** "Day starts at" is 04:00, the close-the-day reminder fired at 21:45, and it is still in Notification Centre at 04:00
- **THEN** the app takes it off Notification Centre at the start of the next record day

#### Scenario: A later day start
- **WHEN** "Day starts at" is 05:00 and the close-the-day reminder is still in Notification Centre at 04:30
- **THEN** the app keeps it until 05:00 and takes it off Notification Centre then

#### Scenario: Launch
- **WHEN** three delivered reminders are in Notification Centre and the person opens the app
- **THEN** Notification Centre holds no Midmorning reminder after Today appears

### Requirement: The morning plan reminder while the plan needs setting

The Reminders group MUST show a "Set today's plan time" control that defaults to 07:30. The scheduler MUST schedule the morning plan reminder at that time only when stage 2 is open. One of two conditions MUST also hold. No template exists: the person has not saved the weekday or the weekend template. Or the previous record day is a set day.

The `regular-eating-plan` capability defines a set day: a day for which the person saves an edit in "Today's plan" or "Tomorrow's plan". A slot rename and a template change are not edits of a day's plan, as that capability states.

When the person sets the current day's plan before the reminder time, the scheduler MUST cancel that day's reminder. A tap on the reminder MUST open "Today's plan".

A morning plan reminder is unanswered when three things hold. The system delivers it. The person does not tap it. The person does not set the day's plan that record day.

On return, the app MUST count at most one unanswered day per elapsed record day with a delivered reminder. After three consecutive unanswered morning plan reminders, the scheduler MUST stop the morning plan reminder. The scheduler MUST start it again, with the count at zero, when the person saves a plan or a template. The two conditions above still apply after that.

#### Scenario: No template yet
- **WHEN** stage 2 is open, the person has saved no template, and the time reaches 07:30
- **THEN** the morning plan reminder fires, and a tap opens "Today's plan"

#### Scenario: A template exists
- **WHEN** the person saved the weekday template on Monday, did not set Monday's plan, and the time reaches 07:30 on Tuesday
- **THEN** no morning plan reminder fires

#### Scenario: An edit the day before
- **WHEN** a template exists and the person saves an edit in "Today's plan" on Tuesday, and does not set Wednesday's plan
- **THEN** the morning plan reminder fires at 07:30 on Wednesday, and none fires on Thursday

#### Scenario: A template change
- **WHEN** a template exists and the person changes the weekday template on Thursday without an edit to Thursday's plan
- **THEN** no morning plan reminder fires on Friday

#### Scenario: Tomorrow set tonight
- **WHEN** the person saves "Tomorrow's plan" at 22:00 on Thursday
- **THEN** no morning plan reminder fires at 07:30 on Friday, and one fires at 07:30 on Saturday

#### Scenario: Three unanswered days
- **WHEN** no template exists, the system delivered the reminder on three consecutive days, and the person neither tapped it nor set a plan on any of them
- **THEN** no morning plan reminder fires on the fourth day, and it fires again the morning after the person saves "Today's plan"

#### Scenario: Days with no delivered reminder
- **WHEN** no template exists, the person does not open the app from Monday 5 October to Friday 16 October, and the horizon delivered morning plan reminders on Monday to Saturday only
- **THEN** the app counts six unanswered days, not eleven, and the morning plan reminder stays stopped until the person saves a plan or a template

#### Scenario: Stage 1
- **WHEN** stage 2 is not open
- **THEN** no morning plan reminder fires

### Requirement: Close the day

The Reminders group MUST show a "Close the day time" control that defaults to 21:45. The scheduler MUST schedule the close-the-day reminder at that time only on a record day where something is missing. In stage 1, something is missing when the day has no entry with a time after 17:00. From stage 2, something is missing when two things hold: the last planned meal has no matched entry, and no entry lies at or after its time. From stage 2, on a day with no planned meal, the stage 1 rule applies. When such an entry arrives before the close-the-day time, the scheduler MUST cancel that day's reminder.

A tap on the reminder MUST open the close-the-day screen. Today shows a "Close the day" control only after the last planned meal's time, or after 17:00 in stage 1. The `record` capability owns Today and that control. The app MUST take no more than two taps from the reminder to a saved word.

The screen MUST show the day's column, an "Add an entry" control and a text field labelled "One word for how today felt". "Add an entry" MUST open the new-entry screen. The text field MUST accept an empty text. The screen MUST show the "Didn't record" control that the `record` capability defines, under the column. The screen MUST close with "Done", quietly.

The store MUST keep the word as one DayState row with its own `changedAt`. The store MUST key the row by the record day key and its state kind. The `record` capability defines the record day key and the DayState rows. The store MUST write the key at the row's creation. The store MUST NOT hard-delete the row.

The screen MUST NOT show a count of entries or any text about the absence of entries. The screen MUST NOT hide Get support.

#### Scenario: The reminder
- **WHEN** stage 2 is not open, the day is not paused, the day has no entry after 17:00, and the time reaches 21:45
- **THEN** the close-the-day reminder fires, and a tap opens the close-the-day screen

#### Scenario: An evening entry in stage 1
- **WHEN** stage 2 is not open and the person saves an entry with the time 18:30
- **THEN** no close-the-day reminder fires at 21:45

#### Scenario: The last planned meal has an entry
- **WHEN** Evening snack at 21:00 is the day's last planned meal and an entry at 20:50 matches it
- **THEN** no close-the-day reminder fires at 21:45

#### Scenario: The last planned meal is missed
- **WHEN** Evening snack at 21:00 is the day's last planned meal, no entry matches it, and the day has no entry at or after 21:00
- **THEN** the close-the-day reminder fires at 21:45

#### Scenario: An entry after the last planned meal's time
- **WHEN** Evening meal at 19:00 is the day's last planned meal, no entry matches it, and the person saves an entry with the time 20:15
- **THEN** no close-the-day reminder fires at 21:45

#### Scenario: Add an entry
- **WHEN** the person taps "Add an entry" on the close-the-day screen
- **THEN** the new-entry screen opens with the keyboard in What

#### Scenario: One word
- **WHEN** the person types "tired" in "One word for how today felt" and taps "Done"
- **THEN** the store keeps "tired" with the current record day, and the screen closes with no message

#### Scenario: A day with no entries
- **WHEN** the current record day has no entry and the person opens the close-the-day screen
- **THEN** the screen shows the day's heading, "Add an entry", "One word for how today felt", "Didn't record" and "Done", and no other text

### Requirement: The midday reminder

The midday reminder's time is 12:00. The Reminders group offers no time control for it. The `settings` capability lists the four time controls. The Reminders group MUST show the text "The midday reminder is at %@." under the "Midday reminder" switch, with 12:00 through the en_GB formatter. The scheduler MUST schedule the midday reminder at 12:00.

The reminder MUST fire only when the current record day has no entry at that time. The reminder MUST NOT fire when the day's plan has a planned meal before that time. The reminder MUST NOT fire on a paused day. The reminder MUST NOT fire on a fasting day. The `record` capability owns the paused state and the fasting state. The scheduler MUST schedule at most one midday reminder per record day.

After the midday reminder, the scheduler MUST schedule no further reminder about the absence of entries until the close-the-day reminder. With explicit wording off, the midday reminder MUST read "Midmorning, 12:00". With explicit wording on, it MUST read "Anything to record from this morning?" with the time as the body. A tap on the reminder MUST open the new-entry screen.

#### Scenario: No entry by midday in stage 1
- **WHEN** stage 2 is not open and the current record day has no entry at 12:00
- **THEN** the midday reminder fires, reads "Midmorning, 12:00", and a tap opens the new-entry screen

#### Scenario: The explicit midday reminder
- **WHEN** "Say what each reminder is for" is on and the current record day has no entry at 12:00
- **THEN** the midday reminder reads "Anything to record from this morning?" with the body "12:00"

#### Scenario: The midday time on the settings screen
- **WHEN** the person opens the Reminders group
- **THEN** it shows "The midday reminder is at 12:00." under "Midday reminder", and no time control for the midday reminder

#### Scenario: An entry in the morning
- **WHEN** the person saved an entry at 09:00
- **THEN** no midday reminder fires

#### Scenario: A fasting day
- **WHEN** the person turned on "Fasting today" at 06:00 and the record day has no entry at 12:00
- **THEN** no midday reminder fires, and the close-the-day reminder still fires at 21:45 when the day meets its rule

#### Scenario: A plan with a morning planned meal
- **WHEN** today's plan has Breakfast at 08:00 and the record day has no entry at 12:00
- **THEN** no midday reminder fires

#### Scenario: A day with no entries at all
- **WHEN** the record day has no entry at 12:00 and none by 21:45
- **THEN** the person receives the midday reminder at 12:00, nothing between 12:00 and 21:45 about it, and the close-the-day reminder at 21:45

### Requirement: The midday and close-the-day reminders stop after seven silent days

A silent day is a record day with a delivered midday or close-the-day reminder and no entry by its end. After seven consecutive silent days, the scheduler MUST stop the midday reminder and the close-the-day reminder. A record day with an entry ends the run.

A record day with neither reminder delivered MUST NOT count as a silent day. Such a day MUST NOT end the run. On return, the app MUST count at most one silent day per elapsed record day. The delivered reminders it reads at launch supply that count.

The scheduler MUST start both types again when the person saves an entry. The stop MUST NOT change either switch. Today MUST show nothing about the stop. The Reminders group MUST show nothing about the stop. The stop decides whether the scheduler puts those two types into a day's reminders at all. The pipeline then runs as usual.

#### Scenario: Seven silent days
- **WHEN** the system delivered the close-the-day reminder on seven consecutive record days and none of them has an entry
- **THEN** no midday reminder and no close-the-day reminder fires on the eighth day, and Today shows nothing about it

#### Scenario: An entry ends the run
- **WHEN** five silent days ran Monday to Friday and the person saves an entry at 10:00 on Saturday
- **THEN** the run ends, and the close-the-day reminder fires at 21:45 on Saturday when the day meets its rule

#### Scenario: An entry after the stop
- **WHEN** both types are stopped and the person saves an entry at 10:00 on Tuesday
- **THEN** the midday reminder fires at 12:00 on Wednesday when Wednesday has no entry by then

#### Scenario: A paused day in the run
- **WHEN** six silent days ran Monday to Saturday, Sunday is paused, and Monday is a silent day
- **THEN** the run is seven silent days, and both types stop from Tuesday

#### Scenario: The switches stay as they were
- **WHEN** both types are stopped and the person opens the Reminders group
- **THEN** "Midday reminder" and "Close the day" show as they were, with no text about the stop

### Requirement: The cap of two other reminders a day

`ProgrammeConstants` holds MAX_OTHER_REMINDERS_PER_DAY = 2. The scheduler MUST count planned meal reminders separately. The scheduler MUST NOT drop a planned meal reminder for the cap. Of every other type together, at most two MUST fire on one record day. The scheduler MUST count reminders from every capability together. The scheduler MUST NOT count a snooze toward the cap.

When a day's other reminders would exceed two, the scheduler MUST drop reminders in this order until two remain. The order is: the midday reminder, the morning plan reminder, the worksheet review reminder, the check-in reminder, the weigh-in day reminder, the close-the-day reminder. The scheduler MUST NOT drop the weekly review reminder.

A worksheet review or check-in reminder that the cap drops MUST move to the next record day, where the cap applies again. A worksheet review reminder that quiet hours or a paused day drop MUST also move to the next record day. The same steps then apply on that day. "Worksheet review and check-in reminders" states the bound of that move. Ash ruled this on 12 October 2026 (r23-04). The scheduler MUST NOT move a dropped reminder of any other type. The next day has its own. The pipeline requirement states where the cap sits among the other steps.

#### Scenario: A weekday with three other reminders
- **WHEN** a day has the morning plan reminder, the midday reminder and the close-the-day reminder
- **THEN** the scheduler drops the midday reminder, and the other two fire

#### Scenario: The weekly review on the weigh-in day
- **WHEN** Sunday has the weigh-in day reminder, the weekly review reminder and the close-the-day reminder
- **THEN** the scheduler drops the weigh-in day reminder, and the weekly review and close-the-day reminders fire

#### Scenario: A worksheet review moves a day
- **WHEN** Sunday has the weekly review reminder, the close-the-day reminder and a worksheet review reminder, and Monday has the close-the-day reminder only
- **THEN** the worksheet review reminder fires on Monday at its time, with Monday's close-the-day reminder

#### Scenario: Six planned meals and two others
- **WHEN** a day has six planned meals, the weigh-in day reminder and the close-the-day reminder
- **THEN** all eight reminders fire

#### Scenario: Snoozes do not count
- **WHEN** a day has the weigh-in day reminder and the close-the-day reminder, and the person snoozes Lunch twice
- **THEN** both other reminders fire, and the day counts two other reminders toward the cap

### Requirement: Two reminders never share a minute

The scheduler MUST NOT schedule two reminders in the same minute. The priority order, from highest, starts with the planned meal reminder, the weekly review reminder, the close-the-day reminder and the weigh-in day reminder. Then come the check-in reminder, the worksheet review reminder, the morning plan reminder and the midday reminder. When two reminders share a minute, the scheduler MUST move the lower-priority one five minutes later. When two worksheet review reminders share a minute, the scheduler MUST move the reminder of the worksheet that started later. The scheduler MUST repeat this until no two share a minute. A moved reminder whose new time is inside quiet hours MUST NOT fire.

#### Scenario: The weigh-in day at the morning plan time
- **WHEN** the weigh-in day reminder and the morning plan reminder are both at 07:30 on Monday
- **THEN** the weigh-in day reminder fires at 07:30 and the morning plan reminder fires at 07:35

#### Scenario: Three at one minute
- **WHEN** Breakfast, the weigh-in day reminder and the morning plan reminder are all at 07:30
- **THEN** Breakfast fires at 07:30, the weigh-in day reminder at 07:35 and the morning plan reminder at 07:40

### Requirement: Quiet hours

Quiet hours are a start time and an end time. The person sets them at onboarding. The default is 22:00 to 07:00.

A moment is inside quiet hours when its clock time lies in the range from the start, included, to the end, excluded. The range wraps around midnight when the end is earlier than the start. The record day does not matter. When the start equals the end, quiet hours are off.

The Reminders group MUST let the person change quiet hours under "Quiet hours". The group MUST also let the person turn quiet hours off. Quiet hours sync, as the `data-and-privacy` capability states. A reminder MUST NOT fire inside quiet hours. The scheduler MUST drop a reminder whose time is inside quiet hours for that day. The scheduler MUST NOT move it to the end of quiet hours. A worksheet review reminder that quiet hours drop moves to the next record day, as "Worksheet review and check-in reminders" states. Ash ruled this on 12 October 2026 (r23-04).

When the person sets a reminder time inside quiet hours, the Reminders group MUST show "This time is in quiet hours. The reminder will not be sent.". The group MUST keep the time. The plan builder shows the same string, as the `regular-eating-plan` capability states.

#### Scenario: A planned meal inside quiet hours
- **WHEN** quiet hours run from 22:00 to 07:00 and today's plan has Evening snack at 22:30
- **THEN** no reminder fires for Evening snack, and Today still shows the Evening snack row

#### Scenario: The edges of the range
- **WHEN** quiet hours run from 22:00 to 07:00
- **THEN** 22:00, 23:30 and 06:59 are inside quiet hours, and 07:00 and 21:59 are not

#### Scenario: A reminder outside quiet hours
- **WHEN** quiet hours run from 22:00 to 07:00 and the morning plan reminder is at 07:30
- **THEN** the morning plan reminder fires at 07:30

#### Scenario: A close-the-day time inside quiet hours
- **WHEN** quiet hours run from 21:00 to 06:00 and the person sets "Close the day time" to 21:45
- **THEN** the Reminders group shows "This time is in quiet hours. The reminder will not be sent." and no close-the-day reminder fires

#### Scenario: Quiet hours off
- **WHEN** the start and the end are both 07:00 and today's plan has Evening snack at 22:30
- **THEN** a reminder fires at 22:30

### Requirement: A paused day and a reminder pause silence everything

When the person taps "Pause for today", the scheduler MUST cancel every pending reminder for the rest of the record day. This MUST include snoozed reminders and the close-the-day reminder. The scheduler MUST schedule the next record day as usual. The scheduler MUST NOT change a reminder switch for a pause. A worksheet review reminder that a paused day drops moves to the next record day, as "Worksheet review and check-in reminders" states. Ash ruled this on 12 October 2026 (r23-04).

`remindersPausedAt` is a synced value. `safeguarding` sets it, and the settings screen control "Turn reminders on" clears it. While `remindersPausedAt` is set, the scheduler MUST cancel every pending reminder. The scheduler MUST schedule nothing while it stays set. Each device MUST compute its own effective reminders from `remindersPausedAt`, `finishDate` and its switches. After `finishDate`, the scheduler MUST apply the reduced cadence the `staying-on-track` capability defines. When the not-right-now page shows no weight reason, the scheduler MUST NOT pause reminders, as the `safeguarding` capability states.

#### Scenario: Pause at 14:00
- **WHEN** the person taps "Pause for today" at 14:00 with Mid-afternoon at 16:00, Evening meal at 19:00 and the close-the-day time 21:45
- **THEN** no reminder fires at 16:00, 19:00 or 21:45

#### Scenario: The day after a pause
- **WHEN** the person paused Thursday and Friday's plan has Breakfast at 08:00
- **THEN** the Breakfast reminder fires at 08:00 on Friday

#### Scenario: A reminder pause
- **WHEN** `remindersPausedAt` is set at 10:00
- **THEN** no reminder fires from 10:00 until it is cleared, and every switch in the Reminders group stays as it was

#### Scenario: Resume
- **WHEN** `remindersPausedAt` is cleared at 09:00 on Tuesday and Tuesday's plan has Lunch at 13:00
- **THEN** the Lunch reminder fires at 13:00

#### Scenario: The self-harm reason
- **WHEN** the app shows the not-right-now page with the self-harm reason and no weight reason, and today's plan has Lunch at 13:00
- **THEN** the Lunch reminder fires at 13:00

### Requirement: The scheduler pipeline

The scheduler MUST compute a day's reminders in seven steps, in this order, and in no other place. The steps are:

- Step 1: the switches drop every type that is off
- Step 2: `remindersPausedAt`, when set, drops everything
- Step 3: a paused day drops the rest of that day
- Step 4: after `finishDate`, the reduced cadence drops what it defines
- Step 5: the cap drops reminders in the drop order
- Step 6: the same-minute shift moves reminders that share a minute
- Step 7: the quiet-hours step drops every reminder inside quiet hours

A reminder that step 7 drops MUST still count toward the cap in step 5. A reminder that step 5 drops MUST NOT take part in step 6. Each step MUST take the output of the step before it. When a step drops a worksheet review reminder on a record day, the scheduler moves it to the next record day. The scheduler then runs the steps for that day again. "Worksheet review and check-in reminders" states the bound, and the steps for a review day after the horizon. Ash ruled this on 12 October 2026 (r23-04).

#### Scenario: A switch outranks the end of a pause
- **WHEN** "Planned meals" is off, `remindersPausedAt` is cleared at 09:00, and today's plan has Lunch at 13:00
- **THEN** no reminder fires at 13:00, and the close-the-day reminder fires at 21:45

#### Scenario: A paused day outlasts the end of a pause
- **WHEN** the person tapped "Pause for today" at 08:00 and `remindersPausedAt` is cleared at 09:00 the same day
- **THEN** no reminder fires for the rest of that record day, and Breakfast fires the next day

#### Scenario: A paused day after the finish
- **WHEN** the reduced cadence is in force and the person taps "Pause for today" at 08:00
- **THEN** no reminder fires that day, and the reduced cadence applies the next day

#### Scenario: The reduced cadence runs before the cap
- **WHEN** the reduced cadence leaves the close-the-day reminder only on Tuesday, and a worksheet review reminder is due at 18:00 on Tuesday
- **THEN** both fire on Tuesday, and the cap counts two

#### Scenario: A dropped reminder takes no part in the shift
- **WHEN** a day has the morning plan reminder and the weigh-in day reminder both at 07:30, the midday reminder and the close-the-day reminder
- **THEN** the cap drops the midday and morning plan reminders, and the weigh-in day reminder fires at 07:30 with nothing at 07:35

#### Scenario: A shifted reminder lands in quiet hours
- **WHEN** quiet hours run from 21:50 to 07:00, Evening snack is at 21:45 and the close-the-day time is 21:45
- **THEN** Evening snack fires at 21:45, and the close-the-day reminder moves to 21:50 and does not fire

#### Scenario: A quiet-hours drop still counts toward the cap
- **WHEN** quiet hours run from 21:00 to 06:00, and a day has the morning plan reminder at 07:30, the midday reminder and the close-the-day reminder at 21:45
- **THEN** the cap drops the midday reminder, quiet hours drop the close-the-day reminder, and only the morning plan reminder fires

### Requirement: Scheduling is local, lazy and bounded

The scheduler MUST use local notifications only. The app MUST NOT use a push server for any reminder. The app MUST compute every reminder's text on the device. Every reminder MUST use a calendar trigger in the device's current time zone.

The scheduler MUST hold a rolling horizon of REMINDER_HORIZON_DAYS = 6 record days from the current one. It MUST also hold every far single reminder: each worksheet review and check-in reminder. The scheduler MUST add one far reminder on the day after the last day of the horizon. The scheduler MUST place it at the close-the-day time. That far reminder MUST use the discreet text with the close-the-day time as its body, for example "Midmorning, 21:45". A tap on it MUST open Today.

The scheduler MUST count the far reminder as that day's close-the-day reminder. The scheduler MUST keep at most 60 pending notification requests. Under that cap the scheduler MUST keep every far single reminder. When the requests need more than 60, the scheduler MUST drop the requests of the farthest horizon days first. "Worksheet review and check-in reminders" states the request id and the userInfo of a far single reminder.

The app MUST register a background refresh task. When the system runs the task, the task MUST extend the horizon by REMINDER_HORIZON_DAYS record days. The cap of 60 still applies. The scheduler MUST NOT depend on the task for any reminder.

The record day starts at the "Day starts at" time that the `settings` capability owns. `ProgrammeConstants` holds its default, DEFAULT_DAY_START_HOUR = 4. The setting is append-only rows, each with an hour and an `effectiveFromDayKey`. The scheduler MUST apply each row from its `effectiveFromDayKey` wherever it uses the record day. Every device applies the same row from the same key.

The day-start obligations are lazy. On activation, the app MUST materialise every elapsed record day. Materialisation writes the template copy as a Day row with the window constants, and the widget snapshot. Materialisation MUST NOT create a Day row for a key that already exists after import. Materialisation MUST write no `changedAt` and no set event row. The `regular-eating-plan` capability defines the Day row and the set event row, under the record day key that `record` defines.

The scheduler MUST compute the schedule again on activation and when protected data becomes available. It MUST compute it again when a plan or a setting changes. It MUST compute it again when an entry matches a planned meal or the person answers a reminder. The app MUST register for CloudKit change pushes.

The scheduler MUST compute the schedule again when a synced setting arrives by push. It MUST compute it again on a time-zone change and on a significant time change. The app MUST NOT depend on a timer at the day start.

#### Scenario: No network
- **WHEN** the device has no network connection and today's plan has Lunch at 13:00
- **THEN** the Lunch reminder fires at 13:00

#### Scenario: The app is not running
- **WHEN** the person closed the app at 09:00 and today's plan has Lunch at 13:00
- **THEN** the Lunch reminder fires at 13:00

#### Scenario: Device restart
- **WHEN** the person restarts the device at 11:00 and today's plan has Lunch at 13:00
- **THEN** the Lunch reminder fires at 13:00

#### Scenario: Six days ahead
- **WHEN** the current day is Monday and every day has six planned meals and two other reminders
- **THEN** the scheduler holds reminders for Monday to Saturday, one far reminder at 21:45 on Sunday, and nothing else for Sunday

#### Scenario: The far reminder
- **WHEN** the person does not open the app from Monday to the following Sunday
- **THEN** the far reminder fires at 21:45 on Sunday, reads "Midmorning, 21:45", and a tap opens Today

#### Scenario: The background refresh task runs
- **WHEN** the system runs the background refresh task at 03:00 on Thursday
- **THEN** the scheduler holds reminders for up to twelve record days from Thursday, within 60 pending requests

#### Scenario: Far single reminders under the cap
- **WHEN** the background refresh task extended the horizon to twelve record days, those days need more than 60 requests, and three worksheet review reminders are pending
- **THEN** the scheduler holds 60 requests with the three worksheet review reminders among them, and it dropped the requests of the farthest horizon days first

#### Scenario: The background refresh task never runs
- **WHEN** the system never runs the background refresh task
- **THEN** every reminder in the horizon and the far reminder still fire at their times

#### Scenario: Three days without opening the app
- **WHEN** the person last opened the app on Monday and opens it at 09:00 on Thursday
- **THEN** the app materialises Tuesday, Wednesday and Thursday, and the scheduler holds reminders for Thursday to the following Tuesday

#### Scenario: A synced setting arrives by push
- **WHEN** the person changes quiet hours on another device and a CloudKit push arrives at 10:00
- **THEN** the scheduler computes the schedule again with the new quiet hours

#### Scenario: A later day start
- **WHEN** the person sets "Day starts at" to 05:00 at 20:00 on Tuesday, with the row effective from Wednesday, and Wednesday's plan has Breakfast at 04:30
- **THEN** the scheduler treats 04:30 on Thursday's calendar date as Wednesday's record day, and the Breakfast reminder fires then

#### Scenario: A time-zone change
- **WHEN** the device moves from London to Lisbon at 15:00 and today's plan has Evening meal at 19:00
- **THEN** the scheduler computes the schedule again, and the Evening meal reminder fires at 19:00 Lisbon time
### Requirement: The weigh-in day reminder

The Reminders group MUST show a "Weigh-in reminder time" control that defaults to 07:30. The scheduler MUST schedule the weigh-in day reminder on the weigh-in day at that time. The scheduler MUST NOT schedule it on any other day. When a weigh-in exists for the weigh-in day before that time, the scheduler MUST cancel the reminder. A tap MUST open the weigh-in screen. The `weigh-in` capability owns that screen.

When the onboarding choice is "I won't be weighing", the scheduler MUST NOT schedule a weigh-in day reminder. The `onboarding` capability owns that choice, and the choice syncs. When the person later picks a weigh-in day, the scheduler MUST schedule the reminder from that day on.

#### Scenario: The weigh-in day
- **WHEN** the weigh-in day is Monday and the time reaches 07:30 on Monday
- **THEN** the reminder fires, reads "Midmorning, 07:30", and a tap opens the weigh-in screen

#### Scenario: I won't be weighing
- **WHEN** the person chose "I won't be weighing" at onboarding
- **THEN** no weigh-in day reminder fires on any day, and the "Weigh-in day reminder" switch stays on

#### Scenario: A weigh-in day chosen later
- **WHEN** the person chose "I won't be weighing" and picks Monday on the weigh-in screen on Thursday 1 October
- **THEN** the weigh-in day reminder fires at 07:30 on Monday 5 October

#### Scenario: A weigh-in before the reminder
- **WHEN** the person saves a weigh-in at 07:15 on Monday
- **THEN** no weigh-in day reminder fires at 07:30

#### Scenario: Another day
- **WHEN** the weigh-in day is Monday and the day is Tuesday
- **THEN** no weigh-in day reminder fires

### Requirement: The weekly review reminder

The Reminders group MUST show a "Weekly review time" control that defaults to 18:00. The scheduler MUST schedule the weekly review reminder at that time on the day the weekly review becomes due. The `weekly-review` capability defines that day. When the person completes the review before that time, the scheduler MUST cancel the reminder. The scheduler MUST schedule at most one weekly review reminder per review.

A tap MUST open the weekly review. After the finish, the `weekly-review` capability makes no weekly review due, so the scheduler MUST schedule none.

#### Scenario: The seventh day
- **WHEN** the weekly review becomes due on Sunday 4 October and the time reaches 18:00
- **THEN** the reminder fires, reads "Midmorning, 18:00", and a tap opens the weekly review

#### Scenario: The review done early
- **WHEN** the person completes the weekly review at 17:00 on Sunday 4 October
- **THEN** no weekly review reminder fires at 18:00

#### Scenario: Mid-week
- **WHEN** the day is Wednesday 30 September and no weekly review is due
- **THEN** no weekly review reminder fires

#### Scenario: After the finish
- **WHEN** the person finished the programme on Sunday 20 December
- **THEN** no weekly review reminder fires on Sunday 27 December

