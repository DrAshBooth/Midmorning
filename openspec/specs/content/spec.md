# content Specification

## Purpose
Content is the set of cards the person reads at each stage, and the other reviewed strings the app shows. The team writes the cards in plain UK English and a clinical psychologist with CBT-E training reviews them. The app bundles every card, keeps which content version the person saw, and generates nothing at runtime.

## Requirements

### Requirement: Each stage has three to five cards

The content bundle MUST hold three to five cards for each of the seven stages. In stage 6, the bundle MUST hold three to five cards for each module. Each card MUST hold the fields id, stage, title, body and oneThing. A card's body MUST hold at most 500 words, so that it reads in under three minutes. A card MUST hold text and at most one in-app link. A card MUST NOT hold an image, a video or a link to a web page.

The content test is a test in the content package. The content test MUST fail when a stage has fewer than three or more than five cards. The content test MUST fail when a body has more than 500 words.

#### Scenario: A stage with four cards
- **WHEN** the bundle holds four cards for stage 3
- **THEN** the content test passes the card count for stage 3

#### Scenario: A stage with six cards
- **WHEN** the bundle holds six cards for stage 2
- **THEN** the content test fails and names stage 2

#### Scenario: A long card
- **WHEN** a card's body holds 501 words
- **THEN** the content test fails and names the card's id

#### Scenario: A card with an image
- **WHEN** a card's body holds an image reference
- **THEN** the content test fails and names the card's id

### Requirement: One in-app link on a card

A card MUST hold at most one in-app link. The link MUST open a screen of the app and nothing outside the app. The link MUST carry the name of the screen it opens, in the card's text. The content test MUST fail when a card holds two links. The content test MUST fail when a link points outside the app.

#### Scenario: Two links
- **WHEN** a card holds a link to "Feeling fat notes" and a link to "Your alternatives list"
- **THEN** the content test fails and names the card's id

#### Scenario: A web link
- **WHEN** a card holds a link to "https://example.org"
- **THEN** the content test fails and names the card's id

### Requirement: Plain UK English

Every card MUST use UK spelling. Every card MUST use plain words that a person with no clinical knowledge understands. A card MUST NOT use a word from the forbidden list. A card MUST address the person as "you". A card MUST NOT address the person as "user", "patient" or "client".

The content test MUST check UK spelling against a list of US spellings the repository holds. The clinical reviewer MUST check the reading level of every card before sign-off.

#### Scenario: UK spelling
- **WHEN** a card's body holds "realize"
- **THEN** the content test fails and names the card's id and the word

#### Scenario: How the card addresses the person
- **WHEN** a card's body holds "the user"
- **THEN** the content test fails and names the card's id

### Requirement: Every card ends with the one thing to do

Every card MUST hold one oneThing field with one sentence. The sentence MUST name one action the person can take today. The app MUST show the oneThing sentence at the end of the card, after the body. The app MUST show it under the heading "One thing to do".

The oneThing sentence MUST NOT name more than one action. The content test MUST fail when a card has an empty oneThing.

#### Scenario: The end of a card
- **WHEN** the person reads the card "How to make an entry" to the end
- **THEN** the card ends with "One thing to do" and one sentence, for example "Write down the next thing you eat within a few minutes of eating it."

#### Scenario: The one thing of "How it keeps itself going"
- **WHEN** the person reads the card "How it keeps itself going" to the end
- **THEN** the card ends with "One thing to do" and "Notice the next time a strict rule comes right before an urge."

#### Scenario: The one thing of "After a skipped meal or a binge"
- **WHEN** the person reads the card "After a skipped meal or a binge" to the end
- **THEN** the card ends with "One thing to do" and "The next planned meal happens on time, whatever happened after the last one."

#### Scenario: A card with no one thing to do
- **WHEN** a card's oneThing field is empty
- **THEN** the content test fails and names the card's id

#### Scenario: Two actions
- **WHEN** a card's oneThing reads "Plan tomorrow and set your weigh-in day."
- **THEN** the clinical reviewer sends the card back with the request for one action

### Requirement: Tone of every card

