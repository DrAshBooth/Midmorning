# Design

## Context

`record-entry-on-today` fixes the stack:

- SwiftPM packages for logic, tested on macOS
- SwiftUI in `App/`
- SwiftData in an App Group container, under CloudKit's constraints
- the store as the only path
- STE specs in OpenSpec

See that change's design and `brain/architecture.md`. This design adds what the full programme needs and nothing the specs do not require. Ash decided the twelve open points on 25 September 2026; the proposal lists them.

## Goals / Non-Goals

**Goals:**
- One data model for every entity, shaped for CloudKit before sync turns on.
- One programme engine that answers "which stage, which tools, which week" from the record, the plan and the stored opening moments, with every threshold in one place.
- One scheduler that turns the plan and settings into local notifications under the cap and inside quiet hours.
- Content as bundled, versioned data with a written sign-off.
- Every computation testable on macOS with fixed dates.

**Non-Goals:**
- A server. A backend. An account.
- A generic "module framework". The two modules are two features.
- Any abstraction for V2.
- An iPad layout or landscape.

## Decisions

### One umbrella package, five targets

`Packages/Package.swift` holds every module as a target, so each compiles once under one `swift test` line. Ash chose this on 25 September 2026 for the verify budget. `Record` keeps the entry, its versions, the record day and the store. `Plan` holds the plan, templates, planned days, the match of planned meals to entries and the gap computation. `Packages/Programme` holds the stage engine, week counting, the weekly review builder, pattern sentences, the safeguarding rules, the scheduler and the analytics summary builder. `Packages/Content` holds the cards, their versions and the string catalogue. `Constants` holds `ProgrammeConstants`. `Constants` is a leaf target that `Record`, `Plan` and `Programme` import (decision 61).

Every target imports Foundation and SwiftData. Content can also import CryptoKit, and `Record`, `Plan` and `Programme` also import `Constants`. `Programme` takes value facts and imports `Constants`, but neither `Record` nor `Plan`. The app target holds views, notifications, widgets, App Intents, LocalAuthentication, PDF rendering and CloudKit code.

Rejected: one package per module. Each one rebuilds `Record`, and a cold verify exceeds the budget. Rejected: logic in the app target. Nothing there runs under `swift test`.

### Two store configurations in one directory

One `ModelContainer` opens two configurations in `Application Support/Record`. `Record.store` syncs to the private database when the person has chosen sync. `Local.store` never syncs. No relationship crosses the two, and no SwiftData relationship exists at all: every reference is a key field that the reader resolves on read. Delete-all releases the container, deletes the whole directory and recreates it.

Rejected: one configuration. A configuration syncs every model in it, so device-only data would sync.

Every synced row carries `changedAt`, an app field, and every row the person can delete carries `deleted` with a moment. The app never hard-deletes a synced row; readers hide deleted rows and their dependants. The `Reconciler` never deletes a row. It picks one winner per natural key on read. The store deletes a losing version or row only after both 90-day tests pass: the device clock and the latest sync moment.

The reader ignores rows that a clock guard would delete. Ash accepted this on 25 September 2026 from the data-model review. Every hard delete and every whole-row winner rule loses data across two devices.

Sixteen `@Model` classes, each a neutral name, carry the conceptual entities with a `kind` field where several share one:

