# Design

## Context

The repository is empty. This change builds the walking skeleton for the record. See proposal.md for why. The PRD fixes the platform: Swift, SwiftUI, iOS 17 and later, SwiftData with CloudKit private-database sync, offline-first, no accounts, no server. Later changes add the lock-screen widget, notification actions, App Intents and Control Centre. Those run in other processes and write entries. This change lays the file where they can reach it.

## Goals / Non-Goals

**Goals:**
- One path through the whole stack: SwiftUI screen, store, SwiftData container, file on disk.
- One test that runs on macOS with `swift test` in seconds and asserts real behaviour.
- A model and a file location that the widget, App Intents and CloudKit can use later without a migration.

**Non-Goals:**
- iCloud sync itself. It needs an entitlement and a signed build. The skeleton runs unsigned on the simulator.
- Any feature beyond the requirements in specs/record/spec.md.
- Any abstraction for future features.

## Decisions

### Logic in a pure SwiftPM package, UI in the Xcode project

`Packages/Record` has the library product `RecordCore`. It holds the model, the store and the row-label function. It targets macOS 14 and iOS 17. `swift test` runs it on macOS with no simulator. `App/Midmorning.xcodeproj` holds only SwiftUI views and the app entry point. Ash chose this on 24 September 2026 to mirror CoachWork. Rejected: a single Xcode project that tests through the simulator. Every test would boot a simulator, and a cold run risks the 240-second budget. Cost to reverse: low now, high once tests accumulate in the wrong place.

The package uses `swift-tools-version: 6.0`. `RecordStore` and the test are `@MainActor`, because `ModelContext` is not `Sendable`. If the `@Model` macro fails strict concurrency checks in Xcode 27, the package sets `swiftLanguageMode(.v5)` and the design records the date.

### SwiftData, written to CloudKit's constraints from day one

The `Entry` model uses SwiftData as the PRD says. Ash chose this on 24 September 2026. Rejected: Core Data with a programmatic model as in CoachWork. It departs from the PRD and costs more code. The constraints are the same for both. The model follows these rules:

- Every non-optional property has an inline default value in its declaration, not only in `init`.
- No `@Attribute(.unique)` and no `#Unique`. The app sets `id` to a UUID. CloudKit does not enforce it, so a later change must dedupe on `id`.
- No relationships in this change. A later relationship is optional and has an explicit inverse.
- Every attribute except `id` carries `@Attribute(.allowsCloudEncryption)`. CloudKit encrypts these fields end to end. CloudKit cannot add this to a field after the production schema deploys.
- `ModelConfiguration` sets `cloudKitDatabase: .none`. An entitlement change alone cannot start sync.

Cost to reverse: high once real people sync, because CloudKit's production schema only grows.

### The entry keeps six stored values

`Entry` stores six values. `id` is a UUID. `time` is the moment the person set, to the minute. `utcOffsetSeconds` is the device's offset when the person saved. `what` is text and can be empty. `feltLikeABinge` is a Bool with default false. `createdAt` is the moment the app saved, to the second. Today reads `time` and formats it at `utcOffsetSeconds`. Rejected: one time field. It loses the delay between the entry time and the creation moment, and the app cannot recover that data. Rejected: a time zone name. It records where the person was, and a UTC offset gives the same clock time. Cost to reverse: high, because the data is gone.

### The store is the only way to create an entry

`RecordStore.add(time:what:feltLikeABinge:createdAt:)` is the only public way to create an `Entry`. `Entry.init` is package-internal. `add` trims white space and line breaks from the start and end of What. `add` truncates `time` to the minute. `add` inserts and calls `save()` before it returns, and throws on failure. The error carries no entry data. Rejected: views that insert into `ModelContext` directly. The rules would live in two places. Rejected: autosave. It runs on the main run loop and does not guarantee a write before a kill. Cost to reverse: low.

The app passes `Date()` as `createdAt`. The test passes fixed values. Rejected: reading the clock inside `add`. The tie-break scenario could not be tested.

### The day query takes the moment and the calendar

`RecordStore.entries(recordDayContaining moment: Date, calendar: Calendar)` returns the entries whose `time` is in the record day that contains `moment`, sorted by `time` then `createdAt`. The app passes now and the current calendar. The test passes fixed values and a calendar with `timeZone` set to `Europe/London`. Rejected: reading the wall clock inside the store. The test would depend on the machine's date and time zone.

### The record day is an interval in the device's time zone

