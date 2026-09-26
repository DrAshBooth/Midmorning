## 1. record

- [x] 1.1 Compute the edit screen's record day bounds from the device's time zone rules for an entry from the device's own time zone, in "Edit an entry" (r13-16, mm-t12b.22). Prove it with `openspec validate rulings-record-edit-bounds --type change --strict`.
- [x] 1.2 Test the 25-hour record day and an edit across the clock change. Prove it with `EntryOffsetTests.testTheEditZoneOfADeviceZoneEntryIsTheDeviceZone` and `EntryOffsetTests.testAnEditAcrossTheAutumnChangeTakesTheOffsetAtTheEditedTime` in `swift test --package-path Packages`.
- [x] 1.3 Apply the same change to the copy of "Edit an entry" in `openspec/changes/v1-programme/specs/record/spec.md`. Prove it with `openspec validate --all --strict`.
