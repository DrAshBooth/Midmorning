# Design

## Context

This change builds task 1.2a from `openspec/changes/v1-programme/tasks.md`. `openspec/changes/v1-programme/design.md` states the full model shape; the sections "One umbrella package, five targets", "Two store configurations in one directory", "Entries are append-only versions", "Dates are keys, fixed at save", "Model names, singletons and the account binding" and "Pure seams the packages expose" govern this change. This file states only the decisions this change itself makes, where the parent design leaves a gap this change had to fill to compile a model.

## Decisions

### `ItemVersion` carries the skeleton's fields now; Where and Context wait for 1.2b

`ItemVersion` holds `entryId`, `changedAt`, `deleted`, `dayKey`, `time`, `utcOffsetSeconds`, `what`, `feltLikeABinge`, `createdAt`. It does not yet carry Where or Context. The data-and-privacy spec's "Entries are append-only versions" requirement text names "the entry id, `changedAt`, the deleted flag, the record day key and the fields" — a generic phrase, not an enumerated field list. `openspec/changes/v1-programme/design.md`'s decision table lists Where and Context inside its description of `ItemVersion`, but `record-full` (1.2b) is the build change task 1.2 names as the owner of "Where, Context, edit, delete". The frozen-schema rule ("a later change adds only an optional field with a default") lets 1.2b add both fields without a second schema version. Cost to reverse: low — adding a field never touches a shipped row.

### Stage-opened rows are `Answer` rows of kind "stageOpened"

The data-and-privacy spec's Reconciler requirement states a stage-opened row's natural key is the stage, with the earliest moment as the winner — the opposite rule from every other kind. `openspec/changes/v1-programme/design.md`'s sixteen-model table names no dedicated model for it. `Answer` already holds two small, keyed fact shapes (a planned-meal answer and a card answer); a third kind, keyed by the stage number in `cardId`, fits the same shape and keeps the schema at sixteen names. `StageOpenedReconciler.winner(stage:in:now:restartAt:)` carries the earliest-wins rule and the two ignore rules (future-dated, and stage 5 before a restart) `programme-engine` (2.1) reads by. Cost to reverse: low — `programme-engine` can instead ADD a seventeenth model later; nothing in this change depends on the choice beyond the Reconciler function's own signature.

### `RecordRow` is the App target's read model; `Entry` stays the spec's typealias

The data-and-privacy spec requires `Entry` to be `Item`'s typealias, and `Item` carries only an id — every content field lives on the winning `ItemVersion`. The App target's `TodayView` and `NewEntryView` need a value with a time, a What and a star, so `RecordStore.entries(dayKey:)` returns `RecordRow`, a plain struct built from `EntryWinner.pick`'s result. `RecordRow` is not one of the sixteen names and carries no CKRecord type of its own; it never persists. Cost to reverse: none — it is a read-only projection, not a stored shape.

### `Reconciler.latestWins` is one generic function most models share

`DayState`, `Template`, `Measure`, `ListItem`, `Sheet`, `Settings` and `Device` all state the same rule: the later `changedAt` wins its key, whole row. `Reconciler.latestWins(_:key:changedAt:)` carries that rule once; each model's own `...Reconciler` enum supplies its natural key. `EntryWinner` (the five-level tie-break) and `ReviewReconciler` (earliest freeze, not latest change) keep their own functions, because their rules differ from the shared one. Cost to reverse: low — a model whose rule changes moves to its own function without touching the others.

### Two `ModelConfiguration`s, one `ModelContainer`, opened through `RecordStore.init(directory:)`

`RecordStore` opens `Record.store` (the sixteen synced models) and `Local.store` (`LocalSetting` only) as two `ModelConfiguration`s passed to one `ModelContainer`. `RecordStore.init(url:)` stays as a thin wrapper over `init(directory:)`, for a call site that still names a single file. The App target's `StoreLocation.directory()` calls the package's own `StoreLayout.storeDirectory(applicationSupportDirectory:)`, so the path rule lives in one place. Cost to reverse: low — a caller can still pass either initializer.

## Risks / Trade-offs

- [The frozen-schema file is hand-authored, not generated] → `FrozenSchema.currentFields()` reads the live `Schema` through SwiftData's own introspection, so a genuine field rename fails the check even though the JSON file itself is a plain, readable list a reviewer can diff.
- [`LocalSetting` is one generic key-value row for every device-only value] → matches `Settings`' own shape for the synced side, and keeps `Local.store`'s schema at one type; a later change can still add a dedicated `@Model` for a device value that needs one.
- [The new schema carries no migration from the skeleton's `Entry` model] → a device that already holds a store the walking skeleton wrote loses every entry, silently, the moment this change's build installs over it; CoreData drops the removed `Entry` entity's persistent history with no error shown. Ash ruled on 25 September 2026 (decision 108) that the skeleton was always a throwaway proof of concept, so this stands as a documented break rather than a migration stage; a device that matters checks its skeleton-era entries by hand before this build installs.
