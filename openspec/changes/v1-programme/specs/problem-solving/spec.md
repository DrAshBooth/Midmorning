# problem-solving

## Purpose

Problem solving is the stage 4 tool. The app finds patterns in the person's starred entries and urges, and states each one as a plain sentence with the numbers filled in. The person works a pattern through with a six-step worksheet, keeps the worksheet in the "Worksheets" list, and reviews it a week later.

## ADDED Requirements

### Requirement: Problem solving opens at stage 4

The `programme` capability opens stage 4 and owns its opening rule. Before stage 4 opens, the app MUST NOT compute a pattern sentence. Before stage 4 opens, the app MUST NOT show a pattern sentence, the suggestion card or the worksheet. The app MUST let the person read the stage 4 cards while stage 4 is closed. The `content` capability owns the cards.

The person reads the stage 4 cards on the "Problem solving" stage screen, which `programme` owns in "The stage screen". For a closed stage, that screen shows the cards and no "Tools" group. So the person cannot reach the Problem solving screen before stage 4 opens. Ash set the stage screen in decision 93 on 25 September 2026.

After stage 4 opens, the "Problem solving" row in the "Tools" group of that stage screen MUST open the Problem solving screen. The screen's title MUST be "Problem solving". The screen MUST show its parts in this order from the top:

- the window line, when the screen shows a pattern sentence
- the pattern sentences, each with its "Work it through" control under it
- the "New worksheet" control
- the heading "Worksheets", when the list holds a worksheet
- the "Worksheets" list

The Problem solving screen MUST show Get support. The `safeguarding` capability owns that button. The suggestion card and the worksheet review reminder each open a worksheet, as their requirements state. Every part of problem solving MUST work with no network.

From stage 4, the current day heading's menu on Today MUST also offer "New worksheet". The heading also offers it as a custom action. `record` owns the menu and states the item in "A new worksheet from the day heading's menu". The item MUST open a new worksheet with no linked sentence, as "New worksheet" on the Problem solving screen does. Ash ruled this on 12 October 2026 (r23-08).

#### Scenario: Before stage 4 opens
- **WHEN** stage 4 is closed and the person taps "Problem solving" on the Programme screen
- **THEN** the "Problem solving" stage screen shows the stage 4 cards and no "Tools" group, and the app shows no pattern sentence, no suggestion card and no worksheet control

#### Scenario: After stage 4 opens
- **WHEN** stage 4 opens after the urge outcome "It passed" and the person taps "Problem solving" in the "Tools" group of the "Problem solving" stage screen
- **THEN** the screen titled "Problem solving" shows "New worksheet", the "Worksheets" list and Get support

#### Scenario: Stage 4 opens by the recorded-day rule
- **WHEN** stage 4 opens after seven recorded days with stage 3 open and no urge outcome
- **THEN** the "Tools" group of the "Problem solving" stage screen holds "Problem solving", and the Problem solving screen works as after an urge outcome

#### Scenario: No network
- **WHEN** the device has no network connection
- **THEN** the app computes the pattern sentences and saves a worksheet

#### Scenario: New worksheet from Today
- **WHEN** stage 4 is open, the person taps "New worksheet" in the current day heading's menu, and then taps "Done"
- **THEN** the worksheet opened as a sheet over Today with no linked sentence, and "Done" returns to Today

#### Scenario: The order of the screen
- **WHEN** stage 4 is open, the after 20:00 group holds 5 of 7 starred entries, the Friday group holds 4 of 7, no other group meets the minimum, and the person has one worksheet
- **THEN** the screen shows "From the last 28 days", then "5 of your 7 starred entries were after 20:00." with "Work it through", then "4 of your 7 starred entries were on a Friday." with "Work it through", then "New worksheet", the heading "Worksheets" and the worksheet's row

### Requirement: The pattern window and the minimum data

The pattern window is the PATTERN_WINDOW_DAYS = 28 record days that end with the current record day. The starred total is the number of starred entries in the pattern window. A pattern group is a set of starred entries in the window that share one dimension value.

The app MUST NOT show a pattern sentence when the starred total is below PATTERN_MIN_STARRED = 5. The app MUST show a sentence for a group only when the group holds at least PATTERN_MIN_GROUP = 3 entries. The group MUST also hold more than half of the starred total. The `programme` capability names PATTERN_WINDOW_DAYS, PATTERN_MIN_STARRED and PATTERN_MIN_GROUP in ProgrammeConstants. The app MUST NOT show any text about the absence of a pattern.

The pattern window counts back from the current record day only. "Start week 1 again" MUST NOT change the pattern window. It MUST NOT delete a card answer row of a suggestion card. `programme` owns the restart in "Start week 1 again". The app MUST read an entry's star from the winning version of the entry. An entry that the person deletes or unstars MUST leave every group at the next computation.

Urges are a second source of pattern sentences in the same pattern window. Each source has its own total and its own minimum. "Pattern sentences from urges" states the urge total, its minimum and the urge groups. Ash ruled this on 12 October 2026 (r23-09).

#### Scenario: A restart keeps the window
- **WHEN** the pattern window holds seven starred entries, five after 20:00, and the person restarts with the start day today
- **THEN** the screen still shows "5 of your 7 starred entries were after 20:00.", and Today shows no card for the after 20:00 template when the person closed it before the restart

#### Scenario: An entry unstarred
- **WHEN** the after 20:00 group holds 5 of 7 starred entries, and the person turns the star off on one of the five
- **THEN** the next computation gives 4 of 6 starred entries for the after 20:00 group

#### Scenario: Four starred entries
- **WHEN** the pattern window holds four starred entries, all after 20:00
- **THEN** the Problem solving screen shows no pattern sentence and no text about the absence of one

#### Scenario: Seven starred entries, five after 20:00
- **WHEN** the pattern window holds seven starred entries and five of them have a time between 20:00 and 03:59
- **THEN** the screen shows "5 of your 7 starred entries were after 20:00."

#### Scenario: Seven starred entries, three after 20:00
- **WHEN** the pattern window holds seven starred entries and three of them have a time between 20:00 and 03:59
- **THEN** the screen shows no sentence for the after 20:00 group

#### Scenario: Starred entries outside the window
- **WHEN** the record holds six starred entries from 40 days ago and two starred entries in the pattern window
- **THEN** the screen shows no pattern sentence

### Requirement: The pattern dimensions

The app MUST place a starred entry in one time band by its entry time. The bands have fixed edges. The before 12:00 band runs from 04:00 to 11:59. The between 12:00 and 17:00 band runs from 12:00 to 16:59. The between 17:00 and 20:00 band runs from 17:00 to 19:59. The after 20:00 band runs from 20:00 to 03:59. The edge at 04:00 is PATTERN_NIGHT_END_HOUR = 4. The `programme` capability names PATTERN_NIGHT_END_HOUR in ProgrammeConstants. That constant is not the day start.

The entry time is the clock time at the UTC offset that the store kept with the entry. `record` owns that offset in "The app keeps the entry's UTC offset and creation moment". The app MUST NOT move an entry to another band after a change of the device zone. "Day starts at" MUST NOT change the band of an entry, at the save or later. So an entry at 09:30 goes in the before 12:00 band, also when "Day starts at" is 10:00.

The record day of an entry is the record day key the store wrote with the entry at save. The `record` capability owns that key. The app MUST read the saved key. The app MUST NOT compute an entry's record day again from its time. The day of week of a starred entry is the weekday of its record day. The weekend group holds the starred entries whose record day is a Saturday or a Sunday.

A Where group holds the starred entries with one chip, fixed or custom. The fixed chips are "Home", "Work", "Out" and "Travelling". The app MUST build a group from a custom chip by the same minimum as any group.

The gap before a starred entry is the time from the previous entry in the same record day. When no earlier entry exists in that record day, the gap before is unknown. The app MUST NOT count an entry with an unknown gap before in the long-gap group. The long-gap group holds the starred entries with a gap before over MAX_AWAKE_GAP_HOURS = 4 hours.

A day with the state fasting, "paused" or "didn't record" counts no gap. The app MUST NOT count an entry on such a day in the long-gap group. The gap band of `record` leaves out the same days. The `record` capability owns these states. Every other group still counts the entry.

There is one missed-slot group per slot. A slot is skipped on a record day when three things are true. The day's resolved plan holds the slot. The winning answer of the slot's planned meal is "Skipped". No entry matches the planned meal, by its window or by "That was it". This is how Today shows the planned meal, as `regular-eating-plan` and `data-and-privacy` state. The App target MUST give the skipped slots of each record day to the pattern engine as facts.

A missed-slot group holds the starred entries on the record days where that slot is skipped. An entry MUST count in the missed-slot group of every skipped slot on its record day. The `regular-eating-plan` capability owns the "Skipped" answer. A combined group holds the starred entries in one time band and one missed-slot group.

