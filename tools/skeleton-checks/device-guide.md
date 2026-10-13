# Device test guide

This guide holds every device check that is still open on the device-check
beads of the closed epics (13 October 2026). One item is one check. Each
item has a guide id, the bead that owns it, the runbook id when one exists,
the steps and the expected result. The archived change READMEs cite the
items by path and id, for example "guide s4-8".

The ids are stable. The numbering follows the first version of the guide
(11 October 2026, a web page in a session scratchpad), so a session can
hold ids of several prefixes. A new item takes the next free number of the
session it lands in.

Rules. A navigation, text or manifest check is not a device check (ruling
r13-19). A flow check is a navigation check (r16-01). Those checks are tests
in `tools/skeleton-checks/HarnessUITests` or in `Packages/Tests`. An
accessibility check is never a device check (8 October 2026): the audits in
`AutomatedChecks+Accessibility.swift` cover what they can, and no person
tests VoiceOver, Voice Control, the largest text size, contrast, Increase
Contrast, Reduce Motion or Accessibility Inspector by hand. A device check
is for what needs a device or a person: the clock, real notifications and
calls, Face ID, a backup, the network, a crash, another device, or the
shame walk.

The full run of 11 October 2026 (commit 2109ddb on main, iOS 27.0
simulator, 153 of 153 passed) covers every item that a bead comment marks
"Automated by ... (r13-19)" or "Automated by ... (r13-19, r16-01)". Ash
skips those items on a build that has such a run (gate mm-t43.31). This
guide lists none of them.

How to record a result. Write a dated line in the "Results on a device"
section of the archived change README of the item's epic. The line names
the device, the iOS version, the build commit, the guide id and the result.
The lines of 11 October 2026 are the model. Decision r27-18 decides whether
a screenshot is also needed. Until Ash rules, write the line without one.

Each remaining check is also on its bead, in the latest comment headed
"Remaining device checks". That comment is the list; the earlier comments
are history.

## Install

You need an iPhone on iOS 17 or later with a passcode and Face ID set up,
the Mac with Xcode 27 signed in to team 42JQW6669W, and a cable for the
first pairing. Update main. Connect the iPhone, tap Trust, and let Xcode
prepare the device (DeviceHub, from the run destination menu). Turn on
Developer Mode in Settings, Privacy & Security. Open
`App/Midmorning.xcodeproj`, pick the Midmorning scheme and your iPhone,
keep automatic signing on, and press Command-R. The build is a Debug build,
so cards show "Draft". The test hooks do nothing unless a UI test turns
them on.

When the app is on the screen, stop it in Xcode (Command-Full stop). Open
Midmorning from the Home Screen for every check. While the debugger is
attached, iOS does not suspend the app in the normal way, so the lock
timing, the app switcher picture and notification taps can look wrong.

To start clean, delete the app first: touch and hold the icon, Remove App,
Delete App, then press Command-R again.

## Checks that passed on 11 October 2026

iPhone 17 Pro Max, iOS 26.6.2 (23G90), Face ID and a passcode, Debug build
of main at 58cbf1a. The archived READMEs hold the dated lines.

