# local-delete-all

4.1 from `openspec/changes/v1-programme/tasks.md`: the real local deletion
behind the two delete-all stubs, launch safety, file protection, the
keyboard block, backup exclusion, the privacy manifest and the Diagnostics
page.

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode `DerivedData`, in this
worktree): 12 seconds. Warm `./verify`: 2 seconds. Both are well inside the
240-second budget.

## Scope: local deletion now, the "Erasure" zone and the sync-on counts later

`4.1b` (`sync`) is not merged in this worktree; onboarding is not built yet
either, so this change works with what already exists. It replaces both
delete-all stubs (`Record.StubDeleteAllSeam`, `AppLock.RecordingDeleteAllSeam`)
with one real engine, `Record.LocalDeletion`, wrapped by
`App/Midmorning/AppLock/RealDeleteAllSeam.swift`. It does not write the
erasure marker or delete a sync zone — decision 45 in `mm-t41.1`'s notes
names that the remainder bead under `4.1b`. Two Diagnostics counts (pending
reminders, queue length) stay at zero behind a named seam
(`Record.DiagnosticsSourceCounts`) until `2.4`'s wiring bead (`mm-t24.20`)
supplies the real values; "last successful sync day" reads "Never" until
`4.1b` writes to it. "Last reconcile outcome" is a real, live counter
(`RecordStore.recordReconcileOutcome`) that starts at zero because nothing in
the shipped first cut runs a reconcile pass yet — zero is the true count, not
a placeholder.

"Launch safety"'s safe mode (skip the Erasure read, the import, the
Reconciler and the scheduler; open the store read-only) has no code path to
gate yet: none of those four systems exists in this worktree. This change
builds the real launch-marker state machine and streak (`Record
.LaunchSafety`, kept in the marker file itself, never in `Local.store`, so
the decision needs no store to open first) and enters safe mode on the third
consecutive uncleared launch; `mm-t42.20` (the wiring bead) proves the full
skip-list once those systems exist.

"What never leaves the device"'s "Export" scenario names a control `4.2`
(`export`) has not built (0 of its 16 children close in this worktree); it
is `deferred: mm-t42.7` ("export: Share sheet only"), not built here, even
though `mm-t41.5`'s own acceptance text lists it under "Built here" — see
that bead's comments for the full note.

## A platform gap: "Share App Analytics with Apple"

The requirement's "Share App Analytics with Apple" scenario states the
control opens the iOS Settings app "at Privacy & Security, Analytics &
Improvements". Apple gives no public, App-Store-safe deep link to that exact
page — only `UIApplication.openSettingsURLString`, which opens the app's own
page in Settings, one tap short of Analytics & Improvements. `SettingsView`'s
new row uses that one public API, the same approximation every iOS app uses
for this kind of control. `mm-t41.4`'s comments flag this for Ash: whether
the requirement's eventual wording should name the app's own Settings page
instead of the specific sub-page. Not a blocker — no other API exists to
choose between.

## Get support on every screen

This change adds four full screens: the deleted screen (`DeletedScreen`),
the "waiting for protected data" screen (`WaitingForProtectedDataView`), the
store-open-failure page (`StoreOpenFailureView`) and the Diagnostics page
(`DiagnosticsView`). Each shows a "Get support" control — the placeholder
sheet needs no store, so it works even on the two screens that show before
or without one. `onboarding-and-safeguarding` (1.4) supplies the real sheet
without moving any of the four controls.

26 September 2026 (mm-t41.22): the "waiting for protected data" screen is
the cover, not a screen with Get support. It shows "Midmorning" only. The
app-lock spec, "The cover", states that the cover does not show Get
support. The safeguarding spec, "Get support on every screen", exempts the
cover and shows Get support only after authentication. The other three
screens keep their "Get support" control.

## The rules checklist

Every item below is a dated yes for 26 September 2026, written by the agent
that built this change.

- mm-pr1, The never list — yes. The Diagnostics page's eight counts are
  release and device metadata (launch failures, schema version, content
  version, the MetricKit crash count and so on), never a count, streak or
  score about the person's eating, the same basis the settings change's own
  "yes" for this rule gives the app version and content version counts.
- mm-pr2, Tone of every string — yes. "Midmorning cannot open your record on
  this device.", "Everything is deleted..." and "This device's copy is
  deleted..." each state a fact with no praise, blame or urgency; none
  reads as judgement to a person who has just binged.
- mm-pr3, Vocabulary — yes. Every string this change adds uses "record" only
  as a noun, never as a verb; none uses "log", "tracker", "user" or any
  other word the vocabulary rule bans.