Urges have the same dimensions, except Where. "Pattern sentences from urges" states how the app places an urge in each group. Ash ruled this on 12 October 2026 (r23-09).

#### Scenario: A zone change
- **WHEN** a starred entry was saved at 21:30 in London, and the person later opens the Problem solving screen in New York
- **THEN** the app places the entry in the after 20:00 band

#### Scenario: The day start changes later
- **WHEN** a starred entry has the time 03:30 on Friday 25 September and the saved record day key Thursday 24 September, and the person later sets "Day starts at" to 03:00
- **THEN** the app keeps the entry in the after 20:00 band and in the Thursday group

#### Scenario: A late day start
- **WHEN** "Day starts at" is 10:00, and a starred entry has the time 09:30 on Friday 25 September and the saved record day key Thursday 24 September
- **THEN** the app places it in the before 12:00 band and in the Thursday group

#### Scenario: An early day start
- **WHEN** "Day starts at" is 03:00, and a starred entry has the time 03:30 on Friday 25 September and the saved record day key Friday 25 September
- **THEN** the app places it in the after 20:00 band and in the Friday group

#### Scenario: A starred entry after midnight
- **WHEN** a starred entry has the time 00:30 on Friday 25 September and the saved record day key Thursday 24 September
- **THEN** the app places it in the after 20:00 band and in the Thursday group, and does not compute the record day again

#### Scenario: The first entry of a record day
- **WHEN** a starred entry at 07:30 is the first entry of its record day
- **THEN** the app counts it in the starred total and not in the long-gap group

#### Scenario: A long gap before
- **WHEN** a record day has an entry at 12:40 and a starred entry at 19:00
- **THEN** the app counts the starred entry in the long-gap group

#### Scenario: A long gap on a fasting day
- **WHEN** a record day with the state fasting has an entry at 12:40 and a starred entry at 19:00
- **THEN** the app counts the starred entry in the starred total and its time band, and not in the long-gap group

#### Scenario: Long gaps on paused and "didn't record" days
- **WHEN** one record day with the state "paused" and one with the state "didn't record" each have an entry at 12:40 and a starred entry at 19:00
- **THEN** the app counts both starred entries in the starred total and in their time band, and neither in the long-gap group

#### Scenario: A custom chip
- **WHEN** four of the seven starred entries in the pattern window have the custom chip "Mum's house"
- **THEN** the app builds a Where group of four entries for "Mum's house"

#### Scenario: A missed lunch
- **WHEN** a starred entry at 21:15 is on a record day where lunch has the answer "Skipped"
- **THEN** the app counts it in the missed-lunch group and in the combined after 20:00 and missed-lunch group

#### Scenario: Two skipped slots on one day
- **WHEN** a starred entry at 21:15 is on a record day where lunch and mid-afternoon both have the answer "Skipped"
- **THEN** the app counts it in the missed-lunch group and in the missed-mid-afternoon group

#### Scenario: A skip that an entry beats
- **WHEN** lunch at 13:00 on a record day has the answer "Skipped", an entry at 13:20 matches lunch's window, and a starred entry at 21:15 is on that day
- **THEN** the app does not count the starred entry in the missed-lunch group, because Today shows the entry beside lunch

### Requirement: Pattern sentence templates

Every pattern sentence MUST come from a bundled template that the clinical reviewer signed off. The app MUST fill only a template's placeholders. These are the group size, and the starred total or the urge total. A missed-slot or combined template also holds the slot label. The custom chip template also holds the chip's text. The long-gap template also holds the gap hours.

The app MUST fill {slot} with the slot's label. The label is the Settings row `slot.label.<index>`, as the person typed it. When that row is missing or empty, the label is the slot's default label from the catalogue, as `regular-eating-plan` states. The app MUST NOT change the label's case or add a word to it. The app MUST NOT generate any other word at runtime. The `product-rules` capability states the "No AI at runtime" rule.

The group size {n}, the starred total {m} and the gap hours {hours} are counts. A template MUST NOT hold a count itself. Each count comes from a string with one count, as `content` requires in "Catalogue rules". The app MUST fill {n} from "pattern.count.group", "%lld", with the group size. The app MUST fill {m} from "pattern.count.total", "%lld starred entries", with the starred total. The app MUST fill {hours} from "pattern.count.hours", "%lld hours", with MAX_AWAKE_GAP_HOURS. Each of these strings MUST carry plural forms. The one form of "pattern.count.total" reads "%lld starred entry", and the one form of "pattern.count.hours" reads "%lld hour". Ash ruled this on 7 October 2026 (r17-05).

An urge sentence uses the same templates. For an urge sentence, {m} is the urge total. The app MUST fill it from "pattern.count.urges", "%lld urges", with the plural forms that `content` requires. The one form reads "%lld urge". "Pattern sentences from urges" states the rest. Ash ruled this on 12 October 2026 (r23-09).

The templates use plural verbs, for example "were". The group minimum, PATTERN_MIN_GROUP = 3 in "The pattern window and the minimum data", keeps {n} at 3 or more. So the verbs agree with {n}, and no sentence reads "1 of your 1".

The bundle MUST hold one template per time band, one per weekday and one for the weekend. The bundle MUST hold one template per fixed chip and one for a custom chip. The bundle MUST hold one for the long-gap group. The bundle MUST hold one missed-slot template with a {slot} placeholder. The bundle MUST hold one combined template per time band, each with a {slot} placeholder. Every clock time in a template MUST use the 24-hour clock. The band edges in a template are fixed text, as `content` allows in "Catalogue rules".

The custom chip template MUST read correctly for any place name that the person types, for example "Mum's house" or "In the car". Its text below is a draft for the clinical reviewer.

The templates and their ids are:
- "pattern.band.before1200": "{n} of your {m} were before 12:00."
- "pattern.band.1200to1700": "{n} of your {m} were between 12:00 and 17:00."
- "pattern.band.1700to2000": "{n} of your {m} were between 17:00 and 20:00."
- "pattern.band.after2000": "{n} of your {m} were after 20:00."
- "pattern.weekday.monday" to "pattern.weekday.sunday": "{n} of your {m} were on a Friday." and one like it per weekday
- "pattern.weekend": "{n} of your {m} were at the weekend."
- "pattern.where.home": "{n} of your {m} were at home.", and one like it for "at work" ("pattern.where.work"), "when you were out" ("pattern.where.out") and "when you were travelling" ("pattern.where.travelling")
- "pattern.place": "{n} of your {m} had the place {place}." for a custom chip, where {place} is the person's chip text and the app adds no other word
- "pattern.longGap": "{n} of your {m} came more than {hours} after the entry before them."
- "pattern.slot": "{n} of your {m} were on days when {slot} didn't happen." where {slot} is the slot's label
- "pattern.combined.after2000": "{n} of your {m} were after 20:00 on days when {slot} didn't happen.", and one like it for each other time band: "pattern.combined.before1200", "pattern.combined.1200to1700" and "pattern.combined.1700to2000"

Each pattern sentence has a pattern key, which "The suggestion card" defines. Each pattern key holds the id of its template. So a template id MUST NOT change after a build that holds it ships. A template MUST NOT contain "you skipped". The `content` capability keeps the version of the template bundle and owns the permitted placeholders.

#### Scenario: A time band sentence
- **WHEN** the group for the after 20:00 band holds 5 entries and the starred total is 7
- **THEN** the sentence reads "5 of your 7 starred entries were after 20:00."

#### Scenario: A weekday sentence
- **WHEN** the Friday group holds 4 entries and the starred total is 6
- **THEN** the sentence reads "4 of your 6 starred entries were on a Friday."

#### Scenario: A custom chip sentence
- **WHEN** the Where group for the custom chip "Mum's house" holds 4 entries and the starred total is 7
- **THEN** the sentence reads "4 of your 7 starred entries had the place Mum's house."

#### Scenario: The place "In the car"
- **WHEN** the Where group for the custom chip "In the car" holds 4 entries and the starred total is 7
- **THEN** the sentence reads "4 of your 7 starred entries had the place In the car."

#### Scenario: A long-gap sentence
- **WHEN** the long-gap group holds 6 entries and the starred total is 8
- **THEN** the sentence reads "6 of your 8 starred entries came more than 4 hours after the entry before them."

#### Scenario: A gap of one hour
- **WHEN** MAX_AWAKE_GAP_HOURS is 1, the long-gap group holds 6 entries and the starred total is 8
- **THEN** the sentence reads "6 of your 8 starred entries came more than 1 hour after the entry before them."

#### Scenario: A missed-lunch sentence
- **WHEN** the slot label is "Lunch", the missed-lunch group holds 4 entries and the starred total is 7
- **THEN** the sentence reads "4 of your 7 starred entries were on days when Lunch didn't happen."

