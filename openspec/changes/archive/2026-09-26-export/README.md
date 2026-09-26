# export

4.2 from `openspec/changes/v1-programme/tasks.md`: the tagged, flowing PDF at fixed sizes, the range, "Include context", the optional weigh-in page, the provenance line, the shared-copies line, empty Creator and Producer, and the share sheet.

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode `DerivedData`, in this worktree): 18 seconds. Warm `./verify`: 3 seconds. Both are well inside the 240-second budget.

## Scope: the whole export capability, in one worktree

`export` did not exist as a spec, a package or a screen before this change. Every requirement in `openspec/changes/v1-programme/specs/export/spec.md` is built here; the delta ADDs the whole capability. `weigh-in` gains one new requirement, "The weigh-in page in an export" (`mm-t22.13`, moved under this epic because its own text names `export` as the owner). Every other capability this change touches (`safeguarding`'s GP suggestion and not-right-now pages, `settings`' Weigh-in group, `data-and-privacy`'s Launch safety) already carries full requirement text on `openspec/specs`; this change writes code and tests against that text, with no spec delta of its own for any of them.

## `Export` depends on `Record` and `Programme`

`ExportDocument` and `Paginator` must import no UIKit, so they stay testable under `swift test` on macOS, where UIKit does not exist. Nothing else about the "no UIKit" rule stops the package depending on other pure packages: `Export` depends on `Record` (for the already-neutral `RecordRow`/`DayStateKind` read types, never a `@Model` class) and `Programme` (for `WeighInWeight.display`, so the export's weigh-in page never carries a second copy of the stone-and-pounds rounding rule). See `design.md` for the decision and the rejected alternative.

## The language tag is an unverified spike

The export spec's own "Accessibility of the export" requirement names this directly: "The team MUST test that during the export change before it commits to the tag." `ExportPDFRenderer` sets `CGPDFTagProperty.languageText` ("en-GB") on every structural tag it opens — the only hook `CGPDFContext` gives for this, since there is no separate document-catalog language key. Whether the system's PDF writer promotes that into a screen reader's own language read is unverified in this worktree; the device-check bead lists reading a built PDF's language property as the spike this change's own spec requires before commitment.

## Safe mode: a fourth root phase, not a flag

`AppLockRootView` gains a `safeMode(RecordStore)` phase alongside `waitingForProtectedData`, `running` and `failedToOpen`. `Record.LaunchSafety` (built by `local-delete-all`, over fixture facts) already computed `enterSafeMode`; this change is the first to read it and route to `SafeModeView` — a minimal Today with only Export and Get support, never `RunningRootView`, so the reminder scheduler is never called on this path.

## Delete-all, proven end to end where it was only structural before

Four scenarios earlier epics proved only by argument ("a fresh store is exactly the post-delete state") now run `Record.LocalEraser`, the real deletion engine, over a real directory: the plan's data, the programme's stage state, onboarding's completion flag, and (over a real `AppLockController`) the app lock's "Delete everything after an enrolment change". `weigh-in`'s own Delete-all scenario was already end to end before this change. `UNUserNotificationCenter.current()` was confirmed, empirically, to crash outside a real app bundle — "Pending requests first" (`data-and-privacy`, Delete-all and Delete from this device) and the Diagnostics page stay device checks; `design.md` and `bd memories` (`ununnotificationcenter-crashes-under-swift-test`) record this so a later change does not re-attempt the same live test.

## Get support on every screen

This change adds two full screens: the export screen (`ExportScreenView`) and safe mode's own Today (`SafeModeView`). Each shows Get support (`.getSupport()`); the export screen also carries it into every place it is reached from a sheet-presented page (the GP suggestion page, the not-right-now page), which already had their own Get support control before this change.

## The rules checklist

Every item below is a dated yes for 26 September 2026, written by the agent that built this change.

- mm-pr1, The never list — yes. The export spec explicitly forbids a count, a total, a streak or a score in the PDF ("What the PDF never contains"); the export screen itself shows only a range, two switches and one control, no number about the record's content.
- mm-pr2, Tone of every string — yes. Every string this change adds is quoted directly from the export spec ("The PDF could not be made. Try again.", the share-disclosure line); none states praise, blame or urgency.
- mm-pr3, Vocabulary — yes. Every string uses "record" and "export" as the PRD's own nouns; none uses "log", "tracker", "user" or another banned word.
- mm-pr4, Nothing looks like a nutrition app — yes. The export screen is a plain `Form` with system `DatePicker`/`Toggle`/`Button` controls; the PDF is one plain black text style, no colour, no fill, no icon.
- mm-pr5, The product name and the plan slot — yes. The export spec itself forbids the product name or the person's name in the PDF or its file name ("What the PDF never contains"); `ExportFileNameTests.testFileNameHasNoProductNameOrPersonName` checks it.
- mm-pr6, What a notification never shows — yes. This change schedules no notification.
- mm-pr7, The person can put it down — yes. "Make PDF" and cancelling the share sheet are both always available with no forced path; a cancel returns to the export screen with no message.
- mm-pr8, Accessibility everywhere — yes. Both `DatePicker`s carry an explicit `accessibilityLabel`; every other control's visible text is already its accessible name; the PDF is a tagged PDF with H1/H2/list structure and selectable text, not an image.
- mm-pr9, Dates and times in strings — yes. Every date in the screen and the PDF comes from the en_GB formatter (`ExportDayKey`); every clock time is 24-hour (`RecordRow.clockTime`, reused unchanged).
- mm-pr10, Offline and private by default — yes. The PDF is built entirely on the device; the export path makes no network call; the temporary file carries complete file protection and is deleted when the share sheet closes.
- mm-pr11, No AI at runtime — yes. This change computes no generated sentence; every string is a bundled, literal constant.
- mm-pr12, Appearance — yes. The screen uses plain system list/form styling and system button styles; no new SF Symbol; the PDF adds no icon or custom colour.

## Device checks

Listed on the epic's device-check bead (`mm-t42.14`); Ash performs each on a built app and adds its date and screenshot here.

- "Screen reader on the PDF" and "The document language after the spike" (export spec, "Accessibility of the export"): open a built export PDF with VoiceOver and with a PDF reader's document-properties panel; VoiceOver reads "Record" as a heading, then each day heading as a level-2 heading, then that day's entries as one list; the language property reads en-GB if the renderer wrote it.
- "Voice Control" and "Largest text size" (export spec, "Accessibility of the export"): with Voice Control on, "Show names" labels every control on the export screen and "Tap Make PDF" builds the PDF; at the largest accessibility text size, the screen shows every control and label without truncation.
- Opens the export screen, once from each of three places (safeguarding spec, "The GP suggestion page", "The not-right-now page"; data-and-privacy spec, "Launch safety"): the GP suggestion page's export control, the not-right-now page's export control, and safe mode's own Today.
- "Pending requests first", twice (data-and-privacy spec, "Delete-all", "Delete from this device"): with six real pending reminders, confirm each deletion; the app cancels all six before the store directory goes, and none fires afterwards.
- "Diagnostics" (settings spec, "The About group"): open "Diagnostics" from the About group; it shows the eight counts and no entry, weight or plan.