`RecordDay.interval(containing moment: Date, calendar: Calendar)` returns a half-open interval. The start is 04:00 on the calendar date of `moment`, or on the previous date when `moment` is before 04:00. The end is 04:00 on the next calendar date. Both come from `calendar.date(bySettingHour:minute:second:of:)`, so a clock-change date gives a 23-hour or 25-hour day. Rejected: `startOfDay` plus four hours. It gives 03:00 or 05:00 on a clock-change date. Rejected: the entry's own zone for assignment. An entry could move between days when the person travels. The stored offset is for display only. Cost to reverse: low while no stored value names a day. It rises when "didn't record" and "Pause for today" write a stored day.

### Today reads two record days

Today queries the current record day and the previous one. It shows the previous day's section only when that query returns at least one entry. After a save, Today scrolls to the saved entry's `id`. Rejected: day navigation. It is a feature. Rejected: hiding a previous-day entry. A saved entry that the person cannot see reads as a refusal.

### Today recomputes the day on activation and at 04:00

A parent view computes the two intervals and passes them to a child view whose `init` builds the `@Query`. The parent recomputes on `scenePhase == .active` and on a timer set for the next 04:00. Rejected: one `@Query` built at launch. Today would show yesterday all morning after an overnight background.

### Display and label functions live in the package

`Entry.clockTime` formats `time` at `utcOffsetSeconds` as hour and minute. `Entry.accessibilityLabel` returns the time, then the What when not empty, then "felt like a binge" when starred, separated by ", ". The test asserts both. Rejected: formatting in the views. The obvious SwiftUI call uses the device zone, and no test could reach it.

### The store file lives in an App Group container

The app creates `Library/Application Support` inside the container for `group.uk.midmorning`, then opens `Record.store` there. The widget, notification actions and App Intents run in other processes and can reach a file only in a shared container. Rejected: the app's own sandbox. Moving the file later is a migration of health data. Cost to reverse: high after the first TestFlight build. The bundle identifier `uk.midmorning.app` and the group name are placeholders. Ash sets the final names before the first signed build.

### File protection and backup exclusion, set on the directory

The app creates the store's directory with the attribute `NSFileProtectionComplete` and sets `isExcludedFromBackup` on it. SQLite's `-wal` and `-shm` files inherit both from the directory. `ModelConfiguration` has no option for either. Ash chose this on 24 September 2026. Rejected: the iOS default class, complete-until-first-unlock. After the first unlock the key stays in memory until reboot. The change that adds the widget lowers the class to complete-until-first-unlock and adds the Face ID app lock, and records why. Rejected: default backup behaviour. iCloud Backup is not end-to-end encrypted without Advanced Data Protection, and a backup copy outlives Delete-all. The simulator does not enforce protection classes. A device build reads the attributes back.

### Erasure is file deletion

Delete-all, a later change, removes `Record.store`, `Record.store-wal` and `Record.store-shm` and creates an empty store. It does not delete rows, because SQLite keeps deleted rows in free pages. Nothing in this change writes any entry data outside those three files. When sync exists, Delete-all also deletes the CloudKit zone.

### Privacy in the app target

The new-entry screen returns `false` for the keyboard extension point, so third-party keyboards cannot read What. Today and the new-entry screen use `.privacySensitive()` and redact when `scenePhase` is not `.active`. The project holds a `PrivacyInfo.xcprivacy` that declares no tracking, no collected data types and the required-reason APIs the app uses. `ITSAppUsesNonExemptEncryption` is `NO`. No code path passes an entry field to `print`, `os_log` or an error.

### Xcode project written by hand with synchronized folders

The project file uses Xcode 16's synchronized root groups so it lists folders, not files. Adding a Swift file needs no project edit. `CODE_SIGN_ENTITLEMENTS` names `Midmorning.entitlements`, which holds the App Group. Rejected: XcodeGen or Tuist. Neither exists on this Mac and both add a tool to the loop.

## Risks / Trade-offs

- [SwiftData macro build on macOS in `swift test`] → the package declares macOS 14 as the platform; Xcode 27's toolchain supports it.
- [App Group on an unsigned simulator build] → the simulator returns a container URL with or without the entitlement. Task 2.2 checks the entitlement in the built app with `codesign` instead.
- [The simulator does not show the protection class or the backup flag] → a device build checks them. Until then, a reviewer reads the code path.
- [xcodebuild cold build time] → the skeleton app is small. The verify script runs `swift test` and `xcodebuild` at the same time, so a cold Xcode build does not use the whole budget alone.
- [No signing identity on this Mac] → all builds target the simulator; a device build waits for a team on the project.
- [Visual rules have no test] → a reviewer checks them on the simulator, as the spec says.
- [Focus in What on open] → SwiftUI sets focus after a short delay in `onAppear`. With a hardware keyboard connected, the simulator shows no keyboard.
