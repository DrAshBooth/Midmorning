# safeguarding

## Purpose

Safeguarding carries the duty of care that a guide would carry in a guided programme. It decides who the programme is not for, at onboarding and during the programme, and shows the pages that say so with warmth. It keeps a route to outside help on every screen after the person unlocks. It never diagnoses, never reads what the person writes, and never locks the person out of their record.

## ADDED Requirements

### Requirement: Screening rules for age, pregnancy and treatment

`onboarding` collects the screening answers and passes them here. The app MUST exclude a person whose age is under 18. The app MUST exclude a person who answers "Yes" to the pregnancy question, whose wording `onboarding` defines. The app MUST NOT exclude a person who answers "Doesn't apply to me". The app MUST exclude a person who answers "Yes" to the treatment question. The app MUST NOT exclude a person who answers "Yes, and they are happy for me to use this".

The typed age is the age gate. The app MUST NOT request the Declared Age Range entitlement in V1. The app MUST NOT read a declared age range from the system. The "Regulatory release gates" requirement states the age rating that goes with this rule.

The app MUST evaluate every rule when the person taps "Continue". When one or more rules exclude at onboarding, the app MUST show the exclusion page with every reason that applies. At a restart re-screen, the "Re-screening at a restart" requirement states what follows. When no rule excludes, the app MUST let onboarding continue.

#### Scenario: Under 18
- **WHEN** the person enters 17 for age
- **THEN** the app shows the exclusion page with the age reason

#### Scenario: Exactly 18
- **WHEN** the person enters 18 for age and no other rule applies
- **THEN** onboarding continues

#### Scenario: In treatment with agreement
- **WHEN** the person answers "Yes, and they are happy for me to use this" and no other rule applies
- **THEN** onboarding continues

#### Scenario: Pregnancy does not apply
- **WHEN** the person answers "Doesn't apply to me" and no other rule applies
- **THEN** onboarding continues

#### Scenario: Two reasons
- **WHEN** the person answers "Yes" to pregnancy and "Yes" to the treatment question
- **THEN** the exclusion page shows the pregnancy reason and the treatment reason

#### Scenario: No Declared Age Range
- **WHEN** a reviewer inspects the app's entitlements and the age rule's inputs
- **THEN** the Declared Age Range entitlement is absent and the rule reads only the typed age

### Requirement: The self-harm item

The self-harm item has two steps. The first question is "Over the last two weeks, have you had thoughts that you'd be better off dead, or of hurting yourself?" with "No", "Yes" and "I'd rather not say". On "Yes" the app MUST ask "Have you thought about how you would do it?" with "No" and "Yes". The app MUST NOT ask the second question after "No" or "I'd rather not say".

The second question avoids the word "plan", which the app uses for the eating plan. The clinical reviewer MUST sign off the wording and the routing of both questions. The "Regulatory release gates" requirement flags them for that sign-off. `onboarding`, `weekly-review` and `staying-on-track` place the item, and the restart re-screen in "Re-screening at a restart" asks it. This capability owns its wording and what follows.

At onboarding, when the person answers "Yes" to the second question, the app MUST exclude with the self-harm reason. When the person answers "Yes" to the first question and "No" to the second, the app MUST NOT exclude. After "No" or "I'd rather not say" the app MUST NOT exclude. The app MUST show nothing under the item after either of those answers.

After "Yes" and then "No" the app MUST show the support line under the item: "That deserves a person. Samaritans are there any time, on 116 123." Under the line the app MUST show the support sheet's items inline, with Samaritans first. "Continue" MUST stay active.

The app MUST NOT keep either answer in the store. The app MUST NOT write either answer to the system log or an error.

#### Scenario: No
- **WHEN** the person answers "No" at onboarding and no other rule applies
- **THEN** onboarding continues with no line under the item

#### Scenario: Rather not say
- **WHEN** the person answers "I'd rather not say" at onboarding and no other rule applies
- **THEN** onboarding continues with no line under the item and no second question

#### Scenario: Thoughts without a method
- **WHEN** the person answers "Yes" and then "No" at onboarding
- **THEN** the screen shows "That deserves a person. Samaritans are there any time, on 116 123." with Samaritans first, and "Continue" stays active

#### Scenario: Thoughts with a method
- **WHEN** the person answers "Yes" and then "Yes" at onboarding
- **THEN** the app shows the exclusion page with the self-harm reason first

### Requirement: Screening rules for BMI

The app MUST exclude a person whose onboarding BMI is below 18.5. The app MUST set the caution flag when the BMI is 18.5 or more and below 19.0. With the caution flag set and no rule that excludes, the app MUST show the caution sheet before onboarding continues. The caution sheet MUST show: "Your height and weight put you close to the range where this programme isn't the right tool. You can continue. If your weight falls, the app will say so and point you to your GP. If you're unsure, talk to your GP first."

The caution sheet MUST show "Continue", the GP paragraph with its "Copy" control, and Get support. The app MUST NOT set the caution flag when the BMI is 19.0 or more. The app MUST NOT show the BMI on the caution sheet or the exclusion page.

#### Scenario: Below 18.5
- **WHEN** the person is 170 cm and 53 kg, a BMI of 18.34
- **THEN** the app shows the exclusion page with the weight reason

#### Scenario: Caution band
- **WHEN** the person is 170 cm and 54 kg, a BMI of 18.69
- **THEN** the app shows the caution sheet, and after "Continue" onboarding continues with the caution flag set

