# programme

## MODIFIED Requirements

### Requirement: Stage 3 opens after seven planned days or two weeks of regular eating

Regular-eating-plan defines a planned day. For the stage 3 count, the day MUST also be a recorded day. The app MUST count a planned day toward stage 3 when the day ends. The count MUST NOT depend on how many planned meals the person followed. A fasting day that is a planned day and a recorded day MUST count. Record owns the fasting state.

The app MUST open stage 3 when the count reaches DAYS_ON_PLAN_FOR_STAGE_3, which is 7. The days MUST NOT need to be consecutive. The app MUST NOT open stage 3 because seven calendar days passed since the person made a plan.

The app MUST also open stage 3 by a fallback count of record days. The fallback counts RECORD_DAYS_FOR_STAGE_3_FALLBACK record days from the record day on which stage 2 opened. That constant is 14. The record day on which stage 2 opened is day 1 of that count.

The fallback MUST open the stage at the day start that ends day RECORD_DAYS_FOR_STAGE_3_FALLBACK. The fallback MUST NOT need a recorded day, a planned day or a template. Whichever of the two rules comes first MUST open the stage.

With the default constants, the stage 3 rule reads "Opens after 7 days on your plan, or 2 weeks after your plan starts.", with a full stop. It shows two counts, so it MUST come from strings with one count each, as `content` requires in "Catalogue rules". The rule string is "Opens after %1$@, or %2$@ after your plan starts.". The app MUST fill %1$@ from "%lld days on your plan", with DAYS_ON_PLAN_FOR_STAGE_3 as the count. The app MUST fill %2$@ from "%lld weeks", with RECORD_DAYS_FOR_STAGE_3_FALLBACK divided by 7 as the count. RECORD_DAYS_FOR_STAGE_3_FALLBACK MUST be a multiple of 7. A test MUST check that.

From the record day on which stage 2 opened, the rule MUST also show the count toward the gate. The app MUST show "You have %lld." after the rule, joined by one space. The app MUST fill %lld with the planned days that count toward stage 3 by the rule above. Before stage 2 opens, the app MUST show the rule with its full stop and no count. "Reading ahead is never blocked" states the strings. Ash ruled this on 12 October 2026 (r24-11).

#### Scenario: Seven planned days over ten days
- **WHEN** seven of the next ten record days are planned days with at least one entry each
- **THEN** stage 3 opens at the day start that ends the seventh of those days, 04:00 with the default setting

#### Scenario: Two weeks with three planned days
- **WHEN** stage 2 opened on Monday 5 October 2026 and the person has three planned days by Sunday 18 October
- **THEN** stage 3 opens at 04:00 on Monday 19 October, and the opening moment in the store is 04:00 on Monday 19 October

#### Scenario: Seven planned days before the two weeks
- **WHEN** stage 2 opened on Monday 5 October 2026 and Tuesday 13 October is the seventh planned day with an entry
- **THEN** stage 3 opens at 04:00 on Wednesday 14 October

#### Scenario: No template in two weeks
- **WHEN** stage 2 opened on Monday 5 October 2026 and the store holds no Template row on Monday 19 October
- **THEN** stage 3 opens at 04:00 on Monday 19 October

#### Scenario: The stage 3 rule string
- **WHEN** stage 2 and stage 3 are closed with the default constants
- **THEN** the stage 3 row on the Programme screen reads "Alternatives" and "Opens after 7 days on your plan, or 2 weeks after your plan starts.", with no count

#### Scenario: The stage 3 rule with its count
- **WHEN** stage 2 opened on Monday 5 October 2026, Monday 5, Tuesday 6 and Wednesday 7 October are planned days with an entry, and the person opens the Programme screen at 09:00 on Thursday 8 October
- **THEN** the stage 3 row reads "Alternatives" and "Opens after 7 days on your plan, or 2 weeks after your plan starts. You have 3."

#### Scenario: A planned day with every planned meal skipped
- **WHEN** a planned day has six planned meals, the person answers "Skipped" to all six, and saves one entry at 22:00
- **THEN** that day counts toward stage 3

#### Scenario: A planned day with no entry
- **WHEN** a record day is a planned day and has no entry
- **THEN** that day does not count toward stage 3

#### Scenario: A fasting day on the plan
- **WHEN** a record day is a planned day, the person turns on "Fasting today" for it, and saves one entry at 20:00
- **THEN** that day counts toward stage 3

