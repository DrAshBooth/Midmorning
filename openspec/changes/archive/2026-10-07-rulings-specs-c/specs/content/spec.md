# content

## MODIFIED Requirements

### Requirement: The forbidden list

The repository MUST hold a forbidden list. The content test MUST fail when a card holds a word from it. The forbidden list MUST hold at least: "Fairburn", "Oxford", "CREDO", "CBT-E", "CBT", "treat", "treats", "treatment", "therapy", "therapist", "cure", "recovery", "disorder", "patient", "symptom", "diagnosis", "clinical", "calories", "calorie", "portion", "log", "tracker", "user", "streak", "binger", "bingeing", "binge episode", "well done", "great job", "proud", "you've got this". The list MUST NOT hold "diary" or "notes".

The content test MUST match each entry as a whole word, case-insensitive. A word is a maximal run of letters, digits, apostrophes and hyphens. An entry with a space MUST match as a run of whole words in that order.

The full forbidden list applies to the cards, the opening sentences, the rule strings and the Today card strings. It also applies to the pattern templates, every question and the alternatives examples. The content test MUST check each of those families against the full list. The content test MUST check the strings with ids support.*, gp.*, exclusion.*, notrightnow.* and gpsuggestion.* against the short list only. The short list is "Fairburn", "Oxford", "CREDO", "CBT-E", "CBT", "binger", "bingeing", "binge episode", "you've got this", "well done", "great job" and "proud".

The content test MUST skip four permitted sentences, and no other text. The permitted sentences are "It is not therapy.", "It is not therapy, and it does not replace your GP or anyone treating you.", "It uses ideas from CBT." and "Are you getting help from a clinic or a therapist for your eating at the moment?". `safeguarding` permits the first three in "What is a treatment claim". The second is line 3 of onboarding screen 1, and the `safeguarding` scenario "A negative statement" passes it. The fourth is the screening treatment question that `onboarding` states in "Screen 2: the screening questions".

The content test MUST divide each card text and each bundle string into sentences. A sentence ends at a full stop, a question mark or an exclamation mark that a space or a line break follows. The last sentence ends at the end of the text. The content test MUST skip a sentence only when it is equal to a permitted sentence, character for character. The content test MUST NOT compare a sentence with a permitted sentence word by word. It MUST check each other sentence of that text against the list of its family. A phrase from a list MUST NOT match across a permitted sentence. The forbidden lists MUST NOT change. Ash ruled this on 7 October 2026 (r17-02).

#### Scenario: A forbidden word
- **WHEN** a card's body holds "This programme treats binge eating."
- **THEN** the content test fails and names the card's id and "treats"

#### Scenario: A capital letter
- **WHEN** a card's body holds "Treatment"
- **THEN** the content test fails and names the card's id and "treatment"

#### Scenario: Part of a longer word
- **WHEN** a card's body holds "untreated"
- **THEN** the content test passes the card for that word

#### Scenario: A hyphen inside a word
- **WHEN** a card's body holds "CBT-E"
- **THEN** the content test fails and names the card's id and "CBT-E"

#### Scenario: Notes is allowed
- **WHEN** a card's body holds "Feeling fat notes"
- **THEN** the content test passes the card for that phrase

#### Scenario: A support string names treatment
- **WHEN** "support.gp" holds "Your GP can talk about treatment options with you."
- **THEN** the content test passes the string, because support strings are checked against the short list only

#### Scenario: A support string on the short list
- **WHEN** "notrightnow.selfharm" holds "well done"
- **THEN** the content test fails and names "notrightnow.selfharm" and "well done"

#### Scenario: A question on the full list
- **WHEN** "maintenance.2" holds "your recovery"
- **THEN** the content test fails and names "maintenance.2" and "recovery"

#### Scenario: Line 1 of onboarding screen 1
- **WHEN** the bundle holds "Midmorning is a 12-week self-help programme for people who binge eat. It uses ideas from CBT." as line 1 of onboarding screen 1
- **THEN** the content test checks the first sentence against the full list, skips "It uses ideas from CBT." and passes the string

#### Scenario: Line 3 of onboarding screen 1
- **WHEN** the bundle holds "It is not therapy, and it does not replace your GP or anyone treating you." as line 3 of onboarding screen 1
- **THEN** the content test passes the string

#### Scenario: A card with a permitted sentence
- **WHEN** a card's body holds "It is not therapy. It is a programme."
- **THEN** the content test passes the card

#### Scenario: A permitted sentence next to a forbidden word
- **WHEN** a card's body holds "It is not therapy. Therapy is not the word."
- **THEN** the content test skips the first sentence, checks the second, fails and names the card's id and "therapy"

#### Scenario: The screening treatment question
- **WHEN** the bundle holds the question "Are you getting help from a clinic or a therapist for your eating at the moment?"
- **THEN** the content test passes the question