#### Scenario: Above the caution band
- **WHEN** the person is 170 cm and 55 kg, a BMI of 19.03
- **THEN** onboarding continues with no caution sheet and the caution flag off

#### Scenario: Exactly 18.5
- **WHEN** the unrounded BMI is 18.50
- **THEN** the app shows the caution sheet and does not exclude

### Requirement: No question about vomiting or laxatives

The app MUST NOT ask about vomiting, laxatives, missed medicine or any other compensation at onboarding. The app MUST NOT ask about them at a weekly review, a check-in, taking stock or any other screen. The store MUST have no field for compensation. The app MUST NOT exclude a person for compensation. Ash ruled this on 24 September 2026 and confirmed it on 25 September 2026.

In place of a question, the app MUST tell the person in two places. Onboarding screen 1 and the "Talk to your GP" item in Get support MUST both show: "Some people make themselves sick, use laxatives, or miss insulin or another medicine after eating. If that happens more than about twice a week, this programme isn't the right tool on its own. Talk to your GP first." `content` bundles a stage-2 card, "Making up for it doesn't work". The team revisits this decision before beta. The proposal says so.

#### Scenario: Screening
- **WHEN** a reviewer lists every question at onboarding
- **THEN** none names vomiting, laxatives or compensation

#### Scenario: Weekly review
- **WHEN** a reviewer lists every question at a weekly review
- **THEN** none names vomiting, laxatives or compensation

#### Scenario: The store
- **WHEN** a reviewer lists every field in the store's model
- **THEN** no field holds compensation

#### Scenario: The sentence in Get support
- **WHEN** the person opens the support sheet and reads "Talk to your GP"
- **THEN** the sentence about making yourself sick, using laxatives or missing medicine is above the GP paragraph

### Requirement: The exclusion page

The exclusion page MUST show the heading "Not right now". Under it the page MUST show: "From your answers, this programme isn't the right thing for you at the moment. Here's why, and what can help instead." The page MUST show one paragraph for each reason that applies, in this order: self-harm, age, weight, pregnancy, treatment. The paragraphs are:

- Self-harm: "You said you've had thoughts of hurting yourself. That deserves a person, not a programme. Samaritans are there any time, on 116 123. If you are in danger now, call 999."
- Age: "Midmorning is built for adults. Beat's Youthline is for anyone under 18: 0808 801 0711."
- Weight: "Your height and weight put you in a range where this programme isn't the right tool for you. This is not a judgement about you. Your GP can look at this with you, and Beat can help you get there."
- Pregnancy: "Pregnancy changes what eating needs to look like, and this programme isn't designed for that. Your GP or midwife can help with eating during pregnancy."
- Treatment: "The people treating you are the right ones to decide what sits alongside it. Ask them about Midmorning. If they're happy, you can come back and start."

Under the reasons the page MUST show the heading "What to do instead". Under that heading the page MUST show the GP paragraph with its "Copy" control. With the age reason the page MUST show the under-18 variant. With the self-harm reason and no age reason the page MUST show the self-harm variant. The page MUST show the four Beat numbers, each with "Call" and "Copy number", and "Beat webchat". The support sheet defines those controls.

The page MUST end with "You can come back if this changes." and one control, "Done". The page MUST show Get support. After an exclusion at onboarding, "Done" MUST return the app to "What this is and isn't". The page MUST NOT name a condition, a diagnosis or a BMI.

#### Scenario: Under 18
- **WHEN** the exclusion page opens for a person aged 16
- **THEN** it shows "Not right now", the age paragraph, "What to do instead", the under-18 GP paragraph, the Beat contacts and "You can come back if this changes."

#### Scenario: Self-harm first
- **WHEN** the exclusion page opens with the self-harm reason and the weight reason
- **THEN** the self-harm paragraph is above the weight paragraph and the GP paragraph is the self-harm variant

#### Scenario: Done
- **WHEN** the person taps "Done" on the exclusion page at onboarding
- **THEN** the app shows "What this is and isn't"

#### Scenario: Call Beat
- **WHEN** the person taps "Call" beside "England 0808 801 0677" and then "Call" on the Recents warning
- **THEN** the app starts the system call flow for 0808 801 0677

### Requirement: The app keeps nothing from an exclusion

The app MUST NOT keep the answers that led to an exclusion. The app MUST NOT keep the reasons or the screening date. With the weight reason at a restart re-screen, the app MUST set the synced `remindersPausedAt`, as "Re-screening at a restart" states. That value is the only data that the app keeps or syncs from an exclusion. It is a reminder value, not a screening date. The app MUST NOT block a later attempt at onboarding. On the next launch after an exclusion at onboarding, the app MUST show "What this is and isn't" with every field empty. Except for `remindersPausedAt`, the app MUST NOT send any signal about an exclusion off the device.

#### Scenario: Relaunch after exclusion
- **WHEN** the person was excluded at onboarding on Thursday and opens the app on Friday
- **THEN** the app shows "What this is and isn't" and every screening field is empty

#### Scenario: The store after exclusion
- **WHEN** a reviewer inspects the store after an exclusion at onboarding
- **THEN** it holds no age, height, weight, BMI, date, answer or reason

### Requirement: Re-screening at every weekly review and check-in

Every weekly review and every check-in MUST ask the self-harm item with both steps. `weekly-review` and `staying-on-track` place the item. "Done" MUST be available with any answer, including no answer. When the person answers "Yes" and then "No", the app MUST show the support line under the item. Under the line the app MUST show the support sheet's items inline, with Samaritans first. The review MUST continue.

