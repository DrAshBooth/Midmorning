# data-and-privacy

## Purpose

This capability governs where the person's data lives and where it can go. It covers sync to the person's private iCloud database and the account it binds to. It covers the change moment every synced row carries, the append-only entry versions and the rules when two devices disagree. It covers the frozen schema, launch safety and Delete-all.

It covers where the store lives, file protection, exclusion from backups and the list of what never leaves the device. The app holds no analytics of its own; the team receives only Apple's App Analytics. The DPIA, the privacy notice and the App Store submission are release gates; this capability states what they contain.

## ADDED Requirements

### Requirement: Sync is off until the person chooses it

Sync MUST be off until the person chooses it at onboarding or in the settings screen. The onboarding capability owns the choice on its screen 4. The app MUST sync `Record.store` to the CloudKit private database of the person's iCloud account and to no other database. The app MUST NOT need any account other than the person's iCloud account. The settings screen MUST show the switch "Sync with iCloud". The app MUST send every synced field except the CKRecord name with CloudKit's end-to-end encryption.

When the device has no iCloud account, the app MUST show the switch off and disabled. Under the disabled switch the app MUST show "iCloud is signed out on this device. Sync is off." Every screen MUST work in full with sync off. Every screen MUST work in full with the device offline or iCloud signed out. When the person turns sync off, the app MUST keep the copy on the device. The app MUST then stop sending and receiving.

When sync is off and a copy exists in iCloud, the app MUST show the control "Remove from iCloud". "Remove from iCloud" MUST write a marker of kind "removed" to the "Erasure" zone. It MUST then delete the sync zone. It MUST keep the copy on the device.

Another device that reads a "removed" marker later than its store creation moment MUST turn sync off. That device MUST show the different-account line under the switch. That device MUST NOT delete its copy.

#### Scenario: This device only
- **WHEN** the person chooses "This device only" at onboarding and opens the settings screen
- **THEN** "Sync with iCloud" is off and the private database holds no zone from this device

#### Scenario: This device and my iCloud
- **WHEN** the person chooses "This device and my iCloud" at onboarding on a device signed into iCloud
- **THEN** "Sync with iCloud" is on and the app sends `Record.store` to the private database in the next batch

#### Scenario: iCloud signed out
- **WHEN** the device has no iCloud account
- **THEN** the settings screen shows "Sync with iCloud" off and disabled, with "iCloud is signed out on this device. Sync is off."

#### Scenario: Entry saved offline
- **WHEN** sync is on, the person saves an entry in airplane mode and the device connects two hours later
- **THEN** the entry is on Today at once and reaches the private database in the batch that follows the record day

#### Scenario: Second device
- **WHEN** sync is on and the person opens the app on a second device signed into the same iCloud account after the first device's batch
- **THEN** Today on the second device shows the same entries as the first

#### Scenario: Turn sync off
- **WHEN** the person turns "Sync with iCloud" off
- **THEN** the record stays on the device, the app sends nothing more, and "Remove from iCloud" appears

#### Scenario: Remove from iCloud with a second device
- **WHEN** the person taps "Remove from iCloud" on device A and device B launches with sync on
- **THEN** device B turns sync off, keeps every entry and shows "This device is signed into a different iCloud account. Your record is still here. Sync is off."

### Requirement: Sync sends one batch per record day

The app MUST send the changes of a record day to the private database in one batch. The app MUST send that batch at a random moment inside the following record day. The app MUST NOT send at the moment of a save. The app MUST NOT send while the device is locked. When the device is locked or offline then, the app MUST send when it is next unlocked and online. The app MUST receive changes from the private database whenever it runs and the device is unlocked.

The sync change MUST use CKSyncEngine and not SwiftData's own mirroring. With CKSyncEngine the sync change MUST honour the daily batch, the lock rule and the erasure marker.

The Privacy group of the settings screen MUST show the control "Sync now" while sync is on. The settings capability owns the group. "Sync now" MUST send every pending change at once, as one batch. The app MUST keep the day of the last successful send in `Local.store`. The Diagnostics page reads that day.

#### Scenario: Save sends nothing
- **WHEN** sync is on, the device is online and the person saves an entry at 13:10
- **THEN** the app sends nothing to the private database at 13:10

#### Scenario: Batch on the following day
- **WHEN** the person saves four entries on 6 October and the device is unlocked and online on 7 October
- **THEN** the app sends the four entries in one batch at one random moment on 7 October

#### Scenario: Locked at the chosen moment
- **WHEN** the random moment falls at 03:10 while the device is locked and the person unlocks it at 07:30
- **THEN** the app sends the batch after 07:30 and not at 03:10

#### Scenario: Sync now
- **WHEN** the person taps "Sync now" at 13:10 with entries saved that day
- **THEN** the app sends every pending change at once, and `Local.store` holds that day as the last successful sync day

#### Scenario: CKSyncEngine
- **WHEN** a reviewer reads the sync code
- **THEN** it drives `CKSyncEngine`, and no `ModelConfiguration` carries a `cloudKitDatabase`

### Requirement: Sync binds to one iCloud account

When the person turns sync on, the app MUST keep a hash of the iCloud account's `userRecordID` in `Local.store`. At every launch the app MUST compare the current account with that hash before it opens `Record.store`. When the account is absent or different, the app MUST open `Record.store` with sync off. The app MUST then show under the switch "This device is signed into a different iCloud account. Your record is still here. Sync is off." The app MUST NOT open a synced container against an account that does not match the hash.

The person MUST turn sync on again from the settings screen to bind the record to the new account. When the person does so, the app MUST replace the hash. The app MUST then read the Erasure zone before it sends anything.

