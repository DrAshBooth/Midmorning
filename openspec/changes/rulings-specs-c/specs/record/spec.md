# record

## Purpose

Ash's ruling of 7 October 2026 (r16-02) changes one record requirement: the cover hides entries when the app is not active.

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
