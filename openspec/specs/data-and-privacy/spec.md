# data-and-privacy Specification

## Purpose
This capability governs where the person's data lives and where it can go. It covers sync to the person's private iCloud database and the account it binds to. It covers the change moment every synced row carries, the append-only entry versions and the rules when two devices disagree. It covers the frozen schema, launch safety and Delete-all.

It covers where the store lives, file protection, exclusion from backups and the list of what never leaves the device. The app holds no analytics of its own; the team receives only Apple's App Analytics. The DPIA, the privacy notice and the App Store submission are release gates; this capability states what they contain.

## Requirements

### Requirement: CKRecord types and model names are neutral

Every CKRecord type name and every `@Model` class name MUST be one of sixteen neutral names. The names are Item, ItemVersion, DayState, Template, Day, Answer, Measure, Session, ListItem, Sheet, Review, Profile, Settings, Seen, Place and Device. `Device` is the model of the one row per install. A type name, a model name or a field name MUST NOT name eating, weight, urges, the body or screening. The zone name MUST NOT contain such a word either.

The Swift API MUST expose a readable typealias for each model, such as `Entry = Item` and `EntryVersion = ItemVersion`. A test MUST list the schema's entity names. The test MUST assert that the set equals the sixteen names.

Where several conceptual entities share one name, the model MUST carry a `kind` field. `ListItem` holds alternatives, food rules, avoided foods, ladder steps and custom places. `Sheet` holds worksheets, the maintenance plan, taking stock, reintroductions and Feeling fat notes.

`Review` holds weekly reviews and check-ins. `Answer` holds planned meal answers and card answers. `Session` holds urges. The design carries the mapping table.

#### Scenario: Kind field
- **WHEN** a reviewer reads a `ListItem` row for an avoided food and a `Sheet` row for a worksheet
- **THEN** each row carries a `kind` value from the design's mapping table, and neither model name names eating or the body

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

### Requirement: The store lives in the app's own container

The store directory MUST be `Application Support/Record` in the app's own container. The store directory MUST NOT be in the App Group container. The App Group container MUST hold only the widget snapshot and the action queue. The widget extension MUST hold no entitlement for the store path. Only the app process MUST open the store. The widgets-and-intents capability states what the extension reads.

#### Scenario: Store path
- **WHEN** a reviewer lists the app's container after onboarding
- **THEN** `Application Support/Record` holds the store directory and the App Group container holds no store file

#### Scenario: App Group content
- **WHEN** a reviewer lists the App Group container after a day of use
- **THEN** it holds the widget snapshot and the action queue, and nothing else

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
| the stage-opened rows, the card answers, the device rows | the pending offline erase instruction, the first-import-running flag, the first-import-failed flag |
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

### Requirement: The privacy notice

The privacy notice MUST be one tap from the settings screen. The team MUST publish the same notice at a public URL. The notice MUST name the controller and its contact. The notice MUST name the contact email of the support page. The notice MUST state who reads that inbox.

The notice MUST state the lawful basis and the Article 9 condition for each processing. The notice MUST name Apple as a recipient. The notice MUST state where Apple holds the data. The notice MUST state what Apple can see and that the team sees nothing the person writes.

The notice MUST state that the team receives only Apple's aggregated App Analytics and crash reports. Those are the ones the person chooses to share with Apple. The notice MUST state how the person reads and deletes their data in the app. The notice MUST state "A backup of your device can hold reminder times until the app cancels them. It never holds your entries." The notice MUST name the ICO as the authority the person can complain to.

#### Scenario: Privacy notice
- **WHEN** the person opens the settings screen and taps "Privacy"
- **THEN** the notice opens and holds the controller, the contact, who reads the contact inbox, Apple, the App Analytics line, the backup line and the ICO

#### Scenario: Erasure
- **WHEN** the person reads the section on deleting their data
- **THEN** it names "Delete everything" in the settings screen
