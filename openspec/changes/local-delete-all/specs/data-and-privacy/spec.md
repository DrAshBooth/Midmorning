# data-and-privacy

## ADDED Requirements

### Requirement: Delete-all

The settings screen MUST show the control "Delete everything". The cover MUST offer the same control after authentication, as the app-lock capability states. From either place the person MUST reach the deletion in two taps.

One tap MUST open one confirmation titled "Delete everything?". The confirmation text MUST read "This removes your record, plan, weigh-ins, lists and settings from this device and from iCloud. Another device that uses your iCloud account deletes its copy the next time it syncs. There is no undo." The confirmation MUST offer "Delete everything" and "Cancel".

After "Delete everything" the app MUST first cancel every pending notification request. The app MUST delete every delivered notification at the same step. The app MUST then write an erasure marker to the "Erasure" zone before it deletes the sync zone. The marker MUST hold a random token, the kind "deleted", `tapAt` and `writtenAt`, and nothing else.

The app MUST then delete the sync zone. The app MUST delete the whole store directory. The app MUST then create the directory again empty.

The app MUST delete the widget snapshot file, the action queue file and the launch marker file. The app MUST reload every widget so it shows the product name and nothing else.

The app MUST then show one screen: "Everything is deleted. To remove the app, touch and hold its icon and choose Remove App." with "Done". The app MUST keep that screen after "Done" until the next launch. The app MUST start onboarding only at the next launch. The app MUST leave no file, keychain item, notification, widget content or private database CKRecord.

Offline, the app MUST complete the deletion on the device. The app MUST keep one instruction in the new `Local.store`. The instruction is: write the marker, delete the zone. The app MUST run that instruction at the next connection. The app MUST NOT start sync again before that instruction succeeds.

#### Scenario: Delete everything
- **WHEN** the person taps "Delete everything" and confirms with "Delete everything"
- **THEN** the app shows "Everything is deleted. To remove the app, touch and hold its icon and choose Remove App.", the store directory holds no file, and the private database has no sync zone

#### Scenario: Next launch
- **WHEN** the person taps "Done" on the deleted screen, closes the app and opens it again
- **THEN** the app shows the first onboarding screen

#### Scenario: Cancel
- **WHEN** the person taps "Delete everything" and then "Cancel"
- **THEN** nothing changes

#### Scenario: Pending requests first
- **WHEN** a reviewer traces Delete-all with six pending reminders
- **THEN** the app cancels the six requests before it deletes the store directory, and none fires afterwards

### Requirement: Delete from this device

The cover after an enrolment change MUST offer "Delete from this device" beside "Delete everything", as the app-lock capability states. The app-lock capability owns the control and its confirmation. This capability owns the deletion. "Delete from this device" MUST delete only this device's copy. The app MUST delete the whole store directory, `Local.store` and `Record.store` with it. The app MUST then create the directory again empty.

The app MUST first cancel every pending notification request. The app MUST delete every delivered notification at the same step. The app MUST delete the widget snapshot file, the action queue file and the launch marker file. The app MUST reload every widget so it shows the product name and nothing else.

The app MUST NOT write an erasure marker. The app MUST NOT delete a zone. The app MUST NOT send anything to iCloud. A copy in iCloud stays as it was, and another device with sync on keeps its copy.

After the deletion the app MUST show one screen: "This device's copy is deleted. To remove the app, touch and hold its icon and choose Remove App." with "Done". The app MUST keep that screen after "Done" until the next launch. The app MUST start onboarding only at the next launch. When the device then has an iCloud account with a sync zone, the app reads iCloud before onboarding, as the requirement above states.

#### Scenario: Delete from this device with sync off
- **WHEN** sync is off and the person confirms "Delete from this device"
- **THEN** the store directory holds no file, the app sends nothing to iCloud and the next launch shows the first onboarding screen

#### Scenario: Pending requests first
- **WHEN** a reviewer traces "Delete from this device" with six pending reminders
- **THEN** the app cancels the six requests before it deletes the store directory, and none fires afterwards

