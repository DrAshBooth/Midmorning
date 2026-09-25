# widgets-and-intents

## Purpose

Entry points put the new-entry screen one tap away. They sit on the Lock Screen, the Home Screen, a reminder, a shortcut or the Action button, and Control Centre. Each one opens the new-entry screen and nothing else. An entry point never shows an entry, a count, a star, a weight or a planned meal's name. This capability defines each entry point, what it shows, the widget snapshot, the action queue and how each one writes. It also owns the "Keep it private" sheet.

## ADDED Requirements

### Requirement: Every entry point opens the new-entry screen

The app MUST offer five entry points. They are the Lock Screen widget, the Home Screen widget, the notification action "Add", the App Intent and the Control Centre control. Each entry point MUST open the new-entry screen in the app with one tap. The new-entry screen MUST behave as the record capability states.

While the app is locked, the app MUST show the new-entry screen at once, empty, with no cover. The app MUST make the system authentication request on Save, not before. The app-lock capability's new-entry-before-authentication rule owns that flow.

An entry point MUST NOT save an entry without the new-entry screen on screen. When onboarding is not complete, an entry point MUST open the first onboarding screen. When the not-right-now page is on, an entry point MUST open the new-entry screen, because the record stays available.

#### Scenario: Widget to entry
- **WHEN** the person taps the Lock Screen widget with the app locked, types "Toast and tea", taps Save and Face ID succeeds
- **THEN** Today shows the entry, as it does for an entry saved from Today

#### Scenario: Empty screen before authentication
- **WHEN** the person taps the Home Screen widget with the app locked and twelve entries on Today
- **THEN** the app shows the empty new-entry screen with no cover, no entry and no part of Today

#### Scenario: Before onboarding
- **WHEN** the person adds the Home Screen widget and taps it before onboarding is complete
- **THEN** the app opens the first onboarding screen

#### Scenario: Not right now
- **WHEN** the not-right-now page is on and the person taps the Control Centre control
- **THEN** the app opens the new-entry screen

### Requirement: Only the app process opens the store

Only the app process MUST open the store. The store directory is `Application Support/Record` in the app's own container, as the data-and-privacy capability states. The widget extension MUST hold no entitlement for the store path. The App Group container MUST hold only the widget snapshot and the action queue. The widget extension, the intent's out-of-app path and the notification action handlers MUST NOT open the store. The widget extension MUST read the widget snapshot only.

Each entry point MUST set a pending route. Each entry point MUST then open the app. The app MUST show the new-entry screen for the route at once, locked or not. The app MUST keep the route until the person saves or cancels. Every write from an entry point MUST go through the store in the app process or through the action queue.

#### Scenario: Extension process
- **WHEN** a reviewer traces file access from the widget extension for a full day
- **THEN** the extension reads the snapshot file and no store file

#### Scenario: Extension entitlement
- **WHEN** a reviewer reads the widget extension's entitlements
- **THEN** the extension holds the App Group and no entitlement that reaches `Application Support/Record`

#### Scenario: Route kept through the lock
- **WHEN** the person taps the Control Centre control with the app locked, types "Coffee", taps Save, cancels the system authentication request, then taps "Unlock" and succeeds
- **THEN** the app shows the new-entry screen with "Coffee"

### Requirement: The Lock Screen widget is static

The app MUST offer a Lock Screen widget in the circular, rectangular and inline families. The circular widget MUST show a plus glyph and nothing else. The rectangular widget MUST show "Midmorning" on one line and "+ Add" on the next. The inline widget MUST show "+ Add". Each family MUST have the VoiceOver label "Midmorning, Add", which equals the visible text. The widget MUST be static: one timeline entry, no reload and no data.

The widget MUST NOT show an entry, an entry's time, a count, a star or a weight. The widget MUST NOT show a planned meal or a "didn't record" state. The widget MUST NOT read the snapshot or the store. The widget's content MUST NOT change with the record. The widget's gallery description MUST read "Add an entry in one tap."

The review notes MUST describe the Lock Screen widget. It is a one-tap entry point, equivalent to the Control Centre control, and shows no data by design.

#### Scenario: Rectangular widget
- **WHEN** the person adds the rectangular widget to the Lock Screen
- **THEN** it shows "Midmorning" and "+ Add" and nothing else

#### Scenario: After a starred entry
- **WHEN** the person saves a starred entry
- **THEN** every Lock Screen widget looks as it did before

#### Scenario: Locked device
- **WHEN** the device is locked and the Lock Screen shows the widget
- **THEN** the widget shows the same content as when the device is unlocked