Every card MUST pass the product-rules tone question first: could a person who has just binged read this as judgement? A card MUST be matter-of-fact. A card MUST NOT cheer, praise, or scold. A card MUST NOT use medical language. A card MUST describe a lapse as a lapse.

A card MUST NOT name Fairburn, Oxford, CREDO, any book or any author. A card MUST NOT name CBT-E, CBT or any named therapy.

A card MUST NOT say that the programme "treats" anything. A card MUST NOT use "treatment", "therapy", "cure" or "recovery". A card MUST use "binge" only in "binge eating", "binge eat" and "a binge". Product-rules owns that rule. A card MUST NOT hold "binger", "bingeing" or "binge episode". A card MUST NOT compare the person to other people.

#### Scenario: Cheerleading
- **WHEN** a card's body holds "You've got this!"
- **THEN** the content test fails and names the card's id

#### Scenario: A lapse
- **WHEN** the card "A slip is a slip" describes a starred entry after weeks without one
- **THEN** it calls it a slip, states that the next planned meal happens on time, and adds no praise and no blame

#### Scenario: The word binge in a card
- **WHEN** a card's body holds "after a binge, the next planned meal still happens"
- **THEN** the content test passes the card for that phrase

#### Scenario: A forbidden form of binge
- **WHEN** a card's body holds "a binge episode"
- **THEN** the content test fails and names the card's id

### Requirement: The forbidden list

The repository MUST hold a forbidden list. The content test MUST fail when a card holds a word from it. The forbidden list MUST hold at least: "Fairburn", "Oxford", "CREDO", "CBT-E", "CBT", "treat", "treats", "treatment", "therapy", "therapist", "cure", "recovery", "disorder", "patient", "symptom", "diagnosis", "clinical", "calories", "calorie", "portion", "log", "tracker", "user", "streak", "binger", "bingeing", "binge episode", "well done", "great job", "proud", "you've got this". The list MUST NOT hold "diary" or "notes".

The content test MUST match each entry as a whole word, case-insensitive. A word is a maximal run of letters, digits, apostrophes and hyphens. An entry with a space MUST match as a run of whole words in that order.

The full forbidden list applies to the cards, the opening sentences, the rule strings and the Today card strings. It also applies to the pattern templates, every question and the alternatives examples. The content test MUST check each of those families against the full list. The content test MUST check the strings with ids support.*, gp.*, exclusion.*, notrightnow.* and gpsuggestion.* against the short list only. The short list is "Fairburn", "Oxford", "CREDO", "CBT-E", "CBT", "binger", "bingeing", "binge episode", "you've got this", "well done", "great job" and "proud".

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

### Requirement: The app bundles the cards

Every card MUST ship inside the app bundle as data. The app MUST read the cards from the bundle. The app MUST NOT fetch a card from a network.

The app MUST NOT call a language model or any generative service to write, change or summarise a card. The card text on screen MUST be equal to the bundled text, with no substitution. A card MUST NOT hold a placeholder that the app fills at runtime. Every card MUST be readable with no network.

#### Scenario: Airplane mode
- **WHEN** the device has no network and the person opens the card "Eating by the clock"
- **THEN** the app shows the full card

#### Scenario: No runtime text
- **WHEN** the literal lint runs
- **THEN** every string the app shows exists in the bundle or a string catalogue, and the lint names no file

#### Scenario: A placeholder
- **WHEN** a card's body holds "{weighInDay}"
- **THEN** the content test fails and names the card's id

### Requirement: Content versions

The content bundle MUST carry one content version, an integer that starts at 1. The bundle MUST carry one bundle hash. The bundle hash MUST be the SHA-256 of the canonical JSON of the bundle and every string catalogue. Canonical JSON MUST sort keys, use no whitespace outside strings and use UTF-8. Every card MUST carry a stable id that never changes across versions. A change to any string's text, in the bundle or in a catalogue, MUST raise the content version.

The repository MUST hold `Packages/Content/Resources/content-lock.json`. The lock MUST hold two fields, contentVersion and bundleHash. The content test MUST fail when the bundle's hash differs from the lock's and the bundle's version equals the lock's. A commit that raises the content version MUST update the lock in the same commit.

The app MUST know the content version it carries. When the app updates and the content version changes, the app MUST NOT show any message about it.