### Requirement: Launch safety

The app MUST write a launch marker file at start. The app MUST clear the marker after Today appears. The marker MUST live outside the store directory. On the third consecutive launch with an uncleared marker, the app MUST enter safe mode.

In safe mode the app MUST skip the Erasure read, the import, the Reconciler and the scheduler. In safe mode the app MUST open the store read-only. In safe mode the app MUST show Today with Export and Get support. The app MUST add one to the launch failure count in `Local.store` each time it finds an uncleared marker.

When the container throws for any reason other than unavailable protected data, the app MUST show one page. The page MUST read "Midmorning cannot open your record on this device." with Get support, "Try again" and "Delete everything". "Try again" MUST open the container again. "Delete everything" MUST open the Delete-all confirmation. The app MUST NOT delete the store without the person's confirmation.

#### Scenario: Third launch with an uncleared marker
- **WHEN** the app ends before Today appears on two launches in a row and the person opens it a third time
- **THEN** the app shows Today with Export and Get support, imports nothing and schedules nothing

#### Scenario: Marker cleared
- **WHEN** Today appears on a launch
- **THEN** the app clears the marker, and the next launch runs the Erasure read, the import, the Reconciler and the scheduler

#### Scenario: Launch failures counted
- **WHEN** the app finds an uncleared marker at launch
- **THEN** the launch failure count in `Local.store` rises by one and the Diagnostics page shows the new count

#### Scenario: Store fails to open
- **WHEN** the container throws an error that is not about protected data
- **THEN** the app shows "Midmorning cannot open your record on this device." with Get support, "Try again" and "Delete everything", and the store files are unchanged

#### Scenario: Try again
- **WHEN** the person taps "Try again" and the container opens
- **THEN** the app shows Today

### Requirement: The app holds no analytics of its own

The app MUST NOT build, keep or send an analytics event. The app MUST NOT write to the CloudKit public database. The app MUST hold no event store. The team MUST receive only Apple's aggregated App Analytics and the crash reports the person chooses to share with Apple. The team MUST take programme-level metrics from the beta panel and the clinical reviewer's notes only.

The Privacy group of the settings screen MUST show "Share App Analytics with Apple". That control MUST open the iOS Settings app at Privacy & Security, Analytics & Improvements. The settings capability owns the group. The app MUST NOT show a switch of its own for analytics. The app MUST NOT read whether the person shares App Analytics with Apple.

#### Scenario: No event
- **WHEN** a reviewer captures the device's network traffic for a full programme week with sync on
- **THEN** the traffic holds no request to the CloudKit public database and no analytics event

#### Scenario: Share App Analytics with Apple
- **WHEN** the person taps "Share App Analytics with Apple" in the Privacy group
- **THEN** the iOS Settings app opens at Privacy & Security, Analytics & Improvements

#### Scenario: Container has no public data
- **WHEN** a reviewer lists the record types of the app's CloudKit container in the public database
- **THEN** the public database holds no record type the app writes

### Requirement: What never leaves the device

The person's data MUST leave the device only to the private iCloud database or in an export the person starts. The person's data is every item in this list.

- What, Where, Context, the star and entry times
- weight values
- the plan and planned meal outcomes
- urge outcomes and every list
- worksheets, weekly review answers and taking stock answers
- Feeling fat notes, the maintenance plan and the pinned note
- height, the onboarding BMI, the caution flag, `askedAt` and the self-harm answers

The app MUST NOT send the person's data to the public database, to a server or to a third party. The app MUST NOT send the person's data to Spotlight, to Siri, to HealthKit or to the pasteboard. The app MUST NOT include a third-party SDK. The app MUST NOT open a network connection except to iCloud for sync.

A link the person taps in Get support MUST open in `SFSafariViewController`. The Beat webchat MUST open in `SFSafariViewController` too. That is Safari's connection, not one the app opens. An export MUST leave the device only through the system share sheet after the person's tap.