#### Scenario: A renamed slot
- **WHEN** the person renamed the lunch slot "midday bite", its missed-slot group holds 4 entries and the starred total is 7
- **THEN** the sentence reads "4 of your 7 starred entries were on days when midday bite didn't happen."

#### Scenario: A default slot label
- **WHEN** the Settings row `slot.label.3` is missing, the missed-mid-afternoon group holds 4 entries and the starred total is 7
- **THEN** the sentence reads "4 of your 7 starred entries were on days when Mid-afternoon didn't happen."

#### Scenario: A combined sentence
- **WHEN** the slot label is "Lunch", the combined after 20:00 and missed-lunch group holds 5 entries and the starred total is 7
- **THEN** the sentence reads "5 of your 7 starred entries were after 20:00 on days when Lunch didn't happen."

### Requirement: How pattern sentences appear

The Problem solving screen MUST show each pattern sentence as body text in one paragraph. The app MUST NOT show a chart, a graph, a table or a bar for a pattern. The app MUST NOT show a percentage or a colour for a pattern. The screen MUST show at most PATTERN_MAX_SENTENCES = 3 pattern sentences. The `programme` capability names PATTERN_MAX_SENTENCES in ProgrammeConstants. The sentences from starred entries and the sentences from urges MUST share one list and that limit.

Above the sentences, the screen MUST show one window line, "From the last %lld days". The app MUST fill %lld with PATTERN_WINDOW_DAYS. The line MUST come from a string with one count and plural forms that the clinical reviewer signs off. `content` names its id. When the screen shows no pattern sentence, it MUST show no window line.

The app MUST order the sentences by these rules, in this order:

- A larger group comes first.
- At the same size, a starred-entry sentence MUST come before an urge sentence. Ash ruled this on 12 October 2026 (r23-09).
- Then groups of the same size MUST follow this order of categories: time band, day of week, Where, long gap, missed slot, combined.
- Inside one category, groups of the same size MUST follow the earlier time band, then the lower slot index. Weekday groups follow the order Monday to Sunday, and a weekday group MUST come before the weekend group. Fixed chips follow the order "Home", "Work", "Out", "Travelling", and a fixed chip MUST come before a custom chip. Custom chips follow the alphabetical order of their text.

When a combined group holds the same entries as its time band group, the app MUST show only the combined sentence. When the weekend group holds the same entries as its Saturday group or its Sunday group, the app MUST show only the weekday sentence. The app MUST apply these equal-group rules inside each source. A starred-entry group never removes an urge sentence. An urge group never removes a starred-entry sentence.

Each sentence MUST have a "Work it through" control under it. A tap MUST open a new worksheet linked to that sentence. When no card answer row exists for the sentence's pattern key, the tap MUST also write one. The row holds the answer, the moment and the record day key of the tap, as after a tap on the suggestion card. So the card of that key does not show after the tap. By the rules of "The suggestion card", no other suggestion card shows on that record day either.

The app MUST compute the sentences again each time the Problem solving screen opens. The app MUST NOT schedule a reminder about a pattern sentence.

#### Scenario: Five groups qualify
- **WHEN** five groups meet the minimum, with sizes 6, 5, 5, 4 and 4
- **THEN** the screen shows three sentences, for the groups of 6, 5 and 5, and no sentence for the groups of 4

#### Scenario: Two missed-slot groups of the same size
- **WHEN** the missed-lunch group and the missed-mid-afternoon group each hold 4 of 7 starred entries, and no other group meets the minimum
- **THEN** the missed-lunch sentence comes before the missed-mid-afternoon sentence, because lunch has the lower slot index

#### Scenario: A time band group and a weekday group of the same size
- **WHEN** the after 20:00 group and the Friday group each hold 5 of 7 starred entries, and no other group meets the minimum
- **THEN** the after 20:00 sentence comes before the Friday sentence

#### Scenario: A combined group with the same entries
- **WHEN** the after 20:00 group and the combined after 20:00 and missed-lunch group hold the same five entries
- **THEN** the screen shows the combined sentence and not the after 20:00 sentence

#### Scenario: The weekend and its Saturday
- **WHEN** the Saturday group and the weekend group hold the same four of seven starred entries
- **THEN** the screen shows the Saturday sentence and no weekend sentence

#### Scenario: Work it through
- **WHEN** the person taps "Work it through" under "5 of your 7 starred entries were after 20:00."
- **THEN** the app opens a new worksheet with that sentence above step 1

#### Scenario: Work it through answers the card
- **WHEN** no card answer row exists for "pattern.band.after2000", and the person taps "Work it through" under "5 of your 7 starred entries were after 20:00." on the Problem solving screen at 10:00 on Monday 12 October 2026
- **THEN** the store holds a card answer row for "pattern.band.after2000" with the `dateKey` Monday 12 October, and Today shows no suggestion card for the rest of that record day

#### Scenario: The window line
- **WHEN** stage 4 is open and the screen shows "5 of your 7 starred entries were after 20:00."
- **THEN** the line above the sentence reads "From the last 28 days"

#### Scenario: A new starred entry
- **WHEN** the person saves a starred entry and opens the Problem solving screen
- **THEN** the sentences show numbers that include the new entry

### Requirement: Pattern sentences from urges

Pattern sentences also come from urges, by the same rules as from starred entries. `urge-toolkit` owns the urges. The urge source holds every urge whose `startDayKey` is in the pattern window, with or without an outcome. The urge total is the number of those urges. An urge group is a set of those urges that share one dimension value. Ash ruled this on 12 October 2026 (r23-09).

The app MUST NOT show an urge sentence when the urge total is below PATTERN_MIN_URGES = 5. The app MUST show a sentence for an urge group only when the group holds at least PATTERN_MIN_GROUP urges. The group MUST also hold more than half of the urge total. The `programme` capability names PATTERN_MIN_URGES in ProgrammeConstants. Each source has its own minimum. So a starred total below PATTERN_MIN_STARRED does not stop an urge sentence, and an urge total below PATTERN_MIN_URGES does not stop a starred-entry sentence.

The urge dimensions are the time band, the weekday, the weekend, the long gap, each missed slot, and the combined time band and missed slot. An urge has no Where, so the app MUST NOT build a Where group from urges. The app MUST read the dimensions of an urge as follows:

- The time band comes from `startedAt` at the urge's own `utcOffsetSeconds`, with the fixed edges that "The pattern dimensions" states.
- The weekday is the weekday of `startDayKey`. The weekend group holds the urges whose `startDayKey` is a Saturday or a Sunday.
- The gap before an urge is the time from the previous entry in the same record day to `startedAt`. When no earlier entry exists in that record day, the gap is unknown, and the urge is not in the long-gap group. The long-gap group holds the urges with a gap over MAX_AWAKE_GAP_HOURS. A day with the state fasting, "paused" or "didn't record" counts no gap. So the app MUST NOT count an urge on such a day in the long-gap group.
- A missed-slot group holds the urges on the record days where that slot is skipped, as "The pattern dimensions" defines. A combined group holds the urges in one time band and one missed-slot group.

The app MUST read the saved `startDayKey`. The app MUST NOT compute the record day of an urge again.

An urge sentence uses the same template as a starred-entry sentence of the same group. The app MUST fill {m} from "pattern.count.urges", "%lld urges", with the urge total, as "Pattern sentence templates" states. An urge sentence has the same pattern key as the starred-entry sentence of the same group. So one answer to a suggestion card covers the starred-entry sentence and the urge sentence of that key, as "The suggestion card" states.

The sentences from both sources share one list on the Problem solving screen, as "How pattern sentences appear" states. "Work it through", the suggestion card, the switch "Pattern sentences", the stage 4 gate, the no-network rule and the privacy rules apply to urge sentences as to starred-entry sentences. At most one suggestion card shows on a record day, from the two sources together, as "The suggestion card" states.

#### Scenario: Six urges, four after 20:00
- **WHEN** stage 4 is open and the pattern window holds six urges, four of them with `startedAt` between 20:00 and 03:59
- **THEN** the Problem solving screen shows "4 of your 6 urges were after 20:00."

#### Scenario: Four urges
- **WHEN** the pattern window holds four urges, all after 20:00
- **THEN** the Problem solving screen shows no urge sentence and no text about the absence of one

#### Scenario: An urge with no outcome counts
- **WHEN** the pattern window holds six urges, five of them after 20:00 and two of those five with no outcome
- **THEN** the Problem solving screen shows "5 of your 6 urges were after 20:00."

#### Scenario: Each source has its own minimum
- **WHEN** the pattern window holds four starred entries and six urges, and four of the urges were after 20:00
- **THEN** the Problem solving screen shows "4 of your 6 urges were after 20:00." and no starred-entry sentence