#### Scenario: A card's body changes
- **WHEN** the team changes one word in the card "The star" and does not raise the content version
- **THEN** the content test fails and reports that the bundle's hash differs from content-lock.json at the same version

#### Scenario: A catalogue string changes
- **WHEN** the team changes "Save" to "Keep" in the string catalogue and does not raise the content version
- **THEN** the content test fails and reports that the bundle's hash differs from content-lock.json at the same version

#### Scenario: The version rises with the lock
- **WHEN** one commit changes a card, raises the content version from 2 to 3, and writes the new version and hash to content-lock.json
- **THEN** the content test passes the lock check

#### Scenario: A title changes
- **WHEN** the team renames the card with id "stage1.star" from "The star" to "Felt like a binge"
- **THEN** the id stays "stage1.star" and the content version rises

#### Scenario: The bundle hash
- **WHEN** the content test computes the SHA-256 of the canonical JSON of the bundle and every string catalogue
- **THEN** it equals the bundle hash the bundle carries

#### Scenario: An update with new content
- **WHEN** the person opens the app after an update that raised the content version from 1 to 2
- **THEN** the app shows Today and no message about new content

### Requirement: Clinical sign-off per content version

The repository MUST hold one sign-off file for each content version that ships. A sign-off file MUST hold the content version, the bundle hash and the date. It MUST hold the reviewer's name, the reviewer's role and the list of ids reviewed. The reviewer MUST be a clinical psychologist with CBT-E training. The sign-off file MUST hold the reviewer's answer to the tone question for every card.

A sign-off file matches the bundle when its content version and its hash equal the bundle's. When the environment variable MIDMORNING_RELEASE is 1 and no sign-off file matches, the content test MUST fail. When MIDMORNING_RELEASE is not 1 and no sign-off file matches, the content test MUST pass. It MUST then set the "Draft" flag in the bundle. When a sign-off file matches, the content test MUST clear the "Draft" flag. The release lane MUST run the content test with MIDMORNING_RELEASE=1.

When the bundle carries the "Draft" flag, the app MUST show "Draft" at the top of every card. The team MUST NOT ship a build that shows "Draft" to any person outside the team. The archive script MUST refuse to upload a build whose bundle carries the "Draft" flag.

#### Scenario: Release without sign-off
- **WHEN** MIDMORNING_RELEASE is 1, the bundle carries content version 3, and the repository holds no sign-off file for version 3
- **THEN** the content test fails and names version 3

#### Scenario: Release with a sign-off for an older hash
- **WHEN** MIDMORNING_RELEASE is 1 and the sign-off file for version 3 holds a hash that differs from the bundle's hash
- **THEN** the content test fails and names version 3

#### Scenario: A local test run without sign-off
- **WHEN** MIDMORNING_RELEASE is not set and the repository holds no sign-off file for version 4
- **THEN** the content test passes, sets the "Draft" flag, and every card shows "Draft" at the top

#### Scenario: Sign-off present
- **WHEN** the sign-off file for version 3 holds the bundle's hash, the reviewer's name, role and date, and every id
- **THEN** the content test passes the sign-off check and no card shows "Draft"

#### Scenario: The archive script and a Draft bundle
- **WHEN** the team runs the archive script on a build whose bundle carries the "Draft" flag
- **THEN** the script stops before the upload and names the flag

### Requirement: Strings live in catalogues

Every string the person can read MUST live in a string catalogue or in the content bundle. The code MUST NOT hold such a string as a literal. The base language MUST be en-GB. The content bundle MUST be per language. V1 MUST ship en-GB only. A card view MUST hold the language of the card.

The literal lint is a test in the Content package. It MUST derive the repository root from #filePath. It MUST scan App/**/*.swift. It MUST check only a call that opens and closes on one line. It MUST fail on any string literal that is the first argument of one of six one-line calls. The six calls are Text(, Label(, Button(, .navigationTitle(, .accessibilityLabel( and .accessibilityValue(.

A literal that is a catalogue key MUST pass. `Text(verbatim:)` is the one escape. The lint MUST pass a `Text(verbatim:)` call. The lint MUST name the file and line of each failure.