| Guide id | Check | Bead | Runbook id | README |
| --- | --- | --- | --- | --- |
| s1-1 | Validation messages are never red, screens 2 and 3 | mm-t14.28 | t14-q2 | onboarding-and-safeguarding |
| s1-2 | The GP paragraph's Copy, the pasteboard clears, no Universal Clipboard | mm-t14.28 | t14-9 | onboarding-and-safeguarding |
| s1-3 | Call Beat from the exclusion page | mm-t14.28 | t14-6 | onboarding-and-safeguarding |
| s1-4 | Leaving onboarding keeps nothing | mm-t14.28 | t14-r4 | onboarding-and-safeguarding |
| s1-5 | The lock sentence names Face ID (the Face ID part) | mm-t14.28 | t14-r7 | onboarding-and-safeguarding |
| s1-6 | No BMI anywhere | mm-t14.28 | t14-3 | onboarding-and-safeguarding |
| s2-1 | Calls from the support sheet on Today | mm-t12b.1, mm-t14.28 | t12b-6, t14-7 | record-full, onboarding-and-safeguarding |
| s2-2 | Copy a support number | mm-t14.28 | t14-7 | onboarding-and-safeguarding |
| s2-3 | Beat webchat | mm-t14.28 | t14-7 | onboarding-and-safeguarding |
| s2-4 | Calls from an earlier day | mm-t12b.1 | t12b-6 | record-full |
| s3-1 | What you type is not offered back in other apps (decision 89) | mm-t12b.1 | t12b-3 | record-full |
| s3-2 | A third-party keyboard is blocked | mm-t12b.1, mm-t41.15 | t12b-4, t41-4 | record-full, local-delete-all |
| s3-3 | Dictation and emoji work | mm-t41.15 | t41-4 | local-delete-all |
| s4-1 | Face ID asks by itself, once | mm-t15.14 | t15-1, t15-r4 | app-lock |
| s4-2 | Device lock and sleep | mm-t15.14 | t15-1 | app-lock |
| s4-3 | Fall back to the passcode | mm-t15.14 | t15-4 | app-lock |
| s4-4 | Face ID lockout | mm-t15.14 | t15-1 | app-lock |
| s4-5 | The app switcher shows only the cover (iOS 26 part) | mm-t15.14, mm-t12b.1 | t15-2, t15-r2, t15-7, t12b-q2 | app-lock, record-full |
| s4-6 | A draft survives the lock | mm-t15.14 | t15-7 | app-lock |
| s4-7 | With the app lock off, Today is not blank (iOS 26 part) | mm-t12b.1, mm-t15.14 | t12b-q2, t15-2 | record-full, app-lock |
| s4-8 | Notification Centre does not lock the app (iOS 26 part) | mm-t15.14, mm-t45.7 | t15-q5 | app-lock |
| s4-9 | Face ID only: the real prompt, Turn on, Cancel the turn-on | mm-t15.14 | t15-q3, t15-5 | app-lock |
| s5-1 | Notification permission: Don't Allow, then Settings | mm-t24.22 | t24-1, t24-r4 | reminders |
| s5-2 | Opening the app replaces the pending reminders | mm-t24.22 | t24-2, t24-r9 | reminders |

The runbook line for t41-4 said that a third-party keyboard works in What.
The spec says the opposite (data-and-privacy, "The app blocks third-party
keyboards"), and the device agreed with the spec on 11 October 2026. Read
s3-2 and s3-3 as the rule: the app blocks third-party keyboards; dictation
and emoji work.

Two checks passed in another way. The Saturday part of mm-t23.21 (mm-t23.15:
"Copy to weekend plan" on a Saturday leaves the Saturday rows) passed in the
full run of Sunday 11 October 2026 (2109ddb), because
`testATemplateChangeKeepsTodaysPlannedRows` proves the weekend part on a
Saturday or a Sunday. The real call ("the numbers call") passed from three
screens (s1-3, s2-1, s2-4); `SupportCallSourceTests` proves one route to a
call, so the call needs no check on each screen (finding D5-06).

## Session A: the day and the clock

When: across several days, or with the clock set by hand. One session
changes the clock one time for every item. Reminders on, with some planned
meals. Set the clock back afterwards.

### s6-1 Day starts at 06:00 (mm-t13.8, t13-r1)

Steps: set Settings, Day starts at, to 06:00. Before 06:00 (for example at
05:00) add an entry. Keep Today on the screen while the clock passes 06:00.

Expect: the 05:00 entry is under the previous day with ", night". At 06:00
Today changes to the new day while it shows. The reminders of the new day
are the new day's (see s5-8 for the real reminders).

Note: the part before 06:00 is Automated by
`testTheNightHeadingAndADayStartAt0600`. "Earlier days uses the same day" is
a navigation check; mm-t45.31 adds its assertion. Only the 06:00 pass needs
a device.

### s6-2 Changing Day starts at moves nothing (mm-t21.24, t21-q1, r14-03)

Steps: with Day starts at 04:00, let stage 2 open between 04:00 and 05:00.
Note "Opened in week" on the Regular eating stage screen and the day of the
plan card. Set Day starts at to 05:00. Open the stage screen again.

Expect: neither moves. The plan card comes on the same record day as
before.

### s6-4 The next record day's plan rows (mm-t21.24, t21-r1)

Steps: set or change the plan from a stage screen. Look at Today on the
next record day.

Expect: Today shows the new plan's rows. (The same record day keeps its
rows: `testPlanOnTheStage2ScreenRemovesThePlanCard` proves that part.)