#### Scenario: A copied plan with no entry
- **WHEN** the app copied the plan to Friday and the person saved no entry for Friday
- **THEN** Friday does not count toward stage 3

#### Scenario: Set plans with no entries
- **WHEN** the person taps "Save" in "Today's plan" on each of six record days after stage 2 opened and saves no entry
- **THEN** none of those days counts toward stage 3, and stage 3 stays closed

### Requirement: Stage 4 opens after the first urge outcome or seven recorded days

The app MUST open stage 4 when the store saves the first urge outcome. Urge-toolkit owns the outcome. Any of the three outcomes MUST open the stage. The app MUST NOT treat one outcome differently from another for this rule. A timer that starts without an outcome MUST NOT open the stage.

The app MUST also open stage 4 after RECORDED_DAYS_FOR_STAGE_4_FALLBACK recorded days with stage 3 open. That constant is 7. The app MUST count recorded days from the record day on which stage 3 opened, that day included. Whichever of the two rules comes first MUST open the stage.

Before stage 3 opens, the stage 4 rule string is "Opens after Alternatives", with no full stop. From the record day on which stage 3 opened, the stage 4 rule is "Opens after your first urge outcome, or after %lld recorded days." then "You have %lld.". The app MUST fill the first %lld with RECORDED_DAYS_FOR_STAGE_4_FALLBACK. The app MUST fill the second %lld with the recorded days that count toward that fallback. The app MUST show the two strings joined by one space. "Reading ahead is never blocked" states the strings. Ash ruled this on 12 October 2026 (r24-11).

#### Scenario: The stage 4 rule before stage 3 opens
- **WHEN** stage 2 is open, stage 3 is closed, and the person opens the Programme screen
- **THEN** the stage 4 row reads "Problem solving" and "Opens after Alternatives"

#### Scenario: The stage 4 rule with its count
- **WHEN** stage 3 opened at 04:00 on Monday 12 October 2026, the person saved entries on Monday 12 and Tuesday 13 October and no urge outcome, and opens the Programme screen at 20:00 on Tuesday 13 October
- **THEN** the stage 4 row reads "Problem solving" and "Opens after your first urge outcome, or after 7 recorded days. You have 2."

#### Scenario: The first outcome is "It passed"
- **WHEN** the person taps Urge and saves the outcome "It passed"
- **THEN** stage 4 opens

#### Scenario: The first outcome is "I binged"
- **WHEN** the person taps Urge and saves the outcome "I binged" at 21:30
- **THEN** stage 4 opens, and its opening card waits for the next record day

#### Scenario: A timer with no outcome
- **WHEN** the person taps Urge, closes the app and saves no outcome
- **THEN** stage 4 stays closed

#### Scenario: Seven recorded days without an urge outcome
- **WHEN** stage 3 opened on Monday 12 October 2026 and the person saves an entry on each day up to Sunday 18 October and no urge outcome
- **THEN** stage 4 opens when the person saves the first entry on Sunday 18 October

#### Scenario: An outcome before the seventh day
- **WHEN** stage 3 opened on Monday 12 October 2026 and the person saves the outcome "I ate as planned" on Wednesday 14 October
- **THEN** stage 4 opens on Wednesday 14 October

### Requirement: Reading ahead is never blocked

The app MUST let the person open every card of every stage from day 1. The Programme screen MUST list every stage, open or closed. A tap on a closed stage's row MUST open its stage screen, which lists its cards. The stage screen rule below owns that screen. The app MUST NOT show a tool before its stage opens. In a closed stage, the Programme screen MUST show the opening rule in plain words in place of the tools. The Programme screen rule below states what a row shows in a build without the stage's tool.

The rule strings are, in stage order from stage 2:

- stage 2: "Opens after %lld recorded days." then "You have %lld."
- stage 3: "Opens after %1$@, or %2$@ after your plan starts.", filled from "%lld days on your plan" and "%lld weeks". From the record day on which stage 2 opened, "You have %lld." follows it.
- stage 4: "Opens after Alternatives" before stage 3 opens. From the record day on which stage 3 opened, "Opens after your first urge outcome, or after %lld recorded days." then "You have %lld."
- stage 5: "Opens %lld weeks after your plan starts"
- stage 6: "Opens after taking stock"
- stage 7: "Opens %lld weeks after your plan starts"