A call that spans more than one line is outside the lint. The catalogue hash and the review cover those calls. The repository MUST NOT hold a literal allowlist file.

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
- **THEN** the literal lint does not check that call, and the catalogue hash and the review cover it

#### Scenario: A literal outside the six calls
- **WHEN** a file in App/ holds `let key = "entry.save"`
- **THEN** the literal lint passes that line

#### Scenario: A device in another language
- **WHEN** the device language is French
- **THEN** the app shows every string and every card in en-GB

### Requirement: The card screen and the card list

The app MUST show the cards of a stage as a list of titles, in the order the bundle gives. The list MUST NOT show a count of cards read, a percentage, a tick or a read state. A card screen MUST show the title, the body, the heading "One thing to do" and the oneThing sentence. A card screen MUST show no image. A card screen MUST show no control except "Close", Get support, the card's in-app link and the standard scroll.

The title MUST be a heading for VoiceOver. "One thing to do" MUST be a heading for VoiceOver. Text on a card MUST use system text styles. Text on a card MUST scale with Dynamic Type. The app MUST let the person open any card any number of times.

#### Scenario: The list for stage 1
- **WHEN** the person opens "Getting started" on the Programme screen
- **THEN** the app lists "Why write it down", "How to make an entry", "The star", "How it keeps itself going" and "Weighing once a week", with no tick and no count

#### Scenario: VoiceOver headings
- **WHEN** a person with VoiceOver on opens a card and moves by heading
- **THEN** VoiceOver stops at the title and at "One thing to do"

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size and opens a card
- **THEN** the card shows all text without truncation

### Requirement: The card catalogue

The content bundle at content version 1 MUST hold these cards, with these ids and titles. The clinical reviewer rewrites the titles and writes the bodies. An id MUST NOT change when its title changes. The content test MUST fail when a card id is missing from the bundle.

Stage 1, "Getting started":
- "stage1.why": "Why write it down"
- "stage1.entry": "How to make an entry"
- "stage1.star": "The star"
- "stage1.cycle": "How it keeps itself going"
- "stage1.weighin": "Weighing once a week"

Stage 2, "Regular eating":
- "stage2.clock": "Eating by the clock"
- "stage2.pattern": "Three meals and two or three snacks"
- "stage2.gap": "No gap over four hours"
- "stage2.makingup": "After a skipped meal or a binge"
- "stage2.when": "When, not what"

Stage 3, "Alternatives":
- "stage3.urges": "Urges rise and pass"
- "stage3.list": "Your alternatives list"
- "stage3.twenty": "The twenty minutes"
- "stage3.after": "After the urge"

Stage 4, "Problem solving":
- "stage4.patterns": "Patterns in the record"
- "stage4.steps": "Six steps"
- "stage4.pick": "Pick one and try it"
- "stage4.review": "Look back a week later"

Stage 5, "Taking stock":
- "stage5.sixweeks": "Six weeks in"
- "stage5.changed": "What has changed"
- "stage5.modules": "Choosing a module"

Stage 6, "Food rules" (the dieting module):
- "dieting.rules": "Food rules"
- "dieting.avoided": "Avoided foods"
- "dieting.ladder": "The ladder"
- "dieting.enough": "Eating enough"

Stage 6, "Body image" (the body image module):
- "body.checking": "Checking"
- "body.avoidance": "Avoidance"
- "body.feelingfat": "Feeling fat"
- "body.underneath": "What is underneath"

Stage 7, "Staying on track":
- "stage7.slip": "A slip is a slip"
- "stage7.plan": "Your maintenance plan"
- "stage7.signs": "Early warning signs"
- "stage7.next": "The next twelve weeks"

"stage1.cycle" is the formulation card. It MUST show how a strict rule, a gap and an urge feed each other. "stage1.entry" MUST cover writing the entry soon after eating.

"stage1.why" and "stage1.cycle" also come to the Today card slot, on the second and fourth recorded days. The Today card shows the card's title with "Read" and "Close". Programme owns when the Today card shows and what its controls do. "Read" opens the card screen below, and the app saves a card view as for any card.

