# onboarding

## Purpose

Onboarding is the four screens the person passes once, before the programme starts. It says what Midmorning is and is not, and collects the screening answers that safeguarding judges. It keeps the person's commitment, says where the record lives, and asks for permissions. In the first cut the record lives on this device only. The iCloud choice, and the offer to get a record back from iCloud, come with the later sync change that data-and-privacy names. It takes under three minutes and creates no account.

## MODIFIED Requirements

### Requirement: Screen 3: weigh-in day and quiet hours

The screen MUST show "Weigh-in day" with the seven weekdays as one-tap choices. Under the weekdays the screen MUST show one more choice, "I won't be weighing". The app MUST NOT preselect a weekday or "I won't be weighing". Under the choices the screen MUST show: "Once a week, on this day, the app asks for your weight and shows the trend. There is no goal and no target." The screen MUST show a "Quiet hours" switch with a start time and an end time. The switch MUST default to on.

The times MUST default to 22:00 and 07:00. The "Continue" control MUST stay active. When the person taps "Continue" with no choice under "Weigh-in day", the app MUST move VoiceOver focus to "Weigh-in day". The app MUST then show "Please answer this one." under the choices. The app MUST NOT advance.

The store MUST keep the weigh-in day or the "I won't be weighing" choice. The store MUST keep the quiet hours switch and the two times. The choice syncs as the weigh-in day does. `data-and-privacy` lists it. `reminders` honours quiet hours. `weigh-in` uses the weigh-in day.

With "I won't be weighing" chosen, the scheduler MUST NOT schedule a weigh-in day reminder. Every weekly review and every check-in MUST leave the weigh-in part out. The weigh-in screen MUST stay open. The weigh-in screen MUST show "Choose a weigh-in day". The person can pick a day there later.

`weigh-in`, `reminders`, `weekly-review` and `staying-on-track` state those rules. `safeguarding` runs the underweight check only when a weigh-in exists.

#### Scenario: No weigh-in day chosen
- **WHEN** the person taps "Continue" without tapping a weekday or "I won't be weighing"
- **THEN** the screen stays, VoiceOver focus moves to "Weigh-in day", and "Please answer this one." shows under the choices

#### Scenario: Weigh-in day chosen
- **WHEN** the person taps "Sunday" and completes onboarding
- **THEN** the store keeps Sunday as the weigh-in day

#### Scenario: I won't be weighing
- **WHEN** the person taps "I won't be weighing" and completes onboarding
- **THEN** the store keeps the choice, the scheduler holds no weigh-in day reminder, and the weigh-in screen shows "Choose a weigh-in day"

#### Scenario: Default quiet hours
- **WHEN** the person changes nothing under "Quiet hours" and completes onboarding
- **THEN** the store keeps quiet hours on, from 22:00 to 07:00

#### Scenario: Quiet hours changed
- **WHEN** the person sets 23:30 and 06:00 and completes onboarding
- **THEN** the store keeps quiet hours on, from 23:30 to 06:00

#### Scenario: Quiet hours off
- **WHEN** the person turns the "Quiet hours" switch off and completes onboarding
- **THEN** the store keeps quiet hours off
