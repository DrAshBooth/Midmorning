# dieting-module

## Purpose

The dieting module helps the person loosen food rules and eat avoided foods again, one step at a time. Its displayed name is "Food rules". Every string the person sees calls the module "Food rules". Only this spec and its capability directory keep the name dieting-module. The person writes two lists, arranges a ladder from least to most feared, and puts one reintroduction a week into a planned meal. The module counts nothing about food, and the app never labels a food.

## ADDED Requirements

### Requirement: The module opens from taking stock

The `programme` capability opens the dieting module's tools when taking stock is complete. The `weekly-review` capability owns taking stock and its module recommendation. The app MUST let the person open the dieting module whatever the recommendation says. The app MUST show the module's cards before taking stock, because the app never blocks reading ahead. The app MUST NOT show the module's lists, ladder or check before taking stock. The `content` capability owns the module's cards.

#### Scenario: Taking stock recommends the module
- **WHEN** taking stock at week 6 recommends the dieting module
- **THEN** the app shows the module with its cards, both lists, the ladder and the check

#### Scenario: Taking stock does not recommend the module
- **WHEN** taking stock at week 6 does not recommend the dieting module
- **THEN** the app shows the same module, with the same cards and tools, and no text about the recommendation

#### Scenario: Before taking stock
- **WHEN** the person opens the dieting module in week 3
- **THEN** the app shows the module's cards and no list, ladder or check

### Requirement: The module's displayed name is "Food rules"

Every string the person sees MUST name the module "Food rules". This covers the module screen's title, the stage 6 module title, the Programme screen row and the settings screen's link. It also covers a card title that names the module and the taking stock recommendation strings, such as "Open Food rules".

The `programme`, `settings`, `content` and `weekly-review` capabilities own those strings. Those capabilities MUST use this name. The app MUST NOT show "dieting" or "diet" as the module's name. The name dieting-module MUST appear only in this spec and its capability directory.

#### Scenario: The module screen
- **WHEN** the person opens the module from the Programme screen
- **THEN** the Programme screen row reads "Food rules" and the module screen's title is "Food rules"

#### Scenario: The recommendation
- **WHEN** taking stock recommends the module
- **THEN** the recommendation string names the module "Food rules", such as "Open Food rules", and does not contain "dieting"

#### Scenario: A reviewer lists every string
- **WHEN** a reviewer lists every string the app shows that names the module
- **THEN** each one reads "Food rules" and none reads "dieting" or "diet"

### Requirement: The food rules list

The app MUST let the person write food rules as a list of free-text items. The app MUST NOT offer preset rules, a picker or autocomplete. The app MUST show two lines above the list. The first is "Rules you keep about what you eat, or how much". The second is "A rule from a doctor, an allergy or your faith is not a rule to loosen. Leave those off this list."

The `content` capability owns the second line, and the dieting.rules card says the same. The app MUST keep the items in the order the person adds them. The app MUST let the person edit any item. The app MUST NOT show a count of items.

On an empty list the app MUST show the two lines and the add control only.

#### Scenario: Add a food rule
- **WHEN** the person types "no carbs after 18:00" and saves
- **THEN** the list shows "no carbs after 18:00" as one item, with no other response

#### Scenario: Edit a food rule
- **WHEN** the person opens "no carbs after 18:00" and changes it to "no bread after 18:00"
- **THEN** the list shows "no bread after 18:00" in the same position

#### Scenario: Empty list
- **WHEN** the person opens the list with no items
- **THEN** the app shows "Rules you keep about what you eat, or how much", then "A rule from a doctor, an allergy or your faith is not a rule to loosen. Leave those off this list.", then the add control, and nothing else

#### Scenario: A long list
- **WHEN** the list has twelve items
- **THEN** the app shows the twelve items at the same weight as a list of two, with no count

### Requirement: The avoided foods list