Each string with a count MUST carry plural forms. A string holds at most one count, so the rules of stages 2, 3 and 4 each come from more than one string. Content owns the catalogue rules. The app MUST fill each gate value from ProgrammeConstants. The rules of stages 2, 3 and 4 also show the count toward the gate, in "You have %lld.". For stage 2, the app MUST fill that %lld with the recorded days that the stage 2 rule counts. For stage 3, the app MUST fill it with the planned days that the stage 3 rule counts. For stage 4, the app MUST fill it with the recorded days that the fallback of the stage 4 rule counts. The app MUST show a rule and its count joined by one space. Ash ruled the counts of stages 3 and 4 on 12 October 2026 (r24-11). This follows ruling r3-05 (decision 32), which showed the count toward a gate in the rule string.

The app MUST show the count in the same text style as every row. The screen MUST show no bar, tick or graphic for it. A rule string of one sentence MUST NOT end with a full stop. The rules of stages 2, 3 and 4 are the exception. Each string of those rules that a count can follow is one sentence that ends with a full stop, and so is "You have %lld.". So the stage 3 rule ends with a full stop also before stage 2 opens, when it shows no count. "Opens after Alternatives" has no full stop.

#### Scenario: A closed stage's row
- **WHEN** stage 2 is closed and the person has two recorded days
- **THEN** its row on the Programme screen reads "Regular eating" and "Opens after 5 recorded days. You have 2."

#### Scenario: The count before any entry
- **WHEN** the person opens the Programme screen after onboarding with no entry
- **THEN** the stage 2 row reads "Opens after 5 recorded days. You have 0."

#### Scenario: The rules of stages 3 and 4 before stage 2 opens
- **WHEN** the person opens the Programme screen after onboarding with no entry
- **THEN** the stage 3 row reads "Opens after 7 days on your plan, or 2 weeks after your plan starts." and the stage 4 row reads "Opens after Alternatives", and neither shows a count

#### Scenario: A gate changes
- **WHEN** the team sets RECORDED_DAYS_FOR_STAGE_2 to 3 and the person has one recorded day
- **THEN** stage 2 opens after 3 recorded days and its rule string reads "Opens after 3 recorded days. You have 1."

### Requirement: The stage screen

A tap on a stage row on the Programme screen MUST push the stage screen for that stage. The Programme screen rule above states the one exception, a row that shows "Comes in a later version". The stage screen's title MUST be the stage title. Decision 93 sets this screen. Ash ruled it on 25 September 2026.

Under the title, the screen MUST show one line. For a closed stage, the line MUST be the stage's rule string. For an open stage, the line MUST be "Opened in week %lld". The app MUST fill %lld with the week of the record day on which the stage opened. For stage 1, that record day is the start day. When that record day or the current record day is before week 1, the screen MUST show no line.

Under the line, the screen MUST show the stage's card list. `content` owns the card list and the card screen.

For an open stage, the screen MUST show a "Tools" group under the card list. For a closed stage, the screen MUST NOT show the group. The group MUST hold one row per tool of the stage. The rows are, by stage number:

1. "Weigh-in", which opens the weigh-in screen that `weigh-in` owns.
2. "Plan", which opens the plan builder at "Weekday plan", as "Set it up" on the plan card does. `regular-eating-plan` owns the plan builder.
3. "Alternatives list", which opens the alternatives list setup that `urge-toolkit` owns.
4. "Problem solving", which opens the Problem solving screen that `problem-solving` owns.
5. "Taking stock", which opens the taking stock session that `weekly-review` owns, as its row in the "Reviews" list opens it.
6. "Food rules" and "Body image", which open the module screens that `dieting-module` and `body-image-module` own.
7. "Staying on track", which opens the maintenance plan that `staying-on-track` owns.

A tap on a tool row MUST open that tool's screen. Each tool's own capability owns what its screen shows.

The screen MUST NOT show a progress bar, a percentage, a tick or a count. The exceptions are the counts inside the rule strings of stages 2, 3 and 4, as "Reading ahead is never blocked" states. Ash ruled the counts of stages 3 and 4 on 12 October 2026 (r24-11). The screen MUST show Get support in the navigation bar. `safeguarding` owns the button.

The title and "Tools" MUST be headings for VoiceOver. Each tool row MUST be one accessibility element, with its visible text as its label. Text on the screen MUST use system text styles. That text MUST scale with Dynamic Type.