#### Scenario: Different account at launch
- **WHEN** sync is on, the person signs the device into another iCloud account and opens the app
- **THEN** Today shows every entry, and the settings screen shows "This device is signed into a different iCloud account. Your record is still here. Sync is off."

#### Scenario: Signed out at launch
- **WHEN** sync is on, the person signs the device out of iCloud and opens the app
- **THEN** the app opens `Record.store` with sync off and sends nothing

#### Scenario: Bind to the new account
- **WHEN** the app shows the different-account line and the person turns "Sync with iCloud" on
- **THEN** the app keeps the new account's hash and sends `Record.store` to the new account's private database

### Requirement: Sync pauses when iCloud storage is full

When iCloud reports that storage is full, the app MUST pause sync. The settings screen MUST show under "Sync with iCloud": "iCloud is full, so sync is paused. Your record is safe on this device." The app MUST keep every write on the device while sync is paused. The app MUST try to sync again at each launch. When a try succeeds, the app MUST take the line off the screen. The app MUST then send the pending changes.

#### Scenario: Storage full
- **WHEN** sync is on and iCloud reports that storage is full
- **THEN** the person can still save entries, and the settings screen shows "iCloud is full, so sync is paused. Your record is safe on this device."

#### Scenario: Space freed
- **WHEN** the person frees iCloud storage and opens the app
- **THEN** the app sends the pending changes and the settings screen no longer shows the storage line

### Requirement: The app reads iCloud before onboarding

Before onboarding, when the device has an iCloud account, the app MUST read the private database. It MUST look for a sync zone and for the Erasure zone. The onboarding capability owns the question "Your record is in iCloud. Get it back on this device?" and its controls "Get it back" and "Start fresh". When the person taps "Get it back", the app MUST turn sync on. The app MUST then import the zone. When the first import fails, sync MUST stay on. "Sync now" in the settings screen MUST then start the first import again.

Until the first import completes or fails, the app MUST NOT write a `Profile` or a `Settings` row. Until then the app MUST NOT write a stage-opened row or a start day. While the first import runs, the app MUST show no card. While it runs, the app MUST write no opening moment.

`Profile` MUST have one fixed id. `Profile` MUST carry no creation moment. When two `Profile` rows share that id, the app MUST keep each field from the row with the later `changedAt`. `Settings` MUST be one row per key, with the key, the value and `changedAt`. When two `Settings` rows share a key, the store keeps the row with the later `changedAt`. So the store keeps a restart's later write of the start day or the height.

The app MUST NOT ask the screening questions again after a restore. The exceptions are the self-harm item at every weekly review and check-in, and the restart re-screen that `safeguarding` states.

#### Scenario: Get it back
- **WHEN** the person reinstalls the app on a device signed into iCloud with a sync zone and taps "Get it back"
- **THEN** the app imports the zone, Today shows the person's entries, and the app asks no screening question

#### Scenario: No zone
- **WHEN** the person installs the app on a device signed into iCloud with no sync zone
- **THEN** the app shows the first onboarding screen and asks no question about iCloud

#### Scenario: Two Profile rows
- **WHEN** an import finds two `Profile` rows with the fixed id, changed on 1 September and 3 September, with heights 170 and 171
- **THEN** the store keeps the height 171 and every other field from the row changed on 3 September

#### Scenario: Two Settings rows for the start day
- **WHEN** an import finds two `Settings` rows for the start day, changed on 1 September and 20 October after a restart
- **THEN** the store reads the start day from the row changed on 20 October and keeps both rows

#### Scenario: A failed first import
- **WHEN** the first import after "Get it back" fails, and the person later taps "Sync now" in the settings screen
- **THEN** the app starts the first import again

#### Scenario: Nothing written during the first import
- **WHEN** the person taps "Get it back" and the import takes two minutes
- **THEN** the store holds no new `Profile`, `Settings` row, stage-opened row or start day before the import completes

### Requirement: CKRecord types and model names are neutral

Every CKRecord type name and every `@Model` class name MUST be one of sixteen neutral names. The names are Item, ItemVersion, DayState, Template, Day, Answer, Measure, Session, ListItem, Sheet, Review, Profile, Settings, Seen, Place and Device. `Device` is the model of the one row per install. A type name, a model name or a field name MUST NOT name eating, weight, urges, the body or screening. The zone name MUST NOT contain such a word either.

The Swift API MUST expose a readable typealias for each model, such as `Entry = Item` and `EntryVersion = ItemVersion`. A test MUST list the schema's entity names. The test MUST assert that the set equals the sixteen names.

Where several conceptual entities share one name, the model MUST carry a `kind` field. `ListItem` holds alternatives, food rules, avoided foods, ladder steps and custom places. `Sheet` holds worksheets, the maintenance plan, taking stock, reintroductions and Feeling fat notes.

`Review` holds weekly reviews and check-ins. `Answer` holds planned meal answers and card answers. `Session` holds urges. The design carries the mapping table.

#### Scenario: Kind field
- **WHEN** a reviewer reads a `ListItem` row for an avoided food and a `Sheet` row for a worksheet
- **THEN** each row carries a `kind` value from the design's mapping table, and neither model name names eating or the body

#### Scenario: Types in the private database
- **WHEN** a reviewer lists the CKRecord types in the person's private database
- **THEN** every type is one of the sixteen names, and no name is a word about eating, weight, urges, the body or screening

#### Scenario: Entity name test
- **WHEN** the schema test lists the entity names of the current schema
- **THEN** the set is exactly the sixteen names

