# settings

## Purpose

The settings screen holds every switch, time and choice the person can change, in one place, one tap from Today. Each item's owning capability defines what it does. This spec defines where the item lives, its label, its default and whether it syncs.

## ADDED Requirements

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

### Requirement: The Record group

The Record group MUST hold these items:

- "Day starts at" (a time from 00:00 to 12:00, default 04:00, syncs)
- "Weekly summary" (on, syncs)
- "Pattern sentences" (on, syncs)
- "Gap bands" (on, syncs)
- "Export" as a control

"Show next planned time" is the widget's own option, which `widgets-and-intents` owns. The group MUST link to the "Food rules" and "Feeling fat notes" screens, which hold their own switches. A change to "Day starts at" MUST apply from the next day start. A change to "Day starts at" MUST NOT change any saved entry's record day.

#### Scenario: Turn pattern sentences off
- **WHEN** the person turns "Pattern sentences" off
- **THEN** the Problem solving screen shows no pattern sentence and the card slot shows no suggestion card

### Requirement: The Weigh-in group

The Weigh-in group MUST hold "Weigh-in day" (a weekday or "I won't be weighing", syncs) and "Unit" ("kg" or "st lb", default "kg", syncs).

#### Scenario: Change the unit
- **WHEN** the person changes the unit to "st lb"
- **THEN** the weigh-in screen and the export show weights in stone and pounds from then on

### Requirement: The Privacy group

The Privacy group MUST hold these items:

- the app lock switch with the label `app-lock` defines (on, device)
- "Face ID only" or "Touch ID only" from the label `app-lock` defines (off, device)
- "Lock after" ("At once", "30 seconds", "2 minutes", "5 minutes", default "At once", device)
- "Sync with iCloud" (off until chosen, device)
- "Sync now" as a control when sync is on
- "Devices with your record: 2" with the day each joined
- "Remove from iCloud" as a control when sync is off and a copy exists in iCloud
- "Share App Analytics with Apple" as a control that opens the iOS Settings toggle
- "Keep it private" as a control that opens the sheet `widgets-and-intents` and `safeguarding` define
- "Delete everything" as a control
- a link to the privacy notice

Before "Face ID only" or "Touch ID only" turns on, the app MUST show the warning `app-lock` defines, with "Turn on" and "Cancel".

#### Scenario: Sync off
- **WHEN** "Sync with iCloud" is off
- **THEN** the group shows "Sync with iCloud is off. A new device starts empty." under the switch

#### Scenario: iCloud full
- **WHEN** iCloud reports that storage is full
- **THEN** the group shows "iCloud is full, so sync is paused. Your record is safe on this device." under the switch

### Requirement: Accessibility of the settings screen

Every control on the settings screen MUST have a VoiceOver label equal to its visible label. Every switch MUST read its state. Text MUST scale with Dynamic Type.

#### Scenario: VoiceOver on a switch
- **WHEN** VoiceOver reads "Weekly summary"
- **THEN** it reads the label, "switch", and "on" or "off"
## MODIFIED Requirements

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

#### Scenario: Face ID only
- **WHEN** the person turns on "Face ID only" and taps "Turn on"
- **THEN** the cover never offers the device passcode

#### Scenario: Diagnostics
- **WHEN** the person opens "Diagnostics"
- **THEN** the page shows eight counts and no entry, weight or plan

#### Scenario: Draft content
- **WHEN** the content bundle has no sign-off file
- **THEN** the About group shows "Draft" beside the content version