#### Scenario: A day of use
- **WHEN** a reviewer captures the device's network traffic for a full record day with sync on
- **THEN** the traffic reaches iCloud hosts only and holds no readable entry field, weight value or free text

### Requirement: Retention

From a screening with no exclusion, the store MUST keep only height, the onboarding BMI, the caution flag and `askedAt`. From a restart re-screen that excludes, the store MUST keep only `remindersPausedAt`, as `safeguarding` states. `askedAt` holds the moment of the last screening. The store MUST NOT keep any other screening date or moment. `remindersPausedAt` is a reminder value, not a screening moment. The `changedAt` of a Profile field is not a screening moment. The onboarding capability lists the four values. The store MUST NOT expose a CKRecord's creation or modification date to any reader. The store MUST NOT keep a self-harm answer. The store MUST keep only `selfHarmAnswered: true` for a review.

Entry versions and losing rows each have a 90-day rule, stated above. The app MUST keep no other copy of the person's data past Delete-all.

#### Scenario: Screening date
- **WHEN** a reviewer reads `Record.store` and `Local.store` after onboarding
- **THEN** `Profile` in `Record.store` holds `askedAt`, and neither store holds any other screening date or moment

#### Scenario: Self-harm answer
- **WHEN** the person answers "Yes" to the self-harm question at a weekly review
- **THEN** the store holds `selfHarmAnswered: true` for that review and not the answer

### Requirement: File protection

Every file in the store directory MUST carry `NSFileProtectionComplete`. The app MUST open the store container only when protected data is available. The app MUST create the container at the first access after protected data becomes available, not at launch. The app MUST NOT call `fatalError` when the container fails to open.

When protected data is unavailable, the app MUST show the cover. The app MUST try again when protected data becomes available. When the container fails for any other reason, the app MUST show the page the launch safety rule states.

Two side files MUST carry `NSFileProtectionCompleteUntilFirstUserAuthentication`: the action queue and the widget snapshot. The widgets-and-intents capability defines their content. Every other file the app writes MUST carry `NSFileProtectionComplete`.

#### Scenario: Store files
- **WHEN** a reviewer reads the protection class of every file in the store directory
- **THEN** every file has `NSFileProtectionComplete`

#### Scenario: Side files
- **WHEN** a reviewer reads the protection class of the action queue and the widget snapshot
- **THEN** both have `NSFileProtectionCompleteUntilFirstUserAuthentication`

#### Scenario: Launch before the first unlock
- **WHEN** the device restarts, a reminder fires and the person taps "Add" before the first unlock
- **THEN** the app shows the cover, opens no container and does not crash

### Requirement: The app blocks third-party keyboards

The app MUST block third-party keyboards on every screen. The app MUST do so by returning false from `application(_:shouldAllowExtensionPointIdentifier:)` for the keyboard extension point. The app MUST NOT call the active-keyboards API. The system keyboard, dictation and the emoji keyboard MUST stay available.

#### Scenario: Third-party keyboard installed
- **WHEN** the person has a third-party keyboard as the default and taps into What
- **THEN** the system keyboard appears and the third-party keyboard does not

#### Scenario: Dictation
- **WHEN** the person taps the microphone on the system keyboard in What
- **THEN** dictation works

### Requirement: The app excludes the whole store directory from backups

The app MUST exclude the whole store directory, `Application Support/Record`, from iCloud Backup and from local device backups. The app MUST exclude every file it writes in the App Group container. A backup copy is not end-to-end encrypted without Advanced Data Protection, and a backup copy outlives Delete-all. A new device MUST receive the record through sync, not from a backup. When sync is off, the settings screen MUST show "Sync with iCloud is off. A new device starts empty." under the switch.

A reviewer MUST inspect a Finder backup of a device made after Delete-all. The reviewer MUST write the result in the change's README as a dated line.

#### Scenario: New device with sync off
- **WHEN** the person had sync off and restores a new device from a backup
- **THEN** the record on the new device is empty and the app shows the first onboarding screen

