# widgets-and-intents

## Purpose

Entry points put the new-entry screen one tap away. They sit on the Lock Screen, the Home Screen, a reminder, a shortcut or the Action button, and Control Centre. Each one opens the new-entry screen and nothing else. An entry point never shows an entry, a count, a star, a weight or a planned meal's name. This capability defines each entry point, what it shows, the widget snapshot, the action queue and how each one writes. It also owns the "Keep it private" sheet.

## ADDED Requirements

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