When the person answers "Yes" and then "Yes", the app MUST show the not-right-now page at once. The page shows the self-harm reason.

When the person answers "No" or "I'd rather not say", the review MUST continue with no other response. "Done" MUST close the review or the check-in with the item answered or not. The app MUST NOT move focus to the item. The app MUST NOT show a count of questions left. When the person taps "Done" or leaves without an answer, the store MUST keep `selfHarmAnswered: false` for that review. The next review MUST ask again.

With any answer the store MUST keep `selfHarmAnswered: true` for that review. The store MUST NOT keep the answer. The app MUST NOT show a count of answers or a history of them. The app MUST NOT cancel or pause a reminder because of any answer.

#### Scenario: Thoughts with a method at review
- **WHEN** the person answers "Yes" and then "Yes" at the week 3 review
- **THEN** the app shows the not-right-now page with the self-harm reason and the scheduler keeps every reminder

#### Scenario: Thoughts without a method at review
- **WHEN** the person answers "Yes" and then "No" at the week 3 review
- **THEN** the review shows "That deserves a person. Samaritans are there any time, on 116 123." with Samaritans first, and continues

#### Scenario: No at review
- **WHEN** the person answers "No" at the week 3 review
- **THEN** the review continues with no message

#### Scenario: Review left open
- **WHEN** the person closes the week 3 review before the item and opens the week 4 review
- **THEN** the week 4 review asks the item

#### Scenario: Done without an answer
- **WHEN** the person taps "Done" at the week 3 review with the self-harm item unanswered
- **THEN** the review closes, the row holds `selfHarmAnswered: false`, and the week 4 review asks the item

#### Scenario: The store after a review
- **WHEN** a reviewer inspects the week 3 review row after any answer
- **THEN** the row holds `selfHarmAnswered: true` and no answer

### Requirement: Re-screening at a restart

`programme` owns the restart control, "Start week 1 again", and the start-day choice it opens. A check-in's "Restart the programme?" is a shortcut to the same control. `staying-on-track` places it.

The app MUST count record days from the record day of the last screening. The last screening is onboarding or the latest re-screen at a restart with no exclusion, whichever is later. The app MUST NOT count from the start day or the restart moment.

The app MUST keep the moment of the last screening in the Profile field `askedAt`, with its own `changedAt`. The field name MUST NOT contain a word about screening, as `data-and-privacy` requires. The app MUST write `askedAt` at onboarding and at each re-screen at a restart with no exclusion. The app MUST NOT write `askedAt` at a weekly review or a check-in. When `askedAt` is later than the device clock, the app MUST re-screen at the next restart, as for more than 84 record days.

Within 84 record days of the last screening, the app MUST NOT ask a screening question at a restart. The app MUST show the start-day choice at once.

More than 84 record days after the last screening, the app MUST re-screen before the start-day choice. The re-screen MUST ask height and weight, with the wording `onboarding` defines. It MUST ask pregnancy, treatment and the self-harm item with both steps. The app MUST NOT ask the age again. The app MUST compute the BMI as `onboarding` defines. The app MUST apply every screening rule except the age rule to the answers.

The BMI rules, with the caution sheet, apply to the new height and weight. At a re-screen, the app MUST exclude with the self-harm reason after "Yes" and then "Yes". After "Yes" and then "No", the app MUST show the support line as the self-harm item defines. The re-screen MUST then continue.

When no rule excludes, the app MUST replace the height, the onboarding BMI, the caution flag and `askedAt`. Each is a Profile field with its own `changedAt`.

Every device keeps the restart's later write. `data-and-privacy` defines that rule. The app MUST NOT compare creation moments. The app MUST then show the start-day choice.

When a rule excludes, the app MUST NOT restart. The app MUST open the not-right-now page with every reason that applies, not the exclusion page. With the weight reason, the app MUST set the synced `remindersPausedAt`, as for Rule A. The app MUST NOT replace the height, the onboarding BMI, the caution flag or `askedAt` when a rule excludes. "Done" on that page MUST return the app to the screen beneath. The record, the plan and every list MUST stay as they were.

#### Scenario: Restart a year later
- **WHEN** the last screening was at onboarding on Monday 5 January and the person taps "Start week 1 again" on 20 January the next year
- **THEN** the app asks height, weight, pregnancy, treatment and the self-harm item, and not the age

#### Scenario: Restart within 84 record days
- **WHEN** the last screening was at onboarding on Monday 5 January and the person taps "Start week 1 again" on Monday 2 March, 56 record days later
- **THEN** the app asks no question and shows the start-day choice at once

#### Scenario: Restart on the 84th record day
- **WHEN** the last screening was at onboarding on Monday 5 January and the person taps "Start week 1 again" on Monday 30 March, 84 record days later
- **THEN** the app asks no question and shows the start-day choice at once

#### Scenario: Restart from a check-in
- **WHEN** the last screening was at onboarding on Monday 5 January, the person finished on Wednesday 25 March and taps "Restart" at the check-in on Wednesday 22 April, 107 record days after that screening
- **THEN** the app re-screens before the start-day choice

#### Scenario: New BMI
- **WHEN** the person re-screens at 170 cm and 65 kg and no rule excludes
- **THEN** the store holds 170 and 22.49 as the height and the onboarding BMI, and the start-day choice opens