#### Scenario: VoiceOver
- **WHEN** a person with VoiceOver on reaches the circular widget on the Lock Screen
- **THEN** VoiceOver reads "Midmorning, Add"

#### Scenario: Review notes
- **WHEN** App Review reads the review notes
- **THEN** it states that the Lock Screen widget is a one-tap entry point, equivalent to the Control Centre control, and shows no data by design

### Requirement: The Home Screen widget

The app MUST offer a Home Screen widget in the small size only. The widget MUST show a plus glyph, "Midmorning" and "Add". The widget MUST have the VoiceOver label "Midmorning, Add", which equals the visible text. The widget's edit sheet MUST offer the option "Show next planned time".

That option is the widget's own configuration, which the system keeps per widget instance. It MUST NOT be a value in `Local.store`. The settings screen MUST NOT show it.

The option MUST hold no value until the person sets it. With no value, the widget MUST read the next-time default flag from the snapshot. The flag is off before stage 2 opens. From the record day when stage 2 opens, the flag is on while notification permission is denied, and off otherwise. When the person has set a value, the widget MUST use that value and not the flag. The programme capability's stage 2 opening card tells the person about the widget when the flag is on.

With the option on, the widget MUST show the next planned meal's time, for example "13:00". The widget MUST read the times, the slot indexes and the explicit-wording flag from the snapshot.

With the explicit-wording flag off, the widget MUST NOT show the slot name. With the flag on, the widget MUST show the slot name before the time, for example "Lunch, 13:00". The snapshot MUST carry the slot's label beside its index only when the flag is on. The label is there because the person can rename a slot. The widget MUST read the label from the snapshot. The reminders capability owns explicit wording.

With no plan or no planned meal left in the snapshot, the widget MUST show no time. On a paused day, the widget MUST show no time until the next record day. After the current record day's last planned meal, the widget MUST show the next record day's first planned time. It reads that time from the snapshot.

The widget MUST wrap the time in `privacySensitive`. When the system redacts the widget, the time MUST render nothing, not a placeholder. The plus glyph and "Midmorning" MUST stay visible when redacted.

#### Scenario: Default
- **WHEN** the person adds the Home Screen widget in stage 1
- **THEN** it shows the plus glyph, "Midmorning" and "Add", and no time

#### Scenario: Default from stage 2 with permission denied
- **WHEN** stage 2 opens, notification permission is denied, the person never set the option and lunch is planned at 13:00
- **THEN** the widget shows "13:00"

#### Scenario: Default from stage 2 with permission granted
- **WHEN** stage 2 opens, notification permission is granted and the person never set the option
- **THEN** the widget shows no time

#### Scenario: The person's value wins
- **WHEN** the person turned "Show next planned time" off in stage 1 and stage 2 opens with permission denied
- **THEN** the widget shows no time

#### Scenario: Next planned time
- **WHEN** "Show next planned time" is on, explicit wording is off and lunch is planned at 13:00
- **THEN** the widget shows "13:00" and no slot name

#### Scenario: Explicit wording
- **WHEN** "Show next planned time" is on, explicit wording is on and the mid-morning planned meal is at 10:30
- **THEN** the widget shows "Mid-morning, 10:30"

#### Scenario: Paused day
- **WHEN** the person taps "Pause for today" with "Show next planned time" on
- **THEN** the widget shows no time until the next record day

#### Scenario: After the last planned meal
- **WHEN** "Show next planned time" is on, the evening snack at 21:00 has passed and tomorrow's plan starts with breakfast at 08:00
- **THEN** the widget shows "08:00" from 21:00

#### Scenario: Redacted
- **WHEN** the device is locked and the system renders the widget redacted
- **THEN** the widget shows the plus glyph and "Midmorning", and the time's place is empty

#### Scenario: VoiceOver
- **WHEN** a person with VoiceOver on reaches the Home Screen widget with "13:00" showing
- **THEN** VoiceOver reads "Midmorning, Add"

#### Scenario: Option per widget
- **WHEN** the person adds two Home Screen widgets and turns "Show next planned time" on for one
- **THEN** only that widget shows a time, `Local.store` holds no value for the option and the settings screen shows no such switch

### Requirement: The widget snapshot

The app MUST write a snapshot file in the App Group container for the Home Screen widget. The snapshot MUST hold only seven things. They are a format version, the current record day's planned meal times and the next record day's planned meal times. The other four are each time's slot index, the pause state, the explicit-wording flag and the next-time default flag. The requirement for the Home Screen widget states when the next-time default flag is on. With the flag on, the snapshot MUST also hold each slot's label as the person typed it.

