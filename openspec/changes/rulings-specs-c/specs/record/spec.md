# record

## MODIFIED Requirements

### Requirement: Today hides entries when the app is not active

When the app is not active, Today, the new-entry screen and the edit screen MUST hide entry text and stars. The app switcher MUST show no entry. The app MUST hide them with the cover that the `app-lock` capability defines in "The cover". The cover shows "Midmorning" over every screen whenever the app is not active, with the app lock on or off. Today, the new-entry screen and the edit screen MUST NOT use `.privacySensitive()` or `.redacted(reason:)`. On 26 September 2026, `.privacySensitive()` on the navigation stack of Today made Today blank on the iOS 27.0 simulator. Ash ruled this on 7 October 2026 (r16-02).

#### Scenario: App switcher
- **WHEN** the person opens the app switcher while Today shows entries
- **THEN** the app's snapshot shows no entry text and no star

#### Scenario: Edit screen with the app lock off
- **WHEN** the app lock is off and the person opens the app switcher while the edit screen shows the entry "Toast and tea"
- **THEN** the snapshot shows the cover with "Midmorning", and no entry text and no star

#### Scenario: Today on iOS 27
- **WHEN** onboarding is done, the current record day holds two entries, and the person opens the app on iOS 27
- **THEN** Today shows its title, its toolbar, both entries and Get support

### Requirement: Edit an entry

A tap on a row on Today or on an earlier day MUST open the entry for editing. The edit screen is the new-entry screen filled with the entry's values. The person MUST be able to change the time, the What, the Where, the star and the Context.

The time control MUST offer only times inside the entry's own record day. The time control MUST show one segment, which names that record day. The time control MUST show and offer times in the entry's edit zone. When the device's current time zone gives the entry's kept UTC offset at the entry's time, the edit zone is the device's current time zone. Otherwise the edit zone is a fixed zone at the entry's kept UTC offset. The app MUST find the edit zone when the edit screen opens. The app MUST compute that record day's bounds in the edit zone, from the day start row. That row is the one in force for that record day key, as `data-and-privacy` states. In the device's current time zone, a record day on a clock-change date is 23 or 25 hours long, as "The record day" requirement states. The time control MUST NOT offer a time after the current moment.

On save the app MUST use the edit zone that the time control showed. This rule also applies when the device's current time zone changes while the edit screen is open. On save the app MUST keep the UTC offset of that edit zone at the edited time. In a fixed zone, that offset is the entry's kept offset. On save the app MUST keep the entry's record day as it was. The edited time and its offset then still give that record day's key. On save the app MUST keep the entry's creation moment as it was. On save the app MUST close the screen as the "Save is quiet" requirement describes. The app MUST NOT show an "edited" label or any text about the edit. "Cancel" MUST discard every change. Ash ruled on 25 September 2026 that an edit keeps the entry in its own record day. The edit zone follows Ash's ruling of 26 September 2026 on the offset at the entry's own time. After travel, it also follows the ruling of 25 September 2026. Ash ruled on 7 October 2026 that an edit uses the edit zone for the time control and for the offset on save (r15-02). So travel never moves an entry, and the time control and Today show the same clock time.

#### Scenario: Change the What
- **WHEN** the person taps the 13:05 entry "Toast and tea", changes What to "Toast, tea and a biscuit" and saves
- **THEN** Today shows the 13:05 entry with What "Toast, tea and a biscuit" and no other change

#### Scenario: Change the time inside the entry's record day
- **WHEN** "Day starts at" is 04:00, the current time is 09:00 on Friday 25 September, and the person opens the Friday 08:30 entry
- **THEN** the time control offers times from 04:00 to 09:00 on Friday only, and after the person sets 06:45 and saves, Today shows the entry under Friday 25 September at 06:45

#### Scenario: One segment on the edit screen
- **WHEN** the current time is 02:00 on Friday 25 September and the person opens the Wednesday 23 September 21:00 entry
- **THEN** the time control shows one segment, "Wednesday 23 September", and the hour-and-minute wheel

#### Scenario: Creation moment stays
- **WHEN** the person edits an entry with the creation moment 13:08 and saves at 18:00
- **THEN** the app keeps 13:08 as the creation moment

#### Scenario: Cancel an edit
- **WHEN** the person turns the star on in the edit screen and taps "Cancel"
- **THEN** the entry keeps the star off

#### Scenario: Edit after travel
- **WHEN** the person saves an entry at 05:00 on Saturday 26 September in London at UTC+1, then on Sunday 27 September opens it in New York at UTC-4 and sets the time 05:30
- **THEN** the time control shows 05:00 when it opens, the app keeps UTC+1 with the entry, and the entry shows at 05:30 under Saturday 26 September

#### Scenario: Edit across a clock change
- **WHEN** the clocks in London go back at 02:00 on Sunday 25 October, and at 09:00 that day the person in London opens the Saturday 24 October 23:00 entry and sets the time 03:30 on Sunday
- **THEN** the time control offers times from 04:00 on Saturday to 03:59 on Sunday, 25 hours, the app keeps UTC+0 with the entry, and the entry shows at 03:30 under Saturday 24 October

#### Scenario: The device's time zone changes while the edit screen is open
- **WHEN** the clocks in London go back at 02:00 on Sunday 25 October, at 09:00 that day the person in London opens the Saturday 24 October 23:00 entry, the device's time zone changes to Paris while the edit screen is open, and the person sets the time 03:30 on Sunday and saves
- **THEN** the app keeps UTC+0, the offset in London at 03:30 on Sunday, and the entry shows at 03:30 under Saturday 24 October
