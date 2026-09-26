# weigh-in

## Purpose

Ash's ruling of 26 September 2026 keeps the onboarding sentence on "Choose a weigh-in day" and states what "the explanation" is.

## MODIFIED Requirements

### Requirement: The weigh-in day

The weigh-in day is the weekday the person picked at onboarding, or none when the person chose "I won't be weighing". `onboarding` owns that choice. The weigh-in day MUST sync between the person's devices. `data-and-privacy` lists it as a shared setting.

The store MUST keep it as one settings row with a key, a value and a `changedAt`. When two devices set it, the app keeps the row with the later `changedAt`. The app MUST treat the weigh-in day as the record day whose calendar date falls on that weekday. `record` defines the record day and its day start.

The app MUST let the person change the weigh-in day from the weigh-in screen. The control's label MUST be "Weigh-in day". The control MUST offer the seven weekdays and "I won't be weighing". The setting in the settings screen MUST carry the same label, "Weigh-in day", and the same choices. `reminders` owns the switch "Weigh-in day reminder".

A change MUST take effect at once. The app MUST NOT show a message about the change. `reminders` owns the weigh-in day reminder and its default time of 07:30.

With no weigh-in day, the weigh-in screen MUST show "Choose a weigh-in day" with the seven weekdays as one-tap choices. Under the weekdays the screen MUST show the onboarding sentence "Once a week, on this day, the app asks for your weight and shows the trend. There is no goal and no target." The screen MUST then show no weight input, no refusal text, no chart and no explanation. In this capability, "the explanation" is the one-line explanation under the chart, as "The one-line explanation" requirement states. The onboarding sentence is not that explanation. Ash ruled this on 26 September 2026. `reminders` MUST NOT schedule a weigh-in day reminder while no weigh-in day exists. `weekly-review` and `staying-on-track` MUST leave the weigh-in part out of every review and check-in while no weigh-in day exists. A tap on a weekday MUST set the weigh-in day at once, with no message. The app MUST then treat the screen as it does after any change of the weigh-in day.

The person can choose "I won't be weighing" after weigh-ins exist. The screen then hides the chart, as the chart rule states. The store MUST keep every weigh-in. When the person picks a weigh-in day again, the chart MUST show every kept weigh-in. Decision 103 sets this rule. Ash ruled it on 25 September 2026.

#### Scenario: Weigh-in after midnight on the weigh-in day
- **WHEN** the weigh-in day is Monday and the person saves a weigh-in at 01:00 on Tuesday 29 September
- **THEN** the store writes the record day key Monday 28 September with the weigh-in

#### Scenario: Weigh-in before the day start on the weigh-in day
- **WHEN** the weigh-in day is Monday, the day start is 04:00, and the person opens the weigh-in screen at 02:00 on Monday 28 September
- **THEN** the app treats the moment as Sunday 27 September and shows no weight input

#### Scenario: No weigh-in day
- **WHEN** the person chose "I won't be weighing" at onboarding and opens the weigh-in screen on any day
- **THEN** the screen shows "Choose a weigh-in day" with the seven weekdays and the sentence "Once a week, on this day, the app asks for your weight and shows the trend. There is no goal and no target.", no weight input, no refusal text and no chart

#### Scenario: Choose a weigh-in day later
- **WHEN** the person has no weigh-in day and taps "Friday" under "Choose a weigh-in day" on Wednesday 30 September
- **THEN** the screen shows "Weigh-in day" as Friday, the app accepts a weigh-in on Friday 2 October, and `reminders` schedules the weigh-in day reminder on Friday at 07:30

#### Scenario: No reminder without a weigh-in day
- **WHEN** the person has no weigh-in day
- **THEN** the pending notification requests hold no weigh-in day reminder

#### Scenario: Change the weigh-in day
- **WHEN** the person has no weigh-in in the last six days and changes the weigh-in day from Monday to Friday on Wednesday 30 September
- **THEN** the screen shows "Weigh-in day" as Friday and the app accepts a weigh-in on Friday 2 October

#### Scenario: The reminder follows the weigh-in day
- **WHEN** the person changes the weigh-in day from Monday to Friday
- **THEN** `reminders` schedules the weigh-in day reminder on Friday at its set time, 07:30 by default

#### Scenario: Opt out after weigh-ins
- **WHEN** the person has four weigh-ins and picks "I won't be weighing" under "Weigh-in day" on the weigh-in screen
- **THEN** the screen shows "Choose a weigh-in day" with the seven weekdays, no chart and no explanation, and the store still holds the four weigh-ins

#### Scenario: A weigh-in day again after an opt-out
- **WHEN** the person has four weigh-ins, the last on Monday 26 October, and no weigh-in day, and taps "Friday" under "Choose a weigh-in day" on Wednesday 4 November
- **THEN** the screen shows the chart with four points, the explanation, and the refusal text that ends "Next: Friday 6 November."