#### Scenario: The restart's height wins on another device
- **WHEN** one device holds the height 170 from onboarding, the person re-screens at 172 cm on a second device, and they sync
- **THEN** every device reads 172 as the height, because the restart's write has the later `changedAt`

#### Scenario: Underweight at a re-screen
- **WHEN** the person re-screens more than 84 record days after the last screening and enters 170 cm and 53 kg
- **THEN** the app does not restart, opens the not-right-now page with the weight reason and sets `remindersPausedAt`, and the store keeps the earlier height, onboarding BMI and `askedAt`

#### Scenario: Excluded at a restart
- **WHEN** the person answers "Yes" to the pregnancy question at a re-screen
- **THEN** the app opens the not-right-now page with the exclusion page's pregnancy paragraph, and after "Done" the record and the plan are as they were

#### Scenario: Self-harm Yes then Yes at a restart
- **WHEN** the person answers "Yes" and then "Yes" to the self-harm item at a re-screen
- **THEN** the app opens the not-right-now page with the self-harm reason, does not restart, and the scheduler keeps every reminder

#### Scenario: Self-harm Yes then No at a restart
- **WHEN** the person answers "Yes" and then "No" to the self-harm item at a re-screen
- **THEN** the re-screen shows "That deserves a person. Samaritans are there any time, on 116 123." with Samaritans first, and continues

#### Scenario: askedAt in the future
- **WHEN** a device clock ran a year ahead at the last re-screen, so `askedAt` is later than the corrected device clock, and the person taps "Start week 1 again"
- **THEN** the app re-screens before the start-day choice

#### Scenario: Restarts less than 84 record days apart
- **WHEN** the person re-screens with no exclusion at a restart on Monday 5 January, restarts on Friday 6 March, 60 record days later, and restarts on Sunday 5 April, 90 record days after the re-screen
- **THEN** the app asks no question on 6 March, and on 5 April, 30 record days after the last restart, it re-screens before the start-day choice

### Requirement: The underweight check

The app MUST run the underweight check each time the person saves a weigh-in. The app MUST NOT run the check when no weigh-in exists. With "I won't be weighing" chosen at onboarding, no weigh-in exists until the person picks a weigh-in day and saves one. `onboarding` and `weigh-in` define that choice.

The check MUST use the rolling average that `weigh-in` computes, the height, the onboarding BMI and the caution flag. The app MUST compute the implied BMI as the rolling average in kilograms divided by the height in metres squared. Rule A applies when the implied BMI is below 18.5. When Rule A applies, the app MUST show the not-right-now page with the weight reason. Of Rules A to C, only Rule A shows the not-right-now page.

Rule B applies when the implied BMI is below 19.5 and at least 1.0 below the onboarding BMI. When Rule B applies, the app MUST show the GP suggestion page with the falling weight reason. Rule C compares the rolling average with the rolling average at the latest weigh-in 28 or more days earlier. Rule C applies when the current value is 5% or more below that earlier value. With the caution flag set, Rule C MUST use 3% in place of 5%. When Rule C applies, the app MUST show the GP suggestion page with the quick change reason.

When no weigh-in is 28 or more days old, the app MUST NOT apply Rule C. When Rule A applies with another rule, the app MUST show the not-right-now page only. When Rules B and C both apply, the page MUST show both reasons. The app MUST NOT show the implied BMI, the onboarding BMI or the height. The app MUST run the check at most once per saved weigh-in.

#### Scenario: Rule A
- **WHEN** the height is 170 cm and the rolling average is 53.0 kg, an implied BMI of 18.34
- **THEN** the app shows the not-right-now page with the weight reason

#### Scenario: Rule B
- **WHEN** the onboarding BMI is 20.76, the height is 170 cm and the rolling average is 56.0 kg, an implied BMI of 19.38
- **THEN** the app shows the GP suggestion page with "Your weight has come down since you started."

#### Scenario: Rule C
- **WHEN** the rolling average was 70.0 kg at the weigh-in 28 days earlier and is 66.0 kg now
- **THEN** the app shows the GP suggestion page with "Your weight has changed quickly over the last four weeks."

#### Scenario: Rule C with the caution flag
- **WHEN** the caution flag is set, the onboarding BMI is 18.9, the height is 170 cm, the rolling average was 56.0 kg 28 days earlier and is 54.2 kg now
- **THEN** the app shows the GP suggestion page with the quick change reason

#### Scenario: No rule applies
- **WHEN** the onboarding BMI is 24.2, the height is 170 cm, the rolling average was 70.0 kg 28 days earlier and is 68.5 kg now
- **THEN** the app shows no page

#### Scenario: No weigh-in
- **WHEN** the person chose "I won't be weighing" and reaches the week 6 review with no weigh-in saved
- **THEN** the app runs no underweight check and shows no page from it

### Requirement: The deterioration rule

`weekly-review` freezes each week's starred count into its Review row at review time. At each weekly review the app MUST read the frozen counts of the last four reviews, the current one last. The rule fires when three conditions hold:

- each of the last three counts exceeds the count before it
- the latest count is at least 4
- the latest count is at least twice the first of the four

DETERIORATION_WEEKS = 3 is a named constant in `ProgrammeConstants`.

