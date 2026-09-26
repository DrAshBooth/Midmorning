# app-lock

## Purpose

Ash's rulings of 26 September 2026 change four app-lock requirements: the line after a failed Delete-all on the cover in two requirements, the kept enrolment state hash at turn-on, and authentication at Save after the notification action "Add".

## MODIFIED Requirements

### Requirement: The cover

While the app is locked, the app MUST show the cover over every screen, Get support included. The one exception is the empty new-entry screen an entry point opens, as the new-entry-before-authentication rule states. The cover MUST show "Midmorning", the control "Unlock" and the control "Delete everything", and nothing else. The one addition is the line "Could not delete. Try again." after a failed Delete-all, as the "Delete everything from the cover" requirement states. After an enrolment change the cover MUST show "Delete from this device" and "Delete everything" instead of "Unlock", as the "Face ID only or Touch ID only" requirement states.

The cover MUST NOT show entry text, a star, a weight value or a plan. The cover MUST NOT show a list, a worksheet, a review or a reminder. The cover MUST NOT show Get support, because the cover names nothing. The cover MUST NOT show a support link, a contact or an email address. Get support appears only after authentication, as the safeguarding capability states.

The cover MUST appear the moment the app becomes inactive, before the system takes the App Switcher snapshot. The App Switcher MUST show the cover and nothing else. "Unlock" MUST make the system authentication request. With the app lock off, the app MUST still show the cover while inactive, with "Midmorning" only. With the app lock off, the app MUST take the cover off the screen when it becomes active.

#### Scenario: App switcher
- **WHEN** the person opens the App Switcher while Today shows five entries
- **THEN** the app's snapshot shows the cover with "Midmorning", "Unlock" and "Delete everything", and no entry

#### Scenario: Unlock control
- **WHEN** the person cancels the system authentication request and then taps "Unlock"
- **THEN** the system authentication request opens again

#### Scenario: App lock off
- **WHEN** the app lock is off and the person opens the App Switcher while Today shows entries
- **THEN** the snapshot shows the cover with "Midmorning" and no entry

#### Scenario: Weigh-in screen
- **WHEN** "Lock after" is "30 seconds" and the person leaves the app from the weigh-in screen and returns after 45 seconds
- **THEN** the cover hides the weigh-in screen until authentication succeeds

#### Scenario: Get support is covered
- **WHEN** "Lock after" is "30 seconds" and the person leaves the app from Get support and returns 45 seconds later
- **THEN** the app shows the cover with no Get support control, and Get support returns after authentication

### Requirement: Delete everything from the cover

The cover MUST show the control "Delete everything" below "Unlock". A tap on it MUST make the system authentication request. When authentication succeeds, the app MUST open the Delete-all confirmation that the data-and-privacy capability defines. The person MUST reach that confirmation in two taps from any state of the app. When authentication fails or the person cancels, the app MUST show the cover. The app MUST NOT delete anything.

After the deletion the app MUST show "Everything is deleted. To remove the app, touch and hold its icon and choose Remove App." with "Done". The app MUST start onboarding only at the next launch. The data-and-privacy capability owns the deletion and that screen.

When the deletion fails, the app MUST show the cover again with the line "Could not delete. Try again." under its controls. The app MUST NOT show the deleted screen. The data-and-privacy capability owns that line, as its "Delete-all" requirement states.

#### Scenario: Delete from the cover
- **WHEN** the person taps "Delete everything" on the cover and Face ID succeeds
- **THEN** the app shows the confirmation "Delete everything?" and no other screen

#### Scenario: Cancel the authentication
- **WHEN** the person taps "Delete everything" on the cover and cancels the system authentication request
- **THEN** the app shows the cover and the store is unchanged

#### Scenario: Two taps
- **WHEN** the person opens the app from the Home Screen with the app lock on and taps "Delete everything", then "Delete everything" in the confirmation, with Face ID in between
- **THEN** the app shows "Everything is deleted. To remove the app, touch and hold its icon and choose Remove App." with "Done"

#### Scenario: Deletion fails from the cover
- **WHEN** the person taps "Delete everything" on the cover, Face ID succeeds, the person confirms and the app cannot delete the store directory
- **THEN** the app shows the cover with "Midmorning", "Unlock", "Delete everything" and "Could not delete. Try again.", and no deleted screen

### Requirement: Face ID only or Touch ID only

The Privacy group of the settings screen MUST show "Face ID only" on a device with Face ID enrolled. It MUST show "Touch ID only" on a device with Touch ID enrolled. Both strings come from the label function. The setting is off by default and is the `face-or-touch-only` value in `Local.store`. The settings capability owns the group. The control MUST be disabled when no biometric is enrolled or the app lock is off.

Before it turns on, the app MUST show a warning with "Turn on" and "Cancel". The warning reads "If Face ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on." on a Face ID device. On a Touch ID device it reads "If Touch ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on." "Cancel" MUST leave it off. The app MUST make the system authentication request before it turns the setting off.

With the setting on, the app MUST use the biometrics-only policy, `deviceOwnerAuthenticationWithBiometrics`. The app MUST NOT offer the device passcode in any system authentication request. The app MUST keep the enrolment state hash it last saw in `Local.store`. On iOS 18 and later the hash is `LAContext.domainState.biometry.stateHash`. On iOS 17 it is a hash of `evaluatedPolicyDomainState`.