### s6-5 Weekend plan on a Saturday (mm-t12b.1, t12b-r5)

Steps: on a Saturday, in Settings, General, Date & Time, turn Set
Automatically off and pick New York. Open Midmorning. Open the plan builder
for the current day. Set the time zone back afterwards.

Expect: the plan builder starts from the weekend template, and Today uses
the weekend plan.

### s6-6 The clock change on Sunday 25 October (mm-t12b.1, t12b-q1, r13-16)

Steps: on Sunday 25 October 2026 at about 10:00, with the zone
Europe/London, add an entry for Saturday at 04:30. Open its time control
and look at Saturday's hours. Set the time to 03:30 Sunday and save.

Expect: the 04:30 entry shows under Saturday 24 October. The time control
shows a 25-hour Saturday (04:00 to 04:00 on Sunday). At 03:30 Sunday the
entry stays under Saturday.

Note: you can do this sooner with the date set by hand, but the real day is
simpler.

### s6-8 A time-zone change with the app open (mm-t24.22, item 11)

Steps: with an Evening meal at 19:00 and reminders on, keep the app open.
Change the device time zone (Settings, General, Date & Time) to a zone one
hour away. Wait for the reminder.

Expect: the schedule computes again, and the Evening meal reminder arrives
at 19:00 local time in the new zone.

### s6-9 A clock change in the background (mm-t15.14, t15-1)

Steps: app lock on, Lock after 30 seconds. Leave the app. Move the device
clock back one hour (Settings, General, Date & Time, Set Automatically
off). Return to the app 10 seconds later. Set the clock right afterwards.

Expect: the app shows the screen you left, with no authentication request
(app-lock, "Clock change in the background"). Lock after runs on the
continuous clock, not the wall clock.

## Session B: real notifications

When: over one ordinary day, a few minutes at a time. Reminders on,
notifications allowed, some planned meals. Set a planned meal a few minutes
ahead when you want a reminder sooner. Each reminder kind is listed once;
each behaviour is listed once. This session is the list of mm-t24.22; the
other beads point to it.

### s5-3 Tap a planned meal reminder on the Lock Screen from a cold start (mm-t24.22, t24-r10; mm-t22.16, t22-r1)

Steps: force-quit the app, with the app lock on. When a planned meal
reminder arrives, tap it on the Lock Screen. Unlock Midmorning.

Expect: after Unlock, Today shows. Do the same with the weigh-in day
reminder on the weigh-in day: the weigh-in screen shows on Today's stack
with Back, and Back shows Today.

### s5-11 Each kind of reminder opens its own screen from a real banner (mm-t24.22, mm-t24.29; mm-t22.16, mm-t22.22)

Steps: with the app in the background and the app lock off, tap each real
reminder on its banner: the midday reminder, the close-the-day reminder,
the morning plan reminder (stage 2), a planned meal reminder, the far
reminder, the weigh-in day reminder and the weekly review reminder. Then
turn the app lock on and tap the far reminder and the weekly review
reminder.

Expect: the midday reminder opens the new-entry screen. The close-the-day
reminder opens the close-the-day screen. The morning plan reminder opens
Today's plan. A planned meal reminder and the far reminder show Today. The
weigh-in day reminder opens the weigh-in screen on Today's stack. The
weekly review reminder opens the due review with Back. With the app lock
on, each tap shows the cover first and opens its screen after Unlock.

Note: the same taps from simulated reminders are Automated by the tests in
`AutomatedChecks+ReminderTaps.swift` and `+RouteFromAnyScreen.swift`
(rulings r20-01, r22-01 and r22-02). Only the real banner needs a device.
The far reminder's tap is not simulated, because the simulator cannot set
its request identifier.

### s5-12 A second tap on the same delivered reminder (mm-t24.22; mm-t22.16, mm-t22.22; mm-t32.17, mm-t32.21)

Steps: let a weekly review reminder arrive while a review is due. Tap it
and finish the review with Done. Open Notification Centre and tap the same
delivered reminder again. With the deterioration rule due (starred counts
that rise over four weeks), tap the reminder a first time, then a second
time after Done on the GP page.

Expect: the second tap opens the finished review of the same week, not
week 1. The GP page shows once, from the reminder; the second tap does not
show it again.

