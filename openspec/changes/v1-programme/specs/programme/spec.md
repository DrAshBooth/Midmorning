# programme

## Purpose

The programme is the twelve-week sequence of seven stages that the person moves through. It decides which tools are open, counts pacing by recorded days and planned days, and counts weeks from the start day. It shows the person where they are without a rating, a bar or a count of consecutive days. The only count it shows is the count toward a gate, in the gate's rule string.

## ADDED Requirements

### Requirement: The seven stages and their tools

The programme has seven stages in a fixed order. The app MUST hold the stages in this order, with these titles:

1. "Getting started": the record, the weekly weigh-in and the stage's cards.
2. "Regular eating": the plan builder, per-planned-meal reminders and the plan beside the record on Today.
3. "Alternatives": the Urge button, the alternatives list, the urge timer and the urge outcome.
4. "Problem solving": pattern sentences, the worksheet, the "Worksheets" list and the worksheet review reminder.
5. "Taking stock": one taking stock session.
6. "Modules": "Food rules" and "Body image".
7. "Staying on track": the maintenance plan, reduced cadence, check-ins and restart.

Stage 3 is the PRD's "Alternatives to binge eating". The app MUST show its title as "Alternatives". Product-rules owns the rule for the word "binge".

"Food rules" is the dieting module. The app MUST show the module's name as "Food rules" everywhere the person sees it. That covers the stage 6 row, the module screen title and every string that names the module.

Dieting-module owns the module. Its capability name stays dieting-module. The app MUST show the body image module's name as "Body image" everywhere the person sees it. Body-image-module owns the module.

Each stage adds tools on top of the tools before it. A tool MUST stay open in every later stage. The app MUST NOT change the order of the stages. Each tool's own capability owns its behaviour. This capability owns only when the tool opens.

#### Scenario: Order on the Programme screen
- **WHEN** the person opens the Programme screen on day 1
- **THEN** it lists "Getting started", "Regular eating", "Alternatives", "Problem solving", "Taking stock", "Modules" and "Staying on track" in that order

#### Scenario: Earlier tools stay open
- **WHEN** stage 3 opens
- **THEN** the record, the weigh-in, the plan builder and the reminders stay open

#### Scenario: A tool before its stage
- **WHEN** stage 3 is closed
- **THEN** Today shows no Urge button and the app offers no alternatives list

### Requirement: Today is home

The app MUST open on Today at every launch, in every stage. Today is home from day 1 because the record is the core. From stage 2, Today also shows the plan beside the record. Regular-eating-plan owns the plan beside the record. The app MUST NOT open on the Programme screen, a card or an opening card.

Record owns Today's navigation bar, its bottom toolbar and their contents. The Programme screen MUST be one tap from Today, through "Programme" in the bottom toolbar. From the moment the first weekly review becomes due, the "Reviews" list MUST be one tap from Today. That tap is on "Reviews" in the bottom toolbar. Before that moment, Today shows no "Reviews" control, as weekly-review states. Weekly-review owns the list.

The settings screen MUST be one tap from Today, through "Settings" in the bottom toolbar. Get support MUST be in the navigation bar of every screen. Safeguarding owns the button.

From the end of onboarding until stage 2 opens, Today MUST show a "Getting started" line. A tap on the line MUST show the stage 1 cards. Record owns the line's place in the Today stack. When stage 2 opens, the app MUST take the line off Today. The line MUST NOT depend on the week.

#### Scenario: Launch on day 1
- **WHEN** the person opens the app for the first time after onboarding
- **THEN** the app shows Today with the "Getting started" line

#### Scenario: Launch in stage 3
- **WHEN** stage 3 is open and the person opens the app
- **THEN** the app shows Today with the plan beside the record

#### Scenario: Launch after a stage opened while the app was closed
- **WHEN** stage 5 opened at 04:00 while the app was closed and the person opens the app at 09:00
- **THEN** the app shows Today, with the opening card in the Today card slot

#### Scenario: The "Getting started" line in week 3 with stage 2 closed
- **WHEN** week 3 begins with three recorded days and stage 2 closed
- **THEN** Today still shows the "Getting started" line

#### Scenario: The "Getting started" line when stage 2 opens
- **WHEN** the person saves the entry that makes the fifth recorded day in week 1
- **THEN** Today shows no "Getting started" line from the next Today load, and the stage 1 cards stay open on the Programme screen

#### Scenario: One tap to each screen
- **WHEN** the person is on Today and the first weekly review has become due
- **THEN** one tap on "Programme", "Reviews" or "Settings" in the bottom toolbar reaches the Programme screen, the "Reviews" list or the settings screen, and one tap reaches Get support in the navigation bar

#### Scenario: Before the first weekly review
- **WHEN** the person is on Today in week 1 and no weekly review has become due
- **THEN** one tap on "Programme" or "Settings" in the bottom toolbar reaches the Programme screen or the settings screen, and the bottom toolbar shows no "Reviews"

### Requirement: Weeks count from the start day

The person picks the start day at onboarding. Onboarding owns that choice. Week 1 MUST start at the day start on the start day.

The day start comes from the "Day starts at" setting. Settings owns the setting. Its default is DEFAULT_DAY_START_HOUR, which is 04:00. Each later week MUST start seven record days after the week before.

The app MUST compute the week from the current record day, not from the clock time. The current record day comes from the device zone and the current day start. Record owns that rule. The app MUST keep counting weeks past week 12.

The app MUST NOT move the start day except through "Start week 1 again". The restart rule below owns that control. Before the start day, the app MUST treat the current record day as before week 1.

#### Scenario: Last day of week 1
- **WHEN** the start day is Monday 28 September 2026 and the current time is 23:00 on Sunday 4 October
- **THEN** the app computes week 1

#### Scenario: After midnight at the end of week 1
- **WHEN** the start day is Monday 28 September 2026 and the current time is 01:00 on Monday 5 October
- **THEN** the current record day is Sunday 4 October and the app computes week 1

#### Scenario: First day of week 2
- **WHEN** the start day is Monday 28 September 2026 and the current time is 09:00 on Monday 5 October
- **THEN** the app computes week 2

#### Scenario: Week 13
- **WHEN** the start day is Monday 28 September 2026 and the current record day is Monday 21 December
- **THEN** the app computes week 13