#### Scenario: The stage 1 screen
- **WHEN** the start day is Monday 28 September 2026, the current record day is Wednesday 30 September, and the person taps "Getting started" on the Programme screen
- **THEN** the app pushes a screen titled "Getting started" with the line "Opened in week 1", the stage 1 card list, and a "Tools" group with one row, "Weigh-in"

#### Scenario: A closed stage's screen
- **WHEN** stage 2 is closed, the person has two recorded days, and taps "Regular eating" on the Programme screen
- **THEN** the screen's title is "Regular eating", its line reads "Opens after 5 recorded days. You have 2.", it lists the stage 2 cards, and it shows no "Tools" group

#### Scenario: The stage 4 screen with its count
- **WHEN** stage 3 opened at 04:00 on Monday 12 October 2026, the person saved entries on Monday 12 and Tuesday 13 October and no urge outcome, and taps "Problem solving" on the Programme screen on Tuesday 13 October
- **THEN** the screen's title is "Problem solving", its line reads "Opens after your first urge outcome, or after 7 recorded days. You have 2.", and it shows no "Tools" group

#### Scenario: An open stage's screen
- **WHEN** the start day is Monday 28 September 2026, stage 2 opened on Monday 5 October, and the person taps "Regular eating"
- **THEN** the screen shows "Regular eating", the line "Opened in week 2", the stage 2 cards, and a "Tools" group with one row, "Plan"

#### Scenario: A tool row
- **WHEN** stage 2 is open and the person taps "Plan" on the "Regular eating" stage screen
- **THEN** the plan builder opens at "Weekday plan"

#### Scenario: The stage 1 screen before week 1
- **WHEN** the person picked tomorrow as the start day and taps "Getting started" today
- **THEN** the screen shows no line under the title, the stage 1 card list, and a "Tools" group with "Weigh-in"

#### Scenario: A stage that opened before a restart
- **WHEN** stage 2 opened on Monday 5 October 2026, the person restarted with the start day Monday 4 January 2027, and taps "Regular eating" on Wednesday 6 January
- **THEN** the screen shows no line under the title, the stage 2 card list, and a "Tools" group with "Plan"

#### Scenario: Get support on the stage screen
- **WHEN** the person opens the stage screen of any stage
- **THEN** the navigation bar shows Get support

#### Scenario: VoiceOver on the stage screen
- **WHEN** a person using VoiceOver opens the "Getting started" stage screen in week 2
- **THEN** VoiceOver reads "Getting started" as a heading, then "Opened in week 1", then the card titles, then "Tools" as a heading, then "Weigh-in"

### Requirement: Accessibility of the Programme screen

Each stage row MUST be one accessibility element. The row's label MUST hold the title. Then it MUST hold "Now" when the row carries the marker. Then it MUST hold the rule string or "Comes in a later version" when the row shows one. A comma and a space MUST separate the parts. The rule of stage 2, 3 or 4 can be two sentences, the rule and its count. The label then holds both sentences, as the row shows them. Ash ruled the counts of stages 3 and 4 on 12 October 2026 (r24-11).

Every control on the Programme screen and the opening card MUST have a VoiceOver label. The label of a control with visible text MUST equal the visible text. "Open", "Close", "Read", "Set it up", "Yes" and "Start week 1 again" MUST have those labels.

Text on the Programme screen and the opening card MUST use system text styles. That text MUST scale with Dynamic Type. Meaning on the Programme screen MUST NOT depend on colour alone. The Programme screen MUST show Get support in the navigation bar. Safeguarding owns the button.

#### Scenario: Label of the stage with the marker
- **WHEN** VoiceOver reads the row of the open stage "Regular eating" that carries the "Now" marker
- **THEN** it reads "Regular eating, Now"

#### Scenario: Label of a closed stage
- **WHEN** stage 2 is closed and VoiceOver reads the row of the closed stage "Alternatives"
- **THEN** it reads "Alternatives, Opens after 7 days on your plan, or 2 weeks after your plan starts."

#### Scenario: Label of the stage 2 row with its count
- **WHEN** VoiceOver reads the row of the closed stage "Regular eating" and the person has two recorded days
- **THEN** it reads "Regular eating, Opens after 5 recorded days. You have 2."

#### Scenario: Label of a row without its tool in the build
- **WHEN** VoiceOver reads the "Problem solving" row in a build without the stage 4 tool
- **THEN** it reads "Problem solving, Comes in a later version"

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the Programme screen and the opening card show all text without truncation