#### Scenario: An urge after a zone change
- **WHEN** the person tapped "Urge" at 21:30 in London, and later opens the Problem solving screen in New York
- **THEN** the app places the urge in the after 20:00 band

#### Scenario: An urge after midnight
- **WHEN** an urge has `startedAt` 00:30 on Friday 23 October 2026, with `utcOffsetSeconds` 3600 and `startDayKey` Thursday 22 October
- **THEN** the app places it in the after 20:00 band and in the Thursday group, and does not compute its record day again

#### Scenario: A long gap before an urge
- **WHEN** a record day has an entry at 12:40 and an urge at 19:00
- **THEN** the app counts the urge in the long-gap group

#### Scenario: An urge first in its record day
- **WHEN** an urge at 07:30 has no earlier entry in its record day
- **THEN** the app counts the urge in the urge total and not in the long-gap group

#### Scenario: No Where group from urges
- **WHEN** the app builds the urge groups of a pattern window that holds six urges
- **THEN** no urge group is a Where group

#### Scenario: Both sources in one list
- **WHEN** the after 20:00 group holds 5 of 7 starred entries, the after 20:00 urge group holds 5 of 6 urges, and no other group meets the minimum
- **THEN** the screen shows "5 of your 7 starred entries were after 20:00.", then "5 of your 6 urges were after 20:00."

#### Scenario: Three sentences from two sources
- **WHEN** the starred-entry groups that meet the minimum hold 6 and 4 entries, and the urge groups that meet the minimum hold 5 and 4 urges
- **THEN** the screen shows the starred-entry sentence of 6, then the urge sentence of 5, then the starred-entry sentence of 4, and no other sentence

#### Scenario: A combined urge group
- **WHEN** the after 20:00 urge group and the combined after 20:00 and missed-lunch urge group hold the same four of six urges, and the after 20:00 starred-entry group meets the minimum
- **THEN** the screen shows the combined urge sentence and not the after 20:00 urge sentence, and still shows the after 20:00 starred-entry sentence

#### Scenario: One answer covers the urge card
- **WHEN** the person tapped "Close" on the after 20:00 card of starred entries on Monday 12 October 2026, and on Tuesday 13 October the after 20:00 urge group meets the minimum
- **THEN** the card slot shows no card for the key "pattern.band.after2000" on Tuesday 13 October or later, and the Problem solving screen still shows "4 of your 6 urges were after 20:00."

#### Scenario: Pattern sentences off
- **WHEN** "Pattern sentences" is off and the after 20:00 urge group meets the minimum
- **THEN** the app computes no urge sentence and shows no suggestion card for it

### Requirement: The suggestion card

When a group first meets the minimum, the app MUST show one suggestion card in the Today card slot, by the rules below. The `record` capability defines the Today stack, the card slot and its rules. The suggestion card MUST show the pattern sentence, a "Work it through" control and a "Close" control. The sentence MUST use the same text style as an entry row, as an opening card does. "Work it through" MUST come before "Close". At an accessibility text size, the two controls MUST stack, one under the other.

Each suggestion card belongs to one pattern key. The pattern key of a sentence is its template family plus its fill value. The template family is the id of the template that "Pattern sentence templates" lists. The fill value is the value that fills the template's {slot} or {place}:

- For "pattern.slot" and each combined template, the fill value is the slot index. The key is the template id, a colon and the slot index, for example "pattern.slot:2" for lunch.
- For "pattern.place", the fill value is the place text as the person typed it. The key is "pattern.place:", then that text, for example "pattern.place:Mum's house".
- Every other template has no fill value. Its key is the template id, for example "pattern.band.after2000".

A starred-entry sentence and an urge sentence about the same thing have the same template and the same fill value. So they share one pattern key. A pattern key MUST NOT change after a build that holds it ships. A card answer row keeps its key for ever, so a changed key would show an answered card again.

The app MUST show the suggestion card once per pattern key, whatever the numbers. The card slot holds one card at a time. When the person taps either control, the app MUST take the card off Today. The app MUST NOT show the suggestion card for that key again. "Work it through" MUST open a new worksheet linked to the sentence. When both sources give a sentence with one key, the card MUST show the sentence that comes first in the card order below. One answer covers both sentences of a key. So after an answer to the card of a starred-entry sentence, the urge sentence of that key does not show as a card. The reverse is also true.

The app MUST keep the answer to a suggestion card as a card answer row in Record.store. The row is an `Answer` row of kind "card". It holds the pattern key in `cardId`, the answer in `value`, the record day key of the tap in `dateKey` and its own `changedAt`. The `data-and-privacy` capability owns card answer rows and their sync. When any device holds a card answer row for a key, the app MUST NOT show that key's card. While the first import after sync turns on is running, the app MUST show no suggestion card.

After a starred entry, the app MUST NOT show the card on a Today load in the same record day. After an "I binged" outcome, the app MUST NOT show the card on a Today load in the same record day. The card MUST wait for the next record day. The app MUST NOT schedule a reminder for a suggestion card.

A key's card is due at a Today load when all of these are true:

- Stage 4 is open.
- "Pattern sentences" is on.
- A group of the key meets the minimum at that load, in either source.
- No equal-group rule of "How pattern sentences appear" leaves out the sentence of that group.
- No device holds a card answer row for the key.

The limit of PATTERN_MAX_SENTENCES does not apply to the card. So "first meets the minimum" needs no stored state other than the card answer row. The app MUST compute the group and the sentence again at each Today load. The card MUST show the sentence with the numbers of that load.

When the group stops meeting the minimum before the person taps a control, the app MUST take the card off Today with no message. The app MUST then write no card answer row. The card can then come back when the group meets the minimum again. "Work it through" MUST link the sentence as the card showed it at the tap.

The card order has these rules, in this order:

- A suggestion card MUST come after every other waiting card in the card slot. So each card of another kind shows first, as the scenario "Two cards waiting" of `record` shows.
- Among the due keys, the key with the largest group MUST come first. When a key has a sentence in both sources, its group is the larger of the two.
- Keys with groups of the same size MUST follow the tie order of their sentences. A starred-entry sentence comes before an urge sentence. Then the categories follow this order: time band, day of week, Where, long gap, missed slot, combined.
- Inside one category, the earlier time band comes first, then the lower slot index. Weekdays follow the order Monday to Sunday, and a weekday group comes before the weekend group. A fixed chip comes before a custom chip, and custom chips follow the alphabetical order of their text.

This is the order of the sentences on the Problem solving screen, as "How pattern sentences appear" states. So the card shows the first due sentence that the screen would show.

The app MUST show at most one suggestion card on a record day, from the two sources together. One pure function MUST decide the suggestion card of each Today load. Its inputs are:

- the current record day key
- the due keys, each with its sentences, their group sizes and their sources
- the `dateKey` values of the card answer rows of suggestion cards
- the key that the card slot showed earlier on the same record day

The function MUST apply these rules in this order:

- When a card answer row of a suggestion card holds the current record day key, the function MUST return no card. The person answered a suggestion card on that record day, with "Work it through" or "Close".
- When the card slot showed a suggestion card earlier on the same record day, the function MUST return that key while it is due. It MUST return no card while that key is not due. A card that shows and has no answer stays the same card for the rest of that record day.
- In all other cases, the function MUST return the due key that comes first in the card order above.

So the next due key waits for the next record day. The card answer row of a suggestion card MUST hold the record day key of the tap in `dateKey`, with the answer and the moment. The app MUST keep in `Local.store` the key that the card slot showed, with the key of that record day. This rule holds back only suggestion cards. A card of another kind can show on the same record day, by the card slot rules of `record`. Ash ruled this on 12 October 2026 (r23-06).

#### Scenario: The numbers change while the card waits
- **WHEN** the after 20:00 card shows "5 of your 7 starred entries were after 20:00." on Monday, the person does not tap it, and on Tuesday the group holds 6 of 8
- **THEN** on Tuesday the card shows "6 of your 8 starred entries were after 20:00."

#### Scenario: The group stops meeting the minimum
- **WHEN** the after 20:00 card shows "5 of your 7 starred entries were after 20:00." with no answer, and the person turns the star off on three of the five entries after 20:00, so that the group holds 2 of 4
- **THEN** the next Today load shows no after 20:00 card, and the store holds no card answer row for the after 20:00 template

#### Scenario: Pattern sentences turned on again
- **WHEN** the after 20:00 group met the minimum while "Pattern sentences" was off, no card answer row exists for it, and the person turns the switch on
- **THEN** the after 20:00 card shows from the next Today load, by the card slot rules

#### Scenario: First time a group qualifies
- **WHEN** the after 20:00 group meets the minimum for the first time, with 5 of 7 starred entries, and the person opens Today the next record day
- **THEN** the card slot shows one card with "5 of your 7 starred entries were after 20:00.", "Work it through" and "Close"

