# Proposal

## Why

Task 1.1 of `v1-programme`. Content is data, not code: the string families, the content versions, the sign-off file and the content test that checks them. Every later screen reads a card or a bundled string through this pipeline, so it goes first. `product-rules` sets the vocabulary and tone rules the content test enforces.

## What Changes

- The `Content` package: a card model, a reviewed-string model, canonical JSON, a SHA-256 bundle hash, a content-lock file, and a sign-off file per content version.
- The card catalogue's stage 1 and stage 2 cards, ten cards, as data in `Packages/Content/Resources`. Decision 97: the agent writes their draft bodies and oneThing sentences, under the Draft flag; the clinical reviewer replaces them.
- The first-cut string families: the stage 2 opening sentence, the rule strings, the Today card strings, the reflection and week-1 questions, the GP paragraph and its variants, the support sheet strings, the exclusion page reasons, the not-right-now page strings and the GP suggestion page strings.
- The content test: the forbidden list, UK spelling, the tone and address rules, the placeholder and plural-form rules, the character limits, the card-count and word-limit rules, and the content-lock and sign-off checks.
- The literal lint: a test in the Content package that scans `App/**/*.swift` for a literal string argument to one of six calls, and fails when it is not a catalogue key.
- `App/Midmorning/Localizable.xcstrings`, the string catalogue for the app's own interface chrome, and the seven skeleton literals in `TodayView.swift` and `NewEntryView.swift` moved into it.
- A `CardScreen` value and a `CardList` function, ready for the Programme screen to render; 2.1 (`programme-engine`) wires them in.
- `scripts/content-lock`, `scripts/content-signoff-list` and `scripts/archive`.

Not in this change: cards for stages 3 to 7, the pattern templates, the worksheet steps, the check-in and urge-timer lines, the taking stock questionnaire, the alternatives examples, the maintenance plan questions, and the card view the store keeps (`deferred.md` names the owning later change for each). The Programme screen, the card screen's view and Get support itself are also later work; this change ships the data and the pure `CardScreen` value they will read.

## Capabilities

### New Capabilities
- `content`: cards and reviewed strings as versioned, sign-off-gated data, with a content test that checks the version's own machine-checkable rules.

### Modified Capabilities
None. `content` is a new capability in `openspec/specs`.

## Impact

- New SwiftPM package `Packages/Content`, with targets `Content`, `ContentTests`, `ContentLockTool` and `ContentSignOffListTool`, added to `Packages/Package.swift`.
- `App/Midmorning/TodayView.swift` and `NewEntryView.swift`: seven literals become catalogue keys.
- New `App/Midmorning/Localizable.xcstrings`.
- New `scripts/content-lock`, `scripts/content-signoff-list`, `scripts/archive`.
- No network. No new third-party dependency. `Content` imports Foundation and CryptoKit only.
