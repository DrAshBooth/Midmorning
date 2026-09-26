# Tasks

Verify for every task below: `swift test --package-path Packages --filter ContentTests` passes. `./verify` passes before each close.

## 1. Foundations

- [x] 1.1 Add the `Content` package target at `Packages/Content`, with `ContentTests`, and add both to `Packages/Package.swift`. Verify: `swift build --package-path Packages` succeeds.
- [x] 1.2 Add the card model, the string-entry model, canonical JSON and the SHA-256 bundle hash. Verify: `ContentVersionTests` passes.
- [x] 1.3 Add the bundle loader, reading `manifest.json`, `cards.json` and `strings.json` from `Packages/Content/Resources`. Verify: `BundledCardsTests.testTheBundleLoadsFromLocalFilesOnly` passes.

## 2. mm-t11.13 — The card catalogue (P0)

- [x] 2.1 Write the ten stage 1 and stage 2 cards as data in `Resources/cards.json`, with the ids and titles the spec fixes. Decision 97: the agent writes the draft body and oneThing of each card, under the Draft flag, from the stage table in `docs/prd.md`. Verify: `CardCatalogueTests` passes.
- [x] 2.2 Built here: "Every id present" (stage 1 and 2 ids only, first cut), "A renamed card", "The stage 2 list". Built here over fixture facts: "A retired card", "A missing id", "A shipped id removed". Verify: `CardCatalogueTests` passes.
- [ ] 2.3 Deferred: "The 'Food rules' list" (mm-t34.13), "The 'Body image' list" (mm-t35.12), "The medical and faith rules sentence" (mm-t34.13).

## 3. mm-t11.11 — Strings live in catalogues (P0)

- [x] 3.1 Add `App/Midmorning/Localizable.xcstrings` and move the seven skeleton literals ("Today", "New entry", "Time", "What", "Cancel", "Save", "*") in `TodayView.swift` and `NewEntryView.swift` into catalogue keys; `Text(verbatim:)` carries "*". Verify: `xcodebuild -project App/Midmorning.xcodeproj -scheme Midmorning -destination 'generic/platform=iOS Simulator' build` succeeds.
- [x] 3.2 Add the literal lint: derive the repository root from `#filePath`, scan `App/**/*.swift`, check the six one-line calls, pass `Text(verbatim:)`. Built here: "A literal in code", "A catalogue key", "The verbatim escape", "A call over several lines", "A literal outside the six calls", "A device in another language". Verify: `LiteralLintTests` and `BundledCardsTests.testLiteralLintNamesNoFileInTheShippedApp` pass.
- [x] 3.3 "A card view's language": mm-t11.9 did not build it. The code review fix mm-t21.30 builds it on 26 September 2026: `Seen.language` (additive; `FrozenSchema.json` in the same commit), `ContentBundle.language`, written from `CardScreenView.load()`. Verify: `RecordTests.ProgrammeStoreTests.testACardViewsLanguage` and `ContentTests.CardViewLanguageTests` pass.

## 4. mm-t11.8 — Content versions (P0)

- [x] 4.1 Add `content-lock.json`, the lock-disagreement check, and `scripts/content-lock` (`swift run --package-path Packages content-lock <version>`). Built here: all six scenarios. Verify: `ContentVersionTests` passes; `./scripts/content-lock 1` writes a lock that matches the shipped bundle.

## 5. Card requirements (P1)

- [x] 5.1 mm-t11.1 Each stage has three to five cards. Built here: all four scenarios, applied to stage 1 and 2 (first cut). Verify: `CardCountTests` passes.
- [x] 5.2 mm-t11.2 One in-app link on a card. Built here: "Two links", "A web link". Deferred: "The 'Feeling fat' card" (mm-t35.12). Verify: `InAppLinkTests` passes.
- [x] 5.3 mm-t11.3 Plain UK English. Built here: "UK spelling", "How the card addresses the person". Deferred: "Plain words" (mm-t31.15). Verify: `PlainUKEnglishTests` passes.
- [x] 5.4 mm-t11.4 Every card ends with the one thing to do. Built here: all five scenarios ("Two actions" as an advisory heuristic; the clinical reviewer decides at sign-off). Verify: `OneThingTests` passes.
- [x] 5.5 mm-t11.5 Tone of every card. Built here: all four scenarios. Verify: `ToneTests` passes.
- [x] 5.6 mm-t11.6 The forbidden list. Built here: all eight scenarios. Verify: `ForbiddenListTests` passes.
- [x] 5.7 mm-t11.7 The app bundles the cards. Built here: all three scenarios. Verify: `BundledCardsTests` passes.
- [x] 5.8 mm-t11.12 The card screen and the card list. Built here: "The list for stage 1". Built here over fixture facts, with no live dependency: "VoiceOver headings", "Largest text size" (a `CardScreen` value; mm-t21.23 runs it end to end on the Programme screen). Verify: `CardScreenTests` passes.
- [x] 5.9 mm-t11.10 Clinical sign-off per content version. Built here: all five scenarios, each over a fixture bundle and sign-off directory. Add `scripts/archive`. Verify: `SignOffTests` passes.