#### Scenario: Close, then the numbers change
- **WHEN** the person taps "Close" on the after 20:00 card, and a week later the after 20:00 group holds 7 of 9 starred entries
- **THEN** Today shows no card for the after 20:00 template

#### Scenario: Work it through from Today
- **WHEN** the person taps "Work it through" on the card
- **THEN** the app opens a new worksheet with the sentence above step 1, and Today shows no card when the person returns

#### Scenario: Two templates qualify on the same day
- **WHEN** the after 20:00 group with 5 entries and the Friday group with 4 entries meet the minimum on Monday 12 October 2026, and the person taps "Close" on the after 20:00 card at 08:10
- **THEN** the card slot shows no second suggestion card on Monday 12 October, and shows the Friday card from the first Today load on Tuesday 13 October

#### Scenario: One key for both sources
- **WHEN** the missed-lunch group of starred entries and the missed-lunch group of urges each meet the minimum
- **THEN** both sentences have the pattern key "pattern.slot:2", and one card answer row for that key covers both

#### Scenario: Two slots of one template
- **WHEN** the person tapped "Close" on the missed-lunch card, and later the missed-mid-afternoon group meets the minimum
- **THEN** the card slot shows the missed-mid-afternoon card on a later record day, because its key "pattern.slot:3" differs from "pattern.slot:2"

#### Scenario: Equal groups are not due
- **WHEN** the after 20:00 group and the combined after 20:00 and missed-lunch group hold the same five of seven starred entries, and neither key has a card answer row
- **THEN** the card slot shows the combined card, and the key "pattern.band.after2000" is not due

#### Scenario: A card that waits keeps its template for the day
- **WHEN** a test calls the function at 12:00 on Monday 12 October 2026 with the after 20:00 key shown earlier that day and still due, and a due key with a larger group
- **THEN** it returns the after 20:00 key

#### Scenario: One suggestion card and a card of another kind
- **WHEN** the person taps "Work it through" on a suggestion card at 08:00 on Monday 12 October 2026, and later that day an opening card and a second suggestion template are due
- **THEN** the card slot shows the opening card on Monday 12 October, and the second suggestion card waits for Tuesday 13 October

#### Scenario: Answered on another device the same day
- **WHEN** the person taps "Close" on a suggestion card on another device at 08:00 on Monday 12 October 2026, and then taps "Sync now" on both devices
- **THEN** this device shows no suggestion card for the rest of Monday 12 October

#### Scenario: The pure function decides the card
- **WHEN** a test calls the function with the current record day Monday 12 October 2026, two due keys with groups of 5 and 4, no key shown earlier that day, and no card answer row with that `dateKey`
- **THEN** the function returns the key with the group of 5, and with a card answer row of a suggestion card with the `dateKey` Monday 12 October it returns no card

#### Scenario: A starred entry the same record day
- **WHEN** the person saves a starred entry at 21:30 that makes the after 20:00 group qualify, then opens Today at 22:00
- **THEN** the card slot shows no suggestion card, and the card appears on the first Today load of the next record day

#### Scenario: Answered on another device
- **WHEN** the person tapped "Close" on the after 20:00 card on another device and that card answer row has synced to this device
- **THEN** this device shows no card for the after 20:00 template

#### Scenario: During the first import
- **WHEN** the person turns sync on, the first import is running, and the after 20:00 group meets the minimum
- **THEN** Today shows no suggestion card until the import completes

### Requirement: Pattern sentences are opt-out

The app MUST offer a switch named "Pattern sentences" in the settings screen, on by default. The `product-rules` capability states the "The person can put it down" rule. When the switch is off, the app MUST NOT compute or show a pattern sentence or a suggestion card, from starred entries or from urges. When the switch is off, the worksheet and the "Worksheets" list MUST stay available. "New worksheet" in the day heading's menu also stays. A saved worksheet MUST keep its linked sentence when the switch is off.

Under the switch, the settings screen MUST show one line that explains it: "Sentences about patterns in your record, on Problem solving and on Today." This line is a draft that the clinical reviewer signs off. `content` names its id.

When the person turns the switch on again, the app MUST compute the sentences again. The app MUST keep the card answer rows of the suggestion cards while the switch is off.

#### Scenario: Switch off
- **WHEN** the person turns "Pattern sentences" off and opens the Problem solving screen
- **THEN** the screen shows "New worksheet" and the "Worksheets" list, and no pattern sentence

#### Scenario: A saved worksheet keeps its sentence
- **WHEN** a worksheet is linked to "5 of your 7 starred entries were after 20:00." and the person turns "Pattern sentences" off
- **THEN** the worksheet still shows that sentence above step 1

#### Scenario: Switch on again
- **WHEN** the person tapped "Close" for the after 20:00 template, turned the switch off, and turns it on again
- **THEN** the Problem solving screen shows the sentences, and Today shows no card for the after 20:00 template

#### Scenario: The line under the switch
- **WHEN** the person opens the Record group of the settings screen
- **THEN** "Pattern sentences" shows with the line "Sentences about patterns in your record, on Problem solving and on Today." under it

### Requirement: The six-step worksheet

A worksheet MUST have six steps in this order. Each step MUST show its question as its heading. The steps are:
1. "What is the problem, exactly?" with two lines under it: "Be as precise as you can." and "Think about what comes before it: a time, a place, a feeling or a long gap." One free-text field.
2. "What could you do about it?" with the line "List every option, even the unlikely ones. Don't judge them yet." under it. A list of free-text lines, one per option.
3. "How would each one work out?" with the line "For each one, ask: does it keep your planned meals and snacks in place?" under it. One free-text field under each option from step 2.
4. "Which will you try?" with the line "One, or a combination." under it. One system switch for each option from step 2, with the option's text as its label. The person turns on one or more.
5. "What are the steps?" A list of free-text lines.
6. "How did it go?" with the line "Look at how you went about it, not only whether it worked." under it. One free-text field.

Each question and each line under a question MUST be a signed catalogue key with the prefix "worksheet.". The clinical reviewer signs off these keys. The questions are "worksheet.1" to "worksheet.6". `content` lists the ids of the lines in "Content versions". This follows ruling r17-03, which put clinical guidance under the sign-off. The line under step 1 about what comes before the problem, and the line under step 3, are drafts for the clinical reviewer. The app MUST NOT rank, judge or comment on one option. A line that asks the same question of every option does not judge one option.

Step 5 MUST show the options chosen in step 4 above its list. Step 6 MUST show step 1's text, then the options chosen in step 4, then the lines of step 5, above its field. When step 1 is empty, step 4 has no chosen option or step 5 has no line, the step MUST show no empty space for that part.

When step 2 has no line, steps 3 and 4 MUST show their question and the lines under it, and nothing else. They MUST NOT show text or an image in place of the fields or the switches. This follows the principle of decision 95: a list shows nothing in place of its rows. Ash ruled it on 25 September 2026 (r8-12).

The worksheet MUST show one step on each page of the sheet. Its navigation bar MUST show the title "Worksheet" as a system title menu, and Get support in the trailing position. The title menu MUST list the six questions. A tap on a question in the menu MUST open that step. The leading position of the navigation bar MUST stay empty.

Under the content of each step, the worksheet MUST show "Back" and "Next" side by side, then "Done" as a full-width button. "Back" MUST open the step before, and "Next" MUST open the step after. Step 1 MUST show no "Back". Step 6 MUST show no "Next". While the keyboard shows, the keyboard's toolbar MUST show "Back", "Next" and "Done", by the same rules. Each of them MUST have a touch target of at least 44 by 44 points, as the keyboard's "Save" on the new-entry screen has. Ash ruled on that "Save" on 25 September 2026 (r8-04).

A worksheet MUST open at step 1, from every route except one. The worksheet review reminder opens step 6. A move to another step MUST use the system's standard transition. With Reduce Motion on, the move MUST be a cross-fade. When a step opens, the keyboard MUST go into the step's first field, and VoiceOver focus MUST move to the step's question. Step 4 has no field, so the keyboard closes there. The person MUST be able to move to any step at any time. The app MUST NOT require text in a step before the person moves on.

In steps 2 and 5, Return in a line MUST add a new line under it, with the keyboard in it. Under the lines, the step MUST show "Add a line", then "Edit". "Add a line" MUST add a line at the end of the list, with the keyboard in it. Each line MUST offer "Delete" as the system's swipe action and as a VoiceOver action. When the worksheet closes, the app MUST drop each line that holds no character that is not a space.

Each line of step 2 and of step 5 MUST have a stable id. The field of step 3 and the switch of step 4 belong to the id of their option. So a reorder of the options and an edit of an option's text keep the note and the choice with their option. A delete of an option MUST delete its note and its choice too.