The app MUST let the person write avoided foods as a list of free-text items. The app MUST NOT offer a food database, a picker or autocomplete. The app MUST show two lines above the list. The first is "Foods you keep away from". The second is "A rule from a doctor, an allergy or your faith is not a rule to loosen. Leave those off this list."

The app MUST keep the items in the order the person adds them. The app MUST let the person edit any item. The app MUST NOT show a count of items.

#### Scenario: Add an avoided food
- **WHEN** the person types "Chocolate" and saves
- **THEN** the list shows "Chocolate" as one item, with no other response

#### Scenario: Two items with the same text
- **WHEN** the person adds "Chips" twice
- **THEN** the list shows two items with the text "Chips" and the app does not merge them

#### Scenario: Empty list
- **WHEN** the person opens the list with no items
- **THEN** the app shows "Foods you keep away from", then "A rule from a doctor, an allergy or your faith is not a rule to loosen. Leave those off this list.", then the add control, and nothing else

### Requirement: The app never labels or counts a food

The app MUST NOT show any label, colour, icon or word that judges a food. This includes "good", "bad", "safe", "unsafe", "healthy" and "unhealthy". The app MUST NOT show calories, portions, weights, quantities or any nutrition value in the module. The app MUST NOT sort, group or rank an item by any property of the food. Every item MUST use the same text style, background and spacing. The app MUST NOT add a word of its own to an item.

#### Scenario: An item on any list
- **WHEN** the avoided foods list shows "Chocolate"
- **THEN** the row shows the text "Chocolate" and no colour, icon, label or number

#### Scenario: A ladder step after an outcome
- **WHEN** a ladder step has a saved outcome
- **THEN** the step shows the person's text and the outcome text, and no tick, colour, label or number

#### Scenario: A reviewer checks the module
- **WHEN** a reviewer walks every screen of the module on the simulator
- **THEN** no screen shows calories, a portion, a quantity, a food judgement or a nutrition value

### Requirement: The ladder

The app MUST let the person build a ladder of steps from the two lists. A step is one avoided food or one food rule. The app MUST let the person arrange the steps, least feared at the top, most feared at the bottom. The app MUST NOT sort, rank or number the steps. The app MUST NOT ask for a fear rating or any number. The app MUST let the person move a step at any time.

A step holds its list item's id, and the app resolves it on read. When the person deletes a list item, the app MUST write the item's `deleted` flag with the moment. It MUST write nothing else. On read the app MUST hide the step of a deleted item and every reintroduction of a hidden step. The app MUST NOT write to the step or to its reintroductions.

#### Scenario: Build a ladder
- **WHEN** the person adds "Chocolate", "Chips" and "no carbs after 18:00" to the ladder in that order
- **THEN** the ladder shows the three steps in that order, with no numbers and no rating

#### Scenario: Move a step
- **WHEN** the person moves "no carbs after 18:00" to the top of the ladder
- **THEN** the ladder shows "no carbs after 18:00" first and the other steps keep their order

#### Scenario: Delete a list item
- **WHEN** the person deletes "Chips" from the avoided foods list
- **THEN** the ladder no longer shows "Chips", Today no longer shows "Ladder step" for its scheduled reintroduction, and the app writes only the item's `deleted` flag

#### Scenario: Empty ladder
- **WHEN** the ladder has no steps
- **THEN** the app shows a control to add a step from a list, and no text about the absence of steps

### Requirement: Schedule one reintroduction a week into a planned meal

The app MUST let the person schedule a step as a reintroduction into one planned meal. The `regular-eating-plan` capability owns planned meals, plans and templates. The app MUST offer the planned meals of the next 7 record days' plans or templates. The app MUST NOT offer a time outside a planned meal.

The `programme` capability counts programme weeks. A reintroduction holds its step's id and the planned meal's date key and slot index. The app resolves both on read.

When the chosen week has a scheduled reintroduction, the app MUST show one question and let the person continue. The question is "This week has one planned. Add a second?" with "Add" and "Not now". The app MUST NOT block the second reintroduction.