### s5-13 The close-the-day reminder before 04:00 from a cold launch (mm-t24.22, mm-t24.29)

Steps: set Close the day time to a time after midnight and before 04:00,
with quiet hours off. Force-quit the app. When the reminder arrives, tap
it.

Expect: the close-the-day screen opens for the current record day (the
previous calendar date), with that day's entries.

Note: the tap from the background is Automated by
`testReminderTapOnCloseTheDayBefore0400`. A cold launch gets no TZ from the
test, so this part needs a device.

### s5-4 Skipped and Add while the iPhone is locked (mm-t24.22, t24-4, t24-r2, mm-t24.24; mm-t12b.1, mm-t12b.20 item 2)

Steps: with the iPhone locked, touch and hold a planned meal reminder and
tap Skipped. Open Midmorning, then Settings, About, Diagnostics. Let the
reminder window of a second planned meal pass with no entry; the reminder
for it must not arrive again after Skipped. On the next reminder, tap Add
while the iPhone is locked. Then tap Skipped on a reminder while the app is
open.

Expect: Today shows the first meal as skipped and Queue length is 0. The
planned meal reminder stops after Skipped. Add opens an empty new entry.
With the app open, Today changes at once.

Note: the queue and the next-planned-meal line are Automated by
`testAQueuedSkippedAppliesWhenTheAppOpens` and
`testAQueuedSkippedPointsToTheNextPlannedMeal`.

### s5-5 Save from a locked Add asks Face ID first (mm-t15.14, t15-q1, r13-04)

Steps: with the app lock and Face ID only on, tap Add on a reminder. Type
an entry and tap Save. When Face ID asks, look away so that it fails. Let it
fail a second time.

Expect: the request offers no passcode. Nothing is saved, and the draft
stays under the cover. A second Save with a real Face ID success saves the
entry.

### s4-10 The reminder Add opens on a blank background (mm-t15.14, mm-t15.18, r13-04 step 1)

Steps: lock the app. Tap Add on a planned meal reminder and watch the
animation. Do the same with a new-entry sheet from Today open under it.

Expect: the empty new-entry screen shows at once with no cover. No part of
Today shows during the animation. Over the sheet from Today, the new screen
opens on a blank background.

### s5-6 Snooze (mm-t24.22, t24-5, t24-r3, mm-t24.26, mm-t24.27)

Steps: snooze a reminder for 15 minutes at 13:00 and open the app at
13:05. Set Remind me again in to 30 minutes and snooze another one at 13:00.
Turn quiet hours off and snooze a 21:50 reminder.

Expect: the first comes back at 13:15, also after you opened the app. The
second comes back at 13:30, and the reminder offered "Remind me in 30
minutes". The third arrives at 22:05.

### s5-7 Notification Centre stays tidy (mm-t24.22, t24-6, t24-r5, mm-t24.28)

Steps: let two reminders arrive without opening the app. Look at
Notification Centre. Quit the app and open it, then look again. With the
app in the background, add an entry that matches a planned meal whose
reminder is in Notification Centre, and look again. Let a reminder's window
end (for example 14:30 for Lunch at 13:00) and look again.

Expect: the reminders are in one group. Opening the app clears them. A
reminder goes away when its meal has an entry, and when its window ends.

### s5-8 A plan change, a pause or an entry stops the right reminder (mm-t24.22, t24-r1, mm-t24.23, mm-t24.33)

Steps: Lunch 13:00, Mid-afternoon 16:00, Evening meal 19:00. Save a 12:40
entry that matches Lunch. Move Lunch to 13:30 in Today's plan on another
day. Tap Pause for today at 14:00 and lock the phone. On a third day, do a
restart re-screen with a weight below the limit.

Expect: no reminder arrives at 13:00 after the 12:40 entry. The moved Lunch
reminder arrives at 13:30, not 13:00. After the pause, no reminder arrives
at 16:00, 19:00 or 21:45. After the re-screen with the weight reason, no
reminder arrives.

Note: the pending counts are Automated by
`testZPauseForTodayCancelsOnlyTodaysReminders` and
`testZRemovingAPlannedMealCancelsOnlyItsReminder`. That the reminders then
arrive, or do not, needs a device.

### s5-14 The reminder title with "Say what each reminder is for" (mm-t24.22, mm-t11.39)

