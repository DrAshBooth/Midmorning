# data-and-privacy

## Purpose

Ash's rulings of 26 September 2026 change three data-and-privacy requirements: the line after a failed Delete-all, the safe mode threshold and read-only open, and the analytics control.

## MODIFIED Requirements

### Requirement: Delete-all

The settings screen MUST show the control "Delete everything". The cover MUST offer the same control after authentication, as the app-lock capability states. From either place the person MUST reach the deletion in two taps.

One tap MUST open one confirmation titled "Delete everything?". The confirmation text MUST read "This removes your record, plan, weigh-ins, lists and settings from this device and from iCloud. Another device that uses your iCloud account deletes its copy the next time it syncs. There is no undo." The confirmation MUST offer "Delete everything" and "Cancel".

After "Delete everything" the app MUST first cancel every pending notification request. The app MUST delete every delivered notification at the same step. The app MUST then write an erasure marker to the "Erasure" zone before it deletes the sync zone. The marker MUST hold a random token, the kind "deleted", `tapAt` and `writtenAt`, and nothing else.

The app MUST then delete the sync zone. The app MUST delete the whole store directory. The app MUST then create the directory again empty.

The app MUST delete the widget snapshot file, the action queue file and the launch marker file. The app MUST reload every widget so it shows the product name and nothing else.

The app MUST then show one screen: "Everything is deleted. To remove the app, touch and hold its icon and choose Remove App." with "Done". The app MUST keep that screen after "Done" until the next launch. The app MUST start onboarding only at the next launch. The app MUST leave no file, keychain item, notification, widget content or private database CKRecord.

When a step of the deletion on the device fails, the app MUST NOT show that screen. The app MUST stay on the screen where the person tapped "Delete everything": the cover, the settings screen or the page "Midmorning cannot open your record on this device.". That screen MUST show one line under its controls: "Could not delete. Try again." The line has the same form as the record's "Could not save. Try again.". The app MUST show no other text about the failure. The person can then tap "Delete everything" again. Ash ruled this on 26 September 2026.

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

#### Scenario: Deletion fails in the settings screen
- **WHEN** the person confirms "Delete everything" in the settings screen and the app cannot delete the store directory
- **THEN** the app shows no deleted screen, and the settings screen shows "Could not delete. Try again." under its controls

#### Scenario: Deletion fails on the store-failure page
- **WHEN** the page "Midmorning cannot open your record on this device." shows, the person confirms "Delete everything" and the app cannot delete the store directory
- **THEN** the app shows no deleted screen, and the same page shows "Could not delete. Try again." under its controls

### Requirement: Launch safety

The app MUST write a launch marker file at start. The marker MUST hold the count of launches in a row that ended before the app cleared the marker. The app MUST clear the marker after Today appears. The marker MUST live outside the store directory. When the app ends before it clears the marker on two launches in a row, the app MUST enter safe mode at the third launch. Ash set this threshold on 26 September 2026. The app MUST choose safe mode from the count in the launch marker before it opens the store.

In safe mode the app MUST skip the Erasure read, the import, the Reconciler and the scheduler. In safe mode the app MUST open `Record.store` and `Local.store` read-only. In safe mode the app MUST NOT write to either store. In safe mode the app MUST NOT let a schema migration write to the store. Ash ruled on 26 September 2026 that safe mode reads the record for Export and writes nothing. In safe mode the app MUST show Today with Export and Get support.

The app MUST add one to the launch failure count in `Local.store` each time it finds an uncleared marker. In safe mode the app MUST keep that failure in the launch marker instead. When Today appears in safe mode, the app MUST clear the count of launches in the marker and keep that failure. The next launch that opens the store for writing MUST add each kept failure to the count in `Local.store`.

When the container throws for any reason other than unavailable protected data, the app MUST show one page. The page MUST read "Midmorning cannot open your record on this device." with Get support, "Try again" and "Delete everything". "Try again" MUST open the container again. "Delete everything" MUST open the Delete-all confirmation. The app MUST NOT delete the store without the person's confirmation.

#### Scenario: Third launch with an uncleared marker
- **WHEN** the app ends before Today appears on two launches in a row and the person opens it a third time
- **THEN** the app shows Today with Export and Get support, imports nothing and schedules nothing

#### Scenario: One uncleared marker
- **WHEN** the app ends before Today appears on one launch and the person opens it again
- **THEN** the app does not enter safe mode

#### Scenario: Safe mode reads only
- **WHEN** the app enters safe mode and the person makes an export
- **THEN** the PDF holds the record, and `Record.store` and `Local.store` hold no new or changed row

#### Scenario: Safe mode with a pending migration
- **WHEN** the store needs a schema migration and the app enters safe mode
- **THEN** the app opens the store read-only, and no migration step writes to the store

#### Scenario: Marker cleared
- **WHEN** Today appears on a launch
- **THEN** the app clears the marker, and the next launch runs the Erasure read, the import, the Reconciler and the scheduler

#### Scenario: Launch failures counted
- **WHEN** the app finds an uncleared marker at a launch that does not enter safe mode
- **THEN** the launch failure count in `Local.store` rises by one and the Diagnostics page shows the new count

#### Scenario: Launch failure in safe mode
- **WHEN** the app enters safe mode, Today appears, and the person opens the app again
- **THEN** the safe mode launch writes nothing to `Local.store`, the launch marker keeps its failure, and the next launch adds that failure to the launch failure count in `Local.store`

#### Scenario: Store fails to open
- **WHEN** the container throws an error that is not about protected data
- **THEN** the app shows "Midmorning cannot open your record on this device." with Get support, "Try again" and "Delete everything", and the store files are unchanged

#### Scenario: Try again
- **WHEN** the person taps "Try again" and the container opens
- **THEN** the app shows Today

### Requirement: The app holds no analytics of its own

The app MUST NOT build, keep or send an analytics event. The app MUST NOT write to the CloudKit public database. The app MUST hold no event store. The team MUST receive only Apple's aggregated App Analytics and the crash reports the person chooses to share with Apple. The team MUST take programme-level metrics from the beta panel and the clinical reviewer's notes only.

The Privacy group of the settings screen MUST show "Share App Analytics with Apple". That control MUST open the app's own page in the iOS Settings app, through `UIApplication.openSettingsURLString`. iOS gives an app no public link to Privacy & Security, Analytics & Improvements. Ash ruled this on 26 September 2026. The settings capability owns the group. The app MUST NOT show a switch of its own for analytics. The app MUST NOT read whether the person shares App Analytics with Apple.

#### Scenario: No event
- **WHEN** a reviewer captures the device's network traffic for a full programme week with sync on
- **THEN** the traffic holds no request to the CloudKit public database and no analytics event

#### Scenario: Share App Analytics with Apple
- **WHEN** the person taps "Share App Analytics with Apple" in the Privacy group
- **THEN** the iOS Settings app opens at the app's own page

#### Scenario: Container has no public data
- **WHEN** a reviewer lists the record types of the app's CloudKit container in the public database
- **THEN** the public database holds no record type the app writes