#### Scenario: Typealias in the code
- **WHEN** a reviewer reads the models package
- **THEN** `Entry` is a typealias of `Item` and no `@Model` class carries a name outside the sixteen

### Requirement: The schema is frozen and grows by addition only

A file in the repository MUST freeze the CKRecord type names and every field name. The content test MUST check that file before the first build that carries the CloudKit entitlement. A later change MUST add only an optional field with a default, or a new record type. A later change MUST NOT rename, delete or retype a record type or a field.

Every schema MUST be a numbered `VersionedSchema` with a migration stage. V1 MUST ship one schema version. A test MUST open a store fixture from every earlier schema version. The fixtures MUST start at the first TestFlight schema.

The action queue and the widget snapshot MUST each carry a format version. The app MUST discard a queue or snapshot file whose format version it does not know. The app MUST then write the snapshot again. The widgets-and-intents capability defines the two files.

#### Scenario: Frozen names
- **WHEN** a change renames a field in a model and the content test runs
- **THEN** the test fails and names the field

#### Scenario: Field added
- **WHEN** a change adds an optional field with a default to `Item` and updates the frozen file in the same commit
- **THEN** the content test passes and a store from the earlier schema opens

#### Scenario: One schema version in V1
- **WHEN** a reviewer lists the `VersionedSchema` types in the V1 release build
- **THEN** there is one, and the Diagnostics page shows its number

#### Scenario: Every earlier version opens
- **WHEN** a later change adds a schema version and the migration test runs against a store fixture from each version since the first TestFlight schema
- **THEN** every store opens and every entry is on Today

#### Scenario: Unknown format version
- **WHEN** the app reads a snapshot file with a format version it does not know
- **THEN** the app discards the file and writes the snapshot again from the store

### Requirement: The store lives in the app's own container

The store directory MUST be `Application Support/Record` in the app's own container. The store directory MUST NOT be in the App Group container. The App Group container MUST hold only the widget snapshot and the action queue. The widget extension MUST hold no entitlement for the store path. Only the app process MUST open the store. The widgets-and-intents capability states what the extension reads.

#### Scenario: Store path
- **WHEN** a reviewer lists the app's container after onboarding
- **THEN** `Application Support/Record` holds the store directory and the App Group container holds no store file

#### Scenario: App Group content
- **WHEN** a reviewer lists the App Group container after a day of use
- **THEN** it holds the widget snapshot and the action queue, and nothing else

#### Scenario: Extension entitlement
- **WHEN** a reviewer reads the widget extension's entitlements
- **THEN** the extension holds the App Group and no entitlement that reaches the app's container

### Requirement: Two store configurations in one directory

The app MUST keep two store configurations in one store directory. `Record.store` MUST hold the synced data. `Local.store` MUST hold every value in the "Device" column of the table below, and nothing else. The Diagnostics counts, the crash count among them, are in that column.

The app MUST NOT sync `Local.store`. Every device value MUST live in `Local.store`, never in UserDefaults and never in the keychain. Each device MUST hold its own copy of the device settings.

#### Scenario: Two files
- **WHEN** a reviewer lists the store directory after onboarding
- **THEN** it holds `Record.store` and `Local.store`, each with its `-wal` and `-shm` files, and nothing else

#### Scenario: App lock on one device only
- **WHEN** the person turns the app lock off on one device
- **THEN** the app lock on the second device stays as it was

#### Scenario: No UserDefaults
- **WHEN** a reviewer reads the app's UserDefaults domain and the keychain after a full day of use
- **THEN** neither holds a setting, a value from the record or a count

### Requirement: What syncs and what stays on the device

The store MUST sync every value in the "Shared" column of this table through `Record.store`. The store MUST keep every value in the "Device" column in `Local.store` on each device.

| Shared (in `Record.store`, syncs) | Device (in `Local.store`, never syncs) |
| --- | --- |
| entries as entry version rows; Day rows, set events and day state rows; plan templates; planned meal answers | the app lock, "Face ID only" or "Touch ID only", the enrolment state hash, "Lock after" |
| weigh-ins, urge sessions, every list, worksheets | the eight reminder switches |
| weekly reviews, check-ins, taking stock answers, Feeling fat notes, the maintenance plan, the pinned note | explicit wording, Time Sensitive, snooze length |
| `Settings` rows: the start day, the day start rows, the slot labels, the weigh-in day, the weigh-in unit, quiet hours | the module switches |
| `Settings` rows: the reminder times, the weekly summary sentence opt-outs, the pattern sentence opt-outs | the install id and moment, the completion flag |
| `Settings` rows: `finishDate`, the finish answers beside it, and `remindersPausedAt` | the sync choice, the iCloud account hash, the last successful sync day |
| the profile: height, the onboarding BMI, the caution flag, `askedAt` | the launch failure count, the reconcile counts, the crash count, the store creation moment |
| the stage-opened rows, the card answers, the device rows | the pending offline erase instruction, the first-import-running flag |
| | the morning-plan unanswered count, the collapse or expand choice per record day, the snooze counts, the permission line tapped flag |

#### Scenario: Plan on two devices
- **WHEN** sync is on and the person saves a planned day on one device
- **THEN** Today on the second device shows the same planned day beside its entries after the batch

#### Scenario: Reminder switch
- **WHEN** the person turns the close-the-day reminder off on one device
- **THEN** the second device keeps its own close-the-day setting

#### Scenario: Reminder time
- **WHEN** sync is on and the person moves the weekly review reminder to 19:00 on one device
- **THEN** the second device schedules its weekly review reminder at 19:00 after the batch

#### Scenario: Paused reminders
- **WHEN** the not-right-now page sets `remindersPausedAt` on one device
- **THEN** the second device reads `remindersPausedAt` and computes its own effective reminders

