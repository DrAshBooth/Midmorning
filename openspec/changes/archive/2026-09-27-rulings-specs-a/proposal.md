# Proposal

## Why

Ash ruled on 24 open decisions on 26 September 2026, on the Midmorning Decisions page. This change writes the spec text for twelve of those rulings in five capabilities: `data-and-privacy`, `app-lock`, `record`, `export` and `weigh-in`. The ruling ids are r12-01, r13-03, r13-04, r13-05, r13-06, r13-07, r13-10, r13-13, r13-14, r13-16, r14-01 and r14-04. Each ruling is final. A second spec change writes the rulings for the other capabilities.

## What Changes

- r12-01: "Share App Analytics with Apple" opens the app's own page in the iOS Settings app, through `UIApplication.openSettingsURLString`.
- r13-13 (`mm-t41.25`): safe mode starts at the third launch, after two launches in a row end before the app clears the marker. It continues at each later launch until Today appears in safe mode. The requirement sentence now agrees with its scenario.
- r13-05 (`mm-t42.23`): the app chooses safe mode from the count in the launch marker before it opens the store. `Record.store` and `Local.store` open read-only in safe mode, and no schema migration writes to them. Delete-all and "Delete from this device" can still delete the store directory. Safe mode keeps its launch failure in the marker, and the next launch that can write adds it to `Local.store`. SwiftData cannot open a store read-only when it needs a migration. So in safe mode that store shows "Midmorning cannot open your record on this device.", and Export is not available.
- r14-01 (`mm-t41.26`): after a failed Delete-all, the cover, the settings screen and the store-failure page show "Could not delete. Try again." under their controls.
- r13-04 (`mm-t15.19`): Save on the new-entry screen that the notification action "Add" opened while the app is locked asks for authentication first. On cancel or failure, the app saves nothing and keeps the text.
- r13-06 (`mm-t15.20`): "Turn on" for "Face ID only" or "Touch ID only" saves the current enrolment state hash. That save is not a reset.
- r13-16 (`mm-t12b.22`): an entry keeps the UTC offset for its own time, not for the save moment, on add and on edit. The edit screen uses the entry's edit zone: the device's current time zone when that zone gives the entry's kept offset, and otherwise a fixed zone at that offset. So an edit after travel keeps the entry in its own record day, as Ash ruled on 25 September 2026.
- r13-07 (`mm-t12b.21`): the six-words rule does not apply to the slot labels, the next-planned-meal line and the missed planned meal prompt. The stale "visible strings of this change" sentence goes.
- r13-14 (`mm-t42.27`): the export share sheet does not offer Copy.
- r14-04 (`mm-t42.26`): a day's entries are one tagged list on each page that holds them. The repeated heading on a continuation page has no tag.
- r13-10 (`mm-t22.26`): "Choose a weigh-in day" keeps the onboarding sentence. "No explanation" means the one-line explanation under the chart.
- r13-03 (`mm-t12.34`): no spec change. `data-and-privacy` "Rows reference each other by key" already says that an edit of a row other than an entry MUST write into the winning row.

Each changed requirement that has a copy in `openspec/changes/v1-programme/specs` gets the same change there.

For r12-01, the Privacy group list in `openspec/changes/v1-programme/specs/settings/spec.md` gets the same words. That requirement is only in `v1-programme`, so this change holds no `settings` delta.

## Open decisions

Three parts of this change wait for Ash. Each one is a card in round 15 on the Midmorning Decisions page. Until Ash rules, the text stays as this change writes it.

- `mm-t42.28` (card r15-01): what safe mode does when the store needs a schema migration, and how the person leaves that state. This change does not say that Export works in that case.
- `mm-t12b.26` and `mm-t12b.25` (card r15-02): the edit zone after travel in record "Edit an entry". This change writes the recommended option.
- `mm-t15.21` (card r15-03): whether "Turn on" for "Face ID only" asks for authentication before the hash save. This change saves the hash at the "Turn on" tap and says nothing about a request.

Branch `rulings-record-store` also changes record "Edit an entry" in `v1-programme`, and its change `rulings-record-edit-bounds` modifies the same requirement. At the merge, the lead takes the text of this change. Before the archive, the lead removes `rulings-record-edit-bounds` or makes its text the same as this change. The scenario "Edit on the day of a clock change" tests the same case as "Edit across a clock change".

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `data-and-privacy`: "Delete-all", "Launch safety", "The app holds no analytics of its own".
- `app-lock`: "The cover", "Delete everything from the cover", "Face ID only or Touch ID only", "A new entry before authentication".
- `record`: "The app keeps the entry's UTC offset and creation moment", "Edit an entry", "Today's appearance".
- `export`: "Share sheet only", "Accessibility of the export".
- `weigh-in`: "The weigh-in day".

## Impact

- Spec text only. Code agents build the code rulings on their own branches: r13-13, r13-05, r14-01, r13-04, r13-06, r13-16, r13-14 and r13-03.
- r13-07, r13-10 and r14-04 need no code change. This change closes `mm-t12b.21`, `mm-t22.26` and `mm-t42.26`.
- `mm-t25.15` now covers only the widget, App Intent and Control Centre routes of "A new entry before authentication".
