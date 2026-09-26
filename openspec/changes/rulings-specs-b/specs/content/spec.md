# content

## MODIFIED Requirements

### Requirement: Content versions

The content bundle MUST carry one content version, an integer that starts at 1. The bundle MUST carry one bundle hash. The bundle hash MUST be the SHA-256 of the canonical JSON of the bundle and the signed catalogue keys. Canonical JSON MUST sort keys, use no whitespace outside strings and use UTF-8. Every card MUST carry a stable id that never changes across versions. A change to the text of a bundle string or of a signed catalogue key MUST raise the content version.

The signed catalogue keys are the keys of the string catalogue that hold record, safeguarding and reminder text. That is the text that the `record`, `safeguarding` and `reminders` capabilities own. The repository MUST hold `Packages/Content/Resources/signed-catalogue-keys.json`. That file MUST list the key prefixes of those three families. A catalogue key is signed when it starts with a prefix from that file. The canonical JSON MUST hold the en-GB text of each signed key, with its plural forms.

The bundle hash, the content-lock tool and `scripts/content-signoff-list` MUST read the prefixes from that one file. They MUST NOT hold a second copy of the list. When the team adds a key to one of the three families, the team MUST make sure that a prefix in the file matches the key.

Every other catalogue key holds interface text, for example the label of a control that names no record, safeguarding or reminder content. The bundle hash, the content version and the sign-off file MUST NOT cover interface text. The clinical reviewer still reviews interface text before release, as `product-rules` requires. Ash ruled this on 26 September 2026 (r13-01).

The repository MUST hold `Packages/Content/Resources/content-lock.json`. The lock MUST hold two fields, contentVersion and bundleHash. The content test MUST fail when the bundle's hash differs from the lock's and the bundle's version equals the lock's. A commit that raises the content version MUST update the lock in the same commit.

The app MUST know the content version it carries. When the app updates and the content version changes, the app MUST NOT show any message about it.

#### Scenario: A card's body changes
- **WHEN** the team changes one word in the card "The star" and does not raise the content version
- **THEN** the content test fails and reports that the bundle's hash differs from content-lock.json at the same version

#### Scenario: A catalogue string changes
- **WHEN** signed-catalogue-keys.json lists the prefix "entry.", and the team changes the key "entry.delete.confirmTitle" from "Delete this entry?" to "Remove this entry?" and does not raise the content version
- **THEN** the content test fails and reports that the bundle's hash differs from content-lock.json at the same version

#### Scenario: The version rises with the lock
- **WHEN** one commit changes a card, raises the content version from 2 to 3, and writes the new version and hash to content-lock.json
- **THEN** the content test passes the lock check

#### Scenario: Interface text changes
- **WHEN** no prefix in signed-catalogue-keys.json matches the key "common.cancel", and the team changes its text from "Cancel" to "Close" and does not raise the content version
- **THEN** the content test passes the lock check, and the sign-off list does not hold "common.cancel"

#### Scenario: One list of prefixes
- **WHEN** the team adds the prefix "weighIn." to signed-catalogue-keys.json
- **THEN** the bundle hash covers the "weighIn." keys, the content-lock tool writes the new hash, scripts/content-signoff-list prints those keys, and no other list of prefixes needs a change

#### Scenario: A title changes
- **WHEN** the team renames the card with id "stage1.star" from "The star" to "Felt like a binge"
- **THEN** the id stays "stage1.star" and the content version rises

#### Scenario: The bundle hash
- **WHEN** the content test computes the SHA-256 of the canonical JSON of the bundle and the signed catalogue keys
- **THEN** it equals the bundle hash the bundle carries

#### Scenario: An update with new content
- **WHEN** the person opens the app after an update that raised the content version from 1 to 2
- **THEN** the app shows Today and no message about new content

### Requirement: Strings live in catalogues

Every string the person can read MUST live in a string catalogue or in the content bundle. The code MUST NOT hold such a string as a literal. The base language MUST be en-GB. The content bundle MUST be per language. V1 MUST ship en-GB only. A card view MUST hold the language of the card.

The literal lint is a test in the Content package. It MUST derive the repository root from #filePath. It MUST scan App/**/*.swift. It MUST check only a call that opens and closes on one line. It MUST fail on any string literal that is the first argument of one of six one-line calls. The six calls are Text(, Label(, Button(, .navigationTitle(, .accessibilityLabel( and .accessibilityValue(.

A literal that is a catalogue key MUST pass. `Text(verbatim:)` is the one escape. The lint MUST pass a `Text(verbatim:)` call. The lint MUST name the file and line of each failure.

A call that spans more than one line is outside the lint. The review covers those calls. When such a call shows a signed catalogue key, the bundle hash also covers its text. The repository MUST NOT hold a literal allowlist file.

