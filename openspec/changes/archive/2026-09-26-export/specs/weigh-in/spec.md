# weigh-in

## ADDED Requirements

### Requirement: The weigh-in page in an export

`export` owns the export and the choice to include weigh-ins. That choice MUST be off until the person turns it on. When the person includes weigh-ins, the export MUST add one page. That page MUST list each weigh-in in the date range with its date and its value in the person's unit. The page MUST NOT show a rolling average, a BMI, a goal, a difference between weigh-ins or a chart. When the person does not include weigh-ins, the export MUST hold no weight value. While no weigh-in day exists, an export that includes weigh-ins MUST still list the kept weigh-ins.

#### Scenario: Weigh-ins included
- **WHEN** the person exports 28 September to 26 October with weigh-ins included and the unit "kg"
- **THEN** the export has one weigh-in page with five rows, each with a date and a value in kg, and no rolling average

#### Scenario: Weigh-ins not included
- **WHEN** the person exports 28 September to 26 October without weigh-ins
- **THEN** the export holds no weight value

#### Scenario: Weigh-ins after an opt-out
- **WHEN** the person saved five weigh-ins from 28 September to 26 October, then chose "I won't be weighing", and exports that range with weigh-ins included
- **THEN** the export has one weigh-in page with five rows