#### Scenario: A later day start
- **WHEN** the start day is Monday 28 September 2026, "Day starts at" is 06:00, and the current time is 05:30 on Monday 5 October
- **THEN** the current record day is Sunday 4 October and the app computes week 1

#### Scenario: Start day is tomorrow
- **WHEN** the person picked tomorrow as the start day and opens the Programme screen today
- **THEN** the app treats today as before week 1 and shows "Starts tomorrow" in place of the week line

### Requirement: Stage 2 opens after five recorded days

A recorded day is a record day with at least one entry. The app MUST count distinct recorded days from the end of onboarding. A recorded day before the start day MUST count. The days MUST NOT need to be consecutive. The app MUST open stage 2 when the count reaches RECORDED_DAYS_FOR_STAGE_2, which is 5. The app MUST count a record day as recorded from the moment it gets its first entry.

A "didn't record" day with an entry MUST count as a recorded day. Record owns that state. A "didn't record" day with no entry MUST NOT count. A paused day with an entry MUST count.

A fasting day with an entry MUST count. Record owns the fasting state. A record day without an entry MUST NOT count. The app MUST NOT open stage 2 because seven calendar days passed.

The app MUST count an entry under the record day key the store wrote at save. Record owns record day assignment. A change to the "Day starts at" setting MUST NOT move an entry to another recorded day.

#### Scenario: Five recorded days over two weeks
- **WHEN** the person saves entries on Monday, Wednesday, Friday, the next Tuesday and the next Thursday, and on no other day
- **THEN** stage 2 opens when the person saves the entry on the second Thursday

#### Scenario: Three recorded days in a week
- **WHEN** seven calendar days pass and the person saved an entry on three of them
- **THEN** stage 2 stays closed

#### Scenario: An entry saved for the previous record day
- **WHEN** the person saves an entry at 07:30 on Friday with the time 23:30 on Thursday, and Thursday had no entry before
- **THEN** the store writes Thursday as the entry's record day, and Thursday counts as a recorded day

#### Scenario: Many entries on one day
- **WHEN** the person saves ten entries on one record day
- **THEN** that day counts as one recorded day

#### Scenario: A "didn't record" day with an entry
- **WHEN** the person sets Tuesday to "didn't record" and then saves one entry for Tuesday
- **THEN** Tuesday counts as a recorded day

#### Scenario: A fasting day with an entry
- **WHEN** the person turns on "Fasting today" for Wednesday and saves one entry for Wednesday
- **THEN** Wednesday counts as a recorded day

#### Scenario: The day start changes
- **WHEN** an entry saved at 04:30 on Friday holds the record day key Friday, and the person later sets "Day starts at" to 05:00
- **THEN** the entry keeps the record day Friday and Friday still counts as a recorded day

### Requirement: Stage 3 opens after seven planned days or two weeks of regular eating

Regular-eating-plan defines a planned day. For the stage 3 count, the day MUST also be a recorded day. The app MUST count a planned day toward stage 3 when the day ends. The count MUST NOT depend on how many planned meals the person followed. A fasting day that is a planned day and a recorded day MUST count. Record owns the fasting state.

The app MUST open stage 3 when the count reaches DAYS_ON_PLAN_FOR_STAGE_3, which is 7. The days MUST NOT need to be consecutive. The app MUST NOT open stage 3 because seven calendar days passed since the person made a plan.

The app MUST also open stage 3 by a fallback count of record days. The fallback counts RECORD_DAYS_FOR_STAGE_3_FALLBACK record days from the record day on which stage 2 opened. That constant is 14. The record day on which stage 2 opened is day 1 of that count.

The fallback MUST open the stage at the day start that ends day RECORD_DAYS_FOR_STAGE_3_FALLBACK. The fallback MUST NOT need a recorded day, a planned day or a template. Whichever of the two rules comes first MUST open the stage.

The rule string for stage 3 is "Opens after %1$lld days on your plan, or %2$lld weeks after your plan starts", with no full stop. The app MUST fill %1$lld from DAYS_ON_PLAN_FOR_STAGE_3. The app MUST fill %2$lld with RECORD_DAYS_FOR_STAGE_3_FALLBACK divided by 7. RECORD_DAYS_FOR_STAGE_3_FALLBACK MUST be a multiple of 7. A test MUST check that.

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
- **WHEN** stage 3 is closed with the default constants
- **THEN** its row on the Programme screen reads "Alternatives" and "Opens after 7 days on your plan, or 2 weeks after your plan starts"

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

The app MUST also open stage 4 after RECORDED_DAYS_FOR_STAGE_4_FALLBACK recorded days with stage 3 open. That constant is 7. The app MUST count recorded days from the record day on which stage 3 opened, that day included. Whichever of the two rules comes first MUST open the stage. The rule string for stage 4 is "Opens after your first urge outcome, or a week from now", with no full stop.

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

### Requirement: Taking stock, the modules and staying on track open by week of regular eating

The app MUST count weeks of regular eating from the record day on which stage 2 opened. That day MUST be day 1 of week 1 of regular eating. Each later week of regular eating MUST start seven record days after the one before.

The app MUST open stage 5 at the start of week WEEK_OF_TAKING_STOCK of regular eating. That constant is 6. The app MUST open stage 7 at the start of week WEEK_OF_STAYING_ON_TRACK of regular eating. That constant is 10. While stage 2 is closed, stages 5 and 7 MUST stay closed.

The app MUST open stage 6 when the person completes the taking stock session. Weekly-review owns that session. The app MUST open both modules together. The app MUST NOT hide a module because taking stock recommended the other. The week gates MUST NOT depend on the state of stages 3 and 4.

The restart rule below owns the restart. A restart MUST NOT delete any StageOpened row. The engine MUST ignore a stage 5 opening whose moment is earlier than the restart moment. The engine MUST read every other stage's opening as before.

After a restart, the app MUST count weeks of regular eating from the new start day. Taking stock therefore runs again at the start of week WEEK_OF_TAKING_STOCK from the new start day. Stages 6 and 7 MUST stay open across a restart.

#### Scenario: Week 6 of regular eating begins
- **WHEN** stage 2 opened on Monday 5 October 2026 and the clock reaches 04:00 on Monday 9 November
- **THEN** stage 5 opens