## 6. mm-t11.15 — Catalogue rules (P1)

- [x] 6.1 Add the pure rule functions: placeholder positions, plural-forms requirement, the character limit by kind, the full-stop and sentence-case checks, the bare-plural check, the Contact-value check. Built here: "A count without plural forms", "A literal constant", "Two placeholders without positions", "A control label over the limit", "A full stop on a label", "A bare plural", "The Contact placeholder". Verify: `CatalogueRulesTests` passes.
- [x] 6.2 Add `scripts/content-signoff-list` and the "Sign-off list" section of this README. Built here: "The sign-off list". Verify: `CatalogueRulesTests.testTheReadmeSignOffListMatchesTheCatalogueIds` passes.
- [ ] 6.3 "Rendering at AX5" is a device check. See mm-t11.37.

## 7. mm-t11.14 — Every bundled string family has ids (P1)

- [x] 7.1 Add the id-uniqueness check. Built here: "Two strings with one id". Built here over a fixture bundle: "Sign-off covers the strings". Verify: `StringFamilyIdsTests` passes.
- [ ] 7.2 Deferred: "The stage 2 opening card with reminders off" (mm-t25.15), "The Focus card text" (mm-t25.16), "A pattern template with its placeholders" (mm-t33.17), "The custom chip template" (mm-t33.17), "{place} in another template" (mm-t33.17), "{weekday} in a pattern template" (mm-t33.17), "The first worksheet step" (mm-t33.17), "The reintroduction question" (mm-t34.15), "The check-in weeks line" (mm-t36.20), "The maintenance plan question" (mm-t36.20), "The urge timer line" (mm-t31.16).

## 8. First-cut string families (P1), each bundled under "Every bundled string family has ids"

- [x] 8.1 mm-t11.28 "opening.stage2". Built here for that bead: "An opening sentence". Verify: `OpeningAndRuleStringsTests` passes.
- [x] 8.2 mm-t11.29 "rule.stage2" to "rule.stage7". Built here for that bead: "A rule string with its numbers", "The stage 3 rule string", "A rule string with three placeholders". Verify: `OpeningAndRuleStringsTests` passes.
- [x] 8.3 mm-t11.30 "todaycard.plan", "todaycard.plan.setup", "todaycard.read". Built here for that bead: "The plan card text". "todaycard.focus" and "todaycard.focus.yes" wait for 2.5 (mm-t25.16). Verify: `TodayCardStringsTests` passes.
- [x] 8.4 mm-t11.31 "reflection.1" to "reflection.3". Built here for that bead: "A placeholder in a question". Verify: `ReflectionAndWeek1Tests` passes.
- [x] 8.5 mm-t11.32 "week1.1" to "week1.3". Verify: `ReflectionAndWeek1Tests` passes.
- [x] 8.6 mm-t11.33 "gp.default", "gp.selfharm", "gp.under18". Verify: `SafeguardingStringsTests` passes.
- [x] 8.7 mm-t11.34 "support.<name>", 22 strings. Verify: `SafeguardingStringsTests` passes.
- [x] 8.8 mm-t11.35 "notrightnow.selfharm", "notrightnow.weight". Built here for that bead: "The not-right-now ids". Verify: `SafeguardingStringsTests` passes.
- [x] 8.9 mm-t11.36 "gpsuggestion.fallingweight", "gpsuggestion.quickchange", "gpsuggestion.deterioration" (with plural forms), "gpsuggestion.gettingworse". Verify: `SafeguardingStringsTests` passes.
- [x] 8.10 mm-t11.38 "exclusion.selfharm", "exclusion.age", "exclusion.weight", "exclusion.pregnancy", "exclusion.treatment". Verify: `SafeguardingStringsTests` passes.

## 9. Close

- [ ] 9.1 mm-t11.37 device checks for 1.1: list "Rendering at AX5" (task 6.3) as the one pending device check. Ash does it and adds a date and a screenshot to this README.
- [ ] 9.2 Write the rules-checklist and safeguarding lines in this README.
- [ ] 9.3 Run `./verify` cold and warm; write both times in this README.