### Requirement: Every synced row carries its own change moment

Every synced row MUST carry `changedAt`, a field the app writes. The app MUST NOT read a CKRecord's system dates. Every row the person can delete MUST carry a `deleted` flag with its moment. The app MUST NOT hard-delete a synced row. A delete MUST write `deleted` with the moment into the row.

A reader MUST hide a deleted row and the rows that depend on it. A ladder step's reintroductions and an entry's link on a Feeling fat note are dependants. The app MUST NOT write a cascade of deletes.

#### Scenario: Delete a list item
- **WHEN** the person deletes "Ring Sam" from the alternatives list
- **THEN** the row stays in `Record.store` with `deleted` on and its moment, and no list shows it

#### Scenario: Delete a ladder step
- **WHEN** the person deletes a ladder step that has two reintroductions
- **THEN** the step's row carries `deleted`, the two reintroduction rows are unchanged, and no screen shows the step or its reintroductions

#### Scenario: System dates unread
- **WHEN** a reviewer searches the code for reads of a CKRecord's creation or modification date
- **THEN** there are none, and every conflict rule reads `changedAt`

### Requirement: Rows reference each other by key

Every reference between rows MUST be a key field the store resolves on read. The key is a UUID, or a date key with a slot index. A model MUST NOT declare a SwiftData relationship. A test MUST assert that no model declares a relationship. An edit of a row other than an entry MUST write into the winning row. An entry edit writes a new entry version, as the next requirement states.

#### Scenario: Entry on a note
- **WHEN** a Feeling fat note links an entry
- **THEN** the note holds the entry's id, and the screen resolves the entry on read

#### Scenario: Edit after a conflict
- **WHEN** two versions of a list item exist and the person edits the item
- **THEN** the store writes the edit into the winning version's row

#### Scenario: No relationships
- **WHEN** the relationship test lists the models' properties
- **THEN** no property is a SwiftData relationship

### Requirement: Entries are append-only versions

Every save, edit and delete of an entry MUST write one entry version row (`ItemVersion`, exposed as `EntryVersion`). The row MUST hold the entry id, `changedAt`, the deleted flag, the record day key and the fields. The store MUST NOT change or delete an existing entry version row before the retention rule deletes it. The store MUST apply the conflict rule on read, not on write.

The rule is: the store keeps the version with the later change moment. When the change moments are equal, the store keeps the version with the star on. When both have the same star, the store keeps the version with the longer What. When both have the same length, the store keeps the version with the lexically greater What. When both have the same What, the store keeps the version with the greater version id.

A deletion MUST be a version with the deleted flag on. The store MUST NOT merge two versions of one entry field by field. When two devices create entries with different ids, the store MUST keep both. Today MUST show one row per id, and no row for an id whose winning version is deleted.

The store MUST delete a losing version only when it is 90 days older than the device clock. The same version MUST also be 90 days older than the latest sync moment. The store MUST NOT delete a version when either 90-day test fails. The store MUST keep a winning deleted version for ever. After both 90-day tests pass, the store MUST reduce it to the entry id, `changedAt` and the deleted flag.

#### Scenario: Two devices offline
- **WHEN** device A saves "Toast and tea" at 08:10 and device B saves "Coffee" at 08:15, both offline, and both connect
- **THEN** Today on both devices shows both entries

#### Scenario: Same entry edited on both devices
- **WHEN** device A edits an entry's What at 13:10 and device B edits the same entry's star at 13:12
- **THEN** both devices show device B's whole version, with device A's What edit absent

#### Scenario: Edit then delete
- **WHEN** device A edits an entry at 13:10 and device B deletes it at 13:12
- **THEN** Today on both devices shows no row for that entry

#### Scenario: Delete then edit
- **WHEN** device B deletes an entry at 13:10 and device A edits it at 13:12
- **THEN** Today on both devices shows the entry with device A's edit

#### Scenario: Tie on moment, star and length
- **WHEN** two versions of one entry share the change moment, the star and a What of five letters, "Toast" and "Beans"
- **THEN** both devices show "Toast", and when both read "Toast" the store keeps the version with the greater version id

#### Scenario: Versions pruned
- **WHEN** an entry has a losing version from 1 June, the latest sync moment is 1 September and the record day 31 August ends
- **THEN** the store deletes the losing version and keeps the winning one

#### Scenario: Clock ahead of sync
- **WHEN** an entry has a losing version from 1 June, the device clock reads 1 September and the latest sync moment is 1 July
- **THEN** the store keeps the losing version

#### Scenario: Deleted entry kept reduced
- **WHEN** an entry's winning version is a deletion from 1 June, the device clock reads 1 October and the latest sync moment is 15 September
- **THEN** the store keeps a row with the entry id, `changedAt` and the deleted flag, and no What

### Requirement: Date-keyed rows keep the key written at creation

The store MUST write an entry's record day key with the entry at save. The store MUST compute that key from the entry's time, its UTC offset and the day start in force then. The record capability owns that rule. An entry MUST NOT change record day after save. The store MUST NOT compute a record day key again from the device zone.

Every date-keyed row MUST keep the key the store wrote when it created the row. The date-keyed rows are the Day row, the set event, the day state, the weigh-in, the review and the check-in.

Every capability that groups by day MUST read the key the store wrote. Today, the export, the weekly review, the pattern sentences and the gap band each read that key. Sync MUST carry the key as a field. A device that receives a row MUST NOT compute its key again.

#### Scenario: Entry across a zone change
- **WHEN** an entry saved at 23:30 in London holds the record day key 6 October and the person opens the app in Tokyo
- **THEN** the entry stays on 6 October on Today and in the export

