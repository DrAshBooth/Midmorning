# content

## MODIFIED Requirements

### Requirement: Every bundled string family has ids

The content bundle MUST hold these families of reviewed strings, each string with an id. The owning capability specifies each string's text. Content bundles it. The signed catalogue keys that "Content versions" defines hold the other reviewed text.

- Cards: the ids in the card catalogue.
- Opening sentences: "opening.stage2" to "opening.stage7". Programme owns the text. "opening.stage2.remindersoff" is the line the stage 2 opening card adds when notification permission is denied: "Reminders are off, so the Home Screen widget shows your next planned time."
- Rule strings: "rule.stage2" to "rule.stage7", and more ids that start with "rule.stage2.", "rule.stage3." or "rule.stage4.". Programme owns the text. The rules of stages 2, 3 and 4 each show more than one count, so each comes from strings with one count each. The stage 2 rule is "rule.stage2", "Opens after %lld recorded days.", then "rule.stage2.count", "You have %lld.". The stage 3 rule is "rule.stage3", "Opens after %1$@, or %2$@ after your plan starts.". The app fills it from "rule.stage3.days", "%lld days on your plan", and "rule.stage3.weeks", "%lld weeks". With the default constants, the stage 3 rule reads "Opens after 7 days on your plan, or 2 weeks after your plan starts.". From the record day on which stage 2 opened, "rule.stage3.count", "You have %lld.", follows it. Before stage 3 opens, the stage 4 rule is "rule.stage4.beforeStage3", "Opens after Alternatives". From the record day on which stage 3 opened, the stage 4 rule is "rule.stage4", "Opens after your first urge outcome, or after %lld recorded days.", then "rule.stage4.count", "You have %lld.". Ash ruled the rules of stages 3 and 4 on 12 October 2026 (r24-11).
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

Programme owns every fill: the gate value from ProgrammeConstants, the recorded-day count of the stage 2 rule, the days, the weeks and the planned-day count of the stage 3 rule, and the recorded-day count of the stage 4 rule. A rule string of one sentence MUST NOT end with a full stop. The rules of stages 2, 3 and 4 are the exception. "rule.stage2", "rule.stage2.count", "rule.stage3", "rule.stage3.count", "rule.stage4" and "rule.stage4.count" are each one sentence, and each ends with a full stop. "rule.stage4.beforeStage3" has no full stop.

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
- **WHEN** the Programme screen shows the closed stage 3 with the default constants, before stage 2 opens
- **THEN** it shows the stage 3 rule, from "rule.stage3" and its other strings, as "Opens after 7 days on your plan, or 2 weeks after your plan starts."

#### Scenario: The stage 3 rule string with its count
- **WHEN** the Programme screen shows the closed stage 3 with the default constants, and three planned days count toward stage 3
- **THEN** it shows "rule.stage3" with its other strings, then "rule.stage3.count" filled with the count, as "Opens after 7 days on your plan, or 2 weeks after your plan starts. You have 3."

#### Scenario: The stage 4 rule strings
- **WHEN** the Programme screen shows the closed stage 4 with the default constants, first before stage 3 opens, and then on a day when two recorded days count toward the fallback
- **THEN** it shows "rule.stage4.beforeStage3" as "Opens after Alternatives", and then "rule.stage4" and "rule.stage4.count" as "Opens after your first urge outcome, or after 7 recorded days. You have 2."

#### Scenario: A rule string with three placeholders
- **WHEN** the bundle holds "rule.stage3" with three %lld placeholders in its text
- **THEN** the content test fails and names "rule.stage3"

#### Scenario: A rule string with two counts
- **WHEN** the bundle holds "rule.stage3" as "Opens after %1$lld days on your plan, or %2$lld weeks after your plan starts"
- **THEN** the content test fails and names "rule.stage3"

#### Scenario: The rule strings match programme
- **WHEN** the test compares the bundle's rule strings with the Programme package's Swift constants
- **THEN** "rule.stage4.beforeStage3" holds "Opens after Alternatives", "rule.stage4" holds "Opens after your first urge outcome, or after %lld recorded days.", and "rule.stage5" and "rule.stage7" each hold "Opens %lld weeks after your plan starts"

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
- A sentence MUST end with a full stop. A label MUST NOT end with a full stop. A rule string of one sentence MUST NOT end with a full stop. The rules of stages 2, 3 and 4 are the exception. Each string of those rules that a count can follow, and each of their count strings, is one sentence that ends with a full stop. "Every bundled string family has ids" names these strings. Ash ruled the rules of stages 3 and 4 on 12 October 2026 (r24-11).
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

#### Scenario: A rule string that a count can follow
- **WHEN** the bundle holds "rule.stage3" as "Opens after %1$@, or %2$@ after your plan starts." and "rule.stage6" as "Opens after taking stock"
- **THEN** the content test passes the full-stop check for both strings

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