Steps: turn "Say what each reminder is for" on, with no renamed slot. Let a
planned meal reminder arrive.

Expect: the title is the slot's default label, for example "Lunch".

### s6-7 The weekly review reminder without opening the app (mm-t24.22, t24-r6, mm-t24.31; mm-t32.17)

Steps: on the day before a weekly review is due, open the app. Do not open
it on the due day.

Expect: the weekly review reminder arrives at 18:00 on the due day.

### s9-1 Delete everything cancels every reminder (mm-t42.14, t42-4)

See Session F. It needs six real pending reminders, so set them up during
this session.

## Session C: Face ID, enrolment and the cover

When: any time. App lock on.

### s9-5 A Face ID enrolment change (mm-t15.14, t15-5, t15-q2, t15-6, r13-06, r15-03; mm-t41.15, t41-q3)

Steps: turn on the app lock and Face ID only. In Settings, Face ID &
Passcode, set up an alternate appearance while Face ID only is off; open
the app, turn Face ID only on again and lock the app with the lock control.
Then add or remove an appearance again while Face ID only stays on. Open
the app and look at the cover. Tap Delete from this device and complete the
request. Onboard again if you want to keep using the app.

Expect: after a new enrolment while the setting was off, the cover shows
Unlock, and Face ID unlocks the app. After an enrolment change while the
setting stays on, the cover shows Delete from this device and Delete
everything, and no Unlock. Delete from this device deletes the record.

Note: iOS can remove an alternate appearance only by resetting Face ID.
Skip this if you do not want to set Face ID up again. The private database
and the sync zone parts of this check are on mm-t41b.12 (s12-2).

## Session D: privacy on the Mac

When: over one day, then at your desk. You need the cable or Wi-Fi pairing
and a Terminal with Full Disk Access.

### s8-1 A day of use reaches no host (mm-t41.15, t41-3, t41-10; mm-t42.14, t42-r4)

Steps: turn on Settings, Privacy & Security, App Privacy Report. Use
Midmorning as normal for a full record day, with sync off: add entries,
open Programme, export a PDF and close the share sheet with no destination.
Next day, open App Privacy Report, Midmorning.

Expect: Midmorning has no network activity: no domain is listed. No
contact means no analytics event, and no entry or weight can leave the
device. This is the one network capture; the two full-day captures of the
26 September list are this item.

### s8-2 A backup holds no record (mm-t41.15, t41-r1, mm-t41.16)

Steps: on a device that never ran Delete everything, connect the iPhone.
In Finder, select it, untick Encrypt local backup, and click Back Up Now.
In Terminal, list the newest backup folder and query its Manifest.db for the
domain `%midmorning%`; grep the backup for a word you typed in What.

Expect: the list holds no Record.store, no Local.store, no -wal or -shm
file, no snapshot and no queue.json. grep finds nothing.

### s8-3 Share App Analytics with Apple (mm-t41.15, t41-1)

Steps: in Midmorning, Settings, Privacy, Share App Analytics with Apple.

Expect: the iOS Settings app opens at Midmorning's own page. On the iOS
27.0 simulator it opened at its first page. If a device on iOS 27 also
opens the first page, tell the team (see s11-5).

Note: that one tap opens the Settings app is Automated by
`testShareAppAnalyticsOpensTheIOSSettingsApp`.

### s8-4 Before the first unlock (mm-t41.15, t41-5, t41-r5, mm-t41.22; mm-t14.28, mm-t14.42)

Steps: set a reminder a few minutes ahead. Restart the iPhone and do not
unlock it. When the reminder shows on the Lock Screen, tap it. Open the app
switcher before you unlock.

Expect: the app does not crash. If it shows its own screen before you
unlock, the screen shows only "Midmorning" and no Get support. The app
switcher shows the same screen. After you unlock, the app opens as usual.

### s8-5 The launch marker's protection class (mm-t41.15, mm-t41.17, mm-t41.21)

Steps: with the app running and before Today appears (for example on the
cover), download the app container (Xcode, Devices, Download Container).
Read the protection class of Application Support/LaunchMarker.

Expect: NSFileProtectionComplete.

## Session E: crashes and MetricKit

When: at your desk, with Xcode.

### s10-1 A real crash in Today's first load (mm-t41.15, mm-t41.17, mm-t41.21)

