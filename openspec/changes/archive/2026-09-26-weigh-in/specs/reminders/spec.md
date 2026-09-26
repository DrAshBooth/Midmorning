# reminders

## Purpose

A reminder is a notification the app schedules. Reminders hold the structure of the day for the person. They cover each planned meal, the morning plan, midday, the close of the day, the weigh-in day and the weekly review. They also cover a worksheet review and a check-in. Every reminder is discreet by default, capped, silent inside quiet hours, and switchable one type at a time.

## ADDED Requirements

### Requirement: The weigh-in day reminder

The Reminders group MUST show a "Weigh-in reminder time" control that defaults to 07:30. The scheduler MUST schedule the weigh-in day reminder on the weigh-in day at that time. The scheduler MUST NOT schedule it on any other day. When a weigh-in exists for the weigh-in day before that time, the scheduler MUST cancel the reminder. A tap MUST open the weigh-in screen. The `weigh-in` capability owns that screen.

When the onboarding choice is "I won't be weighing", the scheduler MUST NOT schedule a weigh-in day reminder. The `onboarding` capability owns that choice, and the choice syncs. When the person later picks a weigh-in day, the scheduler MUST schedule the reminder from that day on.

#### Scenario: The weigh-in day
- **WHEN** the weigh-in day is Monday and the time reaches 07:30 on Monday
- **THEN** the reminder fires, reads "Midmorning, 07:30", and a tap opens the weigh-in screen

#### Scenario: I won't be weighing
- **WHEN** the person chose "I won't be weighing" at onboarding
- **THEN** no weigh-in day reminder fires on any day, and the "Weigh-in day reminder" switch stays on

#### Scenario: A weigh-in day chosen later
- **WHEN** the person chose "I won't be weighing" and picks Monday on the weigh-in screen on Thursday 1 October
- **THEN** the weigh-in day reminder fires at 07:30 on Monday 5 October

#### Scenario: A weigh-in before the reminder
- **WHEN** the person saves a weigh-in at 07:15 on Monday
- **THEN** no weigh-in day reminder fires at 07:30

#### Scenario: Another day
- **WHEN** the weigh-in day is Monday and the day is Tuesday
- **THEN** no weigh-in day reminder fires