When the rule fires, the app MUST show the GP suggestion page with the reason "Your starred entries have gone up for %lld weeks in a row.", filled from DETERIORATION_WEEKS. It reads "Your starred entries have gone up for three weeks in a row." When fewer than four reviews exist, the app MUST NOT apply the rule. Every weekly review MUST offer the choice "I'm getting worse". When the person chooses it, the app MUST show the GP suggestion page at once with the reason "You said things are getting worse." The app MUST show the GP suggestion page at most once per weekly review.

#### Scenario: Three rising weeks
- **WHEN** the frozen counts for weeks 2 to 5 are 3, 4, 5 and 6 and the week 5 review opens
- **THEN** the app shows the GP suggestion page with "Your starred entries have gone up for three weeks in a row."

#### Scenario: Two rising weeks
- **WHEN** the frozen counts for weeks 2 to 5 are 4, 4, 5 and 6 and the week 5 review opens
- **THEN** the app shows no GP suggestion page

#### Scenario: Rising from a low count
- **WHEN** the frozen counts for weeks 2 to 5 are 0, 1, 2 and 3 and the week 5 review opens
- **THEN** the app shows no GP suggestion page, because the latest count is below 4

#### Scenario: Rising but not doubled
- **WHEN** the frozen counts for weeks 2 to 5 are 5, 6, 7 and 8 and the week 5 review opens
- **THEN** the app shows no GP suggestion page, because 8 is less than twice 5

#### Scenario: I'm getting worse
- **WHEN** the person chooses "I'm getting worse" at the week 3 review
- **THEN** the app shows the GP suggestion page with "You said things are getting worse."

### Requirement: The GP suggestion page

The page MUST show the heading "It might help to see your GP". Under it the page MUST show one reason with its line, or two when both apply. The reasons are:

- Falling weight: "Your weight has come down since you started." with "Your plan stays on. It's worth a word with your GP."
- Quick change: "Your weight has changed quickly over the last four weeks." with "Your plan stays on. It's worth a word with your GP."
- Deterioration: "Your starred entries have gone up for %lld weeks in a row.", filled from DETERIORATION_WEEKS, with "That's worth talking through with your GP. Your plan stays on."
- Getting worse: "You said things are getting worse." with "That's worth talking through with your GP. Your plan stays on."

A reason's line MUST NOT give a cause for the weight change. The page suggests the GP and says nothing about why.

Under the reason the page MUST show: "This is not a diagnosis, and nothing here is closed to you." The page MUST then show "Talk to your GP" with the GP paragraph and its "Copy" control. The page MUST show "Export your record to take with you" as a control that opens `export`. The page MUST show Get support and one control, "Done". "Done" MUST return the app to the screen beneath.

The app MUST NOT pause a reminder, close a tool or hide the record because of this page. The app MUST NOT write to `remindersPausedAt` from this page. The page MUST NOT show a number, a weight value or a count. The app MUST NOT show the page again until a rule fires again.

#### Scenario: From the weigh-in
- **WHEN** the page opens from Rule C
- **THEN** it shows the heading, the quick change reason and its line, the diagnosis line, the GP paragraph, the export control, Get support and "Done"

#### Scenario: Nothing closes
- **WHEN** the person taps "Done" on the page
- **THEN** the screen beneath returns, every open tool stays open and the scheduler keeps every reminder

#### Scenario: At the review
- **WHEN** the page opens from the deterioration rule at the week 5 review and the person taps "Done"
- **THEN** the review continues

### Requirement: The not-right-now page

The page MUST show the heading "This may not be right for you now". The self-harm reason is: "You said you've had thoughts of hurting yourself. That deserves a person, not a programme. Samaritans are there any time, on 116 123. If you are in danger now, call 999." The weight reason is: "Your weight has fallen to a point where this programme isn't the right tool for you. This is not a judgement about you. This is not a diagnosis. Your GP can look at this with you."

The page MUST show one paragraph for each reason that applies, in this order: self-harm, weight, pregnancy, treatment. A re-screen at a restart can give any of the four reasons. For pregnancy and treatment, the page MUST show the exclusion page's paragraphs, from the same bundled strings. The team MUST NOT write new wording for these two reasons.

Under the reasons the page MUST show "Talk to your GP" with the GP paragraph and its "Copy" control. With the self-harm reason the paragraph MUST be the self-harm variant. The page MUST show "Export your record to take with you" as a control that opens `export`. The page MUST show: "Your record stays here, and you can keep adding to it." The page MUST show Get support and one control, "Done".

With the weight reason, the app MUST set the synced `remindersPausedAt` to the current moment when the page opens. Each device then computes its effective reminders. `reminders` and `settings` state that rule. With the weight reason the page MUST show: "Reminders are paused. You can turn them on again in Settings." Without the weight reason, the app MUST NOT pause or cancel any reminder. Without the weight reason the page MUST show: "Your plan and its reminders stay on. You can turn them off in Settings."

After the page the app MUST NOT turn paused reminders on again without the person's tap. `reminders` owns the settings screen controls that turn them on again. "Done" MUST return the app to the screen beneath. After the page the record, every open tool and export MUST stay available. The app MUST NOT show the page again until a rule fires again.

#### Scenario: Self-harm reason
- **WHEN** the page opens from the self-harm item at a weekly review
- **THEN** it shows the heading, the self-harm reason, the self-harm GP paragraph, the export control, the record line, "Your plan and its reminders stay on. You can turn them off in Settings.", Get support and "Done"

#### Scenario: Weight reason
- **WHEN** the page opens from the underweight check
- **THEN** it shows the weight reason with "This is not a diagnosis.", "Reminders are paused. You can turn them on again in Settings." and no number