Each day's times MUST sit under that day's record day key. With the flag off, the snapshot MUST hold a slot index and no slot label. The snapshot MUST hold no day earlier than the current record day and no day later than the next. The snapshot MUST hold no entry field, weight value, count, star or list.

The app MUST give the snapshot `NSFileProtectionCompleteUntilFirstUserAuthentication`. The app MUST write the snapshot when the plan changes, on "Pause for today" and when explicit wording changes. The app MUST also write it when stage 2 opens and when notification permission changes. The app MUST also write it when it materialises a record day at activation.

Each time protected data becomes available, the app MUST write the snapshot again with the current and next record days. Only the app process MUST write the snapshot. Delete-all MUST delete the snapshot, as the data-and-privacy capability states.

The app MUST discard a snapshot whose format version it does not know. The app MUST then write the snapshot again. The data-and-privacy capability owns the schema rule.

#### Scenario: Plan change
- **WHEN** the person moves lunch to 13:30
- **THEN** the snapshot holds 13:30 and the widget shows "13:30" at its next refresh

#### Scenario: Snapshot content
- **WHEN** a reviewer reads the snapshot on a device with twenty entries, a weigh-in and explicit wording off
- **THEN** the snapshot holds the format version, the current day's and the next day's times with slot indexes, the pause state, the explicit-wording flag off and the next-time default flag, and no slot name and no earlier day

#### Scenario: Permission denied from stage 2
- **WHEN** stage 2 opens on a device where notification permission is denied
- **THEN** the app writes the snapshot with the next-time default flag on

#### Scenario: Explicit wording on
- **WHEN** the person turns explicit wording on
- **THEN** the app writes the snapshot again with the flag on and the slot labels, and the widget shows "Lunch, 13:00" from the label in the snapshot

#### Scenario: Yesterday's day
- **WHEN** protected data becomes available at 09:00 on 7 October and the snapshot held 6 October and 7 October
- **THEN** the app writes the snapshot again with 7 October's and 8 October's times only

#### Scenario: Unknown format version
- **WHEN** the app reads a snapshot whose format version it does not know
- **THEN** the app discards it and writes the snapshot again from the store

#### Scenario: After a restart
- **WHEN** the device restarts and the person unlocks it once
- **THEN** the widget shows the next planned time without the app opening

### Requirement: Widgets refresh only to update the next time

With "Show next planned time" off, the Home Screen widget MUST use one timeline entry. With the option off, the widget MUST NOT ask for a reload. With the option on, the timeline MUST have one entry per planned meal time in the snapshot, across both days. The widget MUST ask the system for a refresh at those times only.

The app MUST ask for a widget reload only when it writes the snapshot. The app MUST NOT ask for a reload when the person saves, edits or deletes an entry. The app MUST NOT ask for a reload when the person saves a weigh-in.

#### Scenario: Entry saved
- **WHEN** the person saves an entry
- **THEN** the app asks for no widget reload

#### Scenario: Planned time passes
- **WHEN** "Show next planned time" is on, lunch is at 13:00 and the mid-afternoon planned meal is at 15:30
- **THEN** the widget shows "13:00" until 13:00 and "15:30" from 13:00

#### Scenario: Option off
- **WHEN** "Show next planned time" is off for a full day of use
- **THEN** the widget renders once and the app asks for no reload

### Requirement: Notification actions are entry points

The notification action "Add" MUST open the new-entry screen through the same path as the widgets. A planned meal reminder MUST offer the snooze action, "Add" and "Skipped", in this order, whatever the explicit wording setting. The snooze action's title MUST be "Remind me in %lld minutes", filled from SNOOZE_MINUTES. The reminders capability owns the actions, their wording and their effect.

"Skipped" and the snooze action MUST run without opening the app. "Skipped" MUST carry the authentication-required option, so the device is unlocked when it writes. "Add" MUST carry the foreground option and not the authentication-required option. The snooze action MUST carry neither. The handlers MUST read the notification's own `userInfo`. The handlers MUST NOT open the store. The `userInfo` MUST hold these seven values:

- the date key
- the slot index
- the planned time
- the next planned time
- the snooze count
- quiet hours
- the snooze minutes

The `userInfo` MUST hold a slot index, never a slot label. "Skipped" MUST write the action queue. The snooze action MUST reschedule the reminder from `userInfo`.

