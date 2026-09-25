# Tasks

Every task's verify command is `swift test --package-path Packages`, folded into `./verify` before each child closes. Each task names its bead, its requirement heading and spec file, and maps each scenario the requirement lists to a test here or to a `deferred: <bead id>` pointer.

## 1. Package and schema

- [x] 1.1 mm-t12.1 — data-and-privacy, "CKRecord types and model names are neutral". Sixteen `@Model` classes with a `kind` field where several concepts share one name; `Entry = Item` and `EntryVersion = ItemVersion` typealiases. Scenarios: "Kind field", "Entity name test", "Typealias in the code" — `FrozenSchemaTests.swift`. `deferred: mm-t41b.11` — "Types in the private database".
- [x] 1.2 mm-t12.2 — data-and-privacy, "The schema is frozen and grows by addition only". `Packages/Sources/Record/FrozenSchema.json`, `FrozenSchema.swift`, `RecordSchemaV1`, `RecordMigrationPlan`. Scenarios: "Frozen names", "Field added", "One schema version in V1", "Every earlier version opens" — `FrozenSchemaTests.swift`. `deferred: mm-t25.15` — "Unknown format version".

## 2. Store layout

- [x] 2.1 mm-t12.3 — data-and-privacy, "The store lives in the app's own container". `StoreLayout.storeDirectory(applicationSupportDirectory:)`; `App/Midmorning/MidmorningApp.swift`'s `StoreLocation.directory()` calls it. Scenarios: "Store path", "App Group content" (the store's own half) — `StoreLayoutTests.swift`. `deferred: mm-t25.15` — "Extension entitlement", and the widget-snapshot half of "App Group content".
- [x] 2.2 mm-t12.4 — data-and-privacy, "Two store configurations in one directory". `RecordStore.init(directory:)` opens `Record.store` and `Local.store` as two `ModelConfiguration`s in one `ModelContainer`; `LocalSetting` holds the "Device" column. Scenarios: "Two files" — `RecordStoreTests.swift`; "App lock on one device only", "No UserDefaults" — `StoreLayoutTests.swift`.
- [x] 2.3 mm-t12.5 — data-and-privacy, "What syncs and what stays on the device". Confirms each named value's home: `Day`, `Settings` (synced) against `LocalSetting` (device-only). Scenarios: "Plan on two devices", "Reminder switch", "Reminder time", "Paused reminders" — `StoreLayoutTests.swift`.

## 3. Row mechanics

- [x] 3.1 mm-t12.6 — data-and-privacy, "Every synced row carries its own change moment". `deleted` on `ListItem` and `Sheet`; no CKRecord system date read anywhere in the schema. Scenarios: "Delete a list item", "Delete a ladder step", "System dates unread" — `EntryVersionTests.swift`.
- [x] 3.2 mm-t12.7 — data-and-privacy, "Rows reference each other by key". Every reference is a key field (`entryId`, `cardId`, and so on); no `@Relationship` on any of the sixteen models or `LocalSetting`. Scenarios: "Entry on a note", "Edit after a conflict", "No relationships" — `RelationshipTests.swift`.
- [x] 3.3 mm-t12.8 — data-and-privacy, "Entries are append-only versions". `EntryWinner.pick`'s five-level tie-break; `Reconciler.canDeleteLosingRow` for the 90-day retention test. Scenarios: "Two devices offline", "Same entry edited on both devices", "Edit then delete", "Delete then edit", "Tie on moment, star and length", "Versions pruned", "Clock ahead of sync", "Deleted entry kept reduced" — `EntryVersionTests.swift`.
- [x] 3.4 mm-t12.9 — data-and-privacy, "Date-keyed rows keep the key written at creation". `dayKey` on `ItemVersion`, `dateKey` on `Day`, written once and never recomputed. Scenarios: "Entry across a zone change", "Row received by sync" — `EntryVersionTests.swift`.

## 4. Conflict rules

- [x] 4.1 mm-t12.10 — data-and-privacy, "Conflict rules for the plan, weigh-ins and lists". `DayReconciler` (sticky `setAt`/`setBy`), `AnswerReconciler`, `MeasureReconciler`, `ListItemReconciler`. Scenarios: "Planned day edited on both devices", "Skip on one device, plan edit on the other", "Two weigh-ins on the weigh-in day", "Alternatives list on two devices", "Day row after an import", "Set event", "Snooze count stays on the device", "Entry beats Skipped" — `ConflictRulesTests.swift`.
- [x] 4.2 mm-t12.11 — data-and-privacy, "Day states, sessions and reviews". `DayStateReconciler`, `SessionOpenPicker`, `ReviewReconciler`. Scenarios: "Two day states", "Collapsed day", "Two open urges", "Reviews keyed by due day", "Freeze waits for sync", "Two frozen rows" — `DayStateSessionReviewTests.swift`.
- [x] 4.3 mm-t12.12 — data-and-privacy, "Slot labels and the day start are Settings rows". `Settings.slotLabelKey(_:)`, `DayStartSetting.key(effectiveFromDayKey:)`. Scenarios: "Slot rename", "Day start on two devices" — `SettingsRowsTests.swift`.
- [x] 4.4 mm-t12.13 — data-and-privacy, "The Reconciler never deletes a row". `StageOpenedReconciler`, `Reconciler.canDeleteLosingRow`. Scenarios: "Future-dated review", "Restart keeps the stage 5 row", "Two stage-opened rows", "Losing planned day kept", "Clock moved forward" — `ReconcilerNeverDeletesTests.swift`.
- [x] 4.5 mm-t12.14 — data-and-privacy, "Card answers live in the record". `Answer` of kind "card", keyed by `cardId`. Scenario "Card answered on one device" — `CardAnswerTests.swift`. Scenario "Suggestion on two devices" is built here over fixture `Answer` rows, with no live dependency on `pattern-suggestions`; `mm-t41b.13` (a wiring bead) runs it end to end once that capability exists — `CardAnswerTests.swift`. `deferred: mm-t41b.11` — "During the first import".

## 5. Constants

- [x] 5.1 mm-t21.18 — programme, "The constants live in one value". `Constants` target, `ProgrammeConstants` with `.default`. Scenarios: "The values", "The lock grace set", "A threshold test", "The default day start never changes", "A capability reads the day start from the setting" — `ProgrammeConstantsTests.swift`. `deferred: mm-t31.17` — "A capability reads a constant".

## 6. App target and package wiring

- [x] 6.1 `Packages/Package.swift` renames `RecordCore` to `Record`, adds `Constants`, `ConstantsTests` and `Record`'s dependency on `Constants` (tasks.md 4.5 in `v1-programme`: this task adds a target, so it also updates `Packages/Package.swift`; the `swift test` line in `./verify` does not change). Verify: `swift build --package-path Packages`.
- [x] 6.2 `App/Midmorning.xcodeproj`'s package product reference renames from `RecordCore` to `Record`. `MidmorningApp.swift`, `TodayView.swift`, `NewEntryView.swift` read `RecordRow` and call `RecordStore(directory:)`. Verify: `xcodebuild -project App/Midmorning.xcodeproj -scheme Midmorning -destination 'generic/platform=iOS Simulator' build`.