In steps 2 and 5, the person MUST be able to reorder the lines. A tap on "Edit" MUST start edit mode. In edit mode the control MUST read "Stop editing", and a tap on it MUST end edit mode. In edit mode, each line MUST show "Move up" and "Move down" as visible controls. Each line MUST offer "Move up" and "Move down" as VoiceOver actions. The worksheet MUST NOT need a drag to reorder a line. Steps 3 and 4 MUST follow the order of step 2.

The app MUST save each field's text as the person types. The app MUST write the worksheet row at the first character that the person types. When the worksheet closes with nothing typed, the app MUST keep no row. The app MUST NOT show a placeholder in any field.

Every field of the worksheet MUST keep autocorrection and sentence capitalisation. The app MUST turn off the keyboard's inline predictions in every field of the worksheet, as `record` does in What and Context. Ash ruled this for the record on 25 September 2026 (r8-06).

When a save fails, the worksheet MUST stay open. It MUST show "Could not save. Try again." under the navigation bar, as `record` does in "A save that fails". The app MUST keep the text in memory. The app MUST try the save again at the next change. "Done" and a swipe down MUST NOT close the worksheet until a save succeeds.

The worksheet MUST have a "Done" control that closes the worksheet with the system's standard dismissal. A swipe down that closes the worksheet MUST act as "Done". The app MUST NOT show a message, a sound, a haptic or an animation on "Done".

The worksheet MUST open as a sheet over the screen it came from. That screen is the Problem solving screen, or Today for the suggestion card, the worksheet review reminder and "New worksheet" in the day heading's menu. The worksheet MUST show Get support in the trailing position of its navigation bar. The sheet exemption of `safeguarding` in "Get support on every screen" MUST NOT apply to the worksheet. The worksheet is the longest free-text screen, and the app never reads free text for risk. So Get support stays one tap away on it. This follows the PRD's safety principle of the always-present support route. It also follows decision 80, which took the three self-harm screens out of the exemption on 25 September 2026.

A worksheet holds the person's answers. While it shows, a tap on a reminder MUST NOT close it. The app MUST open the screen of the reminder only after the worksheet closes, as `reminders` states in "A tap on a reminder opens its screen from Today". When the reminder is the worksheet review reminder of the worksheet on screen, the app MUST keep that worksheet and MUST open its step 6. This follows Ash's ruling of 11 October 2026 that screens with answers stay (r22-01).

#### Scenario: The worksheet is a sheet
- **WHEN** the person taps "Work it through" on the suggestion card on Today and then taps "Done"
- **THEN** the worksheet opened as a sheet over Today, and "Done" returns to Today, where Get support shows

#### Scenario: Get support on the worksheet
- **WHEN** the person opens a worksheet from "New worksheet"
- **THEN** Get support is the trailing item of the worksheet's navigation bar, and one tap opens the support sheet over the worksheet

#### Scenario: Start from a pattern sentence
- **WHEN** the person taps "Work it through" and the worksheet opens
- **THEN** the worksheet shows the sentence, then "What is the problem, exactly?" with an empty field and the keyboard in that field

#### Scenario: Solutions carry to step 3
- **WHEN** the person types "Plan an evening snack" and "Leave the kitchen after dinner" in step 2 and opens step 3
- **THEN** step 3 shows "Plan an evening snack" with an empty field under it, then "Leave the kitchen after dinner" with an empty field under it

#### Scenario: Pick a combination
- **WHEN** the person turns on the switches of both options in step 4
- **THEN** step 4 shows both switches on and the app shows no message

#### Scenario: Step 5 shows the choice
- **WHEN** the person chose "Plan an evening snack" in step 4 and opens step 5
- **THEN** step 5 shows "Plan an evening snack" above its list

#### Scenario: Step 6
- **WHEN** step 1 holds "Evenings after a missed lunch", the person chose "Plan an evening snack" in step 4, step 5 holds "Pack a snack on Sunday night", and the person opens step 6
- **THEN** the worksheet shows "How did it go?", then "Look at how you went about it, not only whether it worked.", then "Evenings after a missed lunch", then "Plan an evening snack", then "Pack a snack on Sunday night", then an empty field

#### Scenario: Move between steps
- **WHEN** the person is on step 2 and taps "Next", then taps "What are the steps?" in the title menu
- **THEN** the worksheet shows step 3, then step 5

#### Scenario: Back and Next at the ends
- **WHEN** the person opens a new worksheet, and later opens step 6
- **THEN** step 1 shows "Next" and "Done" and no "Back", and step 6 shows "Back" and "Done" and no "Next"

#### Scenario: The keyboard's toolbar
- **WHEN** the keyboard shows in step 2
- **THEN** the keyboard's toolbar shows "Back", "Next" and "Done", each with a touch target of at least 44 by 44 points

#### Scenario: Move a line up
- **WHEN** step 2 holds "Plan an evening snack" then "Leave the kitchen after dinner", and the person uses "Move up" on the second line
- **THEN** step 2 shows "Leave the kitchen after dinner" then "Plan an evening snack", and step 3 follows that order

#### Scenario: Return adds a line
- **WHEN** step 2 holds "Plan an evening snack" and the person taps Return at the end of that line
- **THEN** step 2 shows a new empty line under it, with the keyboard in the new line

#### Scenario: Empty lines drop
- **WHEN** step 2 holds "Plan an evening snack" and an empty line, and the person taps "Done"
- **THEN** the worksheet keeps "Plan an evening snack" and no empty line

#### Scenario: An edited option keeps its note
- **WHEN** step 3 holds the note "Easy on weekdays" under "Plan an evening snack", and the person changes that option in step 2 to "Plan a snack at 21:00"
- **THEN** step 3 shows "Plan a snack at 21:00" with "Easy on weekdays" under it

#### Scenario: Delete an option
- **WHEN** step 3 holds the note "Easy on weekdays" under "Plan an evening snack", its switch is on in step 4, and the person deletes that line in step 2
- **THEN** steps 3 and 4 show nothing for "Plan an evening snack", and the store keeps no note and no choice for it

#### Scenario: No options yet
- **WHEN** step 2 has no line and the person opens step 3, then step 4
- **THEN** each step shows its question and the line under it, and no other text

#### Scenario: Nothing typed
- **WHEN** the person taps "New worksheet" and then "Done" with nothing typed
- **THEN** the store holds no new worksheet row, and the "Worksheets" list shows no new row

#### Scenario: A swipe down
- **WHEN** the person types "Evenings" in step 1 and swipes the worksheet down
- **THEN** the worksheet closes as with "Done", and the "Worksheets" list shows "Evenings"

#### Scenario: Keyboard in a worksheet field
- **WHEN** the person types in step 1
- **THEN** the keyboard offers autocorrection and a capital letter at the start of a sentence, and shows no inline prediction

#### Scenario: A failed save
- **WHEN** the store fails to save "Evenings after a missed lunch" in step 1
- **THEN** the worksheet shows "Could not save. Try again." under the navigation bar and keeps the text, and "Done" does not close it until a save succeeds

#### Scenario: A reminder tap over a worksheet
- **WHEN** a worksheet over Today shows "Evenings after a missed lunch" in step 1, the person taps the body of the weigh-in day reminder, and then taps "Done"
- **THEN** the worksheet and its text stay until "Done", and after it the weigh-in screen shows on Today's navigation stack

#### Scenario: The review reminder over its worksheet
- **WHEN** the worksheet started on Saturday 10 October 2026 shows step 2, and the person taps its worksheet review reminder at 18:00 on Saturday 17 October
- **THEN** the app keeps that worksheet, opens its step 6, and opens no second worksheet

#### Scenario: Leave and return
- **WHEN** the person types "Evenings after a missed lunch" in step 1, closes the app, and opens the worksheet again
- **THEN** step 1 shows "Evenings after a missed lunch"

#### Scenario: Done is quiet
- **WHEN** the person taps "Done" with step 3 empty
- **THEN** the worksheet closes as any sheet closes, with no message about the empty step

### Requirement: The "Worksheets" list

The "Worksheets" list MUST show every saved worksheet, newest first by the moment the person started it. The start moment is the moment the worksheet opened. Each row MUST show the first line of step 1 and the worksheet's start date. The app MUST trim spaces and line breaks from the start of step 1. The first line is then the text up to the first line break, with spaces trimmed from its end. When step 1 holds no character that is not a space, the row MUST show "Worksheet" and the date.

The start date is the record day of the start, from the saved start record day key. The row MUST show it as a date from the en_GB formatter, for example "3 October". When that record day is in another year than the current record day, the date MUST also show the year, for example "3 October 2026".

The "New worksheet" control MUST sit above the "Worksheets" list. When no worksheet exists, the screen MUST show "New worksheet" above an empty list, with no heading. The app MUST NOT show text or an image in place of the rows. Decision 95 sets this rule. Ash ruled it on 25 September 2026.

