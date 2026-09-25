# Design

## Context

`openspec/changes/v1-programme/design.md`, section "Content is data with a version and a sign-off file", sets the shape: cards and every bundled string family live in `Packages/Content/Resources` with ids, a content version and a SHA-256 bundle hash. The content test checks counts, word limits, the forbidden list and UK spelling on every build, and checks the sign-off file only when `MIDMORNING_RELEASE=1`. This design states the decisions the content-pipeline change itself makes inside that shape.

## Goals / Non-Goals

**Goals:**
- One content bundle, loaded from JSON data, that every later screen and every later content-owning capability (`programme`, `safeguarding`, `weekly-review`, and so on) can add to without a format change.
- A content test that checks every machine-checkable rule the content spec states, over the real shipped bundle where a real check is safe, and over a fixture where the rule needs an input the spec does not fix.
- A literal lint that covers the app's own interface chrome, separately from the clinically reviewed content bundle.

**Non-Goals:**
- The Programme screen, the card screen's view, or any other screen. `programme-engine` (2.1) and later changes read `CardScreen` and `CardList`.
- Cards for stages 3 to 7, or any string family a later change owns (`deferred.md`).
- A real clinical sign-off. Content version 1 ships as a Draft.

## Decisions

### The `Content` package sits at `Packages/Content`, not `Packages/Sources/Content`

The content spec names the literal path `Packages/Content/Resources/content-lock.json`, and design.md names `Packages/Content/Resources` for every bundled resource. `Packages/Package.swift` sets `path: "Content"` on the target so the path matches the spec exactly, apart from the skeleton's `RecordCore`, which keeps the default `Sources/RecordCore` layout. `RepositoryRoot.swift` finds the repository root from its own `#filePath`, four directories up, for the literal lint and the sign-off file.

### Two catalogues: the content bundle and the app's own `Localizable.xcstrings`

"Strings live in catalogues" names two homes for a string: "a string catalogue or the content bundle". The content bundle holds every clinically reviewed string: cards and the string families a spec capability owns. Plain interface chrome that carries no clinical review — "Cancel", "Save", "Today", "What", "Time", "New entry" — lives in `App/Midmorning/Localizable.xcstrings`, a real Xcode String Catalog with `sourceLanguage: en-GB`. SwiftUI resolves a literal against it at build time through the normal `LocalizedStringKey` mechanism; the literal lint reads the same file to build its set of valid keys, alongside every card and string-family id. Rejected: one catalogue for everything. The content bundle's version, hash, sign-off and tone rules do not fit a "Save" button, and forcing them through the same gate would block ordinary UI work on a clinical review.

### The canonical JSON is one object, keyed by id, not an array

`ContentBundle.canonicalJSON` writes `cards` and `strings` as objects keyed by each entry's own id, not as arrays in bundle order. Canonical JSON already sorts object keys, so the hash is stable however the source JSON file orders its entries; an array's hash would depend on array order, which a JSON file's own formatting can change with no content change. Rejected: an array with each entry's `id` as a field. The hash would then depend on array order, which the content version rule does not want to notice.

### The literal-constant and plural-forms rules run as fixture-tested functions, not a blanket scan

"Catalogue rules" states two rules a scan of every real string cannot safely apply: "every constant MUST enter a string through %lld, never as a literal number", and "every string with a count MUST carry plural forms". A real digit in real content is not always a constant: `week1.1`'s fixed text, "What do you want to be different by week 12?", is weekly-review's own spec text, quoted verbatim, and a phone number in a support string is a fact, not a constant. `CatalogueRules.hasLiteralConstant` is a pure function the content test exercises with the requirement's own fixture ("Buzz at 20 minutes"); it does not run over the shipped bundle. `CatalogueRules.requiresPluralForms` (a bare, non-positional `%lld`) does run over the shipped bundle, because every first-cut string that carries a count can satisfy it directly; `gpsuggestion.deterioration` carries `PluralForms` for that reason. Rejected: running both checks over every shipped string. `week1.1` and the support sheet's phone numbers would fail a rule they do not break.

### "Two actions" and "A lapse" stay with the clinical reviewer

The content spec frames both as the reviewer's own judgement at sign-off ("the clinical reviewer sends the card back"), not a MUST-fail machine rule. `OneThingTests` and `ToneTests` each add an advisory heuristic or a targeted check over the shipped card, but neither is wired into `ContentChecks`, which the release lane runs. Rejected: inferring "one action" or "no judgement" from sentence structure alone and failing the build on it. A false failure would block an unrelated content change; a missed one is caught at the human sign-off step the requirement already names.

## Risks / Trade-offs

- [First-cut cards are unreviewed draft text] → the Draft flag shows on every card, decision 97 authorises it, and `mm-t43.21` replaces the drafts and raises the content version before any release build.
- [The literal lint's paren-balancing is a hand-written scanner, not a real Swift parser] → it tracks string literals and nested parens on one line only, which the six checked calls' real usage never defeats; `LiteralLintTests` covers the multiline-call and identifier-boundary cases directly.
- [`scripts/archive` cannot be run end to end here] → no Xcode archive scheme exists yet; the script's own content-test gate is what `SignOffTests` checks, and `xcodebuild archive` itself waits for a later change.
