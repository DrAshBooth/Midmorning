# Proposal

## Why

Task 2.1 in `openspec/changes/v1-programme/tasks.md` names this change. The
programme engine decides which stage is open, which tools it unlocks, the
week number and the pending opening cards. Every later capability reads its
gate from this one place.

## What Changes

- A new `Programme/Engine` folder in the existing `Programme` package target
  holds the pure stage engine: `ProgrammeConstants`-driven gates for stages 2
  to 7, week counting from the start day and from the record day stage 2
  opened, the rule-string builder, and the pending-card picker that feeds
  `Record`'s `TodayCardSlot`.
- `RecordStore` gains read and write calls for `StageOpened` rows (kept as
  `Answer` rows of kind `stageOpened`, per `model-foundation`'s
  `StageOpenedReconciler`) and for a card-answer row of kind `card`.
- The Programme screen (`App/Midmorning/ProgrammeScreenView.swift`) lists the
  seven stages with the "Now" marker and each closed stage's rule string, and
  pushes a stage screen with the stage's cards and open tools.
- Today gains the "Getting started" line, the stage 1 cards, the opening
  card and the plan card in the card slot, and "Programme" in the bottom
  toolbar now pushes the real screen.
- "Start week 1 again" opens the start-day choice, after safeguarding's
  restart re-screen when more than 84 record days have passed since the
  last screening.

## Capabilities

### Added Capabilities

- `programme`: the stage engine, week counting, the Programme screen, the
  stage screen, the opening card, the two stage 1 cards, the plan card and
  the restart control.

### Modified Capabilities

- `safeguarding`: adds the restart re-screen ("Re-screening at a restart"),
  reusing onboarding-and-safeguarding's screening rules and pages.
- `content`: adds "The store keeps which content version the person saw".

## Impact

- `Packages/Package.swift`: no new target; `Programme`'s existing target and
  test target gain files under `Programme/Engine/` and
  `Tests/ProgrammeTests/Engine/`.
- `Packages/Sources/Record/RecordStore.swift`: a "Programme" section
  (`stageOpenedMoment`/`recordStageOpened`, `cardAnswer`/`setCardAnswer`,
  `seenCard`/`recordCardSeen`, `restartMoment`/`setRestartMoment`).
- `App/Midmorning/ProgrammeScreenView.swift`, `StageScreenView.swift`,
  `RestartChoiceView.swift`, `RescreenView.swift` (new); `TodayView.swift`
  (changed, additively, per the record spec's card-slot and toolbar seams).
- `App/Midmorning/Localizable.xcstrings`: the plain interface-chrome keys
  this change adds ("Programme", "Now", "Tools", "Start week 1 again",
  "Today", "Tomorrow", "Cancel", card control labels).

## Decisions this change makes

- `Programme.state(...)` takes an explicit `calendar: Calendar` parameter
  beside the inputs the spec's "A pure stage engine" requirement lists, the
  same seam `RecordDay` and `Materialiser` already use for every function
  that turns a moment into a record-day key or back; the requirement's input
  list names the domain facts, not this plumbing parameter.
- A record-day key sorts lexically as chronologically (`"2026-09-24" <
  "2026-10-01"`), so the engine compares and sorts day keys as plain
  strings and uses `Calendar` only to add days to a key or find a key's
  day-start moment (`DayKeyMath.swift`), the same shape `StartDayChoice`
  already uses in `Record`.
- The engine takes value facts (`EntryFact`, `PlannedDayFact`,
  `UrgeOutcomeFact`), never a `RecordRow` or a `Day`, so `Programme` compiles
  without `Record` or `Plan` (`v1-programme/design.md`, "Pure seams the
  packages expose"). The App target gathers these facts from `RecordStore`
  and `Plan` and passes them in; `mm-t21.23` is the wiring bead for every
  scenario that needs the live store.
- `Programme`'s pending-card output (`PendingCard`) is its own value type,
  not `Record`'s `TodayCardFact`, because `Programme` cannot import
  `Record`. The App target maps one to the other one for one.
