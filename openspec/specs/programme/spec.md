# programme Specification

## Purpose
The programme is the twelve-week sequence of seven stages that the person moves through. It decides which tools are open, counts pacing by recorded days and planned days, and counts weeks from the start day. It shows the person where they are without a rating, a bar or a count of consecutive days. The only count it shows is the count toward a gate, in the gate's rule string.

## Requirements

### Requirement: The constants live in one value

The app MUST hold every programme constant in one value type, ProgrammeConstants. ProgrammeConstants MUST have a `.default` value. The `.default` value MUST hold these names and values:

- DEFAULT_DAY_START_HOUR = 4
- PROGRAMME_WEEKS = 12
- MIN_HEIGHT_CM = 100
- MAX_HEIGHT_CM = 250
- MIN_WEIGHT_KG = 30
- RECORDED_DAYS_FOR_STAGE_2 = 5
- DAYS_ON_PLAN_FOR_STAGE_3 = 7
- RECORD_DAYS_FOR_STAGE_3_FALLBACK = 14
- RECORDED_DAYS_FOR_STAGE_4_FALLBACK = 7
- WEEK_OF_TAKING_STOCK = 6
- WEEK_OF_STAYING_ON_TRACK = 10
- MAX_AWAKE_GAP_HOURS = 4
- MAX_OTHER_REMINDERS_PER_DAY = 2
- SNOOZE_MINUTES = 15 or 30
- MAX_SNOOZES = 2
- ROLLING_AVERAGE_WEEKS = 4
- URGE_TIMER_MINUTES = 20
- DETERIORATION_WEEKS = 3
- CHECK_IN_WEEKS = 4, 8, 12
- PATTERN_WINDOW_DAYS = 28
- PATTERN_MIN_STARRED = 5
- PATTERN_MIN_GROUP = 3
- LOCK_GRACE_SECONDS = 0, 30, 120 or 300; the default is 0
- PLANNED_MEAL_WINDOW_BEFORE_MINUTES = 60
- PLANNED_MEAL_WINDOW_AFTER_MINUTES = 90
- REMINDER_HORIZON_DAYS = 6

Every capability MUST read its constant from ProgrammeConstants. The code MUST NOT repeat a constant's value as a literal elsewhere. The type MUST live in the `Constants` target, not in the UI. `Constants` is a leaf target that `Record`, `Plan` and `Programme` import. A test MUST check each value of `.default`.

LOCK_GRACE_SECONDS is a set of four values. App-lock owns the "Lock after" setting that picks one. Its default is 0.

Every threshold test MUST construct a modified ProgrammeConstants value. A test MUST NOT edit `.default`.

DEFAULT_DAY_START_HOUR is the default of the "Day starts at" setting. Settings owns the setting. Every capability that uses the record day MUST read the day start from the setting, not from the constant. The constant MUST NOT stand in for the setting anywhere.

DEFAULT_DAY_START_HOUR MUST stay 4 in every version. A test MUST assert that DEFAULT_DAY_START_HOUR is 4. The team MUST keep that test in every version.

#### Scenario: The values
- **WHEN** the test suite runs
- **THEN** a test reads each constant from ProgrammeConstants.default and checks its value

#### Scenario: The lock grace set
- **WHEN** the test suite runs
- **THEN** a test reads LOCK_GRACE_SECONDS from ProgrammeConstants.default and checks that it holds 0, 30, 120 and 300, with 0 as the default

#### Scenario: A threshold test
- **WHEN** a test checks that stage 2 opens after 3 recorded days
- **THEN** the test constructs a ProgrammeConstants value with RECORDED_DAYS_FOR_STAGE_2 = 3 and passes it to the engine, and `.default` still holds 5

#### Scenario: The default day start never changes
- **WHEN** a version sets DEFAULT_DAY_START_HOUR to 5
- **THEN** the test that asserts DEFAULT_DAY_START_HOUR is 4 fails

#### Scenario: A capability reads the day start from the setting
- **WHEN** "Day starts at" is 05:00 and the app computes the current record day
- **THEN** the app uses 05:00 as the day start, and DEFAULT_DAY_START_HOUR still holds 4