The app MUST compare the enrolment state with the kept hash before each system authentication request. When the enrolment state has changed, the app MUST stay locked. The cover MUST then offer "Delete from this device" and "Delete everything", with "Unlock" off the screen. The next requirement defines "Delete from this device". The cover MUST NOT offer a support link, a contact or an email address.

When the person taps "Turn on" in the warning, the app MUST save the current enrolment state hash in `Local.store` as the kept hash. This save is not a reset. The app then compares the enrolment state with that hash, as above. Apart from this save, the app MUST NOT reset the kept enrolment state hash except through Delete-all. Delete-all deletes it with `Local.store`, as the data-and-privacy capability states. Ash ruled this on 26 September 2026.

#### Scenario: Turn on
- **WHEN** the person turns on "Face ID only" and taps "Turn on"
- **THEN** the next system authentication request offers Face ID and no "Enter Passcode"

#### Scenario: Cancel the turn-on
- **WHEN** the person turns on "Face ID only" and taps "Cancel"
- **THEN** "Face ID only" stays off

#### Scenario: Touch ID device
- **WHEN** the person opens the Privacy group on a device with Touch ID enrolled and turns the setting on
- **THEN** the control reads "Touch ID only" and the warning reads "If Touch ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on."

#### Scenario: Face ID fails with Face ID only
- **WHEN** "Face ID only" is on and Face ID fails twice
- **THEN** the system authentication request offers no passcode and the app stays locked

#### Scenario: Enrolment changed
- **WHEN** "Face ID only" is on and the person adds a second face in the iOS Settings app, then opens the app
- **THEN** the `stateHash` differs from the kept one, and the cover shows "Midmorning", "Delete from this device" and "Delete everything", makes no authentication request and stays locked

#### Scenario: Turn on again after an enrolment change
- **WHEN** "Face ID only" is off after an earlier turn-on, the person adds a second face in the iOS Settings app, turns "Face ID only" on again with "Turn on", and the app then locks
- **THEN** the kept hash is the new `stateHash`, and the cover shows "Unlock" and "Delete everything" and no "Delete from this device"

#### Scenario: Delete everything after an enrolment change
- **WHEN** the cover shows no "Unlock" and the person taps "Delete everything" and confirms
- **THEN** the app deletes everything, writes the erasure marker and starts onboarding at the next launch

#### Scenario: No biometric enrolled
- **WHEN** the device has a passcode and no biometric enrolled
- **THEN** the setting is off and disabled

### Requirement: A new entry before authentication

This rule applies when an entry point opens the app while the app is locked. The entry points are a widget, the notification action "Add", the App Intent and the Control Centre control. The app MUST show the new-entry screen at once, empty, with the keyboard in What and no cover. The screen MUST show no existing entry and no part of Today.

Behind or beside the screen, the app MUST NOT show a count, a star or a planned meal. Behind or beside the screen, the app MUST NOT show a card or the pinned note. The widgets-and-intents capability references this rule for every entry point.

On Save the app MUST make the system authentication request before it saves the entry. When authentication succeeds, the app MUST save the entry. The app MUST then show Today. When the person cancels the request or authentication fails, the app MUST NOT save the entry. The app MUST keep the text in memory. The app MUST then show the cover. This rule applies to the notification action "Add" as to every other entry point. Ash ruled this on 26 September 2026.

"Cancel" on the new-entry screen MUST show the cover. After "Unlock" succeeds with kept text, the app MUST show the new-entry screen with that text. The "Unsaved text survives the lock" requirement states that rule.

A planned meal reminder MUST offer the snooze action, "Add" and "Skipped", in this order, whatever the explicit wording setting. The notification action "Skipped" MUST carry the authentication-required option, because it writes the record. The device MUST be unlocked for "Skipped". The app MUST NOT make an authentication request of its own for "Skipped".

The snooze action MUST NOT require the device or the app to unlock. Its title is "Remind me in %lld minutes", filled from SNOOZE_MINUTES. "Add" MUST carry the foreground option, so iOS unlocks the device before the app opens.

The handlers of "Skipped" and the snooze action MUST use the notification's own `userInfo`. Those handlers MUST write the action queue. The widgets-and-intents capability defines the queue. The reminders capability defines the actions.

#### Scenario: Notification action while locked
- **WHEN** the person taps "Add" on a reminder and the app lock is on
- **THEN** the app shows the empty new-entry screen with no cover and no entry text

#### Scenario: Save from a reminder while locked
- **WHEN** the person taps "Add" on a reminder while the app is locked, types "Toast and tea" and taps Save
- **THEN** the app makes the system authentication request before it saves, and after Face ID succeeds Today shows "Toast and tea"

#### Scenario: Cancel the request at Save from a reminder
- **WHEN** the person taps "Add" on a reminder while the app is locked, types "Toast and", taps Save and cancels the system authentication request
- **THEN** the store holds no new entry, the app shows the cover with "Unlock" and "Delete everything", and after "Unlock" succeeds the new-entry screen shows "Toast and"

#### Scenario: Failed request at Save from a reminder
- **WHEN** "Face ID only" is on, the person taps "Add" on a reminder while the app is locked, types "Toast and", taps Save and Face ID fails twice
- **THEN** the store holds no new entry, the app shows the cover, and after "Unlock" succeeds the new-entry screen shows "Toast and"

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