#### Scenario: A permitted line with one change
- **WHEN** the bundle holds "It is not therapy, and it does not replace your GP or anyone treating you" with no full stop
- **THEN** the content test fails and names the string's id and "therapy"

#### Scenario: A permitted word in another string
- **WHEN** a card's body holds "These ideas come from CBT."
- **THEN** the content test fails and names the card's id and "CBT"

### Requirement: Content versions

The content bundle MUST carry one content version, an integer that starts at 1. The bundle MUST carry one bundle hash. The bundle hash MUST be the SHA-256 of the canonical JSON of the bundle and the signed catalogue keys. Canonical JSON MUST sort keys, use no whitespace outside strings and use UTF-8. Every card MUST carry a stable id that never changes across versions. A change to the text of a bundle string or of a signed catalogue key MUST raise the content version.

The signed catalogue keys are the keys of the string catalogue that hold record, safeguarding, reminder, weigh-in guidance and plan soft-rule text. The `record`, `safeguarding` and `reminders` capabilities own the first three families. The weigh-in guidance is the text that tells the person about the weigh-in, and `weigh-in` and `onboarding` own it. Its prefixes are "weighIn.explanation.", "weighIn.refusal", "weighIn.belowRange" and "onboarding.weighIn.explanation". Each other key that holds weigh-in guidance MUST also match a prefix. The plan soft rules have the prefix "plan.softRules.", and `regular-eating-plan` owns them. Ash added these two families on 7 October 2026 (r17-03), because both give clinical guidance. The repository MUST hold `Packages/Content/Resources/signed-catalogue-keys.json`. That file MUST list the key prefixes of those five families. A catalogue key is signed when it starts with a prefix from that file. The canonical JSON MUST hold the en-GB text of each signed key, with its plural forms.

The bundle hash, the content-lock tool and `scripts/content-signoff-list` MUST read the prefixes from that one file. They MUST NOT hold a second copy of the list. A catalogue key that holds reminder text MUST have the segment "reminders" in its name, for example "reminders.title.midday" or "settings.reminders.pausedLine". A segment is a part of the key that full stops separate. The content test MUST fail when a key with the segment "reminders" matches no prefix in the file. The test MUST name that key. The review MUST check each new record, safeguarding, weigh-in guidance or plan soft-rule key. A prefix in the file MUST match that key.

A catalogue key that no prefix matches holds interface text. An example is the label of a control that names no content from the five families above. The bundle hash, the content version and the sign-off file MUST NOT cover such a key. A prefix can also match some interface text, for example a switch label in the reminder settings. That text is then signed too. The clinical reviewer still reviews all interface text before release, as `product-rules` requires in "No AI at runtime". Ash ruled this on 26 September 2026 (r13-01).

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
- **WHEN** the team adds the prefix "today.reminders." to signed-catalogue-keys.json
- **THEN** the bundle hash covers the "today.reminders." keys, the content-lock tool writes the new hash, scripts/content-signoff-list prints those keys, and no other list of prefixes needs a change

#### Scenario: A reminder key with no prefix
- **WHEN** the string catalogue holds the key "today.reminders.denied" and no prefix in signed-catalogue-keys.json matches it
- **THEN** the content test fails and names "today.reminders.denied"

#### Scenario: A title changes
- **WHEN** the team renames the card with id "stage1.star" from "The star" to "Felt like a binge"
- **THEN** the id stays "stage1.star" and the content version rises

#### Scenario: The bundle hash
- **WHEN** the content test computes the SHA-256 of the canonical JSON of the bundle and the signed catalogue keys
- **THEN** it equals the bundle hash the bundle carries

#### Scenario: An update with new content
- **WHEN** the person opens the app after an update that raised the content version from 1 to 2
- **THEN** the app shows Today and no message about new content

#### Scenario: A weigh-in explanation changes
- **WHEN** the team changes the text of "weighIn.explanation.kg" and does not raise the content version
- **THEN** the content test fails and reports that the bundle's hash differs from content-lock.json at the same version

#### Scenario: The two new families in the sign-off list
- **WHEN** the team runs scripts/content-signoff-list
- **THEN** the list holds "weighIn.refusal", "onboarding.weighIn.explanation" and "plan.softRules.mealLine"

### Requirement: Every bundled string family has ids

The content bundle MUST hold these families of reviewed strings, each string with an id. The owning capability specifies each string's text. Content bundles it. The signed catalogue keys that "Content versions" defines hold the other reviewed text.

