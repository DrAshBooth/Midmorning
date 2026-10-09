# regular-eating-plan

## MODIFIED Requirements

### Requirement: Accessibility of the plan

Each planned meal row on Today MUST be one accessibility element. The row's label MUST hold the slot label, then the planned time. It MUST then hold the matched entry's label when an entry matches. When no entry matches and the answer is "Skipped", it MUST hold "Skipped" instead.

When the row shows the missed planned meal prompt, the label MUST hold the prompt text after the time. When the row shows the next-planned-meal line, the label MUST end with that line, after the other parts. A comma and a space MUST separate the parts. The prompt's buttons MUST also be VoiceOver custom actions on the row: "Skipped" and "Add it", or "Skipped" and "That was it". Ash ruled on 9 October 2026 that the label ends with the next-planned-meal line (r19-02).

Every control in the plan builder MUST have a VoiceOver label. The slot buttons, the time controls and the "Remove %@" controls MUST carry the labels the builder requirement names. The rename controls MUST carry the labels the rename requirement names. Text in the plan builder and on planned meal rows MUST use system text styles. Text in the plan builder and on planned meal rows MUST scale with Dynamic Type. A planned meal's state MUST NOT depend on colour alone.

#### Scenario: Label of a matched planned meal
- **WHEN** VoiceOver reads the Lunch row with a starred entry at 13:10 and What "Toast and tea"
- **THEN** it reads "Lunch, 13:00, 13:10, Toast and tea, felt like a binge"

#### Scenario: Label of a skipped planned meal
- **WHEN** VoiceOver reads the Lunch row after the person answered "Skipped"
- **THEN** it reads "Lunch, 13:00, Skipped"

#### Scenario: Label of a planned meal without an entry
- **WHEN** VoiceOver reads the Evening meal row with no matched entry and no answer
- **THEN** it reads "Evening meal, 19:00"

#### Scenario: Label of a planned meal with the prompt
- **WHEN** VoiceOver reads the Lunch row while it shows "Skipped, or not recorded yet?"
- **THEN** it reads "Lunch, 13:00, Skipped, or not recorded yet?" and offers the custom actions "Skipped" and "Add it"

#### Scenario: Label of a planned meal with the next-planned-meal line
- **WHEN** VoiceOver reads the Mid-afternoon row while it shows "Mid-afternoon at 16:00 still happens."
- **THEN** it reads "Mid-afternoon, 16:00, Mid-afternoon at 16:00 still happens."

#### Scenario: Labels in the builder
- **WHEN** VoiceOver reads a builder day with Lunch at 13:00 and no Breakfast
- **THEN** it reads a button "Breakfast", a time control "Lunch time" with the value "13:00", a button "Rename Lunch" and a button "Remove Lunch"

#### Scenario: Label of a renamed planned meal
- **WHEN** VoiceOver reads the row of a slot renamed "Elevenses" at 10:30 with no matched entry
- **THEN** it reads "Elevenses, 10:30"

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the plan builder and Today show every planned meal without truncation
