# Design

## Context

`openspec/changes/v1-programme/design.md` already states the decision this
change builds against: "Export renders a tagged, flowing column at fixed
sizes." This document states the decisions this change adds on top of it.

## Decisions

### `Export` depends on `Record` and `Programme`, never UIKit

`ExportDocument` and `Paginator` must stay testable under `swift test` on
macOS, where UIKit does not exist; that is the one hard constraint. Nothing
stops the package depending on `Record` (for `RecordRow` and `DayStateKind`,
both plain value types, never a `@Model` class) or `Programme` (for
`WeighInWeight.display`, `weigh-in`'s own stone-and-pounds rounding rule, so
the export never carries a second copy of it). `ExportDocumentBuilder` and
`ExportWeighInPageBuilder` are the two pure functions that turn the store's
rows into a document; `ExportPDFRenderer` (the app target) is the one place
UIKit and Core Graphics meet.

Rejected: a fully independent `Export` package that takes its own narrow
fact types (mirroring how `Programme` takes `RecordedDayFact` rather than
`Record` models). `Programme`'s reason for that shape is to stay usable from
`Plan` and `Record` without a cycle; `Export` sits at the far end of the
dependency graph (nothing depends on it), so the cycle risk does not apply,
and reusing `RecordRow` and `WeighInWeight` avoids two more duplicate types.

### Tagged PDF: the legacy `CGPDFContextBeginTag`/`EndTag` pair

`ExportPDFRenderer` opens `CGPDFContextBeginTag(context, tagType, properties)`
and closes with `CGPDFContextEndTag(context)` around each drawn region: `.header1`
for "Record", `.header2` per day heading, `.list` around a day's contiguous
run of entries, `.listItem` per entry with `kCGPDFTagProperty.actualText` set
to the one-pass reading order ("21:40 * Crisps and half a loaf Home Row with
my sister"). The renderer opens a fresh tag for a day that continues onto a
new page (a new `.header2`, a new `.list`), rather than one tag spanning
several pages — the "New Tagged PDF Authoring" API (`CGPDFStructureElement`)
that would let one element span pages needs iOS 27, and the app's minimum is
iOS 17.

Rejected: `ImageRenderer` over SwiftUI rows (the v1-programme design already
rejects this: "the output has no structure"). Rejected: waiting for the
newer structure-element API — it would drop the minimum iOS version, which
no other change in this cut needs to do.

### The language tag stays an unverified per-tag property

`CGPDFTagProperty.languageText` is the only hook `CGPDFContextBeginTag`
exposes for a tag's language; there is no separate document-catalog
language key in `CGPDFContext`'s own auxiliary-info dictionary. This change
sets it on every structural tag it opens. Whether the system's PDF writer
promotes that into the document's `/Lang` catalog entry a screen reader
reads is unverified in this worktree — the export spec's own "The document
language after the spike" scenario names exactly this uncertainty. The
epic's device-check bead lists reading a built PDF's language property as
the spike.

### Safe mode is a fourth root phase, not a flag on the running one

`AppLockRootView.Phase` gains `safeMode(RecordStore)`, alongside
`waitingForProtectedData`, `running` and `failedToOpen`. `SafeModeView` is a
small, separate screen (one `List` row for Export, `.getSupport()`); it
never builds `RunningRootView`, so the reminder scheduler
(`ReminderCoordinator.recomputeAndApply`, the one call `RunningRootView`
makes on appear and on every foreground) is never reached. `Record
.LaunchSafety` (built by `local-delete-all` over fixture facts) already
returns `enterSafeMode`; this change is the first to read it.

Rejected: a `readOnly` flag threaded through `RecordStore`/`TodayView` that
still shows the ordinary Today. `RecordStore` has no write-blocking mode
today, and adding one is a much larger change than the spec asks for; a
screen that offers only two controls cannot write anything by construction,
which is the same observable guarantee with far less code.

## Risks / Trade-offs

- [The language tag may not reach the PDF's catalog] → listed as a device
  check; the tag is set regardless, so a future SDK that does promote it
  needs no code change here.
- [A day's list/heading tags re-open per page rather than spanning one
  logical element] → each page still reads correctly on its own (a screen
  reader entering mid-document sees a proper H2 and a proper list, not a
  continuation with no heading); the trade-off is one PDF structure element
  becoming two-or-more when a day spans pages, which no test or scenario in
  this change's spec distinguishes from a single spanning element.
- [`UNUserNotificationCenter.current()` crashes outside a real app bundle,
  confirmed empirically] → "Pending requests first" (`data-and-privacy`,
  built by `local-delete-all`) stays proven at the `LocalDeletion` +
  fake-side-effects level, with the real notification centre a device check;
  recorded in `bd memories` (`ununnotificationcenter-crashes-under-swift-test`)
  so a later change does not re-attempt the same live test.
