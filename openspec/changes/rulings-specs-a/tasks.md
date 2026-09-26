## 1. data-and-privacy

- [x] 1.1 Add the line "Could not delete. Try again." after a failed deletion to "Delete-all" (r14-01, mm-t41.26). Prove it with `openspec validate rulings-specs-a --type change --strict`.
- [x] 1.2 Set safe mode at the third launch and choose it from the marker before the store opens in "Launch safety" (r13-13, mm-t41.25; r13-05, mm-t42.23). Prove it with `openspec validate rulings-specs-a --type change --strict`.
- [x] 1.3 Make "Share App Analytics with Apple" open the app's own page in "The app holds no analytics of its own" (r12-01). Prove it with `openspec validate rulings-specs-a --type change --strict`.

## 2. app-lock

- [x] 2.1 Allow the failed-deletion line on "The cover" (r14-01, mm-t41.26). Prove it with `openspec validate rulings-specs-a --type change --strict`.
- [x] 2.2 Show the cover again with the failed-deletion line in "Delete everything from the cover" (r14-01, mm-t41.26). Prove it with `openspec validate rulings-specs-a --type change --strict`.
- [x] 2.3 Save the current enrolment state hash at "Turn on" in "Face ID only or Touch ID only" (r13-06, mm-t15.20). Prove it with `openspec validate rulings-specs-a --type change --strict`.
- [x] 2.4 Add the Save authentication scenarios for the notification action "Add" to "A new entry before authentication" (r13-04, mm-t15.19). Prove it with `openspec validate rulings-specs-a --type change --strict`.

## 3. record

- [x] 3.1 Keep the UTC offset for the entry's own time in "The app keeps the entry's UTC offset and creation moment" (r13-16, mm-t12b.22). Prove it with `openspec validate rulings-specs-a --type change --strict`.
- [x] 3.2 Keep plan text out of the six-words rule and delete the stale strings sentence in "Today's appearance" (r13-07, mm-t12b.21). Prove it with `openspec validate rulings-specs-a --type change --strict`.

## 4. export

- [x] 4.1 Remove Copy from the share sheet in "Share sheet only" (r13-14, mm-t42.27). Prove it with `openspec validate rulings-specs-a --type change --strict`.
- [x] 4.2 Allow one tagged list on each page of a day in "Accessibility of the export" (r14-04, mm-t42.26). Prove it with `openspec validate rulings-specs-a --type change --strict`.

## 5. weigh-in

- [x] 5.1 Keep the onboarding sentence and define "the explanation" in "The weigh-in day" (r13-10, mm-t22.26). Prove it with `openspec validate rulings-specs-a --type change --strict`.

## 6. v1-programme copies

- [x] 6.1 Apply each change above to its copy in `openspec/changes/v1-programme/specs`, where a copy exists. Prove it with `openspec validate --all --strict`.
- [x] 6.2 Make the "Share App Analytics with Apple" item in `v1-programme` settings "The Privacy group" name the app's own page (r12-01). Prove it with `openspec validate --all --strict`.