Steps: make a build that crashes in TodayView's first load. Open it three
times. Remove the crash and open again.

Expect: the third open shows safe mode (Today with Export and Get support).
After the fix, Today shows, and Diagnostics shows the launch failures that
were not cleared.

Note: the app has no way to crash on purpose. This check needs a Debug-only
crash control. Ash decides whether to add one; until then the simulator
proof (`testSafeModeChangesNoStoreFileAndCountsBothFailures`) stands for the
marker logic.

### s10-2 MetricKit (mm-t41.15, mm-t41.23, safe-mode part 5)

Steps: make two real crashes. Open the app with the device locked and
unlock it only after MetricKit delivers (Xcode, Debug, Simulate MetricKit
Payloads, on a device). Then deliver a payload with only a hang diagnostic.
Then start safe mode (two launches that stop before Today) and deliver a
payload in safe mode.

Expect: the Diagnostics crash count rises by the number of crash
diagnostics in the payload. A hang-only payload does not change the count.
In safe mode, Local.store does not change; the count rises at the next
ordinary launch. No file holds the payload.

## Session F: delete everything

When: last, on a day you are finished. These checks delete your record.
You need six pending reminders (Diagnostics, Pending reminders: 6) and the
Mac for the backup.

### s9-1 Delete everything cancels every reminder (mm-t42.14, t42-4)

Steps: confirm Pending reminders shows 6. Settings, Privacy, Delete
everything. Confirm twice. Wait past the time the next reminder was due.
Onboard again and do the same with Delete from this device after an
enrolment change (s9-5).

Expect: "Everything is deleted" shows. No reminder arrives afterwards, for
either deletion.

### s9-2 The deleted screen survives a lock (mm-t41.15, t41-r3, mm-t41.19)

Steps: lock the iPhone on the "Everything is deleted" screen, then unlock
it. Open Midmorning. Do the same after Delete from this device.

Expect: the deleted screen is still there. Onboarding does not start.
Application Support/Record holds no file.

### s9-3 A backup after Delete everything (mm-t41.15, t41-6)

Steps: back up in Finder again, unencrypted. Run the s8-2 commands again.

Expect: no store file, snapshot, queue.json or entry text.

## Session G: the export on a device

When: any time, on a device with a mail account.

### s11-1 Mail: cancel and send (mm-t42.14, mm-t45.1, commit 30802e3)

Steps: open Export and tap Make PDF. Tap Mail, then Cancel, and delete the
draft. Tap Save to Files and save in On My iPhone. Tap Make PDF again, then
Mail, and send the mail.

Expect: after Cancel the share sheet shows again. The Files app holds the
PDF, and the PDF opens. After the send, the share sheet closes and the
export screen shows with no message.

### s11-2 AirDrop stays in the share sheet (mm-t42.14, r13-14)

Steps: open Export and tap Make PDF.

Expect: the share sheet offers AirDrop, Save to Files, Markup and Print,
and no Copy. (No Copy, Save to Files, Markup and Print are Automated by
`testTheExportShareSheetShowsNoCopy`; AirDrop is not on the simulator.)

### s11-3 How the long PDF looks (mm-t42.14, mm-t42.22, mm-t42.25, mm-t42.26)

Steps: make a PDF with Include weigh-ins on, for seven days or more, with
one day of 40 entries or more. Read it as a person.

Expect: the pages read like the paper record. The Weigh-ins heading starts
its own last page. No weight value prints under the record. No page ends
with a day heading, a Paused line or the column headings. (The tag tree and
the page breaks are Automated by
`testTheLongExportKeepsEachHeadingWithItsLinesAndOneH2PerDay`; how the pages
look needs a person.)

## Session H: the shame walk (mm-t43.27)

One first-cut walk, on mm-t43.27 (13 October 2026, finding D5-07). The
device-check beads mm-t12b.1, mm-t23.15 and mm-t24.22 point to it. Not a
pass or fail, but a reading. Dark mode, at night, with entries from earlier
days. For each screen ask two questions. Could a person who has just binged
read this as judgement? Could a person glancing from a metre away tell what
the app is for? Write what you notice, also when the answer is no. A yes
becomes a correction bead under mm-t43c that names the screen. The 1.2b
README also gets the dated line (decision 84), and the panel's outcomes
(mm-t43.29, or mm-t43.9 after r27-03) join it there.