#### Scenario: Row received by sync
- **WHEN** device B receives a planned day for 6 October that device A created in another time zone
- **THEN** device B keeps the key 6 October and shows the planned day on that day

### Requirement: Conflict rules for the plan, weigh-ins and lists

The store MUST identify a Day row by its record day key. The store MUST identify a plan template by its kind. The store MUST identify a planned meal answer, an `Answer` row, by its record day key and slot index. The store MUST identify a weigh-in by its weigh-in day key. The store MUST identify a list item by its id.

Each of these MUST carry `changedAt`. When two versions of one item exist, the store MUST keep the version with the later `changedAt` whole.

The store MUST NOT merge planned meals from two versions of one Day row. When two devices add list items with different ids, the store MUST keep both. The store MUST order a merged list by each item's position, then by its `changedAt`. The store MUST NOT keep two weigh-ins for one weigh-in day. The store MUST NOT compute an average of two versions of one weigh-in.

Materialisation MUST NOT create a Day row for a date key that exists after an import. Materialisation MUST NOT write `changedAt` on a Day row. Each Day row MUST keep the planned meal window constants in force at its materialisation. "Set" MUST be a sticky event row with the date key, `setAt` and `setBy`. A set event on any device means the day is set.

The snooze count MUST live in `Local.store`, keyed by the date key and the slot index. The `Answer` row MUST NOT carry the snooze count. When a planned meal has a matched entry and a "Skipped" answer, readers MUST show the entry.

#### Scenario: Planned day edited on both devices
- **WHEN** device A moves lunch to 13:30 at 08:00 and device B moves the evening meal to 19:00 at 08:05
- **THEN** both devices show device B's whole planned day, with lunch at its previous time

#### Scenario: Skip on one device, plan edit on the other
- **WHEN** device A saves "Skipped" for lunch at 13:40 and device B edits tonight's planned day at 14:00
- **THEN** both devices keep the skip and show device B's planned day

#### Scenario: Two weigh-ins on the weigh-in day
- **WHEN** device A saves a weigh-in at 07:00 and device B saves a weigh-in at 07:30 on the same weigh-in day
- **THEN** both devices show the 07:30 weigh-in only

#### Scenario: Alternatives list on two devices
- **WHEN** device A adds "Walk round the block" and device B adds "Ring Sam", both offline, and both connect
- **THEN** the alternatives list on both devices holds both items

#### Scenario: Day row after an import
- **WHEN** an import brings a Day row for 6 October and the app then materialises 6 October
- **THEN** the store keeps the imported row, creates no second Day row and writes no `changedAt`

#### Scenario: Set event
- **WHEN** the person taps "Use this plan" for 6 October on device A and device B syncs
- **THEN** device B reads the set event with its `setAt` and `setBy` and treats 6 October as set

#### Scenario: Snooze count stays on the device
- **WHEN** the person snoozes lunch's reminder twice on device A
- **THEN** device A's `Local.store` holds 2 for that date key and slot index, and no `Answer` row carries a count

#### Scenario: Entry beats Skipped
- **WHEN** lunch has a "Skipped" answer and a later entry matches its window
- **THEN** Today shows the entry beside lunch and no "Skipped"

### Requirement: Day states, sessions and reviews

A day state MUST be one row per date key and state kind, with its own `changedAt`. The collapse or expand choice is not a day state. It lives in `Local.store` by date key. A `Session` row MUST hold `startedAt`, `startDayKey`, `outcome`, `outcomeAt`, `outcomeDayKey` and `entryId`. Readers MUST treat one urge per record day as open: the one with the earliest start. The store MUST close every other open session of that day silently at the day end.

A review's natural key MUST be the due day's date key: the start day plus seven times n. It MUST NOT be a week number. After a restart the "Reviews" list can show two runs. A device MUST freeze a review's numbers only when its last sync moment is later than the review's due moment. When two frozen rows share a key, the store MUST keep the row with the earliest freeze moment. An edit MUST write into that row.

#### Scenario: Two day states
- **WHEN** device A writes "didn't record" for 6 October and device B writes "Paused" for the same day
- **THEN** the store holds two rows for 6 October, one per state kind, each with its own `changedAt`

#### Scenario: Collapsed day
- **WHEN** sync is on, 6 October is the current record day on both devices, the person collapses it on device A, and both devices sync
- **THEN** device A's `Local.store` holds the collapse choice for 6 October, `Record.store` holds no row for it, and device B shows 6 October expanded

#### Scenario: Two open urges
- **WHEN** device A starts an urge at 21:00 and device B at 21:10 on the same record day, and both sync
- **THEN** both devices show the 21:00 urge as open, and the 21:10 session closes at the day end with no message

#### Scenario: Reviews keyed by due day
- **WHEN** the start day is 1 September and the person restarts on 20 October
- **THEN** the "Reviews" list shows the first run's reviews from 8 September and the second run's from 27 October

#### Scenario: Freeze waits for sync
- **WHEN** device B's last sync moment is 09:00 on 7 September and a review fell due at 18:00 that day
- **THEN** device B does not freeze that review until it syncs after 18:00

#### Scenario: Two frozen rows
- **WHEN** device A freezes the review due 8 September at 18:00 and device B freezes it at 18:30
- **THEN** both devices show the 18:00 row, and an edit to a question writes into that row

### Requirement: Slot labels and the day start are Settings rows

Slot labels MUST be six `Settings` keys, `slot.label.<index>`. A rename MUST NOT change a `Template` row. A rename MUST NOT restart the stable-plan run. The day start MUST be append-only rows, each with an hour and `effectiveFromDayKey`. Every device MUST apply a day start row from that key.