#### Scenario: A literal in code
- **WHEN** a view in App/ holds `Button("Save")` on one line and "Save" is not a catalogue key
- **THEN** the literal lint fails and names the file and line

#### Scenario: A catalogue key
- **WHEN** a view in App/ holds `Text("entry.save")` and "entry.save" is a key in the string catalogue
- **THEN** the literal lint passes that line

#### Scenario: The verbatim escape
- **WHEN** a view in App/ holds `Text(verbatim: "—")`
- **THEN** the literal lint passes that line

#### Scenario: A call over several lines
- **WHEN** a view in App/ holds a `Button(` call whose first argument sits on the line after the opening bracket
- **THEN** the literal lint does not check that call, and the review covers it

#### Scenario: A literal outside the six calls
- **WHEN** a file in App/ holds `let key = "entry.save"`
- **THEN** the literal lint passes that line

#### Scenario: A device in another language
- **WHEN** the device language is French
- **THEN** the app shows every string and every card in en-GB

### Requirement: Every bundled string family has ids

The content bundle MUST hold these families of reviewed strings, each string with an id. The owning capability specifies each string's text. Content bundles it. The signed catalogue keys that "Content versions" defines hold the other reviewed text.

- Cards: the ids in the card catalogue.
- Opening sentences: "opening.stage2" to "opening.stage7". Programme owns the text. "opening.stage2.remindersoff" is the line the stage 2 opening card adds when notification permission is denied: "Reminders are off, so the Home Screen widget shows your next planned time."
- Rule strings: "rule.stage2" to "rule.stage7", and more ids that start with "rule.stage2." or "rule.stage3.". Programme owns the text. The stage 2 rule and the stage 3 rule each show two counts, so each comes from strings with one count each. The stage 2 rule is "rule.stage2", "Opens after %lld recorded days.", then a second string, "You have %lld.". The stage 3 rule reads "Opens after 7 days on your plan, or 2 weeks after your plan starts" with the default constants.
- Today card strings: "todaycard.plan", "Your plan isn't set yet. It takes about two minutes."; "todaycard.plan.setup", "Set it up"; "todaycard.focus", "If you use a Focus at work, let planned meal reminders through?"; "todaycard.focus.yes", "Yes"; "todaycard.read", "Read". Programme owns the text and when each card shows.
- Pattern templates: "pattern.<name>". Problem-solving owns the text. A slot template reads "{n} of your {m} starred entries were on days when {slot} didn't happen." "pattern.place" is the one template for a custom chip: "{n} of your {m} starred entries were at {place}."
- The reintroduction question: "dieting.reintroduction", "{weekday}, {slot}: how did it go?". Dieting-module owns the text.
- The worksheet steps: "worksheet.1" to "worksheet.6". Problem-solving owns the text. "worksheet.1" is "What is the problem, exactly?"
- The check-in weeks line: "checkin.weeks", and more ids that start with "checkin.weeks.". Staying-on-track owns the text. The line reads "A check-in comes at 4, 8 and 12 weeks." with the default constants. It shows three counts, so it comes from strings with one count each. The app fills the three numbers from CHECK_IN_WEEKS.
- The urge timer line: "urge.buzz", "Buzz at %lld minutes". Urge-toolkit owns the text. The app fills the number from URGE_TIMER_MINUTES.
- Reflection questions: "reflection.1" to "reflection.3". Weekly-review owns the text.
- Week-1 questions: "week1.1" to "week1.3". Weekly-review owns the text.
- The taking stock questionnaire: "takingstock.<n>". Weekly-review owns the text.
- The alternatives examples: "alternatives.<n>". Urge-toolkit owns the text.
- The maintenance plan questions: "maintenance.<n>". Staying-on-track owns the text. One of them is "Is there anyone you could tell, if you wanted to?"
- The GP paragraph and its variants: "gp.default", "gp.selfharm" and "gp.under18". Safeguarding owns the text.
- The support sheet strings: "support.<name>". Safeguarding owns the text.
- The exclusion page reasons: "exclusion.selfharm", "exclusion.age", "exclusion.weight", "exclusion.pregnancy" and "exclusion.treatment". Safeguarding owns the text.
- The not-right-now pages: "notrightnow.selfharm" and "notrightnow.weight". Safeguarding owns the text. For the pregnancy and treatment reasons, the page shows "exclusion.pregnancy" and "exclusion.treatment". The bundle MUST NOT hold "notrightnow.pregnancy" or "notrightnow.treatment".
- The GP suggestion pages: "gpsuggestion.<reason>". Safeguarding owns the text.
- The other signed-off text that the Programme package holds as Swift constants. This is the screening questions and their answers, the height and weight limit messages, the onboarding text, the headings and fixed lines of the safeguarding pages, and the review questions, controls and summary sentences. Safeguarding, onboarding and weekly-review own this text.