#### Scenario: Week 10 of regular eating begins
- **WHEN** stage 2 opened on Monday 5 October 2026 and the clock reaches 04:00 on Monday 7 December
- **THEN** stage 7 opens

#### Scenario: A slow starter
- **WHEN** the start day was Monday 28 September 2026, the current record day is Monday 23 November and stage 2 is closed
- **THEN** stage 5 and stage 7 stay closed

#### Scenario: Taking stock recommends "Food rules"
- **WHEN** the person completes taking stock and it recommends "Food rules"
- **THEN** stage 6 opens with both "Food rules" and "Body image" open

#### Scenario: Week 10 of regular eating without taking stock
- **WHEN** week 10 of regular eating begins and the person did not complete taking stock
- **THEN** stage 7 opens and stage 6 stays closed

#### Scenario: Taking stock after a restart
- **WHEN** every stage is open, the person restarts with the start day Monday 4 January 2027, and the clock reaches 04:00 on Monday 8 February
- **THEN** the store keeps the earlier stage 5 StageOpened row, the engine ignores it, stage 5 is closed from the restart until that moment, stage 5 opens at that moment with a new StageOpened row, and stages 6 and 7 stay open throughout

### Requirement: Reading ahead is never blocked

The app MUST let the person open every card of every stage from day 1. The Programme screen MUST list every stage, open or closed. A tap on a closed stage's row MUST open its stage screen, which lists its cards. The stage screen rule below owns that screen. The app MUST NOT show a tool before its stage opens. In a closed stage, the Programme screen MUST show the opening rule in plain words in place of the tools. The Programme screen rule below states what a row shows in a build without the stage's tool.

The rule strings are, in stage order from stage 2:

- "Opens after %1$lld recorded days. You have %2$lld."
- "Opens after %1$lld days on your plan, or %2$lld weeks after your plan starts"
- "Opens after your first urge outcome, or a week from now"
- "Opens %lld weeks after your plan starts"
- "Opens after taking stock"
- "Opens %lld weeks after your plan starts"

Each rule string with a count MUST carry plural forms. Content owns the catalogue rules. The app MUST fill the gate value in each rule string from ProgrammeConstants. The stage 2 rule string shows the count toward the gate. The app MUST fill its %2$lld with the count of recorded days the stage 2 rule counts.

The app MUST show the count in the same text style as every row. The screen MUST show no bar, tick or graphic for it. A rule string of one sentence MUST NOT end with a full stop. The stage 2 rule string is two sentences, and each ends with a full stop.

#### Scenario: Stage 4 cards on day 1
- **WHEN** the person taps "Problem solving" on the Programme screen on day 1
- **THEN** the app shows the "Problem solving" stage screen with the stage's cards, no "Tools" group and no worksheet

#### Scenario: A closed stage's row
- **WHEN** stage 2 is closed and the person has two recorded days
- **THEN** its row on the Programme screen reads "Regular eating" and "Opens after 5 recorded days. You have 2."

#### Scenario: The count before any entry
- **WHEN** the person opens the Programme screen after onboarding with no entry
- **THEN** the stage 2 row reads "Opens after 5 recorded days. You have 0."

#### Scenario: A gate changes
- **WHEN** the team sets RECORDED_DAYS_FOR_STAGE_2 to 3 and the person has one recorded day
- **THEN** stage 2 opens after 3 recorded days and its rule string reads "Opens after 3 recorded days. You have 1."

### Requirement: A gate change never closes a stage

The team can change a gate constant in a later version. When a gate lowers, the app MUST open a stage whose evidence already reaches the new value. The opening moment MUST be the computed moment the evidence reached the new value, not the update moment. When a gate rises, the app MUST NOT close a stage.

The app MUST match past planned meals with the window constants the store kept with the planned day at materialisation. Regular-eating-plan owns the planned day. The change README MUST hold a dated line for every constant change, with the app version.

#### Scenario: A gate lowers
- **WHEN** the person has four recorded days, the fourth from an entry saved at 19:20 on Thursday 8 October 2026, and an update sets RECORDED_DAYS_FOR_STAGE_2 to 3
- **THEN** stage 2 is open after the update, and the opening moment in the store is the save moment of the entry that made the third recorded day

#### Scenario: A gate rises
- **WHEN** stage 2 is open with five recorded days and an update sets RECORDED_DAYS_FOR_STAGE_2 to 7
- **THEN** stage 2 stays open

#### Scenario: Window constants after an update
- **WHEN** an update changes PLANNED_MEAL_WINDOW_AFTER_MINUTES to 120 and the person opens a planned day from before the update
- **THEN** that day's planned meals match entries with the window constants the store kept with that day

#### Scenario: The README line
- **WHEN** the team changes DAYS_ON_PLAN_FOR_STAGE_3 in version 1.2
- **THEN** the change README holds a dated line that names the constant, the old value, the new value and version 1.2

### Requirement: A stage opening shows one card

When a stage opens, the app MUST show one opening card. When the build does not have the stage's tool, a later paragraph states when the card shows. The card MUST sit in the Today card slot. Record defines the Today stack. The card MUST also sit at the top of the Programme screen. The card MUST show the stage title, one opening sentence from the content bundle, and two controls, "Open" and "Close".

The card never returns after either control. Its dismiss control is therefore "Close", not "Not now".

"Open" MUST show the stage on the Programme screen. "Open" MUST also take the card off both screens. "Close" MUST take the card off both screens. The card MUST stay until the person taps one of the two controls.

The app MUST NOT add an animation, a sound or a haptic. The app MUST NOT add a number on the app icon, a notification or a colour change. The card MUST use the same text style as an entry row. The app MUST NOT show an opening card for stage 1. When two stages open at once, the app MUST show their cards one at a time, in stage order.

A stage's tool can arrive in a later app build than the stage's opening. The engine MUST report the opening when it happens, not when the tool arrives. The app MUST write the StageOpened row with the opening moment, as for any other stage. From the first launch of a build that contains the tool, the app MUST show the stage's opening card once. The app MUST NOT show the card before that launch. From that launch, the app MUST also apply the rule "No opening card after a binge in the same record day".

The opening sentences are:

- stage 2: "You can now plan when to eat. The app reminds you at each planned meal."
- stage 3: "Urge is now on Today. Set up your alternatives list when you have a few minutes."
- stage 4: "The app can now show patterns from your record. The worksheet is ready."
- stage 5: "Taking stock is ready. It takes one sitting."
- stage 6: "Both modules are open. Start with either one."
- stage 7: "Staying on track is open. Write your maintenance plan when you are ready."