On Today the app MUST show the row "Ladder step" beside the planned meal's slot, and nothing else about it. The food's name or the rule's text MUST stay inside the module. The app MUST NOT put the reintroduction's text in any notification.

Before stage 2 opens, the app MUST show "A ladder step goes into a planned meal. Regular eating opens after %lld recorded days." The count enters through %lld from RECORDED_DAYS_FOR_STAGE_2, with plural forms. When stage 2 is open and no plan exists, the app MUST show "A ladder step goes into a planned meal. Set up a plan first." The app MUST show a link to the plan builder with it.

#### Scenario: Schedule the first step
- **WHEN** the person picks "Chocolate" and the mid-afternoon planned meal on Tuesday 17 November
- **THEN** the app saves one reintroduction of "Chocolate" for that planned meal, and Today shows "Ladder step" beside Mid-afternoon on Tuesday 17 November and not "Chocolate"

#### Scenario: A planned meal from a template
- **WHEN** the person picks Wednesday 18 November, whose plan is not set, and the weekday template has Mid-afternoon at 16:00
- **THEN** the app offers that planned meal from the template and saves the reintroduction for it

#### Scenario: A second reintroduction in the same week
- **WHEN** the person has a reintroduction on Tuesday 17 November and picks another planned meal on Thursday 19 November in the same programme week
- **THEN** the app shows "This week has one planned. Add a second?" and saves the second when the person taps "Add"

#### Scenario: The planned meal leaves the plan
- **WHEN** the person edits the plan and takes the mid-afternoon planned meal off Tuesday 17 November
- **THEN** the app keeps the reintroduction on Tuesday 17 November and lets the person choose another planned meal for it

#### Scenario: Before stage 2
- **WHEN** stage 2 is closed with 3 recorded days and the person taps the control to schedule a step
- **THEN** the app shows "A ladder step goes into a planned meal. Regular eating opens after 5 recorded days."

#### Scenario: No plan
- **WHEN** stage 2 is open, the person has no plan and taps the control to schedule a step
- **THEN** the app shows "A ladder step goes into a planned meal. Set up a plan first." and a link to the plan builder

#### Scenario: The reminder for that planned meal
- **WHEN** the mid-afternoon reminder fires on Tuesday 17 November with explicit wording on
- **THEN** the notification reads "Mid-afternoon, 16:00" and does not contain "Chocolate"

### Requirement: Write how it went

From the planned meal's time, the app MUST let the person write an outcome for the reintroduction. The outcome MUST be free text in the person's words. The app MUST let the person link the outcome to one entry of that record day, or to none. The reintroduction holds the entry's id, and the app resolves it on read. When the entry's winning version carries the `deleted` flag, the app MUST show the outcome without the link. The app MUST NOT write to the reintroduction because of that.

The app MUST NOT show a rating scale, a number, a face or a tick for the outcome. The app MUST NOT show "success" or "failure". The app MUST NOT infer an outcome from the record.

For a reintroduction with no outcome, the app MUST show at most one line, on the module screen. The line is "{weekday}, {slot}: how did it go?". The weekday comes from the en_GB formatter, and {slot} is the slot label as the person typed it. The app MUST NOT send a notification about a missing outcome. After an outcome the step MUST stay on the ladder, and the person can schedule it again. When the person deletes a reintroduction with no outcome, the app MUST draw no conclusion from it.

#### Scenario: Write an outcome
- **WHEN** the person opens the reintroduction of "Chocolate" at 16:00 on Tuesday 17 November and types "Had two squares with tea. Fine." and saves
- **THEN** the app saves the outcome text under the "Chocolate" step, with no rating and no other response

#### Scenario: Link an entry
- **WHEN** the person writes an outcome and picks the entry at 15:40 with What "Tea and chocolate"
- **THEN** the step shows the outcome text and "15:40, Tea and chocolate" under it

