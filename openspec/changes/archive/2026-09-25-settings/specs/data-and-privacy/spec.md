# data-and-privacy

## ADDED Requirements

### Requirement: The privacy notice

The privacy notice MUST be one tap from the settings screen. The team MUST publish the same notice at a public URL. The notice MUST name the controller and its contact. The notice MUST name the contact email of the support page. The notice MUST state who reads that inbox.

The notice MUST state the lawful basis and the Article 9 condition for each processing. The notice MUST name Apple as a recipient. The notice MUST state where Apple holds the data. The notice MUST state what Apple can see and that the team sees nothing the person writes.

The notice MUST state that the team receives only Apple's aggregated App Analytics and crash reports. Those are the ones the person chooses to share with Apple. The notice MUST state how the person reads and deletes their data in the app. The notice MUST state "A backup of your device can hold reminder times until the app cancels them. It never holds your entries." The notice MUST name the ICO as the authority the person can complain to.

#### Scenario: Privacy notice
- **WHEN** the person opens the settings screen and taps "Privacy"
- **THEN** the notice opens and holds the controller, the contact, who reads the contact inbox, Apple, the App Analytics line, the backup line and the ICO

#### Scenario: Erasure
- **WHEN** the person reads the section on deleting their data
- **THEN** it names "Delete everything" in the settings screen