The stage 2 card MUST add one line after the opening sentence when it first appears with notification permission denied. That line is "Reminders are off, so the Home Screen widget shows your next planned time." The app MUST NOT add the line when permission is granted or not determined. Reminders owns the permission state. Widgets-and-intents owns the widget's "Show next planned time" default from stage 2.

#### Scenario: Stage 2 opens with permission denied
- **WHEN** the person declined notification permission and stage 2 opens
- **THEN** the opening card reads "Regular eating", "You can now plan when to eat. The app reminds you at each planned meal." and "Reminders are off, so the Home Screen widget shows your next planned time.", with "Open" and "Close"

#### Scenario: Stage 2 opens
- **WHEN** the person saves an entry at 13:00 that makes the fifth recorded day, and the entry is not starred
- **THEN** Today shows a card that reads "Regular eating" and "You can now plan when to eat. The app reminds you at each planned meal." with "Open" and "Close", and nothing else changes

#### Scenario: Close
- **WHEN** the person taps "Close" on the opening card
- **THEN** the card leaves Today and the Programme screen, and the stage stays open

#### Scenario: Open
- **WHEN** the person taps "Open" on the stage 3 opening card
- **THEN** the app shows the "Alternatives" stage on the Programme screen and the card leaves both screens

#### Scenario: No celebration, by eye
- **WHEN** a reviewer opens stage 4 on a test device and watches Today and the Programme screen
- **THEN** the reviewer sees no animation, hears no sound, feels no haptic, sees no number on the app icon and gets no notification, and writes the result in the change README

#### Scenario: Two stages open at once
- **WHEN** stage 5 and stage 7 open at the same 04:00
- **THEN** Today shows the stage 5 card, and shows the stage 7 card after the person answers the stage 5 card

#### Scenario: A tool arrives after its stage opened
- **WHEN** stage 3 opens at 04:00 on Monday 19 October 2026 in a build without the Urge button, and the person first opens a build with it at 08:00 on Friday 6 November with no starred entry that record day
- **THEN** the store holds the stage 3 opening moment 04:00 on Monday 19 October 2026, the app shows no stage 3 opening card before that launch, and Today shows the card at that launch

#### Scenario: A tool arrives on a record day with a starred entry
- **WHEN** stage 3 opened in a build without the Urge button, the person saves a starred entry at 07:30 on Friday 6 November 2026, and first opens a build with the Urge button at 08:00
- **THEN** Today shows no stage 3 opening card on Friday 6 November, and shows it the first time Today appears after 04:00 on Saturday 7 November

### Requirement: The card's answer is kept in the record

When the person taps "Open" or "Close", the store MUST write an Answer row of kind card answer in Record.store. The row MUST hold the card id, the answer, the moment and its own changedAt. A card whose Answer row exists on any device MUST NOT show again. Data-and-privacy owns sync and the Answer model. A suggestion card's answer is an Answer row of kind card answer with the template id as its key. Problem-solving owns the suggestion card.

The same rule applies to every other card this capability puts in the card slot. The stage 1 cards on Today have the keys "stage1.why" and "stage1.cycle". The plan card has the key "plancard.3" or "plancard.10". The Focus card has the key "focuscard". The app MUST write the row on any control of those cards.

While the first import after sync turns on is running, the app MUST show no card. During that import the app MUST NOT write an opening moment.

#### Scenario: A card answered on another device
- **WHEN** the person taps "Close" on the stage 3 opening card on one device, and the Answer row syncs to a second device
- **THEN** the second device shows no stage 3 opening card

#### Scenario: Today during the first import
- **WHEN** the person turns sync on, the first import is running, and Today appears
- **THEN** Today shows no card, and the store gets no new opening moment until the import completes

#### Scenario: The answer row
- **WHEN** the person taps "Open" on the stage 2 opening card at 09:12 on Monday 5 October 2026
- **THEN** Record.store holds an Answer row of kind card answer with the card id, the answer "Open" and the moment 09:12 on Monday 5 October 2026

### Requirement: No opening card after a binge in the same record day

The app MUST NOT show an opening card after a starred entry in the same record day. The app MUST NOT show an opening card after an "I binged" urge outcome in the same record day. This rule applies to every Today load that follows the entry or the outcome. The card MUST wait for the next record day.

The stage MUST open at once. Only the card waits. The app MUST show the card the first time Today appears on the next record day. The same rule applies to the stage 1 cards on Today, the plan card and the Focus card below. This rule does not cover the stage 7 lapse card, the maintenance plan card that `staying-on-track` shows. That card alone can show in the same record day as the starred entry or the outcome. Decision 100 sets this exception.

#### Scenario: The fifth recorded day ends with a starred entry
- **WHEN** the person saves a starred entry at 22:10 that makes the fifth recorded day
- **THEN** stage 2 opens, Today shows no opening card that record day, and the card appears the first time Today appears after 04:00

#### Scenario: A starred entry before the stage opens
- **WHEN** the person saves a starred entry at 09:00 and stage 3 opens at 04:00 the next day
- **THEN** the stage 3 card appears at the first Today load after 04:00

#### Scenario: A binge outcome then Today
- **WHEN** the person saves the outcome "I binged" at 23:00 and returns to Today at 23:05
- **THEN** stage 4 is open and Today shows no opening card until the next record day

### Requirement: Two stage 1 cards come to Today

On the second recorded day, the app MUST show the card "Why write it down" in the Today card slot. On the fourth recorded day, the app MUST show the card "How it keeps itself going" there. Content owns both cards, with the ids "stage1.why" and "stage1.cycle".

The card in the slot MUST show the card's title and two controls, "Read" and "Close". The card MUST use the same text style as an entry row. Record defines the Today stack and the card slot.

A record day becomes the second or fourth recorded day when the person saves its first entry. The app MUST show the card from the first Today load after that save. When that entry is starred, the card MUST wait for the next record day. When stage 2 is open, the app MUST NOT show either card.

"Read" MUST open the card screen that content defines. "Read" MUST also take the card off Today. "Close" MUST take the card off Today. Neither card returns after either control. The app MUST NOT show a stage 1 opening card. These two cards are not opening cards.