#### Scenario: No outcome yet
- **WHEN** the mid-afternoon planned meal on Tuesday 17 November passes with no outcome and the person opens the module on Wednesday 18 November
- **THEN** the module shows "Tuesday, Mid-afternoon: how did it go?" once, and the app sends no notification

#### Scenario: Linked entry deleted
- **WHEN** the person deletes the 15:40 entry from the record
- **THEN** the step shows the outcome text with no entry under it, and the app writes nothing to the reintroduction

#### Scenario: It did not happen
- **WHEN** the person types "Didn't do it. Wasn't the day." and saves
- **THEN** the app saves that text as the outcome, keeps "Chocolate" on the ladder, and shows no other text

#### Scenario: Schedule the same step again
- **WHEN** "Chocolate" has one outcome and the person schedules it into a planned meal in the next programme week
- **THEN** the app saves a second reintroduction of "Chocolate" and keeps the first outcome

### Requirement: The eating enough check

The module's check uses the gaps between planned meals and the plan from stage 2. The `regular-eating-plan` capability owns the plan and the gaps. The check MUST cover the last 7 record days. The check MUST group entries by the record day key the store writes at save, as `record` defines. On a fasting day, the day state `fasting` that `record` owns, the check MUST count no gap. The check MUST show two plain sentences and one question.

The first sentence states the days with an entry at every planned meal. Its form is "Days with an entry at every planned meal: %lld." with the count. The sentence MUST NOT show a denominator. The first sentence MUST keep this form whatever the number of planned days.

The second sentence states the longest gap over MAX_AWAKE_GAP_HOURS hours, or that there was none. Its first form is "The longest gap over %1$lld hours was %2$@, on %3$@." Its second form is "No gap over %lld hours." The hours enter through %lld from MAX_AWAKE_GAP_HOURS. The duration and the weekday come from the en_GB formatter.

The question is "Looking at your record, is any planned meal small because of a rule?" with one free-text field. The answer MUST be optional. The answer MUST accept an empty text. The app MUST keep the answer in the store and let the person edit it.

The check MUST use the same layout, colour and text style whatever the numbers. The check MUST NOT show a target, a percentage, a colour, a chart, praise or a warning. The check MUST NOT read the What text of any entry. The check MUST NOT count calories, portions or entries.

#### Scenario: A week on the plan
- **WHEN** the last 7 record days each have an entry at every planned meal and no gap over 4 hours
- **THEN** the check shows "Days with an entry at every planned meal: 7." and "No gap over 4 hours." in the same style as any other week

#### Scenario: A week with gaps
- **WHEN** 3 of the last 7 record days have an entry at every planned meal and the longest gap over 4 hours is 6 hours on Thursday
- **THEN** the check shows "Days with an entry at every planned meal: 3." and "The longest gap over 4 hours was 6 hours, on Thursday." with no colour and no warning

#### Scenario: Fewer than 7 planned days
- **WHEN** only 4 of the last 7 record days are planned days and 3 of them have an entry at every planned meal
- **THEN** the check reads "Days with an entry at every planned meal: 3." with no denominator, in the same form as any other week

#### Scenario: A paused day
- **WHEN** one of the last 7 record days is paused with "Pause for today"
- **THEN** the check leaves that day out of the gap sentence, keeps the form of the first sentence, and draws no conclusion from it

#### Scenario: A fasting day
- **WHEN** one of the last 7 record days is a fasting day and its entries are 9 hours apart
- **THEN** the check counts no gap on that day, takes the gap sentence from the other 6 days, and draws no conclusion from it

#### Scenario: Answer the question
- **WHEN** the person types "Lunch. I still don't eat bread." under the question and saves
- **THEN** the check shows that text under the question, with no other response

### Requirement: The person can delete anything and turn the check off

The app MUST let the person delete any list item, ladder step, reintroduction or outcome at any time. Deletion MUST use the system's standard delete action. Deletion MUST show no message. A delete MUST write `deleted = true` with the moment into the row. The app MUST NOT hard-delete a synced row. The app MUST hide a deleted row and its dependants on read.

