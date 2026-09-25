# Architecture decisions and why

One page. The reader pulls it on demand; nothing auto-loads it. `docs/prd.md` is
authoritative for the product. `openspec/` is authoritative for behaviour. This
page holds the why behind the choices that are expensive to reverse. Ash decided
each one on 24 September 2026 unless a line says otherwise.

## Logic in pure SwiftPM packages, UI in the Xcode project
`Packages/Record` holds the model, the store and the pure functions. It targets
macOS 14 and iOS 17, so `swift test` runs on the Mac in seconds with no
simulator. `App/` holds SwiftUI views and the entry point only. The team writes
the project file by hand with synchronized folders, so a new Swift file needs no
project edit. Reversal cost grows with every test that the team puts in the
wrong place. `./verify` is the contract for done: package test, simulator build,
spec validation, under 240 seconds, both builds in parallel.

## SwiftData, shaped for CloudKit before sync exists
The PRD names SwiftData with CloudKit private-database sync. Sync is off
(`cloudKitDatabase: .none`) until there is a signed build, but the model obeys
CloudKit now. That means inline defaults on every property, no unique
attributes, no ordered relationships, app-set UUID identity, and
`.allowsCloudEncryption` on every attribute except `id`. CloudKit cannot add
that last one to a field after the production schema deploys, and its schema
only grows. Rejected: Core Data as in CoachWork. Same constraints, more code,
and it departs from the PRD.

## Entries are versions; the store picks the winner on read
Every save, edit and delete writes a new version row. Nothing mutates. The store
returns the version with the later change moment (tie: star on, then longer
What). A delete is a version. CloudKit's own merge is per field and applies
deletes unconditionally, so the rule cannot live there. Decided 25 September
2026; expensive to reverse, because every reader depends on the rule.

## Delete-all writes an erasure marker first; sync runs on CKSyncEngine
A second device recreates a deleted zone from its local store. So Delete-all
writes a marker to a separate zone, and every device checks that zone before it
syncs. Sync is off until the person chooses it at onboarding, because a preset
default is not consent for health data. Sync is not in the first TestFlight cut.
When the team builds it, it uses CKSyncEngine, because SwiftData's own mirroring
cannot batch once a day or wait while locked (25 September 2026).

## Nothing is hard-deleted; every row carries its own change moment
Two devices lose data under whole-row winners and cascading deletes. So every
synced row has `changedAt` and a `deleted` flag, and settings are one row per
key. References are keys that the reader resolves on read, and the Reconciler
only picks winners. Expensive to reverse: every reader depends on it.

## The store file, its protection and its erasure
The file lives in the app's own container. Only the app process opens it,
decided 25 September 2026; the App Group holds only the widget snapshot and the
action queue. Moving it later is a migration of health data. Its directory
carries `NSFileProtectionComplete` and backup exclusion, so the SQLite side
files inherit both. The store keeps that class.

Two small side files, the action queue and the widget snapshot, carry the
after-first-unlock class and hold times and states only. So a locked
notification action and a widget work without opening the store. Decided 25
September 2026. Backup exclusion means a new device starts empty until sync
exists; that follows from "no server-side copy of the record". Delete-all
deletes the three store files and recreates the store; it never deletes rows,
because SQLite keeps deleted rows in free pages.

## What an entry stores, and what it never shows
Six values: id, time to the minute, UTC offset, What, the star, creation moment
to the second. The creation moment is separate from the entry time, and the app
never shows it; it exists for the record-latency metric. A UTC offset, not a
zone name, so the record is not a location history. Losing either field later
loses data that nothing can recover.

## The record day is fixed at save
A record day runs from the day start (04:00 by default, a setting since 25
September 2026) to one minute before the next. The store writes an entry's day
key at save from its own time and offset, and never recomputes it. So travel
never changes an entry's day, and a day-start change touches only future days.
Binges cluster late evening; a calendar day would split an evening from its
night. Expensive to reverse: every date-keyed row depends on the key.

## The store is the only path
`RecordStore.add` is the only way to create an entry; `Entry.init` is
package-internal. It trims What, truncates time to the minute, saves
synchronously and throws an error with no entry data. Views never touch
`ModelContext`, and Today reads through the store, not `@Query`. One place for
the rules means App Intents and the widget cannot bypass them.

## Privacy posture built into the skeleton
No server we run, no accounts, no third-party SDK, no analytics of our own: the
team reads Apple's App Analytics only (25 September 2026). Sync sends one batch
a day so Apple never sees the eating timeline. The cover shows nothing and
offers no support until unlocked. Only one safeguarding rule stops the
programme; the rest suggest a GP, and a written MHRA opinion gates the first
external build.

No entry field reaches a log, an error, a crash report or an analytics event.
Today redacts when the app is not active. The app blocks third-party keyboards.
No Spotlight, Siri donation or pasteboard. The privacy manifest declares no
tracking and no collected data. These are cheap now and hard to retrofit.

## Product rules that shape every record screen
Save is quiet: standard dismissal, no confirmation, no colour change. The star
is an asterisk in the time's own colour and weight. No counts, totals, streaks,
dividers or empty-state text. An empty What is a complete entry; a time and a
star is what a person can manage after a binge. Yesterday's entries stay
reachable and visible, so a late entry never vanishes. Visible strings are
"Today", "What", "felt like a binge", "Save", "Cancel".

## Words and specs
All specs follow ASD-STE100; the rules live in `openspec/config.yaml` so every
artifact inherits them. Defined terms: entry, What, Today, felt like a binge,
star, record day, creation moment, new-entry screen, the store. Never log, meal,
food, diary, intake, calories. No string names a condition, treatment, therapy
or outcome: that sentence is the MHRA line.

## Placeholders and gates
Bundle identifier `uk.midmorning.app`, App Group `group.uk.midmorning` and team
`42JQW6669W` are placeholders until the first signed build; after the first
TestFlight build they are fixed. Six gates stand before the first build that
reaches a person outside the team. They are Get support, Delete-all, the Face ID
lock, a privacy notice, the DPIA and the clinical walk of the starred-entry
path.