#### Scenario: Slot rename
- **WHEN** the person renames slot 2 to "Elevenses"
- **THEN** `Settings` holds `slot.label.2` as "Elevenses", the `Template` row is unchanged and the stable-plan run continues

#### Scenario: Day start on two devices
- **WHEN** the person sets the day start to 05:00 from 10 October on device A and device B syncs
- **THEN** device B applies 05:00 from 10 October and keeps the keys of earlier days

### Requirement: The Reconciler never deletes a row

The Reconciler MUST pick one winner per natural key on read, by the rule each capability states. The Reconciler MUST NOT delete a row. The store MUST delete a losing row only when it is 90 days older than the latest sync moment. The same row MUST also be 90 days older than the device clock. For the stage-opened rows the natural key is the stage and the winner is the row with the earliest moment. The programme capability owns the opening moment the engine writes. A reader MUST treat an `askedAt` later than the device clock as `safeguarding` states.

The Reconciler MUST ignore on read a review, a stage opening or a check-in dated later than the device clock. It MUST NOT delete such a row. A restart MUST NOT delete the stage 5 opening row. The engine MUST ignore a stage 5 opening earlier than the restart moment.

The app MUST keep the last reconcile outcome in `Local.store` as counts of winners and losers. The Diagnostics page shows them.

#### Scenario: Future-dated review
- **WHEN** the device clock moves back one day and a review row carries tomorrow's date
- **THEN** the app ignores the row today, keeps it, and reads it tomorrow

#### Scenario: Restart keeps the stage 5 row
- **WHEN** the person restarts on 20 October with a stage 5 opening from 12 October
- **THEN** the row stays in the store and the engine ignores it after the restart

#### Scenario: Two stage-opened rows
- **WHEN** device A and device B each write a stage 2 opening, at 04:00 on 6 October and at 04:00 on 7 October
- **THEN** both devices report stage 2 open from 6 October and both rows stay in the store

#### Scenario: Losing planned day kept
- **WHEN** an import brings a second planned day for 6 October with an earlier change moment
- **THEN** Today shows the later planned day and the store keeps both rows for 90 days

#### Scenario: Clock moved forward
- **WHEN** the device clock moves forward one year and the latest sync moment is today
- **THEN** the store deletes no row

### Requirement: Card answers live in the record

The store MUST keep one card answer row in `Record.store` for each answered card. The row MUST hold the card id, the answer and the moment. A card whose answer row exists on any device MUST NOT show. A suggestion card's answer MUST be a card answer row keyed by the template id. While the first import after sync turns on runs, the app MUST show no card. While it runs, the app MUST write no opening moment.

#### Scenario: Card answered on one device
- **WHEN** the person taps "Close" on an opening card on device A and Today loads on device B after sync
- **THEN** device B shows no card for that card id

#### Scenario: Suggestion on two devices
- **WHEN** the person answers a suggestion card for one pattern template on device A
- **THEN** device B never shows a suggestion card for that template

#### Scenario: During the first import
- **WHEN** the person turns sync on and the first import runs for a minute
- **THEN** Today shows no card and the store writes no opening moment in that minute

### Requirement: Every install has one device row

The store MUST keep one device row per install in `Record.store`. The row's model is `Device`, one of the sixteen neutral names. `Local.store` MUST keep the install id. The `Device` row MUST hold the install id, the day the install joined, `lastSeenDay` and `leftAt`. When the person turns sync off, the app MUST write `leftAt` into its own row.

The Privacy group of the settings screen MUST show "Devices with your record: %lld" and the day each joined. The count MUST exclude rows with `leftAt`. The settings capability owns the group. Delete-all MUST delete every device row with the sync zone. The onboarding capability's iCloud choice states who can read the record on another device.

#### Scenario: Second device joins
- **WHEN** the person turns sync on on a second device on 10 October
- **THEN** the Privacy group on both devices shows "Devices with your record: 2" with 10 October beside the second

#### Scenario: One device
- **WHEN** the person has sync on with one install
- **THEN** the Privacy group shows "Devices with your record: 1"

#### Scenario: Device leaves
- **WHEN** two devices have sync on and the person turns sync off on device B
- **THEN** device B's row carries `leftAt`, and device A shows "Devices with your record: 1"

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

#### Scenario: Delete everything offline
- **WHEN** the person confirms Delete-all in airplane mode and connects an hour later
- **THEN** the device holds nothing at once, and the marker and the zone deletion happen after the connection

#### Scenario: Widget after Delete-all
- **WHEN** the Home Screen widget showed "13:00" and the person confirms Delete-all
- **THEN** the widget shows the product name and no time

### Requirement: Delete from this device

The cover after an enrolment change MUST offer "Delete from this device" beside "Delete everything", as the app-lock capability states. The app-lock capability owns the control and its confirmation. This capability owns the deletion. "Delete from this device" MUST delete only this device's copy. The app MUST delete the whole store directory, `Local.store` and `Record.store` with it. The app MUST then create the directory again empty.

The app MUST first cancel every pending notification request. The app MUST delete every delivered notification at the same step. The app MUST delete the widget snapshot file, the action queue file and the launch marker file. The app MUST reload every widget so it shows the product name and nothing else.

The app MUST NOT write an erasure marker. The app MUST NOT delete a zone. The app MUST NOT send anything to iCloud. A copy in iCloud stays as it was, and another device with sync on keeps its copy.

