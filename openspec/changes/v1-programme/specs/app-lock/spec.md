# app-lock

## Purpose

The app lock keeps the record, the plan, weigh-ins and lists out of sight when the app is not in the person's hands. It uses Face ID, Touch ID or the device passcode, or biometrics alone when the person chooses "Face ID only" or "Touch ID only". It is on by default and covers every screen.

Get support appears only after authentication, because the cover names nothing. This capability defines when the app asks and the "Lock after" choice. It defines what the cover hides and what each entry point sees while the app is locked. It also defines the route from the cover to Delete-all and, after an enrolment change, to "Delete from this device". It defines the empty new-entry screen an entry point shows before authentication.

## ADDED Requirements

### Requirement: The app lock is on by default

The app lock MUST be on by default. The person MUST choose it at onboarding, as the onboarding capability states. The settings screen MUST show a switch for it. The switch's label MUST be "Lock with Face ID" on a device with Face ID enrolled. The label MUST be "Lock with Touch ID" on a device with Touch ID enrolled. The label MUST be "Lock with passcode" on a device with a passcode and no biometric enrolled.

The onboarding screen MUST use the same label for the same device. The label function MUST take a `Biometry` value as its input. The values are `faceID`, `touchID`, `passcodeOnly` and `none`. The function MUST live in a package so a test calls it with each value.

The same function MUST return every string that names the biometric. For `faceID` it returns the setting "Face ID only" and the warning "If Face ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on." For `touchID` it returns "Touch ID only" and "If Touch ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on." The onboarding capability's lock sentence MUST take its Face ID or Touch ID word from the same function. The Info.plist MUST hold `NSFaceIDUsageDescription` with the text "Midmorning uses Face ID to unlock the app."

When the person turns the switch off, the app MUST make the system authentication request first. When authentication fails or the person cancels, the switch MUST stay on. When the device has no passcode, the switch MUST be off and disabled. Under the disabled switch the app MUST show "Set a passcode on your device to lock Midmorning."

#### Scenario: Default
- **WHEN** the person completes onboarding without a change to the lock choice
- **THEN** the app lock is on

#### Scenario: Turn off
- **WHEN** the person turns "Lock with Face ID" off and Face ID succeeds
- **THEN** the app lock is off and the app opens without an authentication request from then on

#### Scenario: Cancel the turn-off
- **WHEN** the person turns "Lock with Face ID" off and cancels the system authentication request
- **THEN** "Lock with Face ID" stays on

#### Scenario: No passcode
- **WHEN** the device has no passcode
- **THEN** the switch is off and disabled, with "Set a passcode on your device to lock Midmorning."

#### Scenario: Same label at onboarding
- **WHEN** the person reaches the app lock section of onboarding on a device with Touch ID enrolled
- **THEN** the switch reads "Lock with Touch ID"

#### Scenario: Label function in a test
- **WHEN** a test calls the label function with `passcodeOnly`
- **THEN** it returns "Lock with passcode", and with `none` it returns the disabled state

#### Scenario: Touch ID strings
- **WHEN** a test calls the label function with `touchID`
- **THEN** it returns "Lock with Touch ID", "Touch ID only" and "If Touch ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on."

#### Scenario: Face ID usage description
- **WHEN** a reviewer reads the Info.plist
- **THEN** `NSFaceIDUsageDescription` reads "Midmorning uses Face ID to unlock the app."

### Requirement: Lock after

The Privacy group of the settings screen MUST show "Lock after". Its values MUST be "At once", "30 seconds", "2 minutes" and "5 minutes". The settings capability owns the group. The default MUST be "At once".

LOCK_GRACE_SECONDS MUST take the chosen value: 0, 30, 120 or 300. `ProgrammeConstants` holds the four values. The choice is a device value in `Local.store`, as the data-and-privacy capability states. A change MUST apply from the next time the app enters the background.

#### Scenario: Default
- **WHEN** the person completes onboarding and opens the Privacy group
- **THEN** "Lock after" reads "At once"

#### Scenario: At once
- **WHEN** "Lock after" is "At once" and the person leaves the app and returns 3 seconds later
- **THEN** the app shows the cover and the system authentication request

#### Scenario: Five minutes
- **WHEN** "Lock after" is "5 minutes" and the person leaves the app and returns 4 minutes later
- **THEN** the app shows the screen the person left, with no authentication request

### Requirement: When the app asks

With the app lock on, the app MUST make the system authentication request at every launch. The app MUST ask again when it returns from the background after the grace period. The grace period is LOCK_GRACE_SECONDS, from "Lock after". The app MUST start the grace timer when it enters the background, not when it becomes inactive. The app MUST measure the grace period with `mach_continuous_time`, which counts through sleep, not with the calendar. When the app returns within the grace period, the app MUST NOT ask.