#### Scenario: Add
- **WHEN** the person taps "Add" on a reminder
- **THEN** the app opens the new-entry screen with the keyboard in What

#### Scenario: Actions in order
- **WHEN** a planned meal reminder arrives, with explicit wording off or on
- **THEN** the reminder offers "Remind me in 15 minutes", "Add" and "Skipped", in that order

#### Scenario: Skipped
- **WHEN** the person taps "Skipped" on a reminder with the device unlocked
- **THEN** the handler writes the skip to the action queue and the app does not open

#### Scenario: Skipped on the locked device
- **WHEN** the person taps "Skipped" on the Lock Screen
- **THEN** iOS asks the person to unlock the device before the handler runs

#### Scenario: Snooze
- **WHEN** the person taps "Remind me in 15 minutes" on a reminder at 13:05 with the snooze minutes 15
- **THEN** the handler schedules the reminder again for 13:20 from `userInfo` and the app does not open

#### Scenario: userInfo content
- **WHEN** a reviewer reads a planned meal reminder's `userInfo`
- **THEN** it holds the seven values with a slot index and no slot label

### Requirement: The action queue

The app MUST keep an action queue file in the App Group container. A handler MUST append to the queue when it cannot open the store, which is always outside the app process. The queue file MUST carry a format version. Each action in the queue MUST hold only six values. They are the action kind, the date key, the slot index, the planned time, the snooze count and the moment.

The queue MUST hold a slot index, never a slot label. The queue MUST hold no entry text. The app MUST give the queue `NSFileProtectionCompleteUntilFirstUserAuthentication`.

Each time protected data becomes available, the app MUST apply the queue through the store in order. The app MUST also apply the queue each time it becomes active. The app MUST then empty the queue. The app MUST drop an action whose date key is earlier than the current record day.

The app MUST apply a snooze action by writing the snooze count to `Local.store`. The key is the date key and the slot index. The app MUST apply a "Skipped" action by writing an `Answer` row without the snooze count. The data-and-privacy capability states that rule. After a queued skip, Today MUST show the next-planned-meal line the first time it appears. The regular-eating-plan capability owns that line.

The app MUST discard a queue file whose format version it does not know. Delete-all MUST delete the queue file. The Diagnostics page shows the count of actions in the queue, as the data-and-privacy capability states.

#### Scenario: Skipped while the app is closed
- **WHEN** the person taps "Skipped" at 13:40 with the device unlocked and the app closed, then opens the app at 14:10
- **THEN** the store holds the skip for lunch with the moment 13:40, and Today shows the next-planned-meal line on the mid-afternoon row the first time it appears

#### Scenario: Queue content
- **WHEN** a reviewer reads the queue file after a "Skipped" action
- **THEN** it holds the format version, the action kind, the date key, the slot index, the planned time and the moment, and no slot name and no other text

#### Scenario: Action from an earlier day
- **WHEN** the queue holds a "Skipped" for lunch dated 5 October and the app opens on 7 October
- **THEN** the app drops the action, and the queue is empty

#### Scenario: Two actions in order
- **WHEN** the person taps "Skipped" for lunch at 13:40 and "Skipped" for mid-afternoon at 16:30, then opens the app
- **THEN** the store holds both skips, lunch first

#### Scenario: Snooze count applied
- **WHEN** the person taps "Remind me in 15 minutes" twice for lunch on 6 October, then opens the app
- **THEN** `Local.store` holds 2 for 6 October and lunch's slot index, and `Record.store` holds no snooze count

#### Scenario: Entry from a widget
- **WHEN** the person saves an entry from the new-entry screen opened by the widget
- **THEN** the store saves it with the same rules as an entry from Today

### Requirement: The App Intent

The app MUST offer one App Intent, titled "Add an entry". The app MUST NOT register an `AppShortcutsProvider`. The app MUST offer no phrase for the intent. The intent's `isDiscoverable` MUST be true, so the Shortcuts app lists it as an action. The intent MUST run only when the person adds it to a shortcut in Shortcuts. To use the Action button, the person assigns that shortcut to the Action button.

Siri MUST NOT offer the intent by voice unless the person made a shortcut for it. Spotlight MUST NOT list the intent.

The intent MUST accept no parameter. The intent MUST set the pending route. The intent MUST then open the app on the new-entry screen. The intent MUST NOT open the store. The intent MUST NOT save an entry. The intent MUST return no dialog and no snippet.

The intent's description in Shortcuts MUST read "Opens Midmorning on a new entry." The description MUST NOT contain "log", "food", "meal", "eat", "snack", "diary", "binge" or "weight". The app MUST offer no other intent. The app MUST NOT donate the intent, as the record capability states.