"stage2.clock" MUST explain why eating by the clock breaks that cycle. "stage2.makingup" MUST cover a skipped meal and a binge alike: the next planned meal happens on time. The "Feeling fat" card MUST name the tool "Feeling fat notes".

The person sees the dieting module as "Food rules". The "dieting.*" ids MUST keep their prefix. The list heading for those cards and every card title that names the module MUST read "Food rules", never "Dieting". Dieting-module owns the module screen.

The person sees the body image module as "Body image". The list heading for the "body.*" cards MUST read "Body image". Every string that names the module MUST use "Body image", for example "Open Body image". Body-image-module owns the module screen.

"dieting.rules" MUST hold the sentence "A rule from a doctor, an allergy or your faith is not a rule to loosen. Leave those off this list." The "Food rules" module shows the same sentence above each list. Dieting-module owns that placement.

A card id present in any shipped version MUST stay in every later bundle. A card the team retires MUST carry a retired flag. The app MUST NOT show a retired card in any list or on any screen. The content test MUST fail when an id from a shipped version is missing from the bundle.

#### Scenario: Every id present
- **WHEN** the content test runs against content version 1
- **THEN** it finds all 33 ids above in the bundle

#### Scenario: A renamed card
- **WHEN** the clinical reviewer renames "stage2.gap" to "Four hours at most"
- **THEN** the id stays "stage2.gap" and the content version rises

#### Scenario: The stage 2 list
- **WHEN** the person opens "Regular eating" on the Programme screen
- **THEN** the app lists "Eating by the clock", "Three meals and two or three snacks", "No gap over four hours", "After a skipped meal or a binge" and "When, not what"

#### Scenario: A retired card
- **WHEN** content version 4 sets the retired flag on "stage3.after"
- **THEN** the bundle still holds "stage3.after" with the retired flag, and the stage 3 list shows "Urges rise and pass", "Your alternatives list" and "The twenty minutes" only

#### Scenario: A missing id
- **WHEN** the bundle lacks "stage3.twenty"
- **THEN** the content test fails and names "stage3.twenty"

#### Scenario: A shipped id removed
- **WHEN** content version 1 shipped with "stage5.changed" and the bundle for version 2 lacks it
- **THEN** the content test fails and names "stage5.changed"

### Requirement: Every bundled string family has ids

The content bundle MUST hold every reviewed string the app shows, in these families, each string with an id. The owning capability specifies each string's text. Content bundles it.

- Cards: the ids in the card catalogue.
- Opening sentences: "opening.stage2" to "opening.stage7". Programme owns the text. "opening.stage2.remindersoff" is the line the stage 2 opening card adds when notification permission is denied: "Reminders are off, so the Home Screen widget shows your next planned time."
- Rule strings: "rule.stage2" to "rule.stage7". Programme owns the text. "rule.stage2" is "Opens after %1$lld recorded days. You have %2$lld." "rule.stage3" is "Opens after %1$lld days on your plan, or %2$lld weeks after your plan starts".
- Today card strings: "todaycard.plan", "Your plan isn't set yet. It takes about two minutes."; "todaycard.plan.setup", "Set it up"; "todaycard.focus", "If you use a Focus at work, let planned meal reminders through?"; "todaycard.focus.yes", "Yes"; "todaycard.read", "Read". Programme owns the text and when each card shows.
- Pattern templates: "pattern.<name>". Problem-solving owns the text. A slot template reads "{n} of your {m} starred entries were on days when {slot} didn't happen." "pattern.place" is the one template for a custom chip: "{n} of your {m} starred entries were at {place}."
- The reintroduction question: "dieting.reintroduction", "{weekday}, {slot}: how did it go?". Dieting-module owns the text.
- The worksheet steps: "worksheet.1" to "worksheet.6". Problem-solving owns the text. "worksheet.1" is "What is the problem, exactly?"
- The check-in weeks line: "checkin.weeks", "A check-in comes at %1$lld, %2$lld and %3$lld weeks.". Staying-on-track owns the text. The app fills the three numbers from CHECK_IN_WEEKS.
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

These strings MUST follow the same version, sign-off, tone and forbidden-list rules as the cards. Every string with a count MUST follow the catalogue rules below. "rule.stage2" and "rule.stage3" MUST hold exactly the two positional placeholders their text shows. Every other rule string MUST hold at most one %lld placeholder.

