# programme

## MODIFIED Requirements

### Requirement: Stage 3 opens after seven planned days or two weeks of regular eating

Regular-eating-plan defines a planned day. For the stage 3 count, the day MUST also be a recorded day. The app MUST count a planned day toward stage 3 when the day ends. The count MUST NOT depend on how many planned meals the person followed. A fasting day that is a planned day and a recorded day MUST count. Record owns the fasting state.

The app MUST open stage 3 when the count reaches DAYS_ON_PLAN_FOR_STAGE_3, which is 7. The days MUST NOT need to be consecutive. The app MUST NOT open stage 3 because seven calendar days passed since the person made a plan.

The app MUST also open stage 3 by a fallback count of record days. The fallback counts RECORD_DAYS_FOR_STAGE_3_FALLBACK record days from the record day on which stage 2 opened. That constant is 14. The record day on which stage 2 opened is day 1 of that count.

The fallback MUST open the stage at the day start that ends day RECORD_DAYS_FOR_STAGE_3_FALLBACK. The fallback MUST NOT need a recorded day, a planned day or a template. Whichever of the two rules comes first MUST open the stage.

The rule string for stage 3 is "Opens after %1$lld days on your plan, or %2$lld weeks after your plan starts", with no full stop. It shows two counts, so it MUST come from strings with one count each, as `content` requires in "Catalogue rules". The app MUST fill %1$lld from DAYS_ON_PLAN_FOR_STAGE_3. The app MUST fill %2$lld with RECORD_DAYS_FOR_STAGE_3_FALLBACK divided by 7. RECORD_DAYS_FOR_STAGE_3_FALLBACK MUST be a multiple of 7. A test MUST check that.

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

### Requirement: Taking stock, the modules and staying on track open by week of regular eating

The app MUST count weeks of regular eating from the record day on which stage 2 opened. That day MUST be day 1 of week 1 of regular eating. Each later week of regular eating MUST start seven record days after the one before.

The app MUST open stage 5 at the start of week WEEK_OF_TAKING_STOCK of regular eating. That constant is 6. The app MUST open stage 7 at the start of week WEEK_OF_STAYING_ON_TRACK of regular eating. That constant is 10. While stage 2 is closed, stages 5 and 7 MUST stay closed.

The app MUST open stage 6 when the person completes the taking stock session. Weekly-review owns that session. The app MUST open both modules together. The app MUST NOT hide a module because taking stock recommended the other. The week gates MUST NOT depend on the state of stages 3 and 4.

The restart rule below owns the restart. A restart MUST NOT delete any StageOpened row. The engine MUST ignore a stage 5 opening whose moment is earlier than the restart moment. The engine MUST read every other stage's opening as before.

After a restart, the app MUST count weeks of regular eating from the later of two days: the new start day and the record day on which stage 2 opened. Taking stock therefore runs again at the start of week WEEK_OF_TAKING_STOCK from that day. So taking stock always comes after five full weeks of regular eating with the default constants. Stages 6 and 7 MUST stay open across a restart. Ash ruled this on 26 September 2026 (r14-02).

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

#### Scenario: A restart before stage 2 opens
- **WHEN** the person restarts with the start day Thursday 1 October 2026 while stage 2 is closed, and stage 2 opens on Thursday 8 October
- **THEN** the app counts weeks of regular eating from Thursday 8 October, and stage 5 opens at 04:00 on Thursday 12 November, not on Thursday 5 November

### Requirement: Reading ahead is never blocked

The app MUST let the person open every card of every stage from day 1. The Programme screen MUST list every stage, open or closed. A tap on a closed stage's row MUST open its stage screen, which lists its cards. The stage screen rule below owns that screen. The app MUST NOT show a tool before its stage opens. In a closed stage, the Programme screen MUST show the opening rule in plain words in place of the tools. The Programme screen rule below states what a row shows in a build without the stage's tool.

The rule strings are, in stage order from stage 2:

- "Opens after %1$lld recorded days. You have %2$lld."
- "Opens after %1$lld days on your plan, or %2$lld weeks after your plan starts"
- "Opens after your first urge outcome, or a week from now"
- "Opens %lld weeks after your plan starts"
- "Opens after taking stock"
- "Opens %lld weeks after your plan starts"

Each rule string with a count MUST carry plural forms. The stage 2 and stage 3 rule strings each show two counts, so each MUST come from strings with one count each. Content owns the catalogue rules. The app MUST fill the gate value in each rule string from ProgrammeConstants. The stage 2 rule string shows the count toward the gate. The app MUST fill its %2$lld with the count of recorded days the stage 2 rule counts.

The app MUST show the count in the same text style as every row. The screen MUST show no bar, tick or graphic for it. A rule string of one sentence MUST NOT end with a full stop. The stage 2 rule string is two sentences, and each ends with a full stop.

#### Scenario: A closed stage's row
- **WHEN** stage 2 is closed and the person has two recorded days
- **THEN** its row on the Programme screen reads "Regular eating" and "Opens after 5 recorded days. You have 2."

#### Scenario: The count before any entry
- **WHEN** the person opens the Programme screen after onboarding with no entry
- **THEN** the stage 2 row reads "Opens after 5 recorded days. You have 0."

#### Scenario: A gate changes
- **WHEN** the team sets RECORDED_DAYS_FOR_STAGE_2 to 3 and the person has one recorded day
- **THEN** stage 2 opens after 3 recorded days and its rule string reads "Opens after 3 recorded days. You have 1."

### Requirement: A pure stage engine with stored openings as input

The stage engine MUST be a pure function of its inputs. The inputs MUST be exactly these:

- startDay
- currentRecordDay; the caller derives it from the device zone and the current day start, as record defines
- dayStart, the day start in force; the caller reads it from the "Day starts at" setting
- constants, a ProgrammeConstants value
- now, the current moment; the caller reads the clock
- the openings in the store, every StageOpened row the Reconciler returns, each with its moment and its record day key
- restartAt, the moment of the last restart, or none; the restart rule below owns the restart
- entries as facts: id, record day, starred; the record day is the key the store wrote at save
- planned-day facts
- urge-outcome facts
- the taking stock completion
- the card answers, the Answer rows of kind card answer
- finishDate

The same inputs MUST give the same result. A stage MUST be open when the store holds an opening moment for it that the engine reads. A stage MUST also be open when the engine computes an opening for it. When the engine computes an opening the store lacks, the app MUST write that moment to the store.

When the app writes a StageOpened row, it MUST also write the record day key of the opening moment into the row. The app MUST compute that key with the day start in force when it writes the row. The engine MUST read the record day on which a stage opened from that key. The engine MUST NOT compute that record day again from the moment with dayStart. An older row can have no record day key. For such a row, the engine MUST compute the record day from the moment with dayStart, as before. Ash ruled this on 26 September 2026 (r14-03).

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

#### Scenario: The opening row holds its record day
- **WHEN** the person saves the entry that makes the fifth recorded day at 04:30 on Friday 9 October 2026, with the day start 04:00
- **THEN** the app writes the StageOpened row for stage 2 with the moment 04:30 on Friday 9 October and the record day key Friday 9 October

#### Scenario: The day start changes after an opening
- **WHEN** the StageOpened row for stage 2 holds the moment 04:30 on Friday 9 October 2026 and the record day key Friday 9 October, and the person later sets "Day starts at" to 05:00
- **THEN** the engine reads Friday 9 October as the record day on which stage 2 opened, not Thursday 8 October

#### Scenario: An older row with no record day key
- **WHEN** the StageOpened row for stage 2 holds the moment 04:30 on Friday 9 October 2026 and no record day key, and the day start in force is 05:00
- **THEN** the engine computes Thursday 8 October from the moment, as the record day on which stage 2 opened