The app MUST lock at once when the system posts `protectedDataWillBecomeUnavailable`, inside or outside the grace period. The app MUST lock at once when the person taps the lock control on Today. The app MUST ask before it shows any screen, with one exception. The exception is the empty new-entry screen an entry point opens, as the new-entry-before-authentication rule states. The reason string in the system authentication request MUST read "Unlock Midmorning".

The rule MUST live in one pure function, `LockPolicy.shouldAsk(enteredBackgroundAt:now:grace:)`. That function and the lifecycle reducer MUST live in a package behind a continuous-clock protocol. The app's implementation of the protocol MUST read `mach_continuous_time`. A test MUST drive the reducer with a stub clock and no UIKit.

#### Scenario: Launch
- **WHEN** the person opens the app from its icon on the Home Screen
- **THEN** the app shows the cover and the system authentication request with "Unlock Midmorning" before any other screen

#### Scenario: Return within the grace period
- **WHEN** "Lock after" is "30 seconds" and the person leaves the app and returns 20 seconds later
- **THEN** the app shows the screen the person left, with no authentication request

#### Scenario: Return after the grace period
- **WHEN** "Lock after" is "30 seconds" and the person leaves the app and returns 45 seconds later
- **THEN** the app shows the cover and the system authentication request

#### Scenario: Inactive is not background
- **WHEN** "Lock after" is "30 seconds" and the person pulls down Notification Centre over the app for 45 seconds and dismisses it
- **THEN** the app shows the screen the person left, with no authentication request

#### Scenario: Clock change in the background
- **WHEN** "Lock after" is "30 seconds", the person leaves the app, the device clock moves back one hour, and the person returns 10 seconds later
- **THEN** the app shows the screen the person left, with no authentication request

#### Scenario: Device locked within the grace period
- **WHEN** "Lock after" is "30 seconds" and the person leaves the app, locks the device at once and unlocks it 10 seconds later
- **THEN** the app shows the cover and the system authentication request

#### Scenario: Device asleep for an hour
- **WHEN** the person leaves the app, the device sleeps for an hour and the person returns
- **THEN** the app shows the cover and the system authentication request

#### Scenario: Policy with a stub clock
- **WHEN** a test calls `LockPolicy.shouldAsk` with a background moment of 0, a now of 31 and a grace of 30
- **THEN** it returns true, and with a now of 29 it returns false

#### Scenario: Policy with no grace
- **WHEN** a test calls `LockPolicy.shouldAsk` with a background moment of 0, a now of 1 and a grace of 0
- **THEN** it returns true

### Requirement: The lock control on Today

Today's navigation bar MUST hold the lock control at its leading edge, in the Today stack that `record` defines. The lock control MUST show the lock glyph and no text. Its VoiceOver label MUST be "Lock". A tap on the lock control MUST show the cover at once. The tap MUST lock the app at once, with no grace period. The next "Unlock" MUST make the system authentication request.

With the app lock off, the lock control MUST still show the cover. That cover MUST stay until the person taps it. The tap MUST take it off the screen with no authentication request.

#### Scenario: Lock at once
- **WHEN** the app lock is on, "Lock after" is "5 minutes" and the person taps the lock control
- **THEN** the app shows the cover at once and the next "Unlock" makes the system authentication request

#### Scenario: Lock control with the app lock off
- **WHEN** the app lock is off and the person taps the lock control, then taps the cover
- **THEN** the cover shows until the tap and Today returns with no authentication request

### Requirement: The cover

While the app is locked, the app MUST show the cover over every screen, Get support included. The one exception is the empty new-entry screen an entry point opens, as the new-entry-before-authentication rule states. The cover MUST show "Midmorning", the control "Unlock" and the control "Delete everything", and nothing else. After an enrolment change the cover MUST show "Delete from this device" and "Delete everything" instead of "Unlock", as the "Face ID only or Touch ID only" requirement states.

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

### Requirement: A new entry before authentication

This rule applies when an entry point opens the app while the app is locked. The entry points are a widget, the notification action "Add", the App Intent and the Control Centre control. The app MUST show the new-entry screen at once, empty, with the keyboard in What and no cover. The screen MUST show no existing entry and no part of Today.

Behind or beside the screen, the app MUST NOT show a count, a star or a planned meal. Behind or beside the screen, the app MUST NOT show a card or the pinned note. The widgets-and-intents capability references this rule for every entry point.

On Save the app MUST make the system authentication request. When authentication succeeds, the app MUST save the entry. The app MUST then show Today. When the person cancels the request, the app MUST keep the text. The app MUST then show the cover.

