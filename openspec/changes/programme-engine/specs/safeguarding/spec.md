# safeguarding

## Purpose

Safeguarding carries the duty of care that a guide would carry in a guided programme. It decides who the programme is not for, at onboarding and during the programme, and shows the pages that say so with warmth.

## ADDED Requirements

### Requirement: Re-screening at a restart

`programme` owns the restart control, "Start week 1 again", and the start-day choice it opens. A check-in's "Restart the programme?" is a shortcut to the same control. `staying-on-track` places it.

The app MUST count record days from the record day of the last screening. The last screening is onboarding or the latest re-screen with no exclusion, whichever is later. A re-screen is the last screening whether or not the person then restarts. The app MUST NOT count from the start day or the restart moment.

The app MUST keep the moment of the last screening in the Profile field `askedAt`, with its own `changedAt`. The field name MUST NOT contain a word about screening, as `data-and-privacy` requires. The app MUST write `askedAt` at onboarding and at each re-screen with no exclusion. The app MUST NOT write `askedAt` at a weekly review or a check-in. When `askedAt` is later than the device clock, the app MUST re-screen at the next restart, as for more than 84 record days.

Within 84 record days of the last screening, the app MUST NOT ask a screening question at a restart. The app MUST show the start-day choice at once.

More than 84 record days after the last screening, the app MUST re-screen before the start-day choice. The re-screen MUST ask height and weight, with the wording `onboarding` defines. The re-screen MUST show the line that `onboarding` places above the height and weight fields. It MUST ask pregnancy, treatment and the self-harm item with both steps. The app MUST NOT ask the age again. The app MUST compute the BMI as `onboarding` defines. The app MUST apply every screening rule except the age rule to the answers.

The BMI rules, with the caution sheet, apply to the new height and weight. At a re-screen, the app MUST exclude with the self-harm reason after "Yes" and then "Yes". After "Yes" and then "No", the app MUST show the support line as the self-harm item defines. The re-screen MUST then continue.

When no rule excludes, the app MUST replace the height, the onboarding BMI, the caution flag and `askedAt`. Each is a Profile field with its own `changedAt`.

Every device keeps the re-screen's later write. `data-and-privacy` defines that rule. The app MUST NOT compare creation moments. The app MUST then show the start-day choice.

A re-screen with no exclusion becomes the last screening, also when the person then taps "Cancel" at the start-day choice. After "Cancel", the app MUST keep the new height, the new onboarding BMI, the new caution flag and the new `askedAt`. "Cancel" MUST keep the old start day. "Cancel" MUST NOT restart. Within 84 record days of that re-screen, the app MUST NOT ask a screening question when the person taps "Start week 1 again".

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

#### Scenario: New BMI
- **WHEN** the person re-screens at 170 cm and 65 kg and no rule excludes
- **THEN** the store holds 170 and 22.49 as the height and the onboarding BMI, and the start-day choice opens

#### Scenario: The restart's height wins on another device
- **WHEN** one device holds the height 170 from onboarding, the person re-screens at 172 cm on a second device, and they sync
- **THEN** every device reads 172 as the height, because the re-screen's write has the later `changedAt`

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

#### Scenario: Cancel after a re-screen
- **WHEN** the height from onboarding is 170 cm, the person re-screens at 172 cm and 65 kg with no exclusion on Monday 5 January, taps "Cancel" at the start-day choice, and taps "Start week 1 again" on Monday 2 March, 56 record days later
- **THEN** after "Cancel" the store holds 172 as the height, 21.97 as the onboarding BMI, the caution flag off and `askedAt` from 5 January, the start day is unchanged, and on 2 March the app asks no question and shows the start-day choice at once

#### Scenario: askedAt in the future
- **WHEN** a device clock ran a year ahead at the last re-screen, so `askedAt` is later than the corrected device clock, and the person taps "Start week 1 again"
- **THEN** the app re-screens before the start-day choice

#### Scenario: Restarts less than 84 record days apart
- **WHEN** the person re-screens with no exclusion at a restart on Monday 5 January, restarts on Friday 6 March, 60 record days later, and restarts on Sunday 5 April, 90 record days after the re-screen
- **THEN** the app asks no question on 6 March, and on 5 April, 30 record days after the last restart, it re-screens before the start-day choice
