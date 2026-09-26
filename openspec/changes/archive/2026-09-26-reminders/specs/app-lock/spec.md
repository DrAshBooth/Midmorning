# app-lock

## Purpose

The app lock keeps the record, the plan, weigh-ins and lists out of sight when the app is not in the person's hands. It uses Face ID, Touch ID or the device passcode, or biometrics alone when the person chooses "Face ID only" or "Touch ID only". It is on by default and covers every screen.

Get support appears only after authentication, because the cover names nothing. This capability defines when the app asks and the "Lock after" choice. It defines what the cover hides and what each entry point sees while the app is locked. It also defines the route from the cover to Delete-all and, after an enrolment change, to "Delete from this device". It defines the empty new-entry screen an entry point shows before authentication.

## ADDED Requirements

### Requirement: A new entry before authentication

This rule applies when an entry point opens the app while the app is locked. The entry points are a widget, the notification action "Add", the App Intent and the Control Centre control. The app MUST show the new-entry screen at once, empty, with the keyboard in What and no cover. The screen MUST show no existing entry and no part of Today.

Behind or beside the screen, the app MUST NOT show a count, a star or a planned meal. Behind or beside the screen, the app MUST NOT show a card or the pinned note. The widgets-and-intents capability references this rule for every entry point.

On Save the app MUST make the system authentication request. When authentication succeeds, the app MUST save the entry. The app MUST then show Today. When the person cancels the request, the app MUST keep the text. The app MUST then show the cover.

"Cancel" on the new-entry screen MUST show the cover. After "Unlock" succeeds with kept text, the app MUST show the new-entry screen with that text. The "Unsaved text survives the lock" requirement states that rule.

A planned meal reminder MUST offer the snooze action, "Add" and "Skipped", in this order, whatever the explicit wording setting. The notification action "Skipped" MUST carry the authentication-required option, because it writes the record. The device MUST be unlocked for "Skipped". The app MUST NOT make an authentication request of its own for "Skipped".

The snooze action MUST NOT require the device or the app to unlock. Its title is "Remind me in %lld minutes", filled from SNOOZE_MINUTES. "Add" MUST carry the foreground option, so iOS unlocks the device before the app opens.

The handlers of "Skipped" and the snooze action MUST use the notification's own `userInfo`. Those handlers MUST write the action queue. The widgets-and-intents capability defines the queue. The reminders capability defines the actions.

#### Scenario: Notification action while locked
- **WHEN** the person taps "Add" on a reminder and the app lock is on
- **THEN** the app shows the empty new-entry screen with no cover and no entry text

#### Scenario: Actions on a planned meal reminder
- **WHEN** a planned meal reminder arrives with explicit wording off
- **THEN** it offers "Remind me in 15 minutes", "Add" and "Skipped", in that order

#### Scenario: Skipped while the app is locked
- **WHEN** the device is unlocked, the app is locked and the person taps "Skipped" on a reminder
- **THEN** the handler writes the skip to the action queue, the app makes no authentication request and shows nothing

#### Scenario: Skipped on the locked device
- **WHEN** the device is locked and the person taps "Skipped" on a reminder
- **THEN** iOS asks the person to unlock the device, and the handler runs only after the device unlocks

#### Scenario: Snooze while the device is locked
- **WHEN** the device is locked and the person taps "Remind me in 15 minutes" on a reminder
- **THEN** the handler reschedules the reminder from `userInfo`, makes no authentication request and shows nothing
