# reminders

## ADDED Requirements

### Requirement: A tap on a reminder opens its screen from Today

When the person taps the body of a reminder, the app MUST first remove every screen from Today's navigation stack. The app MUST then open the screen of that reminder. The requirement of each reminder type names its screen, for example Today, "Today's plan", the close-the-day screen, the weigh-in screen or the weekly review. The weigh-in screen and the weekly review open on Today's navigation stack, so their back control MUST go back to Today.

When the new-entry screen shows unsaved input, the app MUST keep that screen and its input in front. Unsaved input is text in What or Context, a chosen Where, a typed place or the star. The app MUST open the screen of the reminder only after the new-entry screen closes.

A tap MUST NOT close a safeguarding page or a screen that holds answers. While the not-right-now page or the GP suggestion page shows, the app MUST keep the page in front. The app MUST open the screen of the reminder only after the person taps "Done" on the page. While the weekly review, the check-in, the restart re-screen or the weigh-in screen is open, the app MUST keep that screen. The app MUST open the screen of the reminder only after the person leaves that screen. When that screen is the screen of the reminder, the app MUST keep it and MUST NOT open it a second time. Ash ruled this on 11 October 2026 (r22-01).

A sheet of Today is the new-entry screen, the edit screen, the close-the-day screen or "Today's plan". While a sheet of Today shows, the app MUST keep the sheet in front. The app MUST open the screen of the reminder only after the sheet closes. A new-entry screen with no unsaved input MUST close first, and the screen of the reminder then opens. When the sheet is the screen of the reminder, the app MUST keep it, with its input, and MUST NOT open it a second time. So the midday reminder over a new-entry screen opens no second new-entry screen. The "Get support" sheet on Today stays in front, and the screen of the reminder opens under it. A sheet that a screen on Today's navigation stack shows closes with that screen, except the restart re-screen. Ash ruled on 11 October 2026 that the app keeps this build (r22-02).

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

#### Scenario: A tap over a new entry with only the star
- **WHEN** the new-entry screen shows no text and the star is on, the person taps the body of the weigh-in day reminder, and then taps "Cancel"
- **THEN** the new-entry screen and the star stay in front until "Cancel", and after it the weigh-in screen shows on Today's navigation stack

#### Scenario: A tap over an empty new entry
- **WHEN** the new-entry screen shows no input and the person taps the body of the weigh-in day reminder
- **THEN** the new-entry screen closes, and the weigh-in screen shows on Today's navigation stack

#### Scenario: The midday reminder over a new entry
- **WHEN** the new-entry screen shows "Jam" in What, the person taps the body of the midday reminder, and then taps "Save"
- **THEN** the new-entry screen and "Jam" stay in front until the save, and after the save Today shows with no second new-entry screen

#### Scenario: A tap while the close-the-day screen shows
- **WHEN** the close-the-day screen shows and the person taps the body of the weigh-in day reminder, and then taps "Done"
- **THEN** the close-the-day screen stays until "Done", and after it the weigh-in screen shows on Today's navigation stack

#### Scenario: A tap while the GP suggestion page shows
- **WHEN** the weekly review shows the GP suggestion page and the person taps the body of the Lunch reminder
- **THEN** the GP suggestion page stays with its "Done", and after "Done" the weekly review shows

#### Scenario: A tap while the not-right-now page shows
- **WHEN** the weekly review shows the not-right-now page with "Samaritans are there any time, on 116 123. If you are in danger now, call 999." and the person taps the body of the weigh-in day reminder
- **THEN** the page and its text stay until "Done", the weekly review shows after "Done", and the weigh-in screen shows on Today's navigation stack after the person leaves the review

#### Scenario: A tap while the weekly review holds answers
- **WHEN** the weekly review shows "Work was busy" in "What made things harder?" and the person taps the body of the Lunch reminder
- **THEN** the weekly review and "Work was busy" stay, and after "Done" on the review only Today shows

#### Scenario: A tap while the restart re-screen shows
- **WHEN** the restart re-screen shows over "Programme" and the person taps the body of the Lunch reminder
- **THEN** the re-screen and its answers stay, and after the person leaves the re-screen, Today shows with no other screen on its navigation stack

#### Scenario: The weigh-in day reminder on the weigh-in screen
- **WHEN** the weigh-in screen shows "62.5" in its weight field and the person taps the body of the weigh-in day reminder
- **THEN** the weigh-in screen and "62.5" stay, no second weigh-in screen opens, and after "Back" Today shows