After the deletion the app MUST show one screen: "This device's copy is deleted. To remove the app, touch and hold its icon and choose Remove App." with "Done". The app MUST keep that screen after "Done" until the next launch. The app MUST start onboarding only at the next launch. When the device then has an iCloud account with a sync zone, the app reads iCloud before onboarding, as the requirement above states.

#### Scenario: Delete from this device with sync on
- **WHEN** sync is on and the person confirms "Delete from this device" after an enrolment change
- **THEN** the store directory holds no file, the private database holds the sync zone and no new marker, and a second device keeps every entry

#### Scenario: Delete from this device with sync off
- **WHEN** sync is off and the person confirms "Delete from this device"
- **THEN** the store directory holds no file, the app sends nothing to iCloud and the next launch shows the first onboarding screen

#### Scenario: Get it back after the deletion
- **WHEN** the person confirms "Delete from this device" with sync on, sets Face ID up again and opens the app
- **THEN** the app asks "Your record is in iCloud. Get it back on this device?" before onboarding

#### Scenario: Pending requests first
- **WHEN** a reviewer traces "Delete from this device" with six pending reminders
- **THEN** the app cancels the six requests before it deletes the store directory, and none fires afterwards

### Requirement: Every device checks the Erasure zone

Every device with sync on MUST read the "Erasure" zone at launch and before it opens a synced container. When the device is offline at launch, the app MUST open the store. It MUST then read the zone at the next connection before it sends anything. A marker applies when it is later than the device's store creation moment.

A "deleted" marker that applies MUST make the device delete its store and settings. That holds only when the device has no local write later than the marker's `tapAt`. The device MUST then show the first onboarding screen.

When the device holds a local write later than the marker's `tapAt`, the app MUST NOT delete. After authentication the app MUST ask "Your record was deleted from iCloud on %@. Keep this device's copy, or delete it?" with "Keep" and "Delete". The en_GB formatter fills `%@` with the day of `tapAt`.

A "removed" marker MUST NOT delete a copy; the sync requirement states its effect. A device with sync off MUST read the zone when the person next turns sync on. When that device finds a newer marker, the app MUST ask the same question.

The app MUST use one sync zone name. "Keep" MUST create that zone again after the marker. "Keep" MUST then send the copy to that zone. "Delete" MUST delete the copy in the same way as Delete-all on the device.

A device MUST NOT delete its copy without a marker or the person's tap. The app MUST delete a marker older than one year the next time it reads the zone. The team cannot, because the zone is in the person's private database.

#### Scenario: Second device with sync on
- **WHEN** the person confirms Delete-all on device A on 3 October and device B, with no write since 2 October, launches with sync on
- **THEN** device B deletes its own copy and shows the first onboarding screen

#### Scenario: Second device with later writes
- **WHEN** the person confirms Delete-all on device A at 09:00 on 3 October and device B saved an entry offline at 10:00 that day
- **THEN** device B keeps its copy and, after authentication, asks "Your record was deleted from iCloud on 3 October. Keep this device's copy, or delete it?"

#### Scenario: Second device with sync off
- **WHEN** the person confirms Delete-all on device A on 3 October and turns sync on on device B on 10 October
- **THEN** device B asks "Your record was deleted from iCloud on 3 October. Keep this device's copy, or delete it?"

#### Scenario: Keep the copy
- **WHEN** the person taps "Keep" on device B
- **THEN** device B keeps its record and the private database holds the sync zone again, created after the marker, with device B's copy

#### Scenario: Older marker
- **WHEN** the person starts again on device A after Delete-all and device A launches
- **THEN** the marker is older than device A's new store and device A keeps its record

#### Scenario: Offline at launch
- **WHEN** device B launches in airplane mode with sync on and connects an hour later
- **THEN** device B opens the store at launch and reads the Erasure zone before it sends anything

#### Scenario: Marker older than a year
- **WHEN** a device reads the Erasure zone on 4 October 2027 and finds a marker written on 3 October 2026
- **THEN** the app deletes that marker and applies no marker

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

#### Scenario: The App Intent
- **WHEN** the person uses the App Intent to open the new-entry screen
- **THEN** no entry field reaches Siri or Shortcuts, and neither shows an entry

#### Scenario: Export
- **WHEN** the person creates an export and does not tap a share destination
- **THEN** the PDF stays on the device

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

#### Scenario: New device with sync on
- **WHEN** the person restores a new device from a backup and signs into the same iCloud account with sync on
- **THEN** the record is empty until sync runs, and then Today shows the person's entries

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

### Requirement: The privacy notice

The privacy notice MUST be one tap from the settings screen. The team MUST publish the same notice at a public URL. The notice MUST name the controller and its contact. The notice MUST name the contact email of the support page. The notice MUST state who reads that inbox.

The notice MUST state the lawful basis and the Article 9 condition for each processing. The notice MUST name Apple as a recipient. The notice MUST state where Apple holds the data. The notice MUST state what Apple can see and that the team sees nothing the person writes.

The notice MUST state that the team receives only Apple's aggregated App Analytics and crash reports. Those are the ones the person chooses to share with Apple. The notice MUST state how the person reads and deletes their data in the app. The notice MUST state "A backup of your device can hold reminder times until the app cancels them. It never holds your entries." The notice MUST name the ICO as the authority the person can complain to.

#### Scenario: Privacy notice
- **WHEN** the person opens the settings screen and taps "Privacy"
- **THEN** the notice opens and holds the controller, the contact, who reads the contact inbox, Apple, the App Analytics line, the backup line and the ICO

#### Scenario: Public URL
- **WHEN** a person opens the privacy notice URL from App Store Connect in a browser
- **THEN** the page shows the same notice as the app