The list MUST NOT show a count of worksheets or a count of finished steps. A worksheet MUST show its linked pattern sentence above step 1 as the sentence read when the worksheet started. The worksheet MUST show the start date beside the linked sentence, in the format of the row. The app MUST NOT change the linked sentence when the numbers change later.

A worksheet started from "New worksheet", on the Problem solving screen or in the day heading's menu, MUST have no linked sentence and no empty space for one. The person MUST be able to open and edit any worksheet at any time.

The person MUST be able to delete a worksheet in two places. The page of step 6 MUST show "Delete worksheet" as the last control of its content, under its field. The row in the "Worksheets" list MUST offer the system's swipe to delete, and "Delete" as a VoiceOver action. Before it deletes, the app MUST ask once in a system alert: "Delete this worksheet?" with the choices "Delete" and "Cancel". `record` asks in the same way before it deletes an entry. Ash ruled on 7 October 2026 that each such question is an alert (r16-03). After a delete from the worksheet, the worksheet MUST close.

A delete MUST write `deleted = true` and a new `changedAt` into the worksheet row. The delete moment is that `changedAt`. The store MUST NOT hard-delete the row. A reader MUST NOT show a deleted worksheet.

When the person deletes a worksheet, the app MUST cancel its worksheet review reminder. When a deleted worksheet row arrives by sync, the app MUST cancel that reminder too. The app MUST also remove a delivered worksheet review reminder of that worksheet from Notification Centre.

#### Scenario: Delete after the reminder arrived
- **WHEN** the worksheet review reminder of a worksheet is in Notification Centre and the person deletes that worksheet
- **THEN** Notification Centre no longer shows that reminder

#### Scenario: Order of the list
- **WHEN** the person started a worksheet on 3 October and another on 10 October
- **THEN** the "Worksheets" list shows the 10 October worksheet above the 3 October worksheet

#### Scenario: The linked sentence stays
- **WHEN** a worksheet is linked to "5 of your 7 starred entries were after 20:00." and the group later holds 7 of 9
- **THEN** the worksheet still shows "5 of your 7 starred entries were after 20:00."

#### Scenario: The start date beside the linked sentence
- **WHEN** the person started a worksheet on Saturday 3 October 2026 from "5 of your 7 starred entries were after 20:00."
- **THEN** the worksheet shows that sentence with "3 October" beside it, above step 1

#### Scenario: A worksheet without a problem name
- **WHEN** a worksheet started on 3 October has an empty step 1
- **THEN** its row shows "Worksheet" and "3 October"

#### Scenario: A first line after empty lines
- **WHEN** step 1 holds two empty lines, then "  Evenings after a missed lunch", then a second line of text
- **THEN** its row shows "Evenings after a missed lunch"

#### Scenario: A start after midnight
- **WHEN** the day start is 04:00 and the person starts a worksheet at 01:30 on Sunday 11 October 2026
- **THEN** its row shows "10 October", the date of its record day

#### Scenario: A worksheet from last year
- **WHEN** the current record day is Monday 4 January 2027, and a worksheet started on Saturday 3 October 2026
- **THEN** its row shows "3 October 2026"

#### Scenario: No worksheet yet
- **WHEN** stage 4 is open, the person has no worksheet and opens the Problem solving screen
- **THEN** the screen shows "New worksheet" above an empty "Worksheets" list, with no heading and no text or image in place of the rows

#### Scenario: Delete a worksheet
- **WHEN** the person deletes a worksheet with a worksheet review reminder set for 17 October
- **THEN** the store writes `deleted = true` and the moment of the delete as `changedAt` into the worksheet row, the "Worksheets" list stops showing it, and the app cancels the 17 October reminder

#### Scenario: Delete from the worksheet
- **WHEN** the person taps "Delete worksheet" on step 6 and taps "Delete" in the alert "Delete this worksheet?"
- **THEN** the worksheet closes, and the "Worksheets" list shows no row for it

#### Scenario: Cancel a delete
- **WHEN** the person swipes a row of the "Worksheets" list, taps "Delete", and then taps "Cancel" in the alert
- **THEN** the row stays, and the store writes nothing

#### Scenario: Deleted on another device
- **WHEN** the person deletes a worksheet on another device and its row with `deleted = true` syncs to this device
- **THEN** the "Worksheets" list on this device stops showing it, and the app cancels its worksheet review reminder

### Requirement: The worksheet review reminder a week later

When the worksheet closes for the first time with text in step 5, the app MUST save the review day and ask for one worksheet review reminder. The worksheet closes with "Done" or with a swipe down. The reminder is due on the review day, at the "Weekly review time" of that record day. `reminders` owns the "Weekly review time", which defaults to 18:00.

The review day is the record day WORKSHEET_REVIEW_DAYS = 7 calendar days after the record day of that close. The `programme` capability names WORKSHEET_REVIEW_DAYS in ProgrammeConstants. The app MUST compute the review day by calendar arithmetic on the record day key, never as a count of seconds. The reminder MUST NOT use the clock time of the close. The app MUST schedule at most one worksheet review reminder per worksheet.

The `reminders` capability owns the reminder's text, its switch, quiet hours, the daily cap and the move to a later record day. `reminders` states in "Worksheet review and check-in reminders" when the reminder moves, the bound of that move, and how each device keeps the moment of the reminder. Ash ruled this on 12 October 2026 (r23-04).

When the person opens the reminder, the app MUST open that worksheet at step 6, as a sheet over Today. When the person saves text in step 6 before the reminder fires, the app MUST cancel the reminder. The person MUST be able to open step 6 at any time without the reminder.

The app MUST save the review day in the worksheet row, as a record day key, at the first close with text in step 5. The row MUST NOT hold a clock time for the reminder. The scheduler MUST read the day from the saved key and the time from the current "Weekly review time". So a change of that time moves each worksheet review reminder that has not fired. The app MUST NOT change the saved review day on a later close. When step 6 already holds text at that first close, the app MUST NOT schedule a reminder.

The system can end the app before the worksheet closes. At launch, the app MUST give a review day to each worksheet with text in step 5 and no review day. The app MUST compute it from the record day of the row's `changedAt`, as for a close at that moment.

The app MUST NOT ask the scheduler to compute the reminders again at each character that the person types. For a worksheet, the app MUST ask for a new computation only at these moments:

- when step 5 or step 6 changes between empty and not empty
- at "Done"
- at a swipe down that closes the worksheet
- at a delete of the worksheet

The "Worksheet review" switch decides only whether the scheduler schedules the reminder. `reminders` owns the switch. The app MUST save the review day also while the switch is off. When the person turns the switch on, the scheduler MUST schedule the reminder for each worksheet whose reminder can still fire and whose step 6 is empty. `reminders` states in "Worksheet review and check-in reminders" when a reminder can still fire.

After the reminder fires, the app MUST NOT schedule it again for that worksheet. When the person opens a reminder for a worksheet that a reader hides, the app MUST show Today with no message.

#### Scenario: Step 6 already written
- **WHEN** the person taps "Done" for the first time with text in step 5 and in step 6
- **THEN** the app schedules no worksheet review reminder

#### Scenario: The switch turned on later
- **WHEN** "Worksheet review" is off, the "Weekly review time" is 18:00, the person taps "Done" at 21:10 on Saturday 10 October 2026 with text in step 5, and turns the switch on on Monday 12 October
- **THEN** the scheduler schedules the worksheet review reminder for 18:00 on Saturday 17 October

#### Scenario: A reminder for a deleted worksheet
- **WHEN** the person opens a worksheet review reminder, and the winning row of that worksheet in the store has `deleted = true`
- **THEN** the app shows Today with no message

#### Scenario: Schedule the review
- **WHEN** the "Weekly review time" is 18:00 and the person taps "Done" at 21:10 on Saturday 10 October 2026 with text in step 5
- **THEN** the worksheet row holds the review day Saturday 17 October and no clock time, and the app schedules the worksheet review reminder for 18:00 on Saturday 17 October, not for 21:10

#### Scenario: A swipe down with a plan
- **WHEN** the "Weekly review time" is 18:00 and the person swipes the worksheet down at 21:10 on Saturday 10 October 2026 with text in step 5
- **THEN** the worksheet row holds the review day Saturday 17 October, and the reminder fires at 18:00 on Saturday 17 October

#### Scenario: The app ended before a close
- **WHEN** the person types "Pack a snack" in step 5 at 21:10 on Saturday 10 October 2026, the system ends the app's process before the worksheet closes, and the person opens the app at 08:00 on Sunday 11 October
- **THEN** the launch gives the worksheet the review day Saturday 17 October

#### Scenario: Done after midnight
- **WHEN** the day start is 04:00, the "Weekly review time" is 18:00, and the person taps "Done" at 01:30 on Sunday 11 October 2026 with text in step 5
- **THEN** the record day of the tap is Saturday 10 October, the worksheet row holds the review day Saturday 17 October, and the reminder fires at 18:00 on Saturday 17 October