#### Scenario: Reminders paused by the weight reason
- **WHEN** the page opened from Rule A at 12:00 and a planned meal is at 13:00
- **THEN** the scheduler delivers no reminder at 13:00

#### Scenario: Reminders kept by the self-harm reason
- **WHEN** the page opened from the self-harm item at a weekly review at 12:00 and a planned meal is at 13:00
- **THEN** the scheduler delivers the planned meal reminder at 13:00

#### Scenario: The record stays
- **WHEN** the person taps "Done" and then taps the control that opens the new-entry screen
- **THEN** the new-entry screen opens and the person can save an entry

#### Scenario: Reminders back on
- **WHEN** the person turns reminders on in the settings screen after the page
- **THEN** the scheduler schedules the next planned meal reminder

#### Scenario: Two reasons at a re-screen
- **WHEN** a re-screen gives the self-harm reason and the weight reason
- **THEN** the self-harm paragraph is above the weight paragraph, the GP paragraph is the self-harm variant, the app sets `remindersPausedAt`, and the page shows "Reminders are paused. You can turn them on again in Settings."

#### Scenario: Four reasons at a re-screen
- **WHEN** a re-screen gives the treatment, pregnancy, weight and self-harm reasons
- **THEN** the page shows the self-harm paragraph, then the weight paragraph, then the exclusion page's pregnancy paragraph and then its treatment paragraph

### Requirement: Get support on every screen

Every screen the app presents full-screen MUST show a control labelled "Get support" in the navigation bar. A sheet that closes in one tap to a screen with the control is exempt. The cover is exempt, because the cover names nothing. Get support MUST appear only after the person authenticates.

The control MUST be in the same position on every screen. The control MUST use the text style of the other navigation controls. It MUST have no red, no alert icon and no count.

The control MUST be present on every onboarding screen and the three safeguarding pages. The cover MUST show "Midmorning" and "Unlock" only (`app-lock` owns the cover). One tap on the control MUST open the support sheet. The app MUST NOT hide the control behind a detector, a stage or a setting.

#### Scenario: Today
- **WHEN** the person is on Today
- **THEN** "Get support" is visible and one tap opens the support sheet

#### Scenario: Onboarding
- **WHEN** the person is on "What this is and isn't"
- **THEN** "Get support" is visible

#### Scenario: The cover
- **WHEN** app lock is on and the app opens to the cover
- **THEN** the cover shows "Midmorning" and "Unlock" and no "Get support" control, and "Get support" is visible on Today after the person unlocks

#### Scenario: New-entry screen
- **WHEN** the new-entry screen is open as a sheet over Today
- **THEN** the sheet has no "Get support" control and "Cancel" returns to Today, where the control is visible

### Requirement: The support sheet

The support sheet MUST have the title "Get support". It MUST list these items in this order:

- "Beat helpline" with the line "Beat is the UK charity for people who struggle with eating." and four numbers: "England 0808 801 0677", "Scotland 0808 801 0432", "Wales 0808 801 0433", "Northern Ireland 0808 801 0434". Under the numbers: "Opening hours are on Beat's website."
- "Beat webchat" as a link
- "Samaritans" with "116 123" and the line "Any time, about anything." Under it, one more number: "Samaritans in Welsh: 0808 164 0123."
- "Lifeline, Northern Ireland" with "0808 808 8000" and the line "Any time."
- "NHS 111" with "111" and the line "When you need help and it's not an emergency." Under it: "England, Scotland and Wales. In Northern Ireland, call your GP out-of-hours service."
- "999" with the line "If you are in danger now."
- "Talk to your GP" with the sentence about making yourself sick, using laxatives or missing medicine, then the GP paragraph and its "Copy" control

When the sheet opens from a self-harm reason, "Samaritans" MUST be the first item. Each number MUST show two controls, "Call" and "Copy number". "Call" MUST first show "This call will show in your phone's Recents." with "Call" and "Cancel". The line MUST NOT mention a phone bill, because the helplines are free and unitemised.

"Call" on that warning MUST start the system call flow for the number. "Cancel" MUST return the app to the sheet. "Cancel" MUST NOT start a call. "Copy number" MUST place the number on the pasteboard under the rules the GP paragraph's "Copy" follows.

"Beat webchat" MUST open Beat's help page in an SFSafariViewController over the sheet. The app MUST NOT open the page in Safari or in a WKWebView. Safari's history MUST hold no new item after the view closes. The sheet MUST work with no network except the webchat link. The sheet MUST NOT show any entry, weight value, stage or programme data.

The app MUST hold every number and link in the bundled strings. The app MUST NOT fetch a number or a link from a network. Before every release a reviewer MUST check each number, its hours and the webchat URL against the service's own website. The reviewer MUST write a dated line in the change's README with each number, its hours and the webchat URL. The app MUST NOT send any signal about a tap on "Get support" off the device.

#### Scenario: The list
- **WHEN** the support sheet opens from Today
- **THEN** it shows Beat helpline with four numbers, Beat webchat, Samaritans with the Welsh number, Lifeline, NHS 111, 999 and Talk to your GP, in that order, and nothing from the record

#### Scenario: From a self-harm reason
- **WHEN** the support sheet opens from the not-right-now page with the self-harm reason
- **THEN** "Samaritans" with "116 123" is the first item