### s7-1 The record at night (mm-t43.27; mm-t12b.1, t12b-7)

Steps: star an entry with What empty. Star a second entry that has a
Context. Edit one entry, delete one. Open the app again the next morning.

### s7-2 The missed meal prompt and the next meal line (mm-t43.27; mm-t23.15, t23-5)

Steps: let a planned meal pass with no entry, and read the prompt. Star an
entry that matches a planned meal, and read the next-planned-meal line.

### s5-10 A reminder on the Lock Screen at work (mm-t43.27; mm-t24.22, t24-9)

Steps: at work, or anywhere with people around, let a reminder show on the
Lock Screen. Read it as someone else glancing at your phone would.

### s7-3 The rest of the first-cut journey (mm-t43.27)

Steps: the journey of mm-t43.27 as one person: onboarding with every
default; day 1 Today with the "Getting started" line; the fifth recorded
day and the stage 2 card; the plan builder; the close-the-day screen; the
week 1 review with the self-harm item and "I'm getting worse"; the weigh-in
day and the refusal text; Get support from three screens; the export.

## Session I: needs an iOS 27 device (decision r27-19)

Ash's iPhone runs iOS 26.6.2. Decision r27-19 asks whether to update the
iPhone to iOS 27 and do this group in one session, or to accept the iOS
27.0 simulator run (2109ddb, 153 of 153) and the iOS 26 device pass as done.
Until Ash rules, each item blocks its bead.

### s4-5 and s4-7 on iOS 27: the cover and Today (mm-t12b.1, t12b-q2, r16-02; mm-t15.14, t15-2)

Steps: with the app lock on, then off: open Today with entries; open the
app switcher from Today, from the new-entry screen with typed text and
from the edit screen; with the app locked, tap Add on a reminder, type
text, open the app switcher, return; then tap Save.

Expect: Today is not blank. Each app switcher card shows the cover and no
entry text, no star and no typed text (with the lock on: "Midmorning",
"Unlock", "Delete everything"; with the lock off: "Midmorning" only).
After the return the new-entry screen shows the text with no cover. At
Save the cover shows behind the Face ID request, and after a success Today
shows the entry.

### s4-8 on iOS 27: Notification Centre does not lock the app (mm-t15.14, t15-q5; mm-t45.7, r19-05)

Steps: app lock on, Lock after 30 seconds. With Midmorning open, pull down
Notification Centre and keep it down for 45 seconds. Close it.

Expect: Midmorning shows its screen with no Face ID request. Write the
result on mm-t45.7. If the device asks for Face ID, the simulator finding
is real.

### s11-4 Make PDF on iOS 27 (mm-t42.14, mm-t45.1, commit 5d5ba39)

Steps: open Export and tap Make PDF. Share to Mail.

Expect: the share sheet shows the PDF and its destinations, and the share
to Mail works.

### s11-5 Share App Analytics on iOS 27 (mm-t41.15, t41-1)

Steps: Settings, Privacy, Share App Analytics with Apple.

Expect: the iOS Settings app opens at Midmorning's own page. If it opens
its first page, as the iOS 27.0 simulator does, tell the team.

## Session J: needs another device (decision r27-20)

Decision r27-20 asks whether a Touch ID device is available. If not, Ash
accepts `BiometryLabelsTests` and the simulator's passcode case as the
proof and strikes the Touch ID items; the no-passcode case runs on the same
iPhone with the passcode removed.

### s14-1 The lock sentence on a Touch ID device (mm-t15.14; mm-t14.28, t14-5, t14-r7, mm-t14.31)

Steps: on a device with Touch ID, do onboarding to screen 4. Finish
onboarding. In Settings, turn on Touch ID only and tap Turn on (r15-03
step 4).

Expect: screen 4 shows "Lock with Touch ID" and "Midmorning asks for Touch
ID or your passcode when it opens." The Touch ID request shows before the
switch turns on, with no Enter Passcode.

### s14-2 A device with no passcode (mm-t15.14, mm-t15.16; mm-t14.28, mm-t14.31)

Steps: remove the passcode of the iPhone. Complete onboarding. Open the
Privacy group. Then set a passcode again, turn the app lock on, remove the
passcode while the app is in the background, and return.