| Model | Holds | Natural key | Winner |
| --- | --- | --- | --- |
| `Item` | entry identity | id | none |
| `ItemVersion` | entry versions: entry id, changedAt, deleted, dayKey, time, offset, What, Where, Context, star, createdAt | version id | later changedAt, star on, longer What, lexically greater What, greater version id |
| `DayState` | one row per (dateKey, kind): paused, didn't record, fasting, feeling word | dateKey + kind | later changedAt |
| `Template` | weekday or weekend slots | kind | later changedAt |
| `Day` | a planned day: dateKey, slots, window constants; a separate set event row (dateKey, setAt, setBy) | dateKey | later changedAt; set is sticky |
| `Answer` | planned meal answers (dateKey + slot index) and card answers (card id, optional dayKey) | as listed | later changedAt; a match beats Skipped on read |
| `Measure` | weigh-in | dateKey | later changedAt |
| `Session` | urge: startedAt, startDayKey, outcome, outcomeAt, outcomeDayKey, entryId | id | one open per record day, earliest start |
| `ListItem` | alternatives, food rule, avoided food, ladder step, custom place | id | later changedAt; union by id |
| `Sheet` | worksheet, maintenance plan, taking stock, reintroduction, Feeling fat note | id (maintenance plan: fixed) | later changedAt |
| `Review` | weekly review, check-in | due dateKey | earliest freeze; edits into the winner |
| `Profile` | height, onboarding BMI, caution flag, askedAt | fixed id | later changedAt per key |
| `Settings` | one row per key: start day, day start history, slot labels, weigh-in day or none, unit, quiet hours, reminder times, switches that sync, finishDate, finish answers, remindersPausedAt, restart moment | key | later changedAt |
| `Seen` | card views | id | none |
| `Place` | reserved name; holds no rows in v1. Custom places are `ListItem` kind custom place | | |
| `Device` | install id, joinedDay, lastSeenDay, leftAt | install id | later changedAt |

`Local.store` holds these values:

- app lock
- Face ID only
- enrolment state hash
- lock after
- the eight reminder switches
- explicit wording
- Time Sensitive
- snooze length
- module switches
- install id and moment
- completion flag
- sync choice
- account hash
- last successful sync day
- launch failure count
- reconcile counts
- crash count
- store creation moment
- pending offline erase instruction
- first-import-running flag
- morning-plan unanswered count
- collapse or expand choice per record day
- snooze counts

### Entries are append-only versions

Every save, edit and delete writes an `EntryVersion` (entry id, change moment, deleted flag, the fields). Nothing changes or deletes a version before the retention rule. `RecordStore` picks one winner per entry id on read: later change moment, then star on, then longer What. A deletion is a version. Distinct ids both survive. The store keeps a winning deleted version for ever. It deletes a losing version only after both 90-day tests pass: the device clock and the latest sync moment. After both tests pass, it reduces a winning deleted version to the entry id, `changedAt` and the deleted flag.

Rejected: relying on CloudKit's merge. It merges per field, applies a delete unconditionally and cannot see the app's id. Cost to reverse: high, because the on-read rule is what every reader depends on.

### Delete-all writes an erasure marker before it deletes the zone

Delete-all writes a marker (random token, moment) to a separate `Erasure` zone, then deletes the sync zone, then the local directory. Every device reads the `Erasure` zone on launch and before it opens a synced container. A marker newer than its own store makes a device delete its local store and settings and return to onboarding. A device with sync off checks when sync next turns on and asks whether to keep or delete its copy. Rejected: relying on zone deletion. A second device recreates the zone from its local store.

### Sync is off until the person chooses it, sends once a day, and runs on CKSyncEngine

Sync is not in the first TestFlight cut; onboarding there offers "This device only" as the one choice. When the team builds the sync change, it uses `CKSyncEngine`, not SwiftData's own mirroring. Mirroring exports on every save and cannot honour the daily batch, the lock rule or the erasure marker. Ash chose this on 25 September 2026.

Every attribute still carries `.allowsCloudEncryption` and the sixteen neutral names. Onboarding then asks where the record lives, with neither answer preselected. `cloudKitDatabase` stays `.none`; CKSyncEngine maps the models to record types itself. Every attribute except `id` carries `.allowsCloudEncryption` from the first change.

The app sends changes to the private database once per record day, at a random moment inside the following record day. It never sends at a save and never while locked. "Sync now" sends at once. The app keeps a hash of the iCloud account's `userRecordID` and never opens a synced container against another account.

Rejected: on by default. A preset default is not consent for health data. Rejected: sync at every save. Apple would see the eating timeline.

### Dates are keys, fixed at save