#### Scenario: The second recorded day
- **WHEN** the person saves the first entry of the second recorded day at 12:40, and the entry is not starred
- **THEN** Today shows a card that reads "Why write it down" with "Read" and "Close"

#### Scenario: The fourth recorded day
- **WHEN** the person saves the first entry of the fourth recorded day
- **THEN** Today shows a card that reads "How it keeps itself going" with "Read" and "Close"

#### Scenario: Read
- **WHEN** the person taps "Read" on the "Why write it down" card
- **THEN** the app opens the card "Why write it down", the store writes a card view, and the card leaves Today

#### Scenario: Close
- **WHEN** the person taps "Close" on the "How it keeps itself going" card
- **THEN** the card leaves Today, and the card stays open on the Programme screen

#### Scenario: A starred entry makes the second recorded day
- **WHEN** the person saves a starred entry at 21:00 as the first entry of the second recorded day
- **THEN** Today shows no card that record day, and shows "Why write it down" the first time Today appears after 04:00

#### Scenario: Stage 2 opens first
- **WHEN** RECORDED_DAYS_FOR_STAGE_2 is 3 and the person reaches the fourth recorded day with the "How it keeps itself going" card unanswered
- **THEN** Today shows no "How it keeps itself going" card

### Requirement: A card when the plan is not set

The plan card shows while the store holds no Template row. Regular-eating-plan owns the templates. The record day on which stage 2 opened is day 0. The app MUST show the plan card in the Today card slot on day 3. The app MUST show it again on day 10 when the store still holds no Template row.

The card reads "Your plan isn't set yet. It takes about two minutes." with two controls, "Set it up" and "Close". Content bundles that text. The card MUST use the same text style as an entry row.

The app MUST show the card from the first Today load on or after day 3. The second showing MUST start from the first Today load on or after day 10. When a Template row exists at that load, the app MUST NOT show the card. When the person saves a template while the card shows, the app MUST take the card off Today. The app MUST then write no Answer row.

"Set it up" MUST open the plan builder at "Weekday plan". "Set it up" MUST also take the card off Today. "Close" MUST take the card off Today. Each of the two cards returns no more after either control.

#### Scenario: Three record days without a template
- **WHEN** stage 2 opened on Monday 5 October 2026, the store holds no Template row, and Today appears at 08:00 on Thursday 8 October
- **THEN** Today shows a card that reads "Your plan isn't set yet. It takes about two minutes." with "Set it up" and "Close"

#### Scenario: Set it up
- **WHEN** the person taps "Set it up"
- **THEN** the app opens the plan builder at "Weekday plan", and the card leaves Today

#### Scenario: Ten record days without a template
- **WHEN** the person tapped "Close" on the card on Thursday 8 October 2026, the store still holds no Template row, and Today appears on Thursday 15 October
- **THEN** Today shows the card again with "Set it up" and "Close"

#### Scenario: A template before day 10
- **WHEN** the person saves a weekday template on Saturday 10 October 2026 and Today appears on Thursday 15 October
- **THEN** Today shows no plan card

#### Scenario: A template before day 3
- **WHEN** stage 2 opened on Monday 5 October 2026 and the person saves a weekday template on Tuesday 6 October
- **THEN** Today shows no plan card on Thursday 8 October or on Thursday 15 October

#### Scenario: The first Today load after a missed day
- **WHEN** the store holds no Template row, the person did not open the app on Thursday 8 October 2026, and Today appears on Saturday 10 October
- **THEN** Today shows the plan card

### Requirement: The Focus card after stage 2 opens

The Focus card is due on the record day after the record day on which stage 2 opened. The app MUST show it in the Today card slot. The card reads "If you use a Focus at work, let planned meal reminders through?" with two controls, "Yes" and "Close". Content bundles that text. The card MUST use the same text style as an entry row. The app MUST show the card from the first Today load on or after that record day.

"Yes" MUST turn on "Break through Focus for planned meals" on this device. Reminders owns that switch. "Yes" MUST then take the card off Today. "Close" MUST take the card off Today. "Close" MUST NOT change any switch. The card returns no more after either control.

When "Break through Focus for planned meals" is already on, the app MUST NOT show the card. When notification permission is denied, the app MUST NOT show the card.

#### Scenario: The day after stage 2 opened
- **WHEN** stage 2 opened on Monday 5 October 2026 and Today appears at 07:50 on Tuesday 6 October
- **THEN** Today shows a card that reads "If you use a Focus at work, let planned meal reminders through?" with "Yes" and "Close"

#### Scenario: Yes
- **WHEN** the person taps "Yes" on the Focus card
- **THEN** "Break through Focus for planned meals" is on in the Reminders group, and the card leaves Today

#### Scenario: Close
- **WHEN** the person taps "Close" on the Focus card
- **THEN** "Break through Focus for planned meals" stays off, and the card leaves Today

#### Scenario: The switch is already on
- **WHEN** "Break through Focus for planned meals" is on when the record day after stage 2 opened begins
- **THEN** Today shows no Focus card

#### Scenario: Permission denied
- **WHEN** the person declined notification permission and the record day after stage 2 opened begins
- **THEN** Today shows no Focus card

### Requirement: The Programme screen shows where the person is

The Programme screen's title MUST be "Programme". The screen MUST show one week line at the top, for example "Week 3". The screen MUST list the seven stages in order. The row that carries the "Now" marker MUST show "Now" after its title. The "Now" marker MUST sit on the lowest open stage whose next stage is closed. When every stage is open, the marker MUST sit on stage 7.

After a restart, the "Now" marker moves. It MUST sit on the lowest stage whose week gate has not passed since the restart. When every week gate has passed since the restart, the rule above applies again.

A row of an open stage MUST show its title and its tools. The stage 6 row MUST name the dieting module "Food rules". A row of a closed stage MUST show its title and its opening rule. A tap on a row MUST push the stage screen for that stage. The stage screen rule below owns that screen.

A build can lack a stage's tool, as the opening card rule above states. In such a build, the stage's row MUST show "Comes in a later version" under its title. That line MUST replace the row's tools or its opening rule. The row MUST NOT carry the "Now" marker. In its place, the marker MUST sit on the nearest earlier open stage whose tool the build has. A tap on the row MUST NOT open anything. Decision 102 sets this rule. Ash ruled it on 25 September 2026.