Programme owns every fill: the gate value from ProgrammeConstants, the recorded-day count in "rule.stage2", and the weeks in "rule.stage3". A rule string of one sentence MUST NOT end with a full stop. "rule.stage2" is two sentences, and each ends with a full stop.

A pattern template MUST hold only the placeholders {n}, {m}, {slot} and {hours}. The one exception is "pattern.place", which MUST hold {n}, {m} and {place}. The app MUST fill {hours} from MAX_AWAKE_GAP_HOURS. The reintroduction question MUST hold only {weekday} and {slot}.

The app MUST fill {slot} with the slot label as the person typed it, and no other word. The app MUST fill {weekday} with the weekday name from the en_GB formatter. The app MUST fill {place} with the person's custom chip text and no other word. Problem-solving owns that fill.

Every other string in the bundle MUST hold only the placeholders the catalogue rules permit. Those are %lld, %@ and positional placeholders. The content test MUST fail when a string in the bundle has no id, or two strings share an id. The bundle MUST NOT hold a questionnaire from a third party.

#### Scenario: An opening sentence
- **WHEN** stage 2 opens
- **THEN** the opening card shows the bundle's "opening.stage2" text, "You can now plan when to eat. The app reminds you at each planned meal."

#### Scenario: A rule string with its numbers
- **WHEN** the Programme screen shows the closed stage 2 and the person has two recorded days
- **THEN** it shows "rule.stage2", "Opens after %1$lld recorded days. You have %2$lld.", with the gate from RECORDED_DAYS_FOR_STAGE_2 and the count, as "Opens after 5 recorded days. You have 2."

#### Scenario: The stage 3 rule string
- **WHEN** the Programme screen shows the closed stage 3 with the default constants
- **THEN** it shows "rule.stage3" as "Opens after 7 days on your plan, or 2 weeks after your plan starts"

#### Scenario: A rule string with three placeholders
- **WHEN** the bundle holds "rule.stage3" with a third placeholder in its text
- **THEN** the content test fails and names "rule.stage3"

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
- Every constant MUST enter a string through %lld, never as a literal number.
- A string with more than one placeholder MUST use positional placeholders, %1$lld, %2$@ and so on.
- Every date, time, duration and range MUST enter a string as %@, filled by the en_GB formatter.
- Text the person typed MUST enter a string unchanged.
- Every string MUST use sentence case.
- A navigation control or a card control MUST hold at most 16 characters. A notification action MUST hold at most 20. A chip or a slot label MUST hold at most 20. A widget line MUST hold at most 16. A switch label MUST hold at most 40. A state line or a Today line MUST hold at most 40. A one-line message MUST hold at most 80.
- Every string family MUST render at the AX5 text size without truncation.
- A sentence MUST end with a full stop. A label MUST NOT end with a full stop. A rule string of one sentence MUST NOT end with a full stop. "rule.stage2" is two sentences, and each ends with a full stop.
- The VoiceOver label of a control with visible text MUST equal the visible text.
- A string MUST NOT hold the bare plural "binges".
- A script MUST generate the README sign-off list from the catalogue ids. The team MUST NOT write the list by hand.

The catalogue key "about.contact" holds the Contact email that the About group shows. The `settings` capability owns the About group. Until the team sets the confirmed email, the key MUST hold the placeholder "contact@example.invalid". The content test MUST pass "about.contact" when it holds the placeholder or an email address. The sentence-case and full-stop rules MUST NOT apply to "about.contact".

#### Scenario: A count without plural forms
- **WHEN** a catalogue string holds "%lld recorded days" with no plural forms
- **THEN** the content test fails and names the string's id

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

#### Scenario: A bare plural
- **WHEN** a catalogue string holds "your binges"
- **THEN** the content test fails and names the string's id

#### Scenario: The sign-off list
- **WHEN** the team builds the README sign-off list
- **THEN** a script generates it from the catalogue ids, and the content test fails when the list and the ids differ

#### Scenario: The Contact placeholder
- **WHEN** the catalogue key "about.contact" holds "contact@example.invalid"
- **THEN** the content test passes the key and names no rule