"Cancel" on the new-entry screen MUST show the cover. After "Unlock" succeeds with kept text, the app MUST show the new-entry screen with that text. The "Unsaved text survives the lock" requirement states that rule.

A planned meal reminder MUST offer the snooze action, "Add" and "Skipped", in this order, whatever the explicit wording setting. The notification action "Skipped" MUST carry the authentication-required option, because it writes the record. The device MUST be unlocked for "Skipped". The app MUST NOT make an authentication request of its own for "Skipped".

The snooze action MUST NOT require the device or the app to unlock. Its title is "Remind me in %lld minutes", filled from SNOOZE_MINUTES. "Add" MUST carry the foreground option, so iOS unlocks the device before the app opens.

The handlers of "Skipped" and the snooze action MUST use the notification's own `userInfo`. Those handlers MUST write the action queue. The widgets-and-intents capability defines the queue. The reminders capability defines the actions.

#### Scenario: Widget tap while locked
- **WHEN** the person taps the Lock Screen widget and the app lock is on
- **THEN** the app shows the new-entry screen at once, empty, with the keyboard in What, and no cover, no entry and no part of Today

#### Scenario: Notification action while locked
- **WHEN** the person taps "Add" on a reminder and the app lock is on
- **THEN** the app shows the empty new-entry screen with no cover and no entry text

#### Scenario: Save while locked
- **WHEN** the person types "Toast and tea" on the new-entry screen a widget opened while the app was locked and taps Save
- **THEN** the app makes the system authentication request, and after Face ID succeeds Today shows "Toast and tea"

#### Scenario: Cancel the request at Save
- **WHEN** the person types "Toast and" and taps Save on that screen, then cancels the system authentication request
- **THEN** the app shows the cover with "Unlock" and "Delete everything", and after "Unlock" succeeds the new-entry screen shows "Toast and"

#### Scenario: Cancel on the screen
- **WHEN** the person taps "Cancel" on the new-entry screen a widget opened while the app was locked
- **THEN** the app shows the cover with "Unlock" and "Delete everything"

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

### Requirement: Delete everything from the cover

The cover MUST show the control "Delete everything" below "Unlock". A tap on it MUST make the system authentication request. When authentication succeeds, the app MUST open the Delete-all confirmation that the data-and-privacy capability defines. The person MUST reach that confirmation in two taps from any state of the app. When authentication fails or the person cancels, the app MUST show the cover. The app MUST NOT delete anything.

After the deletion the app MUST show "Everything is deleted. To remove the app, touch and hold its icon and choose Remove App." with "Done". The app MUST start onboarding only at the next launch. The data-and-privacy capability owns the deletion and that screen.

#### Scenario: Delete from the cover
- **WHEN** the person taps "Delete everything" on the cover and Face ID succeeds
- **THEN** the app shows the confirmation "Delete everything?" and no other screen

#### Scenario: Cancel the authentication
- **WHEN** the person taps "Delete everything" on the cover and cancels the system authentication request
- **THEN** the app shows the cover and the store is unchanged

#### Scenario: Two taps
- **WHEN** the person opens the app from the Home Screen with the app lock on and taps "Delete everything", then "Delete everything" in the confirmation, with Face ID in between
- **THEN** the app shows "Everything is deleted. To remove the app, touch and hold its icon and choose Remove App." with "Done"

### Requirement: Fallback to the device passcode

With "Face ID only" or "Touch ID only" off, a failed biometric MUST make the system authentication request offer the device passcode. When no biometric is enrolled, the app MUST ask for the device passcode at once. When the system has locked biometrics out after repeated failures, the app MUST ask for the device passcode. The app MUST NOT keep its own passcode or PIN. The app MUST NOT count failures or lock the person out.

#### Scenario: Face ID fails
- **WHEN** "Face ID only" is off and Face ID fails twice
- **THEN** the system authentication request offers "Enter Passcode" and the device passcode unlocks the app

#### Scenario: No biometric enrolled
- **WHEN** the device has a passcode and no Face ID or Touch ID enrolled
- **THEN** the app asks for the device passcode at launch

#### Scenario: Face ID locked out
- **WHEN** "Face ID only" is off and the system has locked Face ID out
- **THEN** the app asks for the device passcode, and the passcode unlocks the app

### Requirement: Face ID only or Touch ID only

The Privacy group of the settings screen MUST show "Face ID only" on a device with Face ID enrolled. It MUST show "Touch ID only" on a device with Touch ID enrolled. Both strings come from the label function. The setting is off by default and is the `face-or-touch-only` value in `Local.store`. The settings capability owns the group. The control MUST be disabled when no biometric is enrolled or the app lock is off.

Before it turns on, the app MUST show a warning with "Turn on" and "Cancel". The warning reads "If Face ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on." on a Face ID device. On a Touch ID device it reads "If Touch ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on." "Cancel" MUST leave it off. The app MUST make the system authentication request before it turns the setting off.