The screen MUST NOT show a progress bar, a percentage or a tick. The count toward a gate appears only inside the gate's rule string, as plain text. The screen MUST NOT show a count of entries or starred entries. The screen MUST NOT show any text about time since the last entry or the last visit. Every row MUST have the same visual weight, open or closed.

The screen MUST show "Start week 1 again" under the stage rows, at all times after onboarding. The restart rule below owns what it does.

#### Scenario: Day 1
- **WHEN** the person opens the Programme screen on the start day
- **THEN** it shows "Week 1", "Getting started" with "Now", each other row with its rule string, and "Start week 1 again"

#### Scenario: A slow starter in week 3
- **WHEN** the person is in week 3 with three recorded days
- **THEN** the screen shows "Week 3", "Getting started" with "Now", and "Regular eating" with "Opens after 5 recorded days. You have 3."

#### Scenario: A slow starter in week 8
- **WHEN** week 8 begins with stage 2 closed and four recorded days
- **THEN** the screen shows "Week 8", "Getting started" with "Now", "Regular eating" with "Opens after 5 recorded days. You have 4.", and "Taking stock" with "Opens 6 weeks after your plan starts"

#### Scenario: Stage 5 open with stage 3 closed
- **WHEN** stages 1, 2 and 5 are open and stages 3, 4, 6 and 7 are closed
- **THEN** the screen shows "Regular eating" with "Now" and no "Now" on any other row

#### Scenario: The stage 6 row
- **WHEN** stage 6 is open
- **THEN** its row names "Food rules" and "Body image", and no row holds the word "Dieting"

#### Scenario: Every stage open
- **WHEN** stage 7 is open and every earlier stage is open
- **THEN** the screen shows "Staying on track" with "Now" and no rule string on any row

#### Scenario: The marker after a restart
- **WHEN** every stage was open, the person restarted with the start day Monday 4 January 2027, and the current record day is Monday 18 January
- **THEN** the screen shows "Taking stock" with "Now" and "Opens 6 weeks after your plan starts", and no "Now" on any other row

#### Scenario: Stages without their tools in the build
- **WHEN** the build holds the tools of stages 1 and 2 only, and stages 1 to 4 are open
- **THEN** "Regular eating" carries "Now", the rows of stages 3 to 7 each show "Comes in a later version" and no "Now", and a tap on the "Alternatives" row opens nothing

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

The screen MUST NOT show a progress bar, a percentage, a tick or a count. The one exception is the count inside the stage 2 rule string. The screen MUST show Get support in the navigation bar. `safeguarding` owns the button.

The title and "Tools" MUST be headings for VoiceOver. Each tool row MUST be one accessibility element, with its visible text as its label. Text on the screen MUST use system text styles. That text MUST scale with Dynamic Type.

#### Scenario: The stage 1 screen
- **WHEN** the start day is Monday 28 September 2026, the current record day is Wednesday 30 September, and the person taps "Getting started" on the Programme screen
- **THEN** the app pushes a screen titled "Getting started" with the line "Opened in week 1", the stage 1 card list, and a "Tools" group with one row, "Weigh-in"

#### Scenario: A closed stage's screen
- **WHEN** stage 2 is closed, the person has two recorded days, and taps "Regular eating" on the Programme screen
- **THEN** the screen's title is "Regular eating", its line reads "Opens after 5 recorded days. You have 2.", it lists the stage 2 cards, and it shows no "Tools" group

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

### Requirement: Start week 1 again

The Programme screen MUST show "Start week 1 again" at all times after onboarding. One tap MUST open the start-day choice with "Today", "Tomorrow" and "Cancel". When the person picks a day, the app MUST set it as the new start day. Week 1 MUST start from it. "Cancel" MUST close the choice and keep the start day. "Cancel" MUST NOT restart. The app MUST keep the values from a re-screen that ran before the choice, as `safeguarding` states in "Re-screening at a restart".

The app MUST count record days from the record day of the last screening. The `safeguarding` capability defines the last screening. The store keeps its moment in the Profile field `askedAt`. Within 84 record days of the last screening, the app MUST ask nothing else. More than 84 record days after the last screening, the app MUST run safeguarding's re-screening first. The start-day choice MUST come after it.

The restart MUST keep every entry, plan, list, worksheet, weigh-in and maintenance plan. Every open stage MUST stay open. The restart MUST NOT delete or write any StageOpened row.

The restart MUST write the restart moment to its Settings key. The engine reads it as restartAt. The engine then ignores a stage 5 opening earlier than that moment, as the stage engine rule states. The "Now" marker then moves as the Programme screen rule states.

Staying-on-track's "Restart the programme?" at a check-in is a shortcut to this control. Staying-on-track states what a restart does to the finish, the check-ins and the reminders.

#### Scenario: Restart today
- **WHEN** the person taps "Start week 1 again" on Friday 15 January 2027, 40 record days after the last screening, and picks "Today"
- **THEN** the app asks nothing else, the start day is Friday 15 January, the Programme screen shows "Week 1", and every entry, plan, list and worksheet stays

#### Scenario: Restart tomorrow
- **WHEN** the person taps "Start week 1 again" on Friday 15 January 2027 and picks "Tomorrow"
- **THEN** the start day is Saturday 16 January, and the app treats Friday as before week 1

#### Scenario: Cancel
- **WHEN** the person taps "Start week 1 again" and then "Cancel"
- **THEN** the start day is unchanged

#### Scenario: A restart in week 1
- **WHEN** the person taps "Start week 1 again" on the third day after onboarding and picks "Today"
- **THEN** the start day is that day, and the recorded days before it still count toward stage 2

#### Scenario: More than 84 record days after the last screening
- **WHEN** the last screening was at onboarding on Monday 28 September 2026, the person restarted with no re-screen on Monday 30 November, 63 record days later, and taps "Start week 1 again" on Tuesday 22 December, 85 record days after that screening and 22 record days after that restart
- **THEN** the app runs the re-screening that safeguarding defines before the start-day choice

#### Scenario: Stages after a restart
- **WHEN** stages 1 to 7 are open and the person restarts with the start day Monday 4 January 2027
- **THEN** the store keeps every StageOpened row, stages 1 to 4, 6 and 7 stay open, and stage 5 is closed until week 6 of regular eating from the new start day