#### Scenario: Across the end of British Summer Time
- **WHEN** the "Weekly review time" is 18:00, the person taps "Done" at 21:10 on Saturday 24 October 2026 with text in step 5, and the clocks go back one hour at 02:00 on Sunday 25 October
- **THEN** the worksheet row holds the review day Saturday 31 October, and the reminder fires at 18:00 by the clock on Saturday 31 October 2026, not at 17:00

#### Scenario: Open from the reminder
- **WHEN** the person opens the worksheet review reminder
- **THEN** the app opens the worksheet at "How did it go?"

#### Scenario: Review before the reminder
- **WHEN** the person types "Had the snack, urge passed" in step 6 on 14 October
- **THEN** the app cancels the 17 October reminder

#### Scenario: Done a second time
- **WHEN** the person edits step 5 on 12 October and taps "Done" again
- **THEN** the reminder stays at 18:00 on 17 October and the app schedules no second reminder

#### Scenario: Typing does not compute the reminders
- **WHEN** step 5 holds "Pack a snack", and the person types " on Sunday night" after it
- **THEN** the app asks the scheduler for no new computation until "Done" or a swipe down

### Requirement: Worksheet text stays on the device

The app MUST save every worksheet in the store on the device. The `data-and-privacy` capability owns sync to the person's iCloud private database and Delete-all. The app MUST NOT send worksheet text or a pattern sentence off the device by any other channel. The app MUST NOT send a group size, a starred total or an urge total off the device by any other channel. The app MUST NOT put worksheet text or a pattern sentence in the system log or an error. The app MUST NOT put them in a crash report.

Stage 4 adds no schema field and no record type. A worksheet is one `Sheet` row of kind "worksheet". `problem-solving` owns the row's `payloadJSON`. The payload holds these keys:

- `startedAt`: the moment the worksheet opened
- `startDayKey`: the record day key of that moment
- `linkedSentence` and `linkedPatternKey`: the linked sentence as it read at the start, and its pattern key, or neither
- `problem`: the text of step 1
- `options`: the lines of step 2, in their order, each with an `id` and its `text`
- `notes`: the text of step 3 for each option, by the option's `id`
- `chosenOptionIds`: the ids of the options with their switch on in step 4
- `steps`: the lines of step 5, in their order, each with an `id` and its `text`
- `howItWent`: the text of step 6
- `reviewDayKey`: the review day, or none

The delete moment of a worksheet is the `changedAt` of its row. A suggestion card's answer is an `Answer` row of kind "card" with `cardId`, `value`, `dateKey` and `changedAt`, as "The suggestion card" states.

Every worksheet row and every card answer row MUST carry its own changedAt. An edit MUST write into the winning row that `data-and-privacy` defines. When two devices change one worksheet, the row with the later `changedAt` wins whole, and the change on the other device is lost. This includes the review day. The team accepts this loss, as for the other rows that `data-and-privacy` names. The store MUST NOT hard-delete a worksheet row or a card answer row. Only Delete-all, which `data-and-privacy` owns, deletes them.

Delete-all MUST delete every worksheet and every card answer row of a suggestion card. When the app is not active, the cover of `app-lock` hides the worksheet and the Problem solving screen, as "The cover" states. The cover shows over every screen and every sheet. The app MUST NOT add a redaction of its own to these screens. Ash ruled this on 7 October 2026 (r16-02).

#### Scenario: Store error
- **WHEN** the store fails to save a worksheet with step 1 "Evenings after a missed lunch"
- **THEN** the error the store throws contains no part of "Evenings after a missed lunch"

#### Scenario: App switcher
- **WHEN** the person opens the app switcher while a worksheet is on screen
- **THEN** the app's snapshot shows no worksheet text and no pattern sentence

#### Scenario: Delete-all
- **WHEN** the person taps Delete-all
- **THEN** the "Worksheets" list is empty, and the after 20:00 template can show a suggestion card again

#### Scenario: A worksheet edited on two devices
- **WHEN** device A changes step 1 of a worksheet at 09:00, device B changes step 2 of the same worksheet at 09:05, and the person taps "Sync now" on both devices
- **THEN** both devices show the worksheet as device B saved it, and the change of device A to step 1 is lost

### Requirement: Accessibility of problem solving

Each pattern sentence MUST be one accessibility element whose label is the sentence text. Every control on the Problem solving screen, the suggestion card and the worksheet MUST have a VoiceOver label. Each step's question MUST carry the header trait. The heading "Worksheets" MUST carry the header trait.

The label of the field of step 1 and of step 6 MUST be its step's question. In step 3, the label of each field MUST be the step's question, then its option's text, for example "How would each one work out?, Plan an evening snack". In steps 2 and 5, the label of each line MUST be the step's question, then the line's number, for example "What could you do about it?, 2". A comma and a space MUST separate the parts of these labels.

The VoiceOver label of a visible "Move up" or "Move down" control MUST be its text, then the line's text, for example "Move up Plan an evening snack". On the Problem solving screen, the label of each "Work it through" control MUST be "Work it through", a comma and a space, then its sentence. Each of these labels starts with the visible text, so Voice Control finds the control by that text. Ash ruled this on 26 September 2026 (r13-08).

In step 4, each option MUST be one system switch. Its label MUST be the option's text, and its value MUST be on or off. So a chosen option does not depend on colour alone. Text on the Problem solving screen and the worksheet MUST use system text styles. That text MUST scale with Dynamic Type.

Each row of the "Worksheets" list MUST be one accessibility element. Its label MUST be the row's visible text, the first line of step 1 or "Worksheet", then the date. Each question in the title menu "Worksheet" MUST be one menu item with the question as its label. The suggestion card MUST follow the same rules, and its sentence MUST be one accessibility element. A control with no visible text MUST have a label a person can say with Voice Control.

When a worksheet that opened over Today closes, VoiceOver focus MUST move to "Add an entry", as after the new-entry screen. When a worksheet that opened over the Problem solving screen closes, VoiceOver focus MUST return to the control that opened it. When that control is gone, focus MUST move to "New worksheet".

#### Scenario: A chosen solution with VoiceOver
- **WHEN** VoiceOver focuses the switch of "Plan an evening snack" in step 4 after the person turned it on
- **THEN** VoiceOver reads "Plan an evening snack" as a switch with the value on

#### Scenario: A row of the "Worksheets" list
- **WHEN** VoiceOver focuses the row of a worksheet started on 3 October with step 1 "Evenings after a missed lunch"
- **THEN** it reads "Evenings after a missed lunch, 3 October"

#### Scenario: The suggestion card at the largest text size
- **WHEN** the person sets the largest accessibility text size and the card slot shows a suggestion card
- **THEN** the card shows the sentence, then "Work it through" and "Close" one under the other, without truncation

#### Scenario: VoiceOver reads a sentence
- **WHEN** VoiceOver reads the first pattern sentence
- **THEN** it reads "5 of your 7 starred entries were after 20:00." and nothing else for that element

#### Scenario: VoiceOver on step 1
- **WHEN** VoiceOver focuses the step 1 field
- **THEN** it reads "What is the problem, exactly?" as the field's label

#### Scenario: A step heading
- **WHEN** VoiceOver focuses the question of step 2
- **THEN** it reads "What could you do about it?" with the header trait, and the title menu "Worksheet" lists the six questions

#### Scenario: A field of step 3 with VoiceOver
- **WHEN** step 2 holds "Plan an evening snack" and VoiceOver focuses its field in step 3
- **THEN** it reads "How would each one work out?, Plan an evening snack" as the field's label

#### Scenario: A line with VoiceOver
- **WHEN** VoiceOver focuses the second line of step 2
- **THEN** it reads "What could you do about it?, 2" as the line's label

#### Scenario: The label of "Work it through"
- **WHEN** VoiceOver focuses "Work it through" under "5 of your 7 starred entries were after 20:00." on the Problem solving screen
- **THEN** it reads "Work it through, 5 of your 7 starred entries were after 20:00."

#### Scenario: Focus when a step opens
- **WHEN** VoiceOver is on, step 2 holds one line, and the person taps "Next" on step 1
- **THEN** VoiceOver focus moves to "What could you do about it?", and the keyboard is in the first line of step 2

#### Scenario: Focus after the card's worksheet
- **WHEN** VoiceOver is on, the person taps "Work it through" on the suggestion card, and then taps "Done"
- **THEN** VoiceOver focus is on "Add an entry" on Today

#### Scenario: Reorder with VoiceOver
- **WHEN** VoiceOver focuses the second line of step 2
- **THEN** the actions rotor offers "Move up" and "Move down"

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the Problem solving screen and the worksheet show all text without truncation