#### Scenario: Restore after Delete-all
- **WHEN** the person confirms Delete-all and later restores the device from a backup made before it
- **THEN** the app shows the first onboarding screen and holds no entry

#### Scenario: Finder backup inspected
- **WHEN** a reviewer makes a Finder backup after Delete-all and inspects the app's files in it
- **THEN** the backup holds no store file, no snapshot, no queue and no entry text, and the README has a dated line with the result

### Requirement: No record content in the system log or crash reports

The app MUST NOT write a weight value, a plan or a list item to the system log. The app MUST NOT write a screening answer to the system log. The app MUST NOT write free text from any screen to the system log or to standard output. The app MUST NOT put any of these in an error description or a crash report. The app MUST NOT include a crash-reporting SDK. The record capability states the same rule for entry fields.

The app MUST receive MetricKit crash diagnostics. From each diagnostic the app MUST keep only a count in `Local.store`. The app MUST NOT keep, show or send the diagnostic payload. The Diagnostics page shows the count.

#### Scenario: Weigh-in save fails
- **WHEN** the store fails to save a weigh-in of 72.4 kg
- **THEN** the error the store throws holds no number

#### Scenario: Crash while typing
- **WHEN** the app crashes while the person types in Context
- **THEN** the crash report holds no part of the typed text

#### Scenario: MetricKit diagnostic
- **WHEN** MetricKit delivers a crash diagnostic at the next launch
- **THEN** the crash count in `Local.store` rises by one and no file holds the payload

### Requirement: The Diagnostics counts come from the device

The About group of the settings screen shows "Diagnostics", as the settings capability states. This capability owns where each count comes from. The page MUST show these counts and nothing else:

- launch failures: the launch failure count in `Local.store`
- last successful sync day: the day in `Local.store`, or "Never" with sync off
- schema version: the number of the current `VersionedSchema`
- content version: the content bundle's version, as the content capability states
- pending reminders: the count of pending requests in the notification centre
- queue length: the count of actions in the action queue file
- last reconcile outcome: the counts of winners and losers in `Local.store`
- crash count: the MetricKit count in `Local.store`

The page MUST hold no record content, no entry text, no weight value and no date of an entry. The person MUST be able to screenshot the page for TestFlight feedback without any record content. The app MUST NOT detect a managed device. The app MUST NOT change its behaviour on a managed device.

#### Scenario: Diagnostics content
- **WHEN** the person opens "Diagnostics" after a week of use with sync on
- **THEN** the page shows the eight counts and no entry, weight, plan or date of an entry

#### Scenario: Sync off
- **WHEN** the person opens "Diagnostics" with sync off
- **THEN** the last successful sync day reads "Never"

#### Scenario: Managed device
- **WHEN** the person runs the app on a device under mobile device management
- **THEN** the app behaves exactly as on any other device

### Requirement: The privacy manifest and the App Store privacy label

The app's privacy manifest MUST declare no tracking. The manifest MUST declare these required-reason API categories and reasons, and no others:

- System boot time: 35F9.1, for the app lock's grace period
- File timestamp: C617.1

The manifest MUST NOT declare the UserDefaults category, because the app uses no UserDefaults. The manifest MUST declare no other required-reason API category.

The privacy label on the App Store MUST be "Data Not Collected". The manifest's `NSPrivacyCollectedDataTypes` MUST be empty. The README MUST quote Apple's definition of "collect" in a dated line at submission. That line MUST state why the label is true. The person's data reaches only their private database, which the team cannot read.

#### Scenario: App Store label
- **WHEN** a person reads the app's privacy label on the App Store
- **THEN** it shows "Data Not Collected" and no data type

#### Scenario: Manifest
- **WHEN** a reviewer reads the privacy manifest
- **THEN** it lists 35F9.1 and C617.1, an empty `NSPrivacyCollectedDataTypes`, no UserDefaults reason and no active-keyboard reason

#### Scenario: Definition of collect
- **WHEN** a reviewer reads the change's README at submission
- **THEN** it has a dated line that quotes Apple's definition of "collect" and states why the label is true
