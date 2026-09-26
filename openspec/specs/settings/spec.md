# settings Specification

## Purpose
The settings screen holds every switch, time and choice the person can change, in one place, one tap from Today. Each item's owning capability defines what it does. This spec defines where the item lives, its label, its default and whether it syncs.

## Requirements

### Requirement: One screen, one tap from Today

The app MUST show one settings screen. The person MUST reach it in one tap from Today. The control "Settings" MUST sit in Today's bottom toolbar, as text, in the Today stack that `record` defines. The screen MUST show these groups in this order: Reminders, Record, Weigh-in, Privacy, About. Get support MUST stay in the navigation bar.

#### Scenario: Reach the settings screen
- **WHEN** the person is on Today and taps "Settings" in the bottom toolbar
- **THEN** the settings screen opens after that one tap

### Requirement: The Reminders group

The Reminders group MUST be its own screen, one tap from the settings screen. It MUST show "Which reminders" with one switch per reminder type, each on by default. The switches are:

- "Planned meals"
- "Set today's plan"
- "Midday reminder"
- "Close the day"
- "Weigh-in day reminder"
- "Weekly review"
- "Worksheet review"
- "Check-in"

It MUST show "When" with the four times:

- "Set today's plan time" 07:30
- "Close the day time" 21:45
- "Weigh-in reminder time" 07:30
- "Weekly review time" 18:00

It MUST show these four items:

- "Say what each reminder is for" (off; the explicit wording setting)
- "Break through Focus for planned meals" (off; the Time Sensitive setting)
- "Remind me again in" ("15 minutes" or "30 minutes", default "15 minutes")
- "Quiet hours" with a start and an end (22:00 to 07:00, on)

Under "When" it MUST state "The midday reminder is at 12:00." Under the switches it MUST show "Each device sends its own reminders." When `remindersPausedAt` is set, the group MUST show the line "Reminders are paused." and a control "Turn reminders on". Every switch here is a device setting. The times and quiet hours sync.

#### Scenario: Reminders paused by the not-right-now page
- **WHEN** the not-right-now page set `remindersPausedAt`
- **THEN** the Reminders group shows "Reminders are paused." and "Turn reminders on", and every switch keeps its own state

#### Scenario: Turn reminders on
- **WHEN** the person taps "Turn reminders on"
- **THEN** the app clears `remindersPausedAt` and the scheduler computes the schedule again

### Requirement: The About group

The About group MUST show the app version and the content version. It MUST show "Draft" when the content has no sign-off. It MUST show Get support. It MUST show "Contact" with the support email `data-and-privacy` names. It MUST show "Diagnostics", a page of counts only. The counts are:

- launch failures
- last successful sync day
- schema version
- content version
- pending reminders
- queue length
- last reconcile outcome
- crash count

The page MUST hold no record content.

#### Scenario: Draft content
- **WHEN** the content bundle has no sign-off file
- **THEN** the About group shows "Draft" beside the content version

#### Scenario: Face ID only
- **WHEN** the person turns on "Face ID only" and taps "Turn on"
- **THEN** the cover never offers the device passcode

#### Scenario: Diagnostics
- **WHEN** the person opens "Diagnostics"
- **THEN** the page shows eight counts and no entry, weight or plan

### Requirement: Accessibility of the settings screen

Every control on the settings screen MUST have a VoiceOver label equal to its visible label. Every switch MUST read its state. Text MUST scale with Dynamic Type.

#### Scenario: VoiceOver on a switch
- **WHEN** VoiceOver reads "Weekly summary"
- **THEN** it reads the label, "switch", and "on" or "off"
