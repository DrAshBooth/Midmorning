# Proposal

## Why

Every later change needs one shared data shape. This change builds that shape once. It gives the app sixteen neutral models, entries as append-only versions, a per-row change moment, the frozen-schema file, `ProgrammeConstants`, and the Reconciler. Task 1.2a in `openspec/changes/v1-programme/tasks.md` names this change.

## What Changes

- The app renames the `RecordCore` package target to `Record` and adds a `Constants` leaf target that `Record` imports.
- `Record` gains sixteen `@Model` classes with neutral CKRecord names: `Item`, `ItemVersion`, `DayState`, `Template`, `Day`, `Answer`, `Measure`, `Session`, `ListItem`, `Sheet`, `Review`, `Profile`, `Settings`, `Seen`, `Place`, `Device`. `Entry` is a readable typealias of `Item`; `EntryVersion` is a readable typealias of `ItemVersion`.
- The entry becomes two rows: `Item` holds the entry's identity; `ItemVersion` holds one append-only row per save, edit or delete. `EntryWinner.pick` reads the winner on read; the store never edits or deletes a version before the retention rule.
- Every model carries `.allowsCloudEncryption` on every attribute except its own id, an inline default, and no SwiftData relationship. A key field, never a relationship, links one row to another.
- `RecordStore` opens two SwiftData configurations in one directory: `Record.store` for synced rows, `Local.store` for the device-only `LocalSetting` rows the "What syncs and what stays on the device" table names.
- `Reconciler` picks one winner per natural key on read and never deletes a row: `EntryWinner`, `DayStateReconciler`, `TemplateReconciler`, `DayReconciler`, `AnswerReconciler`, `StageOpenedReconciler`, `MeasureReconciler`, `ListItemReconciler`, `SheetReconciler`, `ReviewReconciler`, `DeviceReconciler`, `ProfileReconciler`, `SettingsReconciler` and `SessionOpenPicker`.
- A frozen-schema file, `Packages/Sources/Record/FrozenSchema.json`, freezes every CKRecord type name and field name. A `Record`-target test checks the live schema against it.
- `Constants` gains `ProgrammeConstants`, a value type with a `.default` holding every named threshold from the programme spec. `DEFAULT_DAY_START_HOUR` stays 4 in every version.
- The App target's `TodayView` and `NewEntryView` read a new `RecordRow` read-model in place of the old single-version `Entry` model, so the built app keeps showing the record it already shows, now backed by versions.

Not in this change: the Where and Context fields, edit, delete, earlier days, collapse and gap bands (1.2b, `record-full`); the plan builder, templates and the missed-meal prompt (2.3); the stage engine itself (2.1); sync, CKSyncEngine and the two-device device checks (4.1b); the widget snapshot and the action queue (2.5, 4.1); schema migration beyond V1's own fixture.

## Capabilities

### New Capabilities
None. `data-and-privacy` and `programme` already exist as delta specs under `openspec/changes/v1-programme/specs`; this change's own delta adds each requirement's first-built scenarios to `openspec/specs`.

### Modified Capabilities
None yet in `openspec/specs`: `data-and-privacy` and `programme` hold no requirement there before this change archives.

## Impact

- `Packages/Package.swift`: renames the `RecordCore` target and product to `Record`; adds the `Constants` target and product; adds the `ConstantsTests` test target; `Record` depends on `Constants`.
- `Packages/Sources/Record/Models/*.swift`: sixteen new `@Model` classes and `LocalSetting`.
- `Packages/Sources/Record/RecordSchema.swift`, `FrozenSchema.swift`, `FrozenSchema.json`, `Reconciler.swift`, `RecordStore.swift`: the schema, the freeze check, the Reconciler and the two-configuration store.
- `Packages/Sources/Constants/ProgrammeConstants.swift`: the constants value.
- `App/Midmorning.xcodeproj`: the package product reference renames from `RecordCore` to `Record`.
- `App/Midmorning/MidmorningApp.swift`, `TodayView.swift`, `NewEntryView.swift`: read `RecordRow` and call `RecordStore(directory:)`.

## Decisions this change makes

- `ItemVersion` carries the fields the walking skeleton's `Entry` already had (`time`, `utcOffsetSeconds`, `what`, `feltLikeABinge`, `createdAt`), plus `entryId`, `changedAt` and `deleted`. It does not yet carry Where or Context: the spec requirement text names "the fields" generically, `record-full` (1.2b) owns building Where and Context, and the frozen-schema rule lets a later change add them as an optional field with a default without a second schema version.
- Programme's stage-opened rows have no seventeenth model of their own. They are `Answer` rows of kind `"stageOpened"`, keyed by the stage number in `cardId`, with the earliest-moment winner rule the Reconciler requirement states for them. `StageOpenedReconciler` carries this rule; `programme-engine` (2.1) writes the rows.
- `RecordRow` (App-facing, not one of the sixteen names) is the winning-version read model `TodayView` and `NewEntryView` use. `Entry` stays the typealias of `Item` the spec names; the two are different types for a different purpose, one a stored identity row, one a computed read view.