The store keys a record day, a planned day, a weigh-in and a review by a local date string. It writes that string when it creates the row. An entry's `time` stays an instant with its UTC offset. The store writes the entry's `dayKey` at save from that time, that offset and the day start in force. Nothing recomputes a key. The current record day comes from the device zone and the current day start.

Ash chose this on 25 September 2026. Rejected: recomputing days from the device zone. It changes the day of every historic entry when the person travels. The day start is a synced setting with `DEFAULT_DAY_START_HOUR = 4`; a change applies from the next day start.

### The programme engine is a pure function with stored openings as input

`Programme.state(facts:openings:cardAnswers:settings:constants:now:restartAt:currentRecordDay:)` returns the stage, the open tools, the week number, the counts toward the next stage and the pending cards. It ignores a stored opening later than `now` and a stage 5 opening earlier than `restartAt`; it deletes nothing. A stage is open when a `StageOpened` row exists or the rule computes it. The app writes the row the first time the engine reports a stage open. Deleting entries never closes a stage. The scan reads only entries after the last stored opening.

Weeks for taking stock and staying on track count from the record day stage 2 opened. Stage 4 opens after the first urge outcome or seven recorded days with stage 3 open. `ProgrammeConstants` is a value with `.default`. It holds every threshold with the names the programme spec lists, including PROGRAMME_WEEKS, the height and weight limits and the lock grace set.

Rejected: stored flags only. The app cannot recompute them after a restore. Rejected: fully computed. Deletions would close stages.

### A planned meal matches entries by a window

The engine sorts planned meals by time. Each has a window from 60 minutes before to 90 minutes after. Where two adjacent windows overlap, the earlier ends and the later starts at the midpoint. The engine clips every window to the record day. The earliest unmatched entry in a window matches. A planned meal with no match and no "Skipped" answer after its window is missed.

Rejected: matching by a slot the person types. The record has no slot field, by design.

### The scheduler is a pure function over a rolling horizon

`Scheduler.requests(plan:templates:settings:state:snoozes:now:)` returns the local notification requests for the next `REMINDER_HORIZON_DAYS` record days, plus every far single reminder (worksheet reviews, check-ins). It caps the result at 60 pending requests. It applies these rules in order:

- the per-type switches
- `remindersPausedAt`
- the paused day
- quiet hours
- the same-minute rule
- the cap

Under the cap, planned meal reminders never drop. Of the other types, at most `MAX_OTHER_REMINDERS_PER_DAY` fire, and the scheduler drops them in the order the reminders spec gives. The weekly review reminder never drops. On activation the app materialises every elapsed record day, then replaces all pending requests with the result. Snooze state lives in the action queue and is an input.

Rejected: incremental scheduling. A cap or quiet-hours error is hard to see in a partial update. Rejected: a 48-hour horizon. With it, the scheduler never schedules a worksheet review a week away.

### Locked-state actions use the notification's payload

A notification action can wake the app while the device is locked and the store is unreadable. Each planned meal request's userInfo carries the date key, slot, planned time, next planned time, snooze count, quiet hours and snooze length. The "Skipped" and "Not yet" handlers read userInfo only and write the action queue file. The app applies the queue when protected data becomes available. The container opens on first use and never `fatalError`s.

Rejected: opening the store from the handler. It throws while locked.

### The store lives in the app's container; two side files live in the App Group

The store directory is `Application Support/Record` in the app's own container, with `NSFileProtectionComplete` and backup exclusion. Only the app process opens it. The App Group holds only the action queue and the widget snapshot (times, slot indexes, the pause state, the explicit-wording flag). Both carry `NSFileProtectionCompleteUntilFirstUserAuthentication` and a format version. Neither holds entry text, a star or a weight.

Ash chose this on 25 September 2026; the walking skeleton moved the same day. `brain/architecture.md` states it.

### Content is data with a version and a sign-off file

Cards and every other bundled string family live in `Packages/Content/Resources` with ids, a content version and a SHA-256 bundle hash. The content test checks counts, word limits, the forbidden list and UK spelling on every build. It checks the sign-off file only when `MIDMORNING_RELEASE=1`; otherwise it sets a "Draft" flag that the app shows. Rejected: cards in Swift source. The clinician cannot edit them.