With the setting on, the app MUST use the biometrics-only policy, `deviceOwnerAuthenticationWithBiometrics`. The app MUST NOT offer the device passcode in any system authentication request. The app MUST keep the enrolment state hash it last saw in `Local.store`. On iOS 18 and later the hash is `LAContext.domainState.biometry.stateHash`. On iOS 17 it is a hash of `evaluatedPolicyDomainState`.

The app MUST compare the enrolment state with the kept hash before each system authentication request. When the enrolment state has changed, the app MUST stay locked. The cover MUST then offer "Delete from this device" and "Delete everything", with "Unlock" off the screen. The next requirement defines "Delete from this device". The cover MUST NOT offer a support link, a contact or an email address.

The app MUST NOT reset the kept enrolment state hash except through Delete-all. Delete-all deletes it with `Local.store`, as the data-and-privacy capability states.

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

#### Scenario: Delete everything after an enrolment change
- **WHEN** the cover shows no "Unlock" and the person taps "Delete everything" and confirms
- **THEN** the app deletes everything, writes the erasure marker and starts onboarding at the next launch

#### Scenario: No biometric enrolled
- **WHEN** the device has a passcode and no biometric enrolled
- **THEN** the setting is off and disabled

### Requirement: Delete from this device after an enrolment change

The cover MUST show "Delete from this device" only after an enrolment change, above "Delete everything". A tap MUST open one confirmation titled "Delete from this device?". The confirmation text MUST read "This removes your record, plan, weigh-ins, lists and settings from this device. A copy in iCloud stays if sync is on. There is no undo." The confirmation MUST offer "Delete from this device" and "Cancel". "Cancel" MUST return to the cover. "Cancel" MUST NOT delete anything.

"Delete from this device" MUST delete only this device's copy: `Local.store` and `Record.store`. It MUST write no erasure marker. It MUST delete no zone in iCloud. The data-and-privacy capability owns the deletion and states what else it deletes. "Delete everything" MUST stay a separate control on the same cover with its own confirmation. The app MUST start onboarding only at the next launch.

#### Scenario: Delete from this device
- **WHEN** the cover shows no "Unlock" and the person taps "Delete from this device", then "Delete from this device" in the confirmation
- **THEN** the store directory holds no file, the private database holds no new marker and the sync zone is unchanged

#### Scenario: Cancel
- **WHEN** the person taps "Delete from this device" and then "Cancel"
- **THEN** the cover returns and the store is unchanged

#### Scenario: Not shown before an enrolment change
- **WHEN** the app lock is on and the enrolment state matches the kept hash
- **THEN** the cover shows "Unlock" and "Delete everything" and no "Delete from this device"

### Requirement: Unsaved text survives the lock

When the app locks with unsaved text on the new-entry screen, the app MUST keep the text in memory. The cover and the App Switcher MUST NOT show the text. After authentication succeeds, the app MUST show the new-entry screen with the text as typed. The app MUST NOT write unsaved text to a file. When the system ends the app in the background, the app loses the unsaved text.

#### Scenario: Return to a draft
- **WHEN** the person types "Toast and" in What, leaves the app for 45 seconds with "Lock after" at "30 seconds" and unlocks
- **THEN** the new-entry screen shows "Toast and" in What

#### Scenario: Draft in the app switcher
- **WHEN** the person types "Toast and" in What and opens the App Switcher
- **THEN** the snapshot shows the cover and no part of "Toast and"

### Requirement: Accessibility of the cover

Every control on the cover MUST have a VoiceOver label. "Unlock" MUST have the VoiceOver label "Unlock". "Delete everything" MUST have the VoiceOver label "Delete everything". "Delete from this device" MUST have the VoiceOver label "Delete from this device". Text on the cover MUST use system text styles.

Text on the cover MUST scale with Dynamic Type. VoiceOver focus MUST move to "Unlock" when the cover appears with the app lock on.

The cover MUST keep VoiceOver focus on "Unlock" while the system authentication request is on screen. The cover MUST return focus to "Unlock" when the request closes without success. When the cover shows no "Unlock" after an enrolment change, VoiceOver focus MUST move to "Delete from this device".

#### Scenario: VoiceOver on the cover
- **WHEN** a person with VoiceOver on opens the app
- **THEN** VoiceOver reads "Midmorning", then "Unlock", and the person can reach "Delete everything" by swipe

#### Scenario: Focus through the system request
- **WHEN** a person with VoiceOver on sees the system authentication request over the cover and cancels it
- **THEN** VoiceOver focus is on "Unlock" before, during and after the request

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the cover shows "Midmorning", "Unlock" and "Delete everything" without truncation
