# onboarding

## MODIFIED Requirements

### Requirement: Four screens, once, in order

The app MUST show onboarding the first time the app opens after install. From the sync change, the app checks iCloud for a record before screen 1. The "Restore before onboarding" requirement states that. Onboarding MUST have exactly four screens in this order: "What this is and isn't", "A few questions first", "Your start", "Permissions". The app MUST NOT show onboarding again after the person completes it.

After Delete-all the app MUST show onboarding again (`data-and-privacy` owns Delete-all). The app MUST NOT ask the screening questions again after onboarding. The exceptions are the self-harm item at every weekly review and check-in, and the restart re-screen that `safeguarding` defines. Every onboarding screen MUST show Get support in the navigation bar (`safeguarding` owns the button). The four screens MUST NOT need a network connection.

The four screens together MUST ask the person to type at most five numbers. Every other input MUST be one tap. A reviewer walks the four screens with every default on the simulator. The target for that walk is under three minutes.

Every control on the four screens MUST have a VoiceOver label. Every text on the four screens MUST scale with Dynamic Type. The team MUST declare an accessibility label in App Store Connect only after a passing run of the accessibility audits on the commit of the build. `safeguarding` states that gate. Ash ruled on 9 October 2026 that the passing run is sufficient for a declaration (r21-01).

#### Scenario: First launch
- **WHEN** the app opens for the first time after install and iCloud holds no record
- **THEN** the app shows "What this is and isn't" and no other screen, and writes the install moment to Local.store

#### Scenario: Second launch
- **WHEN** the person completed onboarding on Thursday and opens the app on Friday
- **THEN** the app shows Today, as `programme` defines the home screen, and no onboarding screen

#### Scenario: No network
- **WHEN** the device is in airplane mode
- **THEN** the person can pass all four screens and the store keeps the commitment

#### Scenario: Typed numbers
- **WHEN** a reviewer counts every number field on the four screens with "ft in" and "st lb" chosen
- **THEN** the count is five: age, feet, inches, stone and pounds

#### Scenario: Accessibility labels
- **WHEN** the team declares the VoiceOver accessibility label in App Store Connect
- **THEN** `tools/skeleton-checks/README.md` holds a dated line for a passing run of `tools/skeleton-checks/automated-checks.sh --audits` on the commit of that build, and that run includes the audit of the four screens