### Pattern sentences and reviews are templates plus numbers

Every sentence the app builds is a reviewed template with numeric and time placeholders. The engine chooses a template by rule and fills the placeholders. The app forms no other words at runtime.

### No analytics of our own

The app writes nothing to the CloudKit public database and holds no event store. The team reads Apple's App Analytics in App Store Connect. Apple aggregates it and never links it to an account. Ash chose this on 25 September 2026 over the weekly summary event, because every public-database record carries Apple's creator field. Programme-level metrics come from the beta panel and the clinical reviewer's notes.

### App lock covers the window, not the data

LocalAuthentication gates a cover over the window on launch and after the "Lock after" choice in the background (0, 30, 120 or 300 seconds, default 0). The app measures that time with `mach_continuous_time`. An entry point is the one exception. It shows the empty new-entry screen first and authenticates on Save, so the record stays the quickest action in the app (decided 25 September 2026). After an enrolment change the cover offers "Delete from this device" beside "Delete everything". The app locks at once on `protectedDataWillBecomeUnavailable` and on the lock control in Today's navigation bar.

"Biometrics only" uses the biometrics-only policy and keeps the last enrolment state; after a change the app stays locked, and "Delete everything" is the only action. The cover shows nothing but "Midmorning", "Unlock" and "Delete everything"; Get support appears after authentication. Widgets show no data. Rejected: encrypting the store with a lock-derived key. The widget and intents cannot write.

### Export renders a tagged, flowing column at fixed sizes

The PDF uses a PDF context from Core Graphics with tagged-PDF marks (`CGPDFTagType`). "Record" is H1, each day heading is H2, each day's entries are one list with one item per entry, and the language is en-GB. The export sets text at 11 pt body, 14 pt day heading and 18 pt title, independent of Dynamic Type. It flows as one column and repeats the day heading when a day continues on the next page. Creator is empty; the system writes Producer. No password.

The team tests the en-GB language tag before the export change commits to it. Rejected: `ImageRenderer` over SwiftUI rows. The layout follows the device's text size, and the output has no structure.

### Widgets read the snapshot; intents open the app

The widget extension reads the snapshot file only. The App Intent and the Control Centre control set a pending route and open the app. Only the app process opens the store. Rejected: an extension that opens the store. It fails while the device is locked.

### Pure seams the packages expose

Every rule the specs state as a pure function has a named home, so that a test with fixed inputs can prove it under `swift test`:

- `ProgrammeConstants` is a value with `.default`; every function that reads a threshold takes it as a parameter.
- `now: Date`, `calendar: Calendar` and `locale: Locale` are parameters on every function that touches time or formatting. A `Clock` protocol and a `ContinuousClock` protocol (ticks that count through sleep) sit at the app boundary.
- `Programme` takes value facts (`RecordedDayFact`, `PlannedDayFact`, `UrgeOutcomeFact`, card memory, stored openings, `finishDate`), never SwiftData models, so it compiles without `Record` and `Plan`.
- `Scheduler.requests` returns `ReminderRequest` values (id, trigger, empty title, time body, userInfo with a slot index, interruption level, category, thread); the app maps them to `UNNotificationRequest`. `NotificationAuthorisation` is an input. A `NotificationCentre` protocol in the app has a fake that keeps every call.
- `SnoozeDecision.decide(userInfo:now:)` is one pure function that both the notification handler and the scheduler call.
- `ActionQueue` has a codec with a format version and an applier on the store.
- `AppLifecycle.reduce(state, event)` handles background and foreground, protected data availability, authentication and the pending route. `LockPolicy.shouldAsk(enteredBackgroundAt:now:grace:)` and `Biometry` sit beside it.
- `Materialiser.daysElapsed(lastActivation:now:calendar:)` returns, per elapsed record day, the template copy, the planned-day decision, the snapshot, the review freeze and the weekly summary build.
- `SnapshotBuilder` and `SnapshotTimeline.entries(snapshot:now:)` live in a package the widget extension links.
- `ExportDocument`, `Paginator.paginate(document:pageHeight:measure:)` and `ExportFileName` live in a package; the app supplies the text measurer.
- `EntryWinner.pick([EntryVersion])` and `Reconciler` are pure over arrays; two-device scenarios become one-store tests that insert both devices' versions.
- `ErasureZone` is a protocol with `readMarker`, `writeMarker`, `deleteSyncZone` and `deleteEvents`; Delete-all is a state machine over it with a fake in tests.
- `ContentBundle.load(from:)`, `environment: [String: String]` for the release lane, and the repository root from `#filePath` for the sign-off file and the literal lint. The Content package can import CryptoKit for SHA-256.
- Screen models are values: `TodayStack`, `ProgrammeScreen`, `WeighInScreen`, `ReviewDocument`, `TakingStock`, `UrgeScreen`, `EatingEnoughCheck`, `ExclusionPage`, `SupportSheet(order:)`, `GPSuggestionPage(reasons:)`. Views render them and hold no rule.