- Cards: the ids in the card catalogue.
- Opening sentences: "opening.stage2" to "opening.stage7". Programme owns the text. "opening.stage2.remindersoff" is the line the stage 2 opening card adds when notification permission is denied: "Reminders are off, so the Home Screen widget shows your next planned time."
- Rule strings: "rule.stage2" to "rule.stage7", and more ids that start with "rule.stage2." or "rule.stage3.". Programme owns the text. The stage 2 rule and the stage 3 rule each show two counts, so each comes from strings with one count each. The stage 2 rule is "rule.stage2", "Opens after %lld recorded days.", then "rule.stage2.count", "You have %lld.". The stage 3 rule is "rule.stage3", "Opens after %1$@, or %2$@ after your plan starts". The app fills it from "rule.stage3.days", "%lld days on your plan", and "rule.stage3.weeks", "%lld weeks". With the default constants, the stage 3 rule reads "Opens after 7 days on your plan, or 2 weeks after your plan starts".
- Today card strings: "todaycard.plan", "Your plan isn't set yet. It takes about two minutes."; "todaycard.plan.setup", "Set it up"; "todaycard.focus", "If you use a Focus at work, let planned meal reminders through?"; "todaycard.focus.yes", "Yes"; "todaycard.read", "Read". Programme owns the text and when each card shows.
- Pattern templates: "pattern.<name>", and the three count strings "pattern.count.group", "pattern.count.total" and "pattern.count.hours". Problem-solving owns the text. A slot template reads "{n} of your {m} were on days when {slot} didn't happen." "pattern.place" is the one template for a custom chip: "{n} of your {m} were at {place}."
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
- The other signed-off text that the Programme package shows: the screening questions and their answers, the onboarding text, the headings and fixed lines of the safeguarding pages, and the review questions, controls and summary sentences. Safeguarding, onboarding and weekly-review own this text. Each of these strings MUST have a bundle copy, or the app MUST read it from a signed catalogue key, as "Content versions" defines. The height and weight limit messages are signed catalogue keys. The lines of onboarding screen 1 that hold "CBT" or "therapy", and the screening question "Are you getting help from a clinic or a therapist for your eating at the moment?", also have a bundle copy. "The forbidden list" states why the content test passes them. Ash ruled this on 7 October 2026 (r17-02).

These strings MUST follow the same version, sign-off, tone and forbidden-list rules as the cards. Every string with a count MUST follow the catalogue rules below. Every string MUST hold at most one %lld placeholder.

The Programme package also holds some of these strings as Swift constants, and the app can show that copy. For each such constant, the bundle MUST hold the same text under the string's id. This rule has no exception. A test MUST compare each Swift constant with its bundle string, both filled with the same values. The test MUST fail when the two differ, and it MUST name the id. The sign-off, the tone rules, the forbidden list and the catalogue rules read the bundle copy. Text that the app reads from a signed catalogue key is not a Swift constant, and it needs no bundle copy. Ash ruled this on 26 September 2026 (r13-02).

Programme owns every fill: the gate value from ProgrammeConstants, the recorded-day count of the stage 2 rule, and the days and the weeks of the stage 3 rule. A rule string of one sentence MUST NOT end with a full stop. The two strings of the stage 2 rule are the exception: each is one sentence, and each ends with a full stop.

A pattern template MUST hold only the placeholders {n}, {m}, {slot} and {hours}. The one exception is "pattern.place", which MUST hold {n}, {m} and {place}. In a pattern template, {n}, {m} and {hours} stand for counts. A pattern template MUST NOT hold a %lld placeholder. The app MUST fill each count from a string with one %lld and plural forms, as "Catalogue rules" requires. The app MUST fill {n} from "pattern.count.group", "%lld", with the group size. The app MUST fill {m} from "pattern.count.total", "%lld starred entries", with the starred total. The app MUST fill {hours} from "pattern.count.hours", "%lld hours", with MAX_AWAKE_GAP_HOURS. The three count strings are not templates. Each of them MUST hold one %lld and no other placeholder. Ash ruled this on 7 October 2026 (r17-05). The reintroduction question MUST hold only {weekday} and {slot}.

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
- **THEN** the list holds "notrightnow.selfharm" and "notrightnow.weight" and no other id

#### Scenario: Sign-off covers the strings
- **WHEN** the team changes "opening.stage5" and does not raise the content version
- **THEN** the content test fails and reports that the bundle's hash differs from content-lock.json at the same version

### Requirement: Catalogue rules

Every string in the content bundle and in every string catalogue MUST follow these rules. The content test MUST check each rule it can check by machine. The clinical reviewer MUST check the rest at sign-off.

- Every string with a count MUST carry plural forms with the categories zero, one and other.
- Every %lld placeholder is a count. A %@ placeholder is not a count, and it needs no plural forms. In a pattern template, {n}, {m} and {hours} stand for counts, but the template itself holds no count. The app fills each of them from a string with one count, as "Every bundled string family has ids" states. Ash ruled this on 7 October 2026 (r17-05).
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
