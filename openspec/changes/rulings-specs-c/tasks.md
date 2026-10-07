# Tasks

Each task changes one requirement and its copy in `openspec/changes/v1-programme/specs`, when a copy exists. The proof for each task is `openspec validate rulings-specs-c --type change --strict` and `openspec validate --all --strict`.

## 1. data-and-privacy

- [x] 1.1 Modify data-and-privacy "Launch safety" for r15-01: open the store at its own schema version with no migration plan. Run `openspec validate rulings-specs-c --type change --strict`.

## 2. app-lock

- [x] 2.1 Modify app-lock "Face ID only or Touch ID only" for r15-03: make the biometrics-only request at "Turn on" before the hash save. Run `openspec validate rulings-specs-c --type change --strict`.
- [x] 2.2 Modify app-lock "A new entry before authentication" for r17-01: show no custom place from the store before authentication. Run `openspec validate rulings-specs-c --type change --strict`.
- [x] 2.3 Modify app-lock "Delete from this device after an enrolment change" for r17-04: show "Could not delete. Try again." after a failed deletion. Run `openspec validate rulings-specs-c --type change --strict`.
- [x] 2.4 Modify app-lock "The cover" for r17-04: name the line after a failed "Delete from this device". Run `openspec validate rulings-specs-c --type change --strict`.

## 3. record

- [x] 3.1 Modify record "Today hides entries when the app is not active" for r16-02: the cover hides entries, with no `.privacySensitive()`. Run `openspec validate rulings-specs-c --type change --strict`.
- [x] 3.2 Confirm that record "Edit an entry" states r15-02 and "Delete an entry" states r16-03 with no change. Run `openspec show record --type spec`.

## 4. content

- [x] 4.1 Modify content "The forbidden list" for r17-02: skip three exact strings. Run `openspec validate rulings-specs-c --type change --strict`.
- [x] 4.2 Modify content "Content versions" for r17-03: add the weigh-in guidance and plan soft-rule prefixes. Run `openspec validate rulings-specs-c --type change --strict`.
- [x] 4.3 Modify content "Every bundled string family has ids" for r17-02 and r17-05: bundle copies and the pattern count strings. Run `openspec validate rulings-specs-c --type change --strict`.
- [x] 4.4 Modify content "Catalogue rules" for r17-05: {n}, {m} and {hours} stand for counts. Run `openspec validate rulings-specs-c --type change --strict`.

## 5. settings

- [x] 5.1 Modify the "Face ID only" scenario of settings "The About group" for r15-03: Face ID succeeds at "Turn on". Run `openspec validate rulings-specs-c --type change --strict`.

## 6. problem-solving

- [x] 6.1 Edit problem-solving "Pattern sentence templates" in v1-programme for r17-05: fill each count from a string with one count. This requirement is in v1-programme only. Run `openspec validate --all --strict`.

## 7. Follow-ups

This change does not build code. These beads hold the build work for the rulings.

- mm-t42.28 builds r15-01 in `RecordStore` with a test-only second schema version.
- mm-t12b.25 and mm-t12b.26 build r15-02 in `EntryOffset.forEdit`.
- mm-t15.21 builds r15-03 in `AppLockController.confirmTurnOnFaceOrTouchOnly`.
- mm-t12b.27 builds r16-02 on Today, the new-entry screen and the edit screen.
- mm-t12b.28 builds r16-03 for each confirmation dialog with a "Cancel".
- mm-t15.22 builds r17-01 in `NewEntryView`.
- mm-t11.47 and mm-t11.48 build r17-02 in the content test and the bundle.
- mm-t11.50 builds r17-03 in `signed-catalogue-keys.json`.
- mm-t41.27 builds r17-04 on the cover.
- mm-t33.19 builds r17-05 in the problem-solving build (epic mm-t33).
