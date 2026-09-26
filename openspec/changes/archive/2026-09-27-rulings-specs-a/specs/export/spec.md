# export

## Purpose

Ash's rulings of 26 September 2026 change two export requirements: no Copy in the share sheet, and one tagged list on each page for a day that crosses a page.

## MODIFIED Requirements

### Requirement: Share sheet only

On "Make PDF" the app MUST build the PDF on the device and present it in the system share sheet. The app MUST write the PDF to a temporary file with the store's protection class. The app MUST delete the file when the share sheet closes. The app MUST NOT upload the PDF or send it by any channel of its own. The app MUST NOT keep a copy in the store. The PDF MUST have no password and no encryption.

The share sheet MUST NOT offer Copy. The app MUST exclude the activity type `UIActivity.ActivityType.copyToPasteboard`, because the data-and-privacy capability keeps the person's data off the pasteboard. Ash ruled this on 26 September 2026. The app MUST NOT save the PDF to Files or Photos unless the person chooses that in the share sheet. The app MUST NOT index the PDF in Spotlight or place it in an NSUserActivity. When the person cancels the share sheet, the app MUST return to the export screen with no message.

#### Scenario: Share
- **WHEN** the person taps "Make PDF"
- **THEN** the system share sheet opens with one PDF and the app makes no network request

#### Scenario: No Copy
- **WHEN** the person taps "Make PDF" and the share sheet opens
- **THEN** the share sheet offers no "Copy" action

#### Scenario: Cancel the share sheet
- **WHEN** the person cancels the share sheet
- **THEN** the app shows the export screen, shows no message, and no PDF file remains in the app's container

#### Scenario: After a share
- **WHEN** the person sends the PDF to Mail and returns
- **THEN** no PDF file remains in the app's container and the store holds no copy

#### Scenario: No password
- **WHEN** the person saves the PDF to Files and opens it there
- **THEN** the PDF opens with no password request

### Requirement: Accessibility of the export

Every control on the export screen MUST have a VoiceOver label. A control with no visible text MUST have a label a person can say with Voice Control. Text on the export screen MUST use system text styles. Text on the export screen MUST scale with Dynamic Type. The PDF MUST hold selectable text, not an image of text.

The PDF MUST use fixed text sizes. The body MUST be 11 pt, a day heading 14 pt and the title 18 pt. Those sizes MUST NOT change with Dynamic Type. The asterisk MUST be a text character in the PDF. The PDF's meaning MUST NOT depend on colour.

The PDF MUST be a tagged PDF. The PDF MUST tag the heading "Record" as an H1. The PDF MUST tag each day heading as an H2. On each page that holds a day's entries, those entries MUST be one tagged list, with one list item per entry. A day that continues on the next page therefore has one list on each of its pages, because a Core Graphics tag cannot cross a page. The heading that a continuation page repeats MUST NOT be a tagged heading, so each day has one H2. Ash ruled this on 26 September 2026. Each item's text MUST read, in order: the time, the asterisk when starred, the What, the Where, the Context. With "Include context" off, the item's text MUST end at the Where.

When the system's PDF renderer can write the tag, the PDF MUST declare the language en-GB. The team MUST test that during the export change before it commits to the tag. The design states the risk. A screen reader MUST read the days in date order. A screen reader MUST read each entry in one pass, not one column at a time.

#### Scenario: Screen reader on the PDF
- **WHEN** a screen reader opens the PDF
- **THEN** it reads "Record" as a heading, then each day heading as a level 2 heading in date order, then that day's entries as one list on each page that holds them

#### Scenario: One pass per entry
- **WHEN** a screen reader reaches an entry at 21:40 with the star on, What "Crisps and half a loaf", Where "Home" and Context "Row with my sister"
- **THEN** it reads one list item: "21:40 * Crisps and half a loaf Home Row with my sister"

#### Scenario: The tag tree of a day
- **WHEN** a day has three entries on one page and a PDF reader shows the tag tree
- **THEN** one list with three list items follows the day's H2, and no other structure

#### Scenario: A day across a page break
- **WHEN** a day's entries start on page 1 and continue on page 2, and a PDF reader shows the tag tree
- **THEN** the day has one H2, one list on page 1 and one list on page 2, and the heading that page 2 repeats has no tag

#### Scenario: The document language after the spike
- **WHEN** the spike shows that the renderer writes the language tag, and a PDF reader shows the document's properties
- **THEN** the language reads en-GB

#### Scenario: Voice Control
- **WHEN** a person using Voice Control says "Show names" on the export screen
- **THEN** every control shows a name, and "Tap Make PDF" builds the PDF

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size and opens the export screen
- **THEN** the screen shows every control and label without truncation

#### Scenario: The PDF at the largest text size
- **WHEN** the person sets the largest accessibility text size and taps "Make PDF"
- **THEN** the PDF's body is 11 pt, each day heading is 14 pt and the title is 18 pt

#### Scenario: Greyscale
- **WHEN** a printer prints the PDF in black and white
- **THEN** every starred entry still shows its asterisk and every heading is legible
