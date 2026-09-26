# programme-engine

2.1 from `openspec/changes/v1-programme/tasks.md`: the pure stage engine,
week counting, the Programme screen model, opening cards, the two stage 1
cards, the plan card and card answer rows. Also holds the restart re-screen
rule from `safeguarding`.

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode DerivedData, in this
worktree): 16 seconds. Warm `./verify`: 2 seconds. Both are well inside the
240-second budget.

## The rules checklist

Every item below is a dated yes for 26 September 2026, written by the agent
that built this change.

- mm-pr1, The never list — yes. No stage row, card or screen shows a tick,
  a cross, a colour-coded status, a percentage, a streak or a score
  (`StageRow`, `TodayCardSlotView`, `ProgrammeScreenView`); the "Now" marker
  is text, never a bar or a badge; meaning never depends on colour alone.
- mm-pr2, Tone of every string — yes. Every string this change adds names a
  fact or a control ("Regular eating, Now", "Comes in a later version",
  "Your plan isn't set yet. It takes about two minutes."); none praises,
  shames or cheers, and the opening sentences are the content bundle's own
  reviewed text, copied verbatim.
- mm-pr3, Vocabulary — yes. This change's own strings use "stage", "opens",
  "record day" and "plan"; none uses "unlock", "level", "streak" or
  "tracker". `StageEngine`'s doc comments use "opens"/"closes", never
  "unlocks".
- mm-pr4, Nothing looks like a nutrition app — yes. This change adds no
  `Image(systemName:)` at all, in any file it adds.
- mm-pr5, The product name and the plan slot — yes. This change adds no new
  slot label and renames nothing; it reads `Slot`/`SlotLabel` only through
  `regular-eating-plan`'s existing rows.
- mm-pr6, What a notification never shows — yes. This change schedules no
  notification; `reminders` (2.4) owns the stage 2 opening card's
  permission-denied line as a Today card, not a notification.
- mm-pr7, The person can put it down — yes. Every card this change adds has
  a one-tap "Close" that never returns; "Start week 1 again" always offers
  "Cancel"; no control frames staying on a stage as a broken commitment.
- mm-pr8, Accessibility everywhere — yes, with the on-device VoiceOver walk
  still to come (mm-t21.24). Every stage row is one accessibility element
  with the label order "Accessibility of the Programme screen" states
  (`StageRow.accessibilityLabel`, `AccessibilityOfTheProgrammeScreenTests`);
  every control this change adds uses a system text style and scales with
  Dynamic Type; the stage screen's title and "Tools" are VoiceOver headings.
- mm-pr9, Dates and times in strings — yes. This change adds no new clock
  time or date string; "Opened in week %lld" and every rule string are
  plain counts, and the restart choice reuses `Record`'s own
  `StartDayChoice` for "Today"/"Tomorrow".
- mm-pr10, Offline and private by default — yes. Every new `RecordStore`
  call (`stageOpenedRows`, `recordStageOpened`, `cardAnswer`,
  `setCardAnswer`, `answeredCardIds`, `restartAt`, `setRestartAt`,
  `recordedEntryFacts`, `plannedDayKeys`, `urgeOutcomeFacts`,
  `hasAnyTemplate`, `recordCardSeen`, `cardViews`) is a local SwiftData
  read or write; this change adds no network code.
- mm-pr11, No AI at runtime — yes. `StageEngine.state`, `StageRuleText` and
  `RestartRescreen.evaluate` are deterministic pure functions over fixed
  inputs and fixed templates; nothing here generates a sentence.
- mm-pr12, Appearance — yes. Every new screen uses `recordListStyle()` (or
  a plain `Form`/`ScrollView` matching onboarding's own screens) and adds
  no new glyph, font, colour or corner radius; every card in the card slot
  uses the same text style as an entry row.

### Get support on every screen

`ProgrammeScreenView`, `StageScreenView` and `CardScreenView` each carry
`.getSupport()` (`GetSupportModifier`, built by `onboarding-and-safeguarding`,
1.4). `RescreenView` carries it too, because safeguarding's "Get support on
every screen" names the restart re-screen as one of the three screens the
sheet exemption never covers. `RestartChoiceView`'s own start-day choice
step (Today/Tomorrow/Cancel) is a sheet that closes in one tap to the
Programme screen, which already has the control — the spec's own exemption,
the same pattern the new-entry sheet uses. The excluded outcome reuses
`NotRightNowPageView` (1.4), which already carries its own Get support.

## Constant changes

No `ProgrammeConstants` value changed during this build (programme spec, "A
gate change never closes a stage"). `mm-t36.16` owns the clock-guard
scenarios for when one does.

## Scope notes

- `weigh-in` (2.2) is not built. The stage 1 "Weigh-in" tool row shows the
  tool's name with no action; `mm-t22.3` connects it, as the stage screen
  requirement's own text expects.
- `urge-toolkit` (3.1), `problem-solving` (3.3), `weekly-review` /
  `taking-stock` (3.2/3.2b), `dieting-module` (3.4), `body-image-module`
  (3.5) and `staying-on-track` (3.6) are not built. This build's own tools
  are stages 1 and 2 only (decision 102); every row for stages 3 to 7 shows
  "Comes in a later version" and opens nothing. The engine still computes
  and stores every stage's `StageOpened` row on schedule, so no window is
  lost once each later tool ships. `tasks.md` lists each scenario those
  epics own as `deferred: <bead id>`.
- `weekly-review`'s taking-stock completion is a fixture fact
  (`ProgrammeFacts.takingStockCompletedAt`, always `nil` in this build);
  `mm-t32b.7` wires the real completion moment in.
- The restart re-screen (`RescreenView`) reuses `OnboardingAnswers` for its
  typed fields and unit conversion, minus the age field; it does not reuse
  Screen2View's own private `SamaritansInlineRow`/`BeatContactsView`, so its
  self-harm support line shows a compact inline Samaritans row built from
  the same public `SupportSheet`/`CommonLabels` constants rather than the
  richer card those private views draw. Get support still reaches every
  helpline from any screen.
- `Card.Section`'s stage list (`content`, "The card screen and the card
  list") ships a real, wired card list and card screen from this change
  (`StageScreenView`, `CardScreenView`) — `content-pipeline`'s own
  `CardScreen.swift` named this bead as its wiring point.
- The engine's `Programme.state`/`.pendingCards`/`.week` are named
  `StageEngine.state`/`.pendingCards`/`.week`: naming the type `Programme`
  inside the `Programme` module collided with the module's own name and
  broke every existing `Programme.<Type>` qualified reference elsewhere in
  the app target (caught by `xcodebuild`, not `swift test`); see
  `proposal.md`, "Decisions this change makes".
