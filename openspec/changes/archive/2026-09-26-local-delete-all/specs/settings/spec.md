# settings

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

#### Scenario: Draft content
- **WHEN** the content bundle has no sign-off file
- **THEN** the About group shows "Draft" beside the content version

#### Scenario: Face ID only
- **WHEN** the person turns on "Face ID only" and taps "Turn on"
- **THEN** the cover never offers the device passcode

#### Scenario: Diagnostics
- **WHEN** the person opens "Diagnostics"
- **THEN** the page shows eight counts and no entry, weight or plan
