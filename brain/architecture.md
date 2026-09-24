# Architecture decisions and why

One page. Pulled on demand, not auto-loaded. `docs/prd.md` is authoritative
for the product. `openspec/` is authoritative for behaviour. This page holds
the why behind the choices that are expensive to reverse. Decided on
24 September 2026 unless a line says otherwise.

## Logic in pure SwiftPM packages, UI in the Xcode project
`Packages/Record` holds the model, the store and the pure functions. It
targets macOS 14 and iOS 17, so `swift test` runs on the Mac in seconds with
no simulator. `App/` holds SwiftUI views and the entry point only. The project
file is hand-written with synchronized folders, so a new Swift file needs no
project edit. Reversal cost grows with every test that lands in the wrong
place. `./verify` is the contract for done: package test, simulator build,
spec validation, under 240 seconds, both builds in parallel.

## SwiftData, shaped for CloudKit before sync exists
The PRD names SwiftData with CloudKit private-database sync. Sync is off
(`cloudKitDatabase: .none`) until there is a signed build, but the model obeys
CloudKit now: inline defaults on every property, no unique attributes, no
ordered relationships, app-set UUID identity, and `.allowsCloudEncryption` on
every attribute except `id`. That last one cannot be added to a field after
the production schema deploys, and CloudKit's schema only grows. Core Data as
in CoachWork was rejected: same constraints, more code, off the PRD.

## The store file, its protection and its erasure
The file lives in the App Group container `group.uk.midmorning`, because the
widget, notification actions and App Intents write entries from other
processes. Moving it later is a migration of health data. Its directory
carries `NSFileProtectionComplete` and backup exclusion, so the SQLite side
files inherit both. The change that adds the widget lowers the class to
complete-until-first-unlock and adds the Face ID lock in the same change.
Backup exclusion means a new phone starts empty until sync ships; that is the
price of "no server-side copy of the record". Delete-all removes the three
store files and recreates the store; it never deletes rows, because SQLite
keeps deleted rows in free pages.

## What an entry stores, and what it never shows
Six values: id, time to the minute, UTC offset, What, the star, creation
moment to the second. The creation moment is separate from the entry time and
is never shown; it exists for the record-latency metric. A UTC offset, not a
zone name, so the record is not a location history. Losing either field
later loses data with no way back.

## The record day starts at 04:00
A record day runs 04:00 to 03:59 in the device's current zone, computed with
"04:00 on this calendar date", so a clock-change day is 23 or 25 hours. Binges
cluster late evening; a calendar day would split an evening from its night.
The stored offset is for display only, never for day assignment, so an entry
cannot change day when the person travels. Cheap to move while no stored
value names a day; expensive once "didn't record" and "Pause for today" do.

## The store is the only path
`RecordStore.add` is the only way to create an entry; `Entry.init` is
package-internal. It trims What, truncates time to the minute, saves
synchronously and throws an error with no entry data. Views never touch
`ModelContext`, and Today reads through the store, not `@Query`. One place
for the rules means App Intents and the widget cannot bypass them.

## Privacy posture built into the skeleton
No server we run, no accounts, no third-party SDK, no analytics yet. No entry
field reaches a log, an error, a crash report or an analytics event. Today
redacts when the app is not active. Third-party keyboards are blocked. No
Spotlight, Siri donation or pasteboard. The privacy manifest declares no
tracking and no collected data. These are cheap now and hard to retrofit.

## Product rules that shape every record screen
Save is quiet: standard dismissal, no confirmation, no colour change. The
star is an asterisk in the time's own colour and weight. No counts, totals,
streaks, dividers or empty-state text. An empty What is a complete entry; a
time and a star is what a person can manage after a binge. Yesterday's
entries stay reachable and visible, so a late entry never vanishes. Visible
strings are "Today", "What", "felt like a binge", "Save", "Cancel".

## Words and specs
All specs follow ASD-STE100; the rules live in `openspec/config.yaml` so every
artifact inherits them. Defined terms: entry, What, Today, felt like a binge,
star, record day, creation moment, new-entry screen, the store. Never log,
meal, food, diary, intake, calories. No string names a condition, treatment,
therapy or outcome: that sentence is the MHRA line.

## Placeholders and gates
Bundle identifier `uk.midmorning.app`, App Group `group.uk.midmorning` and
team `42JQW6669W` are placeholders until the first signed build; after the
first TestFlight build they are fixed. No build reaches a person outside the
team before Get support, Delete-all, the Face ID lock, a privacy notice, the
DPIA and the clinical walk of the starred-entry path.