### Requirement: A pure stage engine with stored openings as input

The stage engine MUST be a pure function of its inputs. The inputs MUST be exactly these:

- startDay
- currentRecordDay; the caller derives it from the device zone and the current day start, as record defines
- dayStart, the day start in force; the caller reads it from the "Day starts at" setting
- constants, a ProgrammeConstants value
- now, the current moment; the caller reads the clock
- the openings in the store, every StageOpened row the Reconciler returns
- restartAt, the moment of the last restart, or none; the restart rule below owns the restart
- entries as facts: id, record day, starred; the record day is the key the store wrote at save
- planned-day facts
- urge-outcome facts
- the taking stock completion
- the card answers, the Answer rows of kind card answer
- finishDate

The same inputs MUST give the same result. A stage MUST be open when the store holds an opening moment for it that the engine reads. A stage MUST also be open when the engine computes an opening for it. When the engine computes an opening the store lacks, the app MUST write that moment to the store.

The engine MUST ignore an opening in the store whose moment is later than now. The engine MUST ignore a stage 5 opening whose moment is earlier than restartAt. An ignored opening MUST NOT open its stage. The engine MUST NOT delete an ignored opening. The app MUST NOT delete it either.

The engine MUST report each computed opening with its moment. For a week or day gate, that moment MUST be the day start that ended the gate. For an entry or outcome gate, it MUST be the save moment of the entry or outcome that met it. The app MUST write that computed moment. The app MUST NOT write the current time as an opening moment.

The engine MUST read only facts dated after the last opening moment in the store. Facts dated before that moment MUST NOT change the result. The engine MUST NOT read the clock, the store or the network by itself.

#### Scenario: Stored moment without the entries
- **WHEN** the store holds an opening moment for stage 2 and the entries hold two recorded days
- **THEN** the engine reports stage 2 open

#### Scenario: A computed opening
- **WHEN** the store holds no opening moment for stage 2 and the entries hold five recorded days
- **THEN** the engine reports stage 2 open and the app writes the opening moment to the store

#### Scenario: The scan is bounded
- **WHEN** the store holds an opening moment for stage 3 at 04:00 on Monday 12 October 2026 and the engine computes stage 4
- **THEN** entries, planned days and urge outcomes dated before the stage 3 opening in the store do not change the stage 4 result

#### Scenario: A computed moment is the day start that ended the gate
- **WHEN** the day start is the default, the seventh planned day ends at 04:00 on Monday 12 October 2026, and the person opens the app at 09:15 that day
- **THEN** the store holds the stage 3 opening moment 04:00 on Monday 12 October 2026, not 09:15

#### Scenario: A computed moment is the save moment
- **WHEN** the person saves the entry that makes the fifth recorded day at 13:02 on Tuesday 6 October 2026
- **THEN** the store holds the stage 2 opening moment 13:02 on Tuesday 6 October 2026

#### Scenario: The same inputs twice
- **WHEN** the engine runs twice with the same inputs
- **THEN** both runs report the same stage state

#### Scenario: A future-dated opening
- **WHEN** the store holds a stage 5 opening at 04:00 on Monday 9 November 2026 and now is 10:00 on Tuesday 3 November 2026
- **THEN** the engine ignores that opening, reports stage 5 closed, and the row stays in the store

#### Scenario: A stage 5 opening before the restart
- **WHEN** the store holds a stage 5 opening at 04:00 on Monday 9 November 2026 and restartAt is 09:00 on Monday 4 January 2027
- **THEN** the engine ignores that opening and computes stage 5 from the new start day

### Requirement: The app keeps the stage state

The app MUST keep the start day and the moment each stage opened in the store. Once a stage opens, it MUST stay open. There are two exceptions: the restart's stage 5 rule above and the clock guard below. In both, the engine ignores a row on read. Nothing deletes it.

The app MUST NOT close a stage when the person deletes an entry, a plan or an urge outcome. The stage state MUST survive the app closing and opening again. The stage state MUST sync with the record; data-and-privacy owns sync.

The store MUST keep each opening as a StageOpened row with its own changedAt. The row's key MUST be the stage. When a stage has more than one StageOpened row, the app MUST use the earliest moment the engine reads. The app MUST NOT delete a StageOpened row, and the app MUST NOT write a deleted flag on one. Data-and-privacy owns the Reconciler, which never deletes a row on read.

The device clock can move back past an opening moment in the store. The engine MUST then ignore that StageOpened row while its moment is later than now. The store MUST keep the row. The engine MUST then compute the opening again from the facts. When the clock passes the row's moment again, the engine MUST read the row as before.

Delete-all MUST delete the stage state with everything else. Data-and-privacy owns Delete-all. The app MUST NOT write the stage state to the system log. The stage state MUST leave the device only through sync.

#### Scenario: Entries deleted after stage 2 opened
- **WHEN** stage 2 is open and the person deletes entries until two recorded days remain
- **THEN** stage 2 stays open

#### Scenario: The first urge outcome deleted
- **WHEN** stage 4 is open and the person deletes the only urge outcome
- **THEN** stage 4 stays open

#### Scenario: Restart of the app
- **WHEN** stage 3 is open and the person closes the app and opens it again
- **THEN** stage 3 is open

#### Scenario: Delete-all
- **WHEN** the person taps Delete-all
- **THEN** the start day and every stage's open moment leave the store with the record

#### Scenario: The opening stays in the store
- **WHEN** stage 3 opens
- **THEN** the app writes the StageOpened row, and writes nothing about the opening to the system log

#### Scenario: Two devices open one stage
- **WHEN** one device holds a StageOpened row for stage 2 at 13:02 on Tuesday 6 October 2026 and a second device holds one for stage 2 at 18:40 the same day, and they sync
- **THEN** each device reports stage 2 open from 13:02 on Tuesday 6 October 2026

#### Scenario: The clock moves back past an opening
- **WHEN** the store holds a stage 5 opening at 04:00 on Monday 9 November 2026 and the device clock moves back to Tuesday 3 November
- **THEN** the store keeps that StageOpened row, the engine ignores it until the clock passes its moment, and stage 5 opens again at 04:00 on Monday 9 November

### Requirement: Resume after an absence

When the person returns after any absence, the app MUST resume in the same stage state. The app MUST count the week from the start day as before. The app MUST NOT show any text about the absence. The app MUST NOT reset a recorded-day count or a planned-day count because of the absence.