These strings MUST follow the same version, sign-off, tone and forbidden-list rules as the cards. Every string with a count MUST follow the catalogue rules below. Every string MUST hold at most one %lld placeholder.

The Programme package also holds some of these strings as Swift constants, and the app can show that copy. For each such constant, the bundle MUST hold the same text under the string's id. A test MUST compare each Swift constant with its bundle string, both filled with the same values. The test MUST fail when the two differ, and it MUST name the id. The sign-off, the tone rules, the forbidden list and the catalogue rules read the bundle copy. Ash ruled this on 26 September 2026 (r13-02).

Programme owns every fill: the gate value from ProgrammeConstants, the recorded-day count of the stage 2 rule, and the days and the weeks of the stage 3 rule. A rule string of one sentence MUST NOT end with a full stop. The two strings of the stage 2 rule are the exception: each is one sentence, and each ends with a full stop.

A pattern template MUST hold only the placeholders {n}, {m}, {slot} and {hours}. The one exception is "pattern.place", which MUST hold {n}, {m} and {place}. The app MUST fill {hours} from MAX_AWAKE_GAP_HOURS. The reintroduction question MUST hold only {weekday} and {slot}.

The app MUST fill {slot} with the slot label as the person typed it, and no other word. The app MUST fill {weekday} with the weekday name from the en_GB formatter. The app MUST fill {place} with the person's custom chip text and no other word. Problem-solving owns that fill.

Every other string in the bundle MUST hold only the placeholders the catalogue rules permit. Those are %lld, %@ and positional placeholders. The content test MUST fail when a string in the bundle has no id, or two strings share an id. The bundle MUST NOT hold a questionnaire from a third party.

#### Scenario: An opening sentence
- **WHEN** stage 2 opens
- **THEN** the opening card shows the bundle's "opening.stage2" text, "You can now plan when to eat. The app reminds you at each planned meal."

#### Scenario: A rule string with its numbers
- **WHEN** the Programme screen shows the closed stage 2 and the person has two recorded days
- **THEN** it shows "rule.stage2" filled with the gate from RECORDED_DAYS_FOR_STAGE_2, then the second stage 2 string filled with the count, as "Opens after 5 recorded days. You have 2."

#### Scenario: The stage 3 rule string
- **WHEN** the Programme screen shows the closed stage 3 with the default constants
- **THEN** it shows the stage 3 rule, from "rule.stage3" and its other strings, as "Opens after 7 days on your plan, or 2 weeks after your plan starts"

#### Scenario: A rule string with three placeholders
- **WHEN** the bundle holds "rule.stage3" with three %lld placeholders in its text
- **THEN** the content test fails and names "rule.stage3"

#### Scenario: A rule string with two counts
- **WHEN** the bundle holds "rule.stage3" as "Opens after %1$lld days on your plan, or %2$lld weeks after your plan starts"
- **THEN** the content test fails and names "rule.stage3"

#### Scenario: The rule strings match programme
- **WHEN** the test compares the bundle's rule strings with the Programme package's Swift constants
- **THEN** "rule.stage4" holds "Opens after your first urge outcome, or a week from now", and "rule.stage5" and "rule.stage7" each hold "Opens %lld weeks after your plan starts"

#### Scenario: A Swift constant differs from its bundle copy
- **WHEN** the Programme package shows "Opens %lld weeks after your plan starts" for stage 5, and the bundle holds "rule.stage5" as "Opens after six weeks in the programme"
- **THEN** the test fails and names "rule.stage5"

#### Scenario: A signed-off Swift constant with no bundle copy
- **WHEN** the Programme package holds "Please answer this one." as a Swift constant, and no bundle string holds that text
- **THEN** the test fails and names the constant

#### Scenario: The plan card text
- **WHEN** programme shows the plan card
- **THEN** the card shows the bundle's "todaycard.plan" text, "Your plan isn't set yet. It takes about two minutes.", with "todaycard.plan.setup", "Set it up"

#### Scenario: A placeholder in a question
- **WHEN** the bundle holds "reflection.1" with "{weekNumber}" in its text
- **THEN** the content test fails and names "reflection.1"

#### Scenario: Two strings with one id
- **WHEN** the bundle holds two strings with the id "support.samaritans"
- **THEN** the content test fails and names "support.samaritans"

#### Scenario: The not-right-now ids
- **WHEN** a reviewer lists every bundle id that starts with "notrightnow."
- **THEN** the list holds "notrightnow.selfharm" and "notrightnow.weight", and no "notrightnow.pregnancy" or "notrightnow.treatment"