- mm-pr4, Nothing looks like a nutrition app — yes. Every screen this change
  adds is plain text and system buttons; none adds an image, an icon or an
  SF Symbol.
- mm-pr5, The product name and the plan slot — yes. "Midmorning" appears
  only in plain in-app text (the existing cover title, and the new
  store-open-failure message), never beside a meal word and never in a
  notification.
- mm-pr6, What a notification never shows — yes. This change schedules no
  notification.
- mm-pr7, The person can put it down — yes. This change adds no new
  always-on feature; "Get support" and "Try again" each let the person move
  on with no forced path.
- mm-pr8, Accessibility everywhere — yes. Every control this change adds is
  a plain `Button`, `NavigationLink` or `LabeledContent` with a catalogue-key
  label, so its VoiceOver label already equals its visible label; the
  Diagnostics page's eight rows each carry `.accessibilityElement(children:
  .combine)`, matching the About group's existing compound rows. This
  change adds no accessibility bead of its own (none exists under `mm-t41`);
  the pattern it follows is the one `mm-t13.7` already proved for the
  settings screen.
- mm-pr9, Dates and times in strings — yes. This change formats no date; the
  one day-shaped value it can show today, "last successful sync day", reads
  the fixed word "Never" until `4.1b` writes a real day key to it.
- mm-pr10, Offline and private by default — yes. Every read and write this
  change adds is a local `RecordStore` call or a local file operation;
  "Share App Analytics with Apple" only switches to the iOS Settings app, on
  the device, with no data leaving it.
- mm-pr11, No AI at runtime — yes. This change computes no sentence; every
  string is a bundled or catalogued literal.
- mm-pr12, Appearance — yes. Every new screen uses the plain system list
  style, system button styles and the accent colour on its one prominent
  control, matching the cover's own established styling (`applock.cover
  .deleteEverything`'s quiet, secondary-coloured treatment for the most
  drastic option, reused for "Delete everything" on the store-open-failure
  page). No custom colour, corner radius, shadow or font.

## Device checks

Listed on the epic's device-check bead (`mm-t41.15`); Ash performs each on a
built app and adds its date and screenshot here.

- "Share App Analytics with Apple" (data-and-privacy spec, "The app holds no
  analytics of its own"): tap the row in the Privacy group; the iOS Settings
  app opens at the app's own page (see "A platform gap" above for why not
  Analytics & Improvements directly).
- "Container has no public data" (data-and-privacy spec, "The app holds no
  analytics of its own"): list the app's CloudKit container's public
  database record types in CloudKit Dashboard; it holds none the app writes.
- "No event", sync off (data-and-privacy spec, "The app holds no analytics
  of its own"): capture the device's network traffic for a full day of use;
  it holds no analytics event.
- "Third-party keyboard installed" and "Dictation" (data-and-privacy spec,
  "The app blocks third-party keyboards"): with a third-party keyboard set
  as default, tap into What; the system keyboard appears, dictation works.
- "Launch before the first unlock" (data-and-privacy spec, "File
  protection"): restart the device, let a reminder fire, tap its action
  before unlocking; the app shows the waiting screen, opens no container,
  does not crash.
- "New device with sync off" restore-adjacent checks, "Restore after
  Delete-all" and "Finder backup inspected" (data-and-privacy spec, "The app
  excludes the whole store directory from backups"): make a Finder backup
  after Delete-all and inspect the app's files in it; the backup holds no
  store file, snapshot, queue or entry text.
- "MetricKit diagnostic" (data-and-privacy spec, "No record content in the
  system log or crash reports"): induce a crash, relaunch, wait for
  MetricKit's next delivery; the Diagnostics page's crash count rises by one
  and no file holds the payload.
- "App Store label" and "Manifest" (data-and-privacy spec, "The privacy
  manifest and the App Store privacy label"): read `PrivacyInfo.xcprivacy`
  and the App Store Connect privacy section on a built app; the manifest
  lists 35F9.1 and C617.1 with an empty `NSPrivacyCollectedDataTypes`, and
  the label reads "Data Not Collected".
- "Diagnostics" (settings spec, "The About group"): open "Diagnostics" from
  the About group; it shows the eight counts and no entry, weight, plan or
  date of an entry.
- "A day of use", sync off (data-and-privacy spec, "What never leaves the
  device"): capture the device's network traffic for a full record day; it
  reaches iCloud hosts only (none, with sync off) and holds no readable
  entry field, weight value or free text.
