# Proposal

## Why

The record is the core of Midmorning. Every other feature reads from it. This change builds the smallest path through the whole stack. The person creates one entry, the app saves it on the device, and Today shows it. It proves the stack works before the team adds any feature.

## What Changes

- The person can create an entry with a time, a What text, and a "felt like a binge" star.
- The time defaults to the moment the new-entry screen opens. The person can set any time from the start of the previous record day to the save moment.
- A record day runs from 04:00 to 03:59 the next calendar day. The app assigns an entry between 00:00 and 03:59 to the record day that started the day before.
- What can be empty. A time and a star is a complete entry.
- Save is quiet. The screen closes, Today shows the entry on screen, and the app adds no confirmation.
- The app saves the entry in a file that iOS can read only while the device is unlocked. The app excludes the file from backups. The entry survives a restart.
- The app keeps the entry's UTC offset and the creation moment. It never shows the creation moment.
- Today shows the current record day's entries in time order. When the previous record day has entries, Today shows them above under their date heading. A starred entry shows an asterisk and nothing else changes. Today shows no count, total, streak or empty-state message.
- Today hides entries when the app is not active. The new-entry screen blocks third-party keyboards. No entry field goes to a log, an error or an analytics event.
- Each row is one accessibility element. Text uses system text styles.

Not in this change: onboarding, screening, the regular eating plan, reminders, widgets, App Intents, the Where chips, the Context field, the Compensated field, edit, delete, "didn't record", entries before the previous record day, day navigation, iCloud sync, app lock, export, Get support, Delete-all, a privacy notice.

Get support, Delete-all, the Face ID app lock and a privacy notice are first-release safety and privacy requirements. Each needs its own change. The team must complete those changes before it gives any build to a person outside the team. The DPIA covers the co-design panel and TestFlight before the first external build.

## Capabilities

### New Capabilities
- `record`: the person creates entries and sees them on Today. Entries stay on the device.

### Modified Capabilities
None. This is the first spec in the repository.

## Impact

- New SwiftPM package `Packages/Record` with library product `RecordCore`: the model, the store and the one test.
- New Xcode project `App/Midmorning.xcodeproj` with the Today screen and the new-entry screen.
- No network. No accounts. No third-party dependency.

## Decisions Ash made on 24 September 2026

- The record day starts at 04:00 in the device's time zone. A later change can let the person move the boundary.
- The person can set a time back to the start of the previous record day. Today shows the previous day's entries when it has any.
- The app saves an entry with an empty What.
- The app excludes the store's files from backups. Until sync exists, a new phone starts with an empty record.
- Every attribute carries CloudKit's end-to-end encryption option now, because CloudKit cannot add it to a deployed field.
- The store's files use the protection class that iOS can read only while unlocked. The change that adds the widget lowers it and adds the app lock in the same change.
- The app stores a UTC offset, not a time zone name, so the record is not a location history.
- Between 00:00 and 03:59 the heading adds ", night". It is the only extra text on an empty Today.
