# reminders

## ADDED Requirements

### Requirement: The weekly review reminder

The Reminders group MUST show a "Weekly review time" control that defaults to 18:00. The scheduler MUST schedule the weekly review reminder at that time on the day the weekly review becomes due. The `weekly-review` capability defines that day. When the person completes the review before that time, the scheduler MUST cancel the reminder. The scheduler MUST schedule at most one weekly review reminder per review.

A tap MUST open the weekly review. After the finish, the `weekly-review` capability makes no weekly review due, so the scheduler MUST schedule none.

#### Scenario: The seventh day
- **WHEN** the weekly review becomes due on Sunday 4 October and the time reaches 18:00
- **THEN** the reminder fires, reads "Midmorning, 18:00", and a tap opens the weekly review

#### Scenario: The review done early
- **WHEN** the person completes the weekly review at 17:00 on Sunday 4 October
- **THEN** no weekly review reminder fires at 18:00

#### Scenario: Mid-week
- **WHEN** the day is Wednesday 30 September and no weekly review is due
- **THEN** no weekly review reminder fires