#### Scenario: Sign-off covers the strings
- **WHEN** the team changes "opening.stage5" and does not raise the content version
- **THEN** the content test fails and reports that the bundle's hash differs from content-lock.json at the same version

### Requirement: Catalogue rules

Every string in the content bundle and in every string catalogue MUST follow these rules. The content test MUST check each rule it can check by machine. The clinical reviewer MUST check the rest at sign-off.

- Every string with a count MUST carry plural forms with the categories zero, one and other.
- Every %lld placeholder is a count. A %@ placeholder is not a count, and it needs no plural forms.
- A string MUST hold at most one count. A text that shows two or more counts MUST come from strings with one count each. The app can show two sentences from two strings, joined by one space. The app can also fill each %@ placeholder of a string from a string with one count, as the meal line in `regular-eating-plan` does. Ash ruled this on 26 September 2026 (r13-12).
- Every constant MUST enter a string through %lld, never as a literal number.
- A string with more than one placeholder MUST use positional placeholders, %1$lld, %2$@ and so on.
- Every date, time, duration and range MUST enter a string as %@, filled by the en_GB formatter.
- Text the person typed MUST enter a string unchanged.
- Every string MUST use sentence case. A string that starts with a placeholder, such as "%lld cm", passes this rule.
- A navigation control or a card control MUST hold at most 16 characters. A notification action MUST hold at most 20. A chip or a slot label MUST hold at most 20. A widget line MUST hold at most 16. A switch label MUST hold at most 40. A state line or a Today line MUST hold at most 40. A one-line message MUST hold at most 80.
- Every string family MUST render at the AX5 text size without truncation.
- A sentence MUST end with a full stop. A label MUST NOT end with a full stop. A rule string of one sentence MUST NOT end with a full stop. The stage 2 rule is the exception: it is two sentences from two strings, and each ends with a full stop.
- The VoiceOver label of a control with visible text MUST equal the visible text, or start with the visible text and add words after it. For example, the "Rename" control in the plan builder has the label "Rename Lunch". Voice Control then finds the control by its visible text. Ash ruled this on 26 September 2026 (r13-08).
- A string MUST NOT hold the bare plural "binges".
- `scripts/content-signoff-list` MUST generate the README sign-off list from the bundle ids and the signed catalogue keys. It MUST read the prefixes from `signed-catalogue-keys.json`. The team MUST NOT write the list by hand.

The catalogue key "about.contact" holds the Contact email that the About group shows. The `settings` capability owns the About group. Until the team sets the confirmed email, the key MUST hold the placeholder "contact@example.invalid". The content test MUST pass "about.contact" when it holds the placeholder or an email address. The sentence-case and full-stop rules MUST NOT apply to "about.contact".

#### Scenario: A count without plural forms
- **WHEN** a catalogue string holds "%lld recorded days" with no plural forms
- **THEN** the content test fails and names the string's id

#### Scenario: Two counts in one string
- **WHEN** a bundle string holds "Opens after %1$lld recorded days. You have %2$lld."
- **THEN** the content test fails and names the string's id

#### Scenario: A placeholder that is not a count
- **WHEN** a catalogue string holds "Weigh-in: done on %@." with no plural forms
- **THEN** the content test passes the plural check for that string

#### Scenario: A literal constant
- **WHEN** a catalogue string holds "Buzz at 20 minutes"
- **THEN** the content test fails and names the string's id

#### Scenario: Two placeholders without positions
- **WHEN** a catalogue string holds "A day runs from %@ to %@."
- **THEN** the content test fails and names the string's id

#### Scenario: A control label over the limit
- **WHEN** a card control's string holds 17 characters
- **THEN** the content test fails and names the string's id and the limit 16

#### Scenario: A full stop on a label
- **WHEN** a switch label ends with a full stop
- **THEN** the content test fails and names the string's id

#### Scenario: A label that starts with the visible text
- **WHEN** a reviewer checks the "Rename" control of the Lunch slot, whose VoiceOver label is "Rename Lunch"
- **THEN** the label passes the rule, because it starts with "Rename"

#### Scenario: A bare plural
- **WHEN** a catalogue string holds "your binges"
- **THEN** the content test fails and names the string's id

#### Scenario: The sign-off list
- **WHEN** the team builds the README sign-off list
- **THEN** scripts/content-signoff-list generates it from the bundle ids and the signed catalogue keys, and the content test fails when the list and those ids differ

#### Scenario: The Contact placeholder
- **WHEN** the catalogue key "about.contact" holds "contact@example.invalid"
- **THEN** the content test passes the key and names no rule