#### Scenario: Call Samaritans
- **WHEN** the person taps "Call" beside "116 123"
- **THEN** the sheet shows "This call will show in your phone's Recents." with "Call" and "Cancel", and a tap on "Call" starts the system call flow for 116 123

#### Scenario: Cancel the call
- **WHEN** the person taps "Call" beside "116 123" and then "Cancel"
- **THEN** the sheet returns and the app starts no call

#### Scenario: Call Beat in Scotland
- **WHEN** the person taps "Call" beside "Scotland 0808 801 0432" and then "Call" on the warning
- **THEN** the app starts the system call flow for 0808 801 0432

#### Scenario: Copy a number
- **WHEN** the person taps "Copy number" beside "Lifeline, Northern Ireland"
- **THEN** the pasteboard holds "0808 808 8000" with the local-only option and a 60-second expiry, and the sheet shows "Copied. It clears in a minute."

#### Scenario: Beat webchat
- **WHEN** the person taps "Beat webchat"
- **THEN** Beat's help page opens in an SFSafariViewController over the sheet, and Safari's history holds no new item

#### Scenario: Offline
- **WHEN** the device has no network and the person opens the support sheet
- **THEN** every number, the GP paragraph and "Copy" work

#### Scenario: Release check
- **WHEN** the team prepares a release
- **THEN** the change's README holds a dated line with each number, its hours and the webchat URL

### Requirement: The GP paragraph

The GP paragraph is: "I'd like to talk about my eating. I've been having times when I eat a lot and feel out of control. I've been following a self-help programme on my phone and I have a record I can show you. Can we talk about what support there is?" The self-harm variant adds one sentence at the end: "I've been having thoughts of hurting myself and I'd like to talk about that." The under-18 variant is: "I'd like to talk about my eating. Is there someone for people my age I can see?"

The app MUST show the paragraph in an editable text field, with Dynamic Type, wherever a spec places it. The app MUST show a "Copy" control under the field. "Copy" MUST place the text as edited on the general pasteboard with the local-only option and a 60-second expiry. The app MUST NOT send the text through Universal Clipboard. After "Copy" the control's label MUST read "Copied" for two seconds and then "Copy".

After "Copy" the screen MUST show "Copied. It clears in a minute." under the field until the screen closes. After "Copy" the app MUST post the VoiceOver announcement "Copied". The app MUST NOT keep an edited text after the screen closes. The next time the paragraph shows, the app MUST show the bundled text.

The app MUST NOT add any entry, weight, date or programme data to the copied text. `content` bundles the paragraph and its two variants.

#### Scenario: Copy
- **WHEN** the person taps "Copy" without an edit
- **THEN** the pasteboard holds the paragraph and nothing else, the label reads "Copied", the screen shows "Copied. It clears in a minute." and VoiceOver announces "Copied"

#### Scenario: The pasteboard clears
- **WHEN** 60 seconds pass after "Copy"
- **THEN** the pasteboard no longer holds the paragraph

#### Scenario: Universal Clipboard
- **WHEN** the person taps "Copy" on a device signed into iCloud with Handoff on
- **THEN** a Mac signed into the same account receives nothing on its pasteboard

#### Scenario: Copy after an edit
- **WHEN** the person deletes the third sentence and taps "Copy"
- **THEN** the pasteboard holds the three remaining sentences

#### Scenario: Edit not kept
- **WHEN** the person edits the paragraph, closes the sheet and opens it again
- **THEN** the field shows the bundled paragraph

#### Scenario: Copy and paste into Messages
- **WHEN** the person pastes into another app within a minute of "Copy"
- **THEN** the pasted text is the paragraph, with no entry, weight or date

#### Scenario: Largest text size
- **WHEN** the person uses the largest accessibility text size and opens the support sheet
- **THEN** the paragraph shows in full without truncation

### Requirement: V1 does not read free text for risk

The app MUST NOT scan What, Context, a worksheet, the "feeling fat" notes or any free text for risk words. The app MUST NOT show an alert, a message or a page because of the content of free text. The app bundle MUST contain no word list or classifier for risk detection. The reason follows. A word list gives false alarms on ordinary entries and false reassurance on real ones. Nobody is on the other end to act on a result.

Get support is on every screen after the person unlocks instead. A guided V2 changes this first. Onboarding screen 1 tells the person: "No person and no AI reads what you write. The app counts your starred entries, times and places to build your weekly review, on this device only."

#### Scenario: Free text about self-harm
- **WHEN** the person saves an entry whose Context reads "I want to hurt myself"
- **THEN** the app saves the entry as any other and shows no alert, message or page

#### Scenario: The bundle
- **WHEN** a reviewer inspects the app bundle
- **THEN** it contains no word list or model for risk detection

#### Scenario: Get support unchanged
- **WHEN** the person saves any free text
- **THEN** "Get support" stays where it was, with no change in appearance

### Requirement: What is a treatment claim

The app MUST NOT claim more about itself than this: "a structured self-help programme based on CBT principles for people who binge eat". The app MUST NOT say that it treats, cures, prevents, diagnoses or monitors a condition. This rule covers every string in the app, the widgets, the reminders and the App Store listing. The app MUST NOT describe itself with "treatment", "clinically proven", "therapy" or "the treatment NICE recommends".

The app can make a negative statement: "It is not therapy." The app can describe the method: "based on CBT principles" or "It uses ideas from CBT." The app can describe the person: "for people who binge eat" or "binge eating". The app MUST NOT use "binger", "bingeing behaviour" or "binge episode" in any string. The exclusion page, the not-right-now page and the GP suggestion page MUST say "this programme isn't the right tool", never a condition or a diagnosis.