### Model names, singletons and the account binding

Every `@Model` class has one of sixteen neutral names (Item, ItemVersion, DayState, Template, Day, Answer, Measure, Session, ListItem, Sheet, Review, Profile, Settings, Seen, Place, Device). The Swift API exposes typealiases such as `Entry = Item`. The team renames the `Entry` model in `Packages/Record` before the first build that carries the CloudKit entitlement. `Profile` and `Settings` have one fixed id each.

A file in the repository freezes the record type and field names; the content test checks it. When the person turns sync on, `Local.store` keeps a hash of the iCloud account's `userRecordID`. The app never opens a synced container against a different account. A card answer row (card id, answer, moment) lives in `Record.store` so a card shows once across devices.

### A first TestFlight cut; the specs keep every requirement

`deferred.md` lists every requirement the first cut leaves out with its owning later build change. No spec loses a requirement. The model foundation (names, versions, per-row change moments, settings rows, the Reconciler) is its own build change, 1.2a model-foundation, ahead of 1.2b record-full. Nothing later rewrites a shipped model. Rejected: building in spec order. Sync arrives last and rewrites fifteen shipped changes.

### iPhone layout in portrait only

The app has an iPhone layout in portrait. It runs on iPad in compatibility mode, because App Store Connect cannot withhold an iPhone-only app from iPad. No iPad layout or landscape in V1. `App/Midmorning.xcodeproj/project.pbxproj` sets `TARGETED_DEVICE_FAMILY = 1` and portrait as the only iPhone orientation on both configurations.

Rejected: an iPad layout and landscape. No spec requires them, and each adds a device check per screen. Cost to reverse: low. The settings change in one file, and each screen then needs a device check in the new size.

## Risks / Trade-offs

- [SwiftData with CloudKit and many entities] → every relationship optional with an inverse; V1 ships one schema version and store fixtures start at the first TestFlight schema; the `Reconciler` picks winners on read and never deletes.
- [The on-read winner rule costs a scan] → the store indexes versions by entry id and deletes only losing versions, after both 90-day tests pass.
- [Templates sound robotic] → the clinician writes the templates; the engine only fills numbers.
- [A person who purges is not screened out] → Ash's decision; screen 1 warns, a stage-2 card explains, and the proposal dates a revisit before beta.
- [Threshold rules as device function] → Rule A, and the weight reason at a restart re-screen, pause reminders; the rest suggest a GP; a written MHRA opinion is a release gate.
- [Simulator cannot verify protection classes, sync, zone deletion or Face ID] → each build task names its device checklist beside its pure-function tests. About 120 scenarios need a device and about 22 a second device; the agent lists each in the epic's device-check bead, and Ash does the check and adds a date and a screenshot to the change README (decision 68).
- [Separate packages each rebuild Record] → Ash decides the package layout; until then `Programme` takes value facts so it does not import `Record`.
- [A launch that fails] → a launch marker file; the third failed launch opens the store read-only with Export and Get support; a store that fails to open shows a page with "Try again" and "Delete everything".