#### Scenario: Erasure
- **WHEN** the person reads the section on deleting their data
- **THEN** it names "Delete everything" in the settings screen

### Requirement: Release gates and the App Store submission

The team MUST NOT give a build to a person outside the team before the DPIA sign-off file is complete. The DPIA MUST cover the co-design panel and the children's-code assessment. The DPIA MUST name App Analytics as the only analytics and Apple as its processor. The team MUST NOT give such a build before the privacy notice is in the app. The team MUST tell each TestFlight tester that Apple collects crash logs and feedback screenshots.

The team MUST submit the app from the company's organisation account. One legal entity MUST appear in App Store Connect, the copyright field, the privacy notice and the DPIA. The team MUST answer the age rating questionnaire truthfully. The team MUST raise the minimum age to 18+.

The app MUST NOT request the Declared Age Range entitlement in V1. The typed age is the gate. The app MUST be on the UK storefront only.

The README MUST hold the clinical reviewer's dated sign-off of the screening thresholds. Those are 18.5, 19.0, Rules A to C and the deterioration rule. The same sign-off MUST cover the self-harm item's wording and routing. The team MUST invite testers by email only, never through a public link. Test Information MUST hold the privacy notice URL, the contact email, the onboarding walk and the crash-log line. The team MUST declare only the accessibility labels whose device checks have a dated screenshot.

The Info.plist MUST hold the `NSFaceIDUsageDescription` the app-lock capability states. The app MUST declare the fetch and remote-notification background modes and one `BGTaskScheduler` identifier. The review notes MUST state the purpose of each of the three.

The team MUST submit a demo video that walks every stage on a device. The review notes MUST carry this fixed text.

"No account. Onboarding walk: age 34, height 170 cm, weight 60 kg, answer No to the three questions, choose Sunday, choose 'This device only', tap Start. Entering an age under 18 or a weight that gives a BMI under 18.5 shows a safety page; tap Done to return. App lock is on by default and uses the device passcode or Face ID. No HealthKit. No third-party SDKs. Time Sensitive notifications are opt-in in Settings. Background refresh only extends local reminder scheduling. Face ID is used only to unlock the app. Clinical reviewer: name, role, registration number. Demo video: link."

The team MUST keep that text under version control beside the README. The team MUST enter the privacy notice's public URL in App Store Connect and in Test Information.

The team MUST publish a support page with a contact email. The About group of the settings screen MUST show "Contact" with that email. The settings capability owns the group. The privacy notice states who reads that inbox.

The category MUST stay Lifestyle. The review notes MUST carry the justification "a structured self-help programme, not a tracker, and holds no HealthKit data". The app MUST hold no hidden unlock, reviewer code or bypass of the app lock. App Review unlocks the app as any person does.

#### Scenario: One legal entity
- **WHEN** a reviewer compares the organisation in App Store Connect, the copyright field, the privacy notice and the DPIA
- **THEN** all four name the same legal entity

#### Scenario: Thresholds signed off
- **WHEN** a reviewer reads the change's README before the first build for a person outside the team
- **THEN** it holds the clinical reviewer's dated sign-off of 18.5, 19.0, Rules A to C, the deterioration rule and the self-harm item

#### Scenario: Age rating
- **WHEN** a reviewer reads the age rating answers and the entitlements
- **THEN** the minimum age is 18+ and no Declared Age Range entitlement is present

#### Scenario: Testers and Test Information
- **WHEN** a reviewer reads the TestFlight configuration
- **THEN** the team invited every tester by email, no public link exists, and Test Information holds the privacy notice's public URL, the contact email, the onboarding walk and the crash-log line

#### Scenario: Accessibility labels declared
- **WHEN** the team fills the accessibility section in App Store Connect
- **THEN** every declared label has a device check with a dated screenshot in the README

#### Scenario: Background modes in the review notes
- **WHEN** App Review reads the review notes
- **THEN** they state why the app declares fetch, remote-notification and one `BGTaskScheduler` identifier

#### Scenario: Demo video and review notes
- **WHEN** a reviewer reads the submission before the team sends it to App Review
- **THEN** it holds a demo video that walks every stage on a device, and the review notes carry the fixed text with the onboarding walk, the clinical reviewer and the video link

#### Scenario: Review notes under version control
- **WHEN** a reviewer compares the review notes in App Store Connect with the file beside the README
- **THEN** the two texts are the same and the file's history shows every change

#### Scenario: Support page and Contact
- **WHEN** the person opens the About group of the settings screen
- **THEN** it shows "Contact" with the support page's email, and the privacy notice states who reads that inbox

#### Scenario: Category
- **WHEN** a reviewer reads the App Store Connect category and the review notes
- **THEN** the category is Lifestyle and the review notes carry "a structured self-help programme, not a tracker, and holds no HealthKit data"

#### Scenario: No hidden unlock
- **WHEN** a reviewer searches the code and the review notes for a reviewer code or a bypass of the app lock
- **THEN** there is none, and the review notes state that the app lock uses the device passcode or Face ID

#### Scenario: First TestFlight build
- **WHEN** the team prepares the first build for a person outside the team
- **THEN** the change's README has a dated line with the DPIA completion date and the privacy notice's version

#### Scenario: DPIA names App Analytics
- **WHEN** a reviewer reads the DPIA's list of processings
- **THEN** App Analytics is the only analytics named and no analytics event of the app's own appears

#### Scenario: TestFlight tester
- **WHEN** a tester receives the invitation
- **THEN** the invitation text states that Apple collects crash logs and feedback screenshots

#### Scenario: Storefront
- **WHEN** a person in Ireland searches the App Store for Midmorning
- **THEN** the App Store does not list it