#### Scenario: Screen 1
- **WHEN** a regulatory reviewer reads "Midmorning is a 12-week self-help programme for people who binge eat. It uses ideas from CBT."
- **THEN** the sentence passes

#### Scenario: A card draft
- **WHEN** a card draft reads "Midmorning treats binge eating"
- **THEN** the sentence fails and the card does not ship

#### Scenario: A marketing draft
- **WHEN** an App Store draft reads "based on the treatment NICE recommends"
- **THEN** the sentence fails and the listing does not ship

#### Scenario: A negative statement
- **WHEN** a reviewer reads "It is not therapy, and it does not replace your GP or anyone treating you."
- **THEN** the sentence passes

#### Scenario: A forbidden form
- **WHEN** a card draft reads "for bingers"
- **THEN** the sentence fails and the card does not ship

### Requirement: Regulatory release gates

The team MUST hold a written MHRA classification opinion before it gives any build to a person outside the team. A TestFlight build counts as such a build. A regulatory reviewer MUST review every claim before launch. The reviewer MUST write a dated line in the change's README. The App Store subtitle MUST be "A 12-week self-help programme for people who binge eat".

The App Store category MUST be Lifestyle. The review notes MUST carry the justification for that category: "a structured self-help programme, not a tracker, and holds no HealthKit data". `data-and-privacy` owns the review notes and the demo video that walks every stage on a device.

The App Store listing MUST be available on the United Kingdom storefront only. The organisation in App Store Connect and the copyright field MUST name one legal entity. The privacy notice's controller and the DPIA's controller MUST name the same entity. `data-and-privacy` owns the other release gates: the DPIA, the privacy notice and the age rating.

The change's README MUST hold the clinical reviewer's dated sign-off of the screening thresholds. The team MUST NOT give a build to a person outside the team before that sign-off. The sign-off MUST name 18.5, 19.0, Rules A to C and the deterioration rule. The sign-off MUST cover the wording and the routing of both self-harm questions.

The team MUST answer the age rating questionnaire truthfully. The team MUST raise the minimum age to 18+. The app MUST NOT request the Declared Age Range entitlement in V1. The typed age is the gate.

The team MUST declare an accessibility label in App Store Connect only after a device check of that label. The check MUST have a dated screenshot in the README. The team MUST NOT declare a label from a simulator check alone.

A cohort runs while any person outside the team has a TestFlight build. During a cohort the team MUST ship a new build at least every 45 days. The team MUST NOT let a tester's build reach 75 days. The change's README MUST hold a dated line per build with its expiry. A build MUST NOT raise the minimum iOS version during a running cohort. The tester invitation MUST state the expiry rule and the exit: export, then "Delete everything".

The team MUST invite every tester by email. The team MUST NOT create a public TestFlight link. Test Information in App Store Connect MUST hold four items. They are the privacy notice URL, a contact email, the onboarding walk and the crash-log line that `data-and-privacy` defines.

#### Scenario: No opinion yet
- **WHEN** the team has no written MHRA classification opinion
- **THEN** the team gives no TestFlight or App Store build to anyone outside the team

#### Scenario: The subtitle
- **WHEN** a reviewer reads the App Store listing
- **THEN** the subtitle is "A 12-week self-help programme for people who binge eat"

#### Scenario: Storefront
- **WHEN** a reviewer checks the App Store availability
- **THEN** the app is available in the United Kingdom and in no other storefront

#### Scenario: Category
- **WHEN** a reviewer reads the App Store listing and the review notes
- **THEN** the category is Lifestyle and the review notes carry "a structured self-help programme, not a tracker, and holds no HealthKit data"

#### Scenario: Build cadence
- **WHEN** a tester outside the team installed a TestFlight build 45 days ago and no newer build exists
- **THEN** the team ships a new build that day, and the README gains a dated line with the new build's expiry

#### Scenario: Minimum iOS version
- **WHEN** a cohort is running and a build would raise the minimum iOS version
- **THEN** the team does not ship that build until the cohort ends

#### Scenario: The invitation
- **WHEN** a reviewer reads the tester invitation
- **THEN** it states that a build expires, the 45-day rule, and the exit: export, then "Delete everything"

#### Scenario: One legal entity
- **WHEN** a reviewer compares the organisation in App Store Connect, the copyright field, the privacy notice and the DPIA
- **THEN** all four name the same legal entity

#### Scenario: Thresholds signed off
- **WHEN** the team prepares the first build for a person outside the team
- **THEN** the README holds the clinical reviewer's dated sign-off naming 18.5, 19.0, Rules A to C, the deterioration rule and both self-harm questions

#### Scenario: Age rating
- **WHEN** a reviewer reads the age rating questionnaire and the entitlements
- **THEN** the minimum age is 18+ and no Declared Age Range entitlement is present

#### Scenario: Accessibility label without a screenshot
- **WHEN** a device check of VoiceOver has no dated screenshot in the README
- **THEN** the team does not declare the VoiceOver label in App Store Connect

#### Scenario: Testers by email
- **WHEN** the team invites a tester
- **THEN** the team sends the invitation to the tester's email address and no public TestFlight link exists

#### Scenario: Test Information
- **WHEN** a reviewer reads Test Information in App Store Connect
- **THEN** it holds the privacy notice URL, a contact email, the onboarding walk and the crash-log line