#### Scenario: No App Shortcuts
- **WHEN** the person installs the app and says "Add an entry in Midmorning" without a shortcut
- **THEN** Siri does not open the app, and Spotlight lists no action for Midmorning

#### Scenario: Shortcut made
- **WHEN** the person adds "Add an entry" to a shortcut in the Shortcuts app and runs it
- **THEN** the app opens on the new-entry screen and Shortcuts shows no entry and no text about eating

#### Scenario: No parameter
- **WHEN** the person runs the shortcut with text passed to it
- **THEN** the app opens on the new-entry screen with What empty

#### Scenario: Action button
- **WHEN** the person creates a shortcut that runs "Add an entry", assigns that shortcut to the Action button and presses it
- **THEN** the app opens on the new-entry screen

#### Scenario: Shortcuts
- **WHEN** the person opens the Shortcuts app and searches the actions for Midmorning
- **THEN** Shortcuts lists "Add an entry" and no other action

### Requirement: The Control Centre control

On iOS 18 and later, the app MUST offer one Control Centre control. The control MUST show a plus glyph and the title "Midmorning". The control MUST set the pending route. The control MUST then open the app on the new-entry screen. The control MUST NOT open the store. The control MUST NOT show a state, a count, a star or a time.

On iOS 17 the app MUST offer no control. On iOS 17 the app MUST change nothing else. The control's VoiceOver label MUST be "Midmorning, Add".

#### Scenario: Control tap
- **WHEN** the person taps the control in Control Centre
- **THEN** the app opens on the new-entry screen

#### Scenario: Control appearance
- **WHEN** the person adds the control to Control Centre
- **THEN** it shows a plus glyph and "Midmorning" and nothing else

#### Scenario: iOS 17
- **WHEN** the person runs the app on iOS 17
- **THEN** the other four entry points work and no control exists

### Requirement: Keep it private

The Privacy group of the settings screen MUST show "Keep it private". The settings capability owns the group and links to the sheet. This capability owns the sheet. One tap MUST open a sheet with this text and nothing else:

"To hide Midmorning from Purchases: App Store, your account, Purchases, swipe left, Hide. On iOS 18 and later, Lock App keeps the icon and reminders; Hide App also stops reminders."

The sheet MUST close in one tap. The sheet MUST NOT change any setting. Before release, a reviewer MUST verify the exact labels of each step on every supported iOS version. The reviewer MUST also test Lock App and Hide App on iOS 18 with a reminder pending. The reviewer MUST write both results in the change's README as a dated line.

#### Scenario: Keep it private
- **WHEN** the person taps "Keep it private" in the Privacy group
- **THEN** the sheet shows the text above and nothing else, and closes in one tap

#### Scenario: Labels verified
- **WHEN** a reviewer follows the sheet's steps on each supported iOS version and tests Lock App and Hide App with a reminder pending
- **THEN** the README has a dated line with the exact labels per version and what happened to the reminder

### Requirement: An entry point never shows the record

This rule covers every widget, control, intent response, Shortcuts output and Siri snippet. Each of them MUST NOT show entry text, a count, a star or a weight value. Each of them MUST NOT show a "didn't record" state or a reward. A widget or a control MUST NOT show a planned meal's name unless explicit wording is on. Every widget and control MUST show only the plus glyph and text, and no image, as the product-rules capability states.

Every widget and control MUST write the product name as "Midmorning". A person who glances at a widget MUST NOT be able to tell what the app is for.

#### Scenario: Glance at the Lock Screen
- **WHEN** a person sees the Lock Screen from a metre away
- **THEN** they see "Midmorning" and "+ Add" and no word about eating, weight or health

#### Scenario: Day with fifteen entries
- **WHEN** the current record day has fifteen entries and three stars
- **THEN** every widget and control shows the same content as on a day with none

### Requirement: Accessibility of entry points

Every widget and control MUST have a VoiceOver label. Text in every widget MUST scale with Dynamic Type. A meaning in a widget MUST NOT depend on colour alone. The widgets MUST render in the system's light and dark appearances with the same text. On iOS 18 and later the widgets MUST also render in the tinted appearance with the same text.

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the Home Screen widget shows "Midmorning" and "Add" without truncation

#### Scenario: Tinted Home Screen on iOS 18
- **WHEN** the Home Screen uses the tinted appearance on iOS 18 or later
- **THEN** the widget shows the same text and glyph as in the light appearance
