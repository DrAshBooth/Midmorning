# reminders

## ADDED Requirements

### Requirement: A tap on a reminder opens its screen from Today

When the person taps the body of a reminder, the app MUST first remove every screen from Today's navigation stack. The app MUST then open the screen of that reminder. The requirement of each reminder type names its screen, for example Today, "Today's plan", the close-the-day screen, the weigh-in screen or the weekly review. The weigh-in screen and the weekly review open on Today's navigation stack, so their back control MUST go back to Today.

When the new-entry screen shows unsaved text, the app MUST keep that screen and its text in front. The app MUST open the screen of the reminder only after the new-entry screen closes.

This requirement applies only to a tap on the body of a reminder. It does not change "Add", "Skipped" or the snooze action. While the app is locked, `app-lock` governs "Add", as its requirement "A new entry before authentication" states. Ash ruled this on 9 October 2026 (r20-01).

#### Scenario: A tap while another screen shows
- **WHEN** the person opens "Programme" from Today, goes to the Home Screen and taps the body of the Lunch reminder
- **THEN** Today shows, and Today's navigation stack holds no other screen

#### Scenario: A tap on the weigh-in day reminder while another screen shows
- **WHEN** the person opens "Programme" from Today, goes to the Home Screen and taps the body of the weigh-in day reminder
- **THEN** the weigh-in screen shows, and a tap on its back control shows Today, not "Programme"

#### Scenario: A tap over a new entry with a draft
- **WHEN** the new-entry screen shows "Toast and" in What, the person taps the body of the weigh-in day reminder, and then taps "Save"
- **THEN** the new-entry screen and "Toast and" stay in front until the save, and after the save the weigh-in screen shows on Today's navigation stack