Expect: screen 4 and the Privacy group show the switch off and disabled,
with "Set a passcode on your device to lock Midmorning." Today opens with
no cover. After the passcode is removed in the background, no cover shows.

### s14-3 The locked reminder Add after the passcode is removed (mm-t15.14, r13-04 step 10)

Steps: with the app lock on, tap Add on a reminder, type text, tap Save and
cancel the request. Remove the device passcode in the iOS Settings app and
open the app again.

Expect: the new-entry screen shows with its text.

## Session K: needs sync (4.1b, mm-t41b.12)

These checks moved from mm-t13.8, mm-t15.14 and mm-t41.15 (finding D5-09),
as "Container has no public data" moved on 26 September 2026. They run on
the first build that carries 4.1b.

### s12-1 Settings on a second device after sync (mm-t13.8, mm-t13.13)

Steps: with sync on and two devices, choose Day starts at 06:00 on one
device. Let both sync. Open Settings on the second device.

Expect: opening Settings changes no value on the second device. Both show
06:00.

### s12-2 Delete from this device leaves the private database alone (mm-t15.14, mm-t41.15, mm-t15.10)

Steps: with sync on, cause an enrolment change (s9-5) and tap Delete from
this device. Open the CloudKit Dashboard.

Expect: the private database holds no new marker, and the sync zone is
unchanged.

### s12-3 Delete everything after an enrolment change writes the marker (mm-t15.14, item 5)

Steps: with sync on, after an enrolment change, tap Delete everything on
the cover and confirm. Open the CloudKit Dashboard.

Expect: the Erasure zone holds a marker of kind "deleted".

### s12-4 Container has no public data (mm-t41b.12; from mm-t41.15, 26 September 2026)

Steps: after sync is on, open the CloudKit Dashboard for the app's
container.

Expect: the public database holds no record type that the app writes.

## Session L: needs the second schema version (3.1, mm-t31.24)

### s13-1 Safe mode over a store at the earlier version (mm-t31.24; from mm-t41.15 part 6 and mm-t42.14, r15-01, t42-q2)

Steps: on the first tester build that adds a schema version, use a device
with a store from the build before that version, with some entries. Put the
file Application Support/LaunchMarker with the text 2 in the app container.
Install the new build and open it. Then open the app again.

Expect: safe mode's Today shows Export and Get support, and Make PDF makes a
PDF with the entries. Record.store and Local.store do not change in safe
mode. The next launch is an ordinary launch: the migration runs, and Today
shows the same entries.

## Removed from the guide on 13 October 2026

Each line names the reason and the bead that holds the work.

- The real call from each screen ("the numbers call", mm-t13.8, mm-t23.15,
  mm-t41.15): passed from three screens on 11 October 2026;
  `SupportCallSourceTests` proves one route to a call (D5-06).
- "Earlier days uses the same day" (mm-t13.8): a navigation check;
  mm-t45.31 adds the assertion (D5-05).
- The Instruments check of mm-t21.35 (mm-t21.24): `ShippedContent.bundle` is
  a `static let` (App/Midmorning/Programme/ShippedContent.swift), so
  `BundleLoader.loadShipped` runs at most once per process. No test and no
  device check is needed (D5-16).
- The rename control's visible text and the not-red validation colour on
  the re-screen and the weigh-in screen (mm-t23.15, mm-t14.28): text checks;
  mm-t45.32 adds the assertions (D5-15).
- The Saturday part of mm-t23.21 (mm-t23.15): passed in the full run of
  Sunday 11 October 2026 (D5-15).
- "Release check" of the support numbers (mm-t14.28, item 8): gate
  mm-t43.14, per build (D5-10).
- "App Store Connect shows Data Not Collected" (mm-t41.15): mm-t43.17, the
  App Store Connect entry (D5-10).
- "No biometric enrolled" (mm-t15.14): a navigation check; mm-t45.26 proves
  it (D5-19).
- "No new pending reminder set" after two opens of Settings, Reminders
  (mm-t24.22, mm-t24.38): a new set with the same requests is not visible
  on a device either; `testOpeningRemindersTwiceWritesNoSettingsRow` proves
  the store part.
- The document-properties panel of a PDF reader (mm-t42.14): closed by
  ruling r20-02.
- Every accessibility check: left the list on 8 October 2026.
