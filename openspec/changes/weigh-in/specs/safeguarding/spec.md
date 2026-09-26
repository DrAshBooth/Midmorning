# safeguarding

## Purpose

Safeguarding carries the duty of care that a guide would carry in a guided programme. It decides who the programme is not for, at onboarding and during the programme, and shows the pages that say so with warmth. It keeps a route to outside help on every screen after the person unlocks. It never diagnoses, never reads what the person writes, and never locks the person out of their record.

## ADDED Requirements

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
