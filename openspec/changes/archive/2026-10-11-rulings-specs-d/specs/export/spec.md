# export

## MODIFIED Requirements

### Requirement: Choose a date range

The app MUST show an export screen with the title "Export". The screen MUST be reachable from the settings screen and from Today in at most two taps. The screen MUST show a "From" date control and a "To" date control. Each date control MUST be a wheel date picker (the iOS wheel style), with its label above it. A date control MUST NOT open the system calendar. Ash ruled this on 11 October 2026 (r22-05): the calendar filled the selected day with the accent colour, and its white numeral was 2.2:1 in dark mode. The screen MUST show a switch "Include weigh-ins", a switch "Include context" and a control "Make PDF". The range MUST be in whole record days. "To" MUST NOT be after the current record day.

"From" MUST NOT be after "To". "From" MUST default to 27 days before the current record day. When the earliest record day with an entry is later, "From" MUST default to that day. "To" MUST default to the current record day. "Include weigh-ins" MUST be off by default. "Include context" MUST be on by default.

The screen MUST show one line above "Make PDF": "The PDF leaves the app when you share it. Mail, Files and Messages keep their own copy, and Delete everything does not reach those copies." The screen MUST NOT show a count of entries or a count of starred entries. The screen MUST NOT show any other text about the range's content.

#### Scenario: Default range
- **WHEN** the person opens the export screen on Thursday 24 September and the record has entries since 1 August
- **THEN** "From" reads 28 August and "To" reads 24 September

#### Scenario: Short record
- **WHEN** the person opens the export screen on Thursday 24 September and the earliest entry is on 20 September
- **THEN** "From" reads 20 September and "To" reads 24 September

#### Scenario: A range of one day
- **WHEN** the person sets "From" and "To" both to 21 September and taps "Make PDF"
- **THEN** the PDF holds the record day 21 September and no other day

#### Scenario: To before From
- **WHEN** "To" is 21 September and the person tries to set "From" to 22 September
- **THEN** the "From" control does not offer 22 September

#### Scenario: The dates are wheels
- **WHEN** the person opens the export screen in dark mode
- **THEN** "From" and "To" each show a label above a wheel of day, month and year, and no control opens a calendar

#### Scenario: The switches when the screen opens
- **WHEN** the person opens the export screen for the first time
- **THEN** "Include weigh-ins" is off and "Include context" is on

#### Scenario: The line above "Make PDF"
- **WHEN** the person opens the export screen
- **THEN** the line above "Make PDF" reads "The PDF leaves the app when you share it. Mail, Files and Messages keep their own copy, and Delete everything does not reach those copies."

### Requirement: Accessibility of the export

Every control on the export screen MUST have a VoiceOver label. A control with no visible text MUST have a label a person can say with Voice Control. Text on the export screen MUST use system text styles. Text on the export screen MUST scale with Dynamic Type. The PDF MUST hold selectable text, not an image of text.

The PDF MUST use fixed text sizes. The body MUST be 11 pt, a day heading 14 pt and the title 18 pt. Those sizes MUST NOT change with Dynamic Type. The asterisk MUST be a text character in the PDF. The PDF's meaning MUST NOT depend on colour.

The PDF MUST be a tagged PDF. The PDF MUST tag the heading "Record" as an H1. The PDF MUST tag each day heading as an H2. On each page that holds a day's entries, those entries MUST be one tagged list, with one list item per entry. A day that continues on the next page therefore has one list on each of its pages, because a Core Graphics tag cannot cross a page. The heading that a continuation page repeats MUST NOT be a tagged heading, so each day has one H2. Ash ruled this on 26 September 2026. Each item's text MUST read, in order: the time, the asterisk when starred, the What, the Where, the Context. With "Include context" off, the item's text MUST end at the Where.

The PDF MUST declare the language en-GB on each tag: the H1, each H2, each list and each list item. Core Graphics has no key for the language of the whole document, so the document catalog holds no language. Ash ruled on 9 October 2026 that the language on each tag is the declaration of the PDF's language (r20-02). A screen reader MUST read the days in date order. A screen reader MUST read each entry in one pass, not one column at a time.

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
- **WHEN** a PDF reader shows the tag tree of an export PDF
- **THEN** the H1, each H2, each list and each list item declare the language en-GB

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