Deleting an outcome MUST clear the outcome fields of its reintroduction with a new `changedAt`. The check MUST be opt-out with a switch on the module screen, labelled "Eating enough check". The switch MUST live on the module screen only. The settings screen MUST link to it. `settings` owns that link. The link reads "Food rules".

When the switch is off, the app MUST NOT compute or show the check. The `data-and-privacy` capability owns Delete-all. Delete-all MUST delete every item of the module.

#### Scenario: Delete a step with an outcome
- **WHEN** the person deletes the "Chocolate" step from the ladder
- **THEN** the ladder no longer shows "Chocolate", the ladder hides its reintroductions and their outcomes, the app writes only the step's `deleted` flag, and the avoided foods list still shows "Chocolate"

#### Scenario: Turn the check off
- **WHEN** the person turns off "Eating enough check"
- **THEN** the module shows no check sentences and no question, and the switch stays on screen to turn it on

#### Scenario: From the settings screen
- **WHEN** the person follows the settings screen's link "Food rules"
- **THEN** the app opens the module screen, titled "Food rules", with the "Eating enough check" switch on it, and the settings screen holds no switch of its own

#### Scenario: Delete-all
- **WHEN** the person uses Delete-all
- **THEN** both lists, the ladder, every reintroduction, every outcome and the check's answer are gone

### Requirement: The module's data stays in the store

The app MUST keep the lists, the ladder, reintroductions, outcomes and the check's answer in the store. Each list item, ladder step and reintroduction is one synced row with its own `changedAt` and a `deleted` flag with a moment. The check's answer is one synced row with its own `changedAt`. An edit MUST write into the winning row.

Every reference between rows is a key field that the app resolves on read. A step holds its list item id. A reintroduction holds its step id, its entry id, and the planned meal's date key and slot index. The store MUST NOT use a SwiftData relationship for any of them. The `data-and-privacy` capability owns the conflict rule and retention.

The store MUST give them the record's protection. The app MUST NOT put list, ladder, outcome or answer text in a notification, a log or an error. The app MUST hide the module's text when the app is not active. The `data-and-privacy` capability owns sync of the module's data to the person's private iCloud.

#### Scenario: App switcher
- **WHEN** the person opens the App Switcher while the avoided foods list is on screen
- **THEN** the app's snapshot shows no list text

#### Scenario: No network
- **WHEN** the device has no network connection
- **THEN** the person can add an item, arrange the ladder, schedule a reintroduction and write an outcome

#### Scenario: A step deleted on another device
- **WHEN** one device writes the `deleted` flag on the "Chocolate" step and a second device syncs that row
- **THEN** the second device hides the step and its reintroductions, and writes nothing to them

#### Scenario: Store error
- **WHEN** the store fails to save an outcome with the text "Had two squares with tea."
- **THEN** the error the store throws contains no part of that text

### Requirement: Accessibility of the module

Every control in the module MUST have a VoiceOver label. Every control MUST meet the hit-area rule that `product-rules` defines. Each list item and ladder step MUST be one accessibility element with the person's text as its label. The ladder MUST offer "Move up" and "Move down" as VoiceOver actions on each step.

In edit mode the ladder MUST show "Move up" and "Move down" as visible controls on each step. A step MUST NOT need a drag to move. Every text MUST scale with Dynamic Type. Meaning MUST NOT depend on colour alone.

#### Scenario: A ladder step with VoiceOver
- **WHEN** VoiceOver reads the step "Chocolate" with the outcome "Had two squares with tea. Fine."
- **THEN** it reads "Chocolate, Had two squares with tea. Fine." and offers "Move up" and "Move down"

#### Scenario: Move a step without a drag
- **WHEN** the person enters edit mode on a ladder of "Chocolate", "Chips" and "no carbs after 18:00" and taps "Move up" on "Chips"
- **THEN** the ladder shows "Chips", "Chocolate" and "no carbs after 18:00", with no drag

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** both lists, the ladder and the check show all text without truncation