The one-tap restart that keeps the plan and lists is "Start week 1 again". The restart rule below owns it. The app MUST let staying-on-track read every stage's state.

#### Scenario: Three weeks away
- **WHEN** the person last opened the app in week 2 with four recorded days and opens it in week 5
- **THEN** the app shows Today, the Programme screen shows "Week 5", stage 2 is closed and the four recorded days still count

#### Scenario: Away past week 6 of regular eating
- **WHEN** stage 2 opened on Monday 5 October 2026, the person last opened the app on 20 October and opens it on 15 November
- **THEN** stage 5 is open and its opening card shows once

### Requirement: Accessibility of the Programme screen

Each stage row MUST be one accessibility element. The row's label MUST hold the title. Then it MUST hold "Now" when the row carries the marker. Then it MUST hold the rule string or "Comes in a later version" when the row shows one. A comma and a space MUST separate the parts.

Every control on the Programme screen and the opening card MUST have a VoiceOver label. The label of a control with visible text MUST equal the visible text. "Open", "Close", "Read", "Set it up", "Yes" and "Start week 1 again" MUST have those labels.

Text on the Programme screen and the opening card MUST use system text styles. That text MUST scale with Dynamic Type. Meaning on the Programme screen MUST NOT depend on colour alone. The Programme screen MUST show Get support in the navigation bar. Safeguarding owns the button.

#### Scenario: Label of the stage with the marker
- **WHEN** VoiceOver reads the row of the open stage "Regular eating" that carries the "Now" marker
- **THEN** it reads "Regular eating, Now"

#### Scenario: Label of a closed stage
- **WHEN** VoiceOver reads the row of the closed stage "Alternatives"
- **THEN** it reads "Alternatives, Opens after 7 days on your plan, or 2 weeks after your plan starts"

#### Scenario: Label of the stage 2 row with its count
- **WHEN** VoiceOver reads the row of the closed stage "Regular eating" and the person has two recorded days
- **THEN** it reads "Regular eating, Opens after 5 recorded days. You have 2."

#### Scenario: Label of a row without its tool in the build
- **WHEN** VoiceOver reads the "Problem solving" row in a build without the stage 4 tool
- **THEN** it reads "Problem solving, Comes in a later version"

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the Programme screen and the opening card show all text without truncation
## MODIFIED Requirements

### Requirement: The constants live in one value

The app MUST hold every programme constant in one value type, ProgrammeConstants. ProgrammeConstants MUST have a `.default` value. The `.default` value MUST hold these names and values:

- DEFAULT_DAY_START_HOUR = 4
- PROGRAMME_WEEKS = 12
- MIN_HEIGHT_CM = 100
- MAX_HEIGHT_CM = 250
- MIN_WEIGHT_KG = 30
- RECORDED_DAYS_FOR_STAGE_2 = 5
- DAYS_ON_PLAN_FOR_STAGE_3 = 7
- RECORD_DAYS_FOR_STAGE_3_FALLBACK = 14
- RECORDED_DAYS_FOR_STAGE_4_FALLBACK = 7
- WEEK_OF_TAKING_STOCK = 6
- WEEK_OF_STAYING_ON_TRACK = 10
- MAX_AWAKE_GAP_HOURS = 4
- MAX_OTHER_REMINDERS_PER_DAY = 2
- SNOOZE_MINUTES = 15 or 30
- MAX_SNOOZES = 2
- ROLLING_AVERAGE_WEEKS = 4
- URGE_TIMER_MINUTES = 20
- DETERIORATION_WEEKS = 3
- CHECK_IN_WEEKS = 4, 8, 12
- PATTERN_WINDOW_DAYS = 28
- PATTERN_MIN_STARRED = 5
- PATTERN_MIN_GROUP = 3
- LOCK_GRACE_SECONDS = 0, 30, 120 or 300; the default is 0
- PLANNED_MEAL_WINDOW_BEFORE_MINUTES = 60
- PLANNED_MEAL_WINDOW_AFTER_MINUTES = 90
- REMINDER_HORIZON_DAYS = 6

Every capability MUST read its constant from ProgrammeConstants. The code MUST NOT repeat a constant's value as a literal elsewhere. The type MUST live in the `Constants` target, not in the UI. `Constants` is a leaf target that `Record`, `Plan` and `Programme` import. A test MUST check each value of `.default`.

LOCK_GRACE_SECONDS is a set of four values. App-lock owns the "Lock after" setting that picks one. Its default is 0.

Every threshold test MUST construct a modified ProgrammeConstants value. A test MUST NOT edit `.default`.

DEFAULT_DAY_START_HOUR is the default of the "Day starts at" setting. Settings owns the setting. Every capability that uses the record day MUST read the day start from the setting, not from the constant. The constant MUST NOT stand in for the setting anywhere.

DEFAULT_DAY_START_HOUR MUST stay 4 in every version. A test MUST assert that DEFAULT_DAY_START_HOUR is 4. The team MUST keep that test in every version.

#### Scenario: The values
- **WHEN** the test suite runs
- **THEN** a test reads each constant from ProgrammeConstants.default and checks its value

#### Scenario: The lock grace set
- **WHEN** the test suite runs
- **THEN** a test reads LOCK_GRACE_SECONDS from ProgrammeConstants.default and checks that it holds 0, 30, 120 and 300, with 0 as the default

#### Scenario: A threshold test
- **WHEN** a test checks that stage 2 opens after 3 recorded days
- **THEN** the test constructs a ProgrammeConstants value with RECORDED_DAYS_FOR_STAGE_2 = 3 and passes it to the engine, and `.default` still holds 5

#### Scenario: The default day start never changes
- **WHEN** a version sets DEFAULT_DAY_START_HOUR to 5
- **THEN** the test that asserts DEFAULT_DAY_START_HOUR is 4 fails

#### Scenario: A capability reads the day start from the setting
- **WHEN** "Day starts at" is 05:00 and the app computes the current record day
- **THEN** the app uses 05:00 as the day start, and DEFAULT_DAY_START_HOUR still holds 4

#### Scenario: A capability reads a constant
- **WHEN** the urge timer starts
- **THEN** it reads URGE_TIMER_MINUTES from ProgrammeConstants and runs for 20 minutes

