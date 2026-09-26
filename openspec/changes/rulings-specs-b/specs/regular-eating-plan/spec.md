# regular-eating-plan

## MODIFIED Requirements

### Requirement: Rename a slot in the plan builder

Each planned meal in the builder MUST show a control "Rename". Its visible text MUST stay "Rename". Its VoiceOver label MUST be "Rename %@", filled with the slot's label, for example "Rename Lunch". The label starts with the visible text, so Voice Control finds the control by "Rename". `product-rules` allows such a label. Ash ruled this on 26 September 2026 (r13-08). "Rename" MUST open a text field that holds the current label, with "Save" and "Cancel". The field MUST accept at most 20 characters. The field MUST NOT accept a 21st character.

When the person saves an empty field, the app MUST restore the slot's default label. When the text is "Midmorning", in any letter case, the app MUST keep the field open. The app MUST then show "That is the app's name. Choose another word." under the field.

The store MUST keep each label as the Settings row `slot.label.<index>`, one row per slot index. Settings rows are one row per key with a `changedAt`, as the `data-and-privacy` capability states. On read, the app keeps the row with the later `changedAt`. A saved label MUST apply at once wherever the app shows that slot. Those places are the templates, every day's plan and every planned meal row on Today.

A rename MUST NOT change the slot's kind, its slot index, its default time or its time on any day. A rename MUST NOT set a day's plan. A rename MUST NOT write to a Template row. A rename is not an edit of a day's plan for the morning plan reminder that the `reminders` capability defines.

#### Scenario: Rename a slot
- **WHEN** the person taps "Rename" on Mid-morning, types "Elevenses" and taps "Save"
- **THEN** the builder shows "Elevenses" in place of "Mid-morning", and Today shows "Elevenses" on that row

#### Scenario: The Rename label
- **WHEN** VoiceOver focuses the "Rename" control of the Lunch slot
- **THEN** VoiceOver reads "Rename Lunch", the row shows "Rename" only, and Voice Control finds the control when the person says "Tap Rename"

#### Scenario: Twenty-one characters
- **WHEN** the person types "Second breakfast time" into the field
- **THEN** the field holds "Second breakfast tim" and accepts no more

#### Scenario: The product name
- **WHEN** the person types "midmorning" and taps "Save"
- **THEN** the field stays open with "That is the app's name. Choose another word." under it, and the label does not change

#### Scenario: An empty label
- **WHEN** the person clears the field on a slot labelled "Elevenses" and taps "Save"
- **THEN** the slot's label is "Mid-morning" again

#### Scenario: A rename is not a plan edit
- **WHEN** a template exists and the person renames "Evening snack" to "Supper" on Tuesday without an edit to Tuesday's plan
- **THEN** Tuesday's plan is unchanged, Tuesday is not a set day, and no morning plan reminder fires on Wednesday
