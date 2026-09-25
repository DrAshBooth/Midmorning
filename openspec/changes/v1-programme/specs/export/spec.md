# export

## Purpose

The export makes a PDF of any date range of the record, formatted like the paper record. The person takes it to a GP or therapist. The person picks the range, the app builds the PDF on the device and hands it to the system share sheet. The app uploads nothing and keeps no copy. The `safeguarding` capability owns the deterioration rule that also offers this export.

## ADDED Requirements

### Requirement: Choose a date range

The app MUST show an export screen with the title "Export". The screen MUST be reachable from the settings screen and from Today in at most two taps. The screen MUST show a "From" date control and a "To" date control. The screen MUST show a switch "Include weigh-ins", a switch "Include context" and a control "Make PDF". The range MUST be in whole record days. "To" MUST NOT be after the current record day.

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

#### Scenario: The switches when the screen opens
- **WHEN** the person opens the export screen for the first time
- **THEN** "Include weigh-ins" is off and "Include context" is on

#### Scenario: The line above "Make PDF"
- **WHEN** the person opens the export screen
- **THEN** the line above "Make PDF" reads "The PDF leaves the app when you share it. Mail, Files and Messages keep their own copy, and Delete everything does not reach those copies."

### Requirement: The PDF is formatted like the paper record

The PDF MUST use A4 pages. The first page MUST start with the heading "Record", then the range, for example "28 August – 24 September 2026". The app MUST format the range with the en_GB interval formatter. The formatter writes a thin space (U+2009) on each side of the en dash. Under the range the PDF MUST show the line "Self-recorded on a phone. Times and words are the person's own.". Under that line the PDF MUST show the line "* felt like a binge".

The PDF MUST then show one line about the day start, "A day runs from %1$@ to %2$@.". The app MUST fill %1$@ with the day start and %2$@ with the minute before it. Both times MUST come from the en_GB formatter. With the day start at 04:00 the line reads "A day runs from 04:00 to 03:59.". `record` owns the day start, which "Day starts at" in the settings screen sets.

The PDF MUST then show every record day in the range, in date order, earliest first. Each day MUST start with a heading with the weekday and date, for example "Thursday 24 September 2026". The heading MUST come from the en_GB formatter. The PDF MUST show the winning version of each entry, as `record` defines it. The PDF MUST NOT show an entry whose winning version carries the `deleted` flag.

The PDF MUST place each entry under the day of its stored record day key. `record` writes that key at save and never changes it. The PDF MUST place each state line under the day of the state's stored key. A later change of the day start or the device zone MUST NOT move an entry to another day.

Under the heading the PDF MUST show the day's entries as a column. The column MUST have the headings "Time", "What", "Where" and "Context". When "Include context" is off, the column MUST have no "Context" heading and no Context column. The PDF MUST order the entries by entry time, then by creation moment, as Today does.

The days MUST flow as one column across the pages. The PDF MUST NOT start a new page for each day. When a day continues on a new page, the PDF MUST repeat the day's heading on that page. The PDF MUST use one text style for all entries, with no colour, no fill and no icon.

#### Scenario: The first page
- **WHEN** the range is 28 August to 24 September 2026
- **THEN** the first page reads "Record", "28 August – 24 September 2026", "Self-recorded on a phone. Times and words are the person's own.", "* felt like a binge" and "A day runs from 04:00 to 03:59." in that order, then the first day

#### Scenario: Two days in order
- **WHEN** the range is 21 September to 22 September and both days have entries
- **THEN** the PDF shows "Monday 21 September 2026" and its column, then "Tuesday 22 September 2026" and its column

#### Scenario: Entry after midnight
- **WHEN** an entry has the time 00:30 and the stored record day key Thursday 24 September
- **THEN** the PDF shows it under "Thursday 24 September 2026" with the time "00:30", after the day's earlier entries

#### Scenario: A deleted entry
- **WHEN** the person deleted an entry at 13:05 on Tuesday 22 September and taps "Make PDF" for a range that holds that day
- **THEN** the PDF shows no line for that entry and no text about a deletion

#### Scenario: The day start changed after a save
- **WHEN** an entry at 04:30 holds the stored record day key Friday 25 September, and the person later sets the day start to 05:00
- **THEN** the PDF still shows it under "Friday 25 September 2026"

#### Scenario: A day start other than 04:00
- **WHEN** the day start is 05:00 and the person taps "Make PDF"
- **THEN** the first page shows "A day runs from 05:00 to 04:59." in place of the 04:00 line

#### Scenario: Days flow on one page
- **WHEN** the range holds three days with two entries each
- **THEN** the PDF shows all three days on the first page, one after the other

#### Scenario: A long day over two pages
- **WHEN** a day has forty entries and the column runs past the end of the page
- **THEN** the next page repeats that day's heading above the rest of the column

#### Scenario: Context left out
- **WHEN** "Include context" is off and an entry has Context "Row with my sister"
- **THEN** the PDF has no "Context" heading and holds no part of "Row with my sister"

### Requirement: Each entry in the PDF

Each entry line MUST show the entry's clock time at its UTC offset. A starred entry MUST show the asterisk "*" beside the time, in the same weight and size as the time. The line MUST show the What, the Where and the Context in their columns, each only when not empty. An entry with an empty What MUST show the time and the asterisk when starred, and empty columns. The PDF MUST show the full text of every field with no truncation. The PDF MUST NOT show any label or difference for an entry the person saved late or edited.

#### Scenario: A starred entry
- **WHEN** an entry at 21:40 has the star on, What "Crisps and half a loaf", Where "Home" and Context "Row with my sister"
- **THEN** the PDF line shows "21:40 *", "Crisps and half a loaf", "Home" and "Row with my sister"

#### Scenario: An unstarred entry with What only
- **WHEN** an entry at 13:05 has What "Toast and tea" and no Where or Context
- **THEN** the PDF line shows "13:05" and "Toast and tea" and empty Where and Context columns

#### Scenario: An entry saved the next morning
- **WHEN** the person saved an entry at 07:30 with the time 23:30 the night before
- **THEN** the PDF shows it at 23:30 with no label about the creation moment

### Requirement: Days with no entries, "didn't record" days and paused days

A record day in the range with no entries and no state MUST show its heading and nothing under it. A day with the state "didn't record" MUST show the line "Didn't record" under its heading. A day with the state "paused" MUST show the line "Paused" under its heading. A day with both states MUST show both lines, "Didn't record" first. A day with a state and entries MUST show the state line, then the column of entries. The PDF MUST NOT show any other text about a day with no entries.

#### Scenario: Empty day
- **WHEN** Tuesday 22 September is in the range and has no entries and no state
- **THEN** the PDF shows "Tuesday 22 September 2026" and nothing under it before the next day's heading

#### Scenario: "Didn't record" day
- **WHEN** Tuesday 22 September has the state "didn't record" and no entries
- **THEN** the PDF shows "Tuesday 22 September 2026" and "Didn't record"

#### Scenario: Paused day with entries
- **WHEN** Thursday 24 September has the state "paused" and entries at 08:00 and 13:05
- **THEN** the PDF shows "Thursday 24 September 2026", "Paused", then the two entries

### Requirement: The optional weigh-in page

When "Include weigh-ins" is on, the PDF MUST add a last page with the heading "Weigh-ins". The page MUST list each weigh-in in the range with its date and value, in the person's unit. The page MUST show a value as `weigh-in` displays it: kilograms to one decimal place, or stone and whole pounds. The page MUST show no rolling average, no chart, no BMI, no goal, no target and no change between values. When no weigh-in falls in the range, the app MUST omit the page.

When "Include weigh-ins" is off, the PDF MUST hold no weight value. The `weigh-in` capability owns the weigh-in values and the unit.

#### Scenario: Weigh-ins included
- **WHEN** "Include weigh-ins" is on and the range holds weigh-ins on 7 September and 14 September
- **THEN** the last page reads "Weigh-ins" and lists "Monday 7 September 2026" and "Monday 14 September 2026" with their values, and nothing else

#### Scenario: Weigh-ins in stone and pounds
- **WHEN** "Include weigh-ins" is on, the unit is "st lb" and the range holds a weigh-in of 66.40 kg on 7 September
- **THEN** the page lists "Monday 7 September 2026" with "10 st 6 lb"

#### Scenario: Weigh-ins not included
- **WHEN** "Include weigh-ins" is off and the range holds two weigh-ins
- **THEN** the PDF holds no weight value and no "Weigh-ins" page

#### Scenario: No weigh-in in the range
- **WHEN** "Include weigh-ins" is on and no weigh-in falls in the range
- **THEN** the PDF has no "Weigh-ins" page

### Requirement: What the PDF never contains

The PDF MUST NOT contain an entry's creation moment or any late label. The PDF MUST NOT contain a count of entries or a count of starred entries. The PDF MUST NOT contain a total, a streak or a score. The PDF MUST NOT contain a gap band, a planned meal, a pattern sentence, an urge outcome or a worksheet. The PDF MUST NOT contain the height, the onboarding BMI or a screening answer. The PDF MUST NOT contain a weight value unless "Include weigh-ins" is on.

The PDF and its file name MUST NOT contain the product name or the person's name. The PDF's metadata MUST hold the title "Record" and the range, and no author. The PDF's Creator field MUST be empty. The app MUST leave the Producer field as the system writes it.

#### Scenario: A day with fifteen entries
- **WHEN** a day in the range has fifteen entries, three of them starred
- **THEN** the PDF shows the fifteen lines and no number for either count

#### Scenario: A gap in the range
- **WHEN** a day in the range has entries at 08:00 and 14:00 and stage 2 is open
- **THEN** the PDF shows the two entries and no band and no text about the gap

#### Scenario: File name
- **WHEN** the range is 28 August to 24 September 2026
- **THEN** the file's name is "Record 2026-08-28 to 2026-09-24.pdf"

#### Scenario: Metadata
- **WHEN** a PDF reader shows the document's properties
- **THEN** the title reads "Record 28 August – 24 September 2026", the Author and Creator fields are empty, and the Producer field holds what the system writes

### Requirement: Share sheet only

On "Make PDF" the app MUST build the PDF on the device and present it in the system share sheet. The app MUST write the PDF to a temporary file with the store's protection class. The app MUST delete the file when the share sheet closes. The app MUST NOT upload the PDF or send it by any channel of its own. The app MUST NOT keep a copy in the store. The PDF MUST have no password and no encryption.

The app MUST NOT save the PDF to Files or Photos unless the person chooses that in the share sheet. The app MUST NOT index the PDF in Spotlight or place it in an NSUserActivity. When the person cancels the share sheet, the app MUST return to the export screen with no message.

#### Scenario: Share
- **WHEN** the person taps "Make PDF"
- **THEN** the system share sheet opens with one PDF and the app makes no network request

#### Scenario: Cancel the share sheet
- **WHEN** the person cancels the share sheet
- **THEN** the app shows the export screen, shows no message, and no PDF file remains in the app's container

#### Scenario: After a share
- **WHEN** the person sends the PDF to Mail and returns
- **THEN** no PDF file remains in the app's container and the store holds no copy

#### Scenario: No password
- **WHEN** the person saves the PDF to Files and opens it there
- **THEN** the PDF opens with no password request

### Requirement: The export offered by the deterioration rule

When the `safeguarding` deterioration rule offers the export, the app MUST open the export screen. The screen MUST use the default range. The export screen MUST NOT show any text about why it opened. The person MUST be able to change the range before "Make PDF". The `safeguarding` capability owns the rule, its text and the GP suggestion page.

#### Scenario: Opened from the deterioration rule
- **WHEN** the deterioration rule offers the export on Thursday 24 September and the person accepts
- **THEN** the export screen opens with "From" 28 August, "To" 24 September and no text about the rule

#### Scenario: Change the range
- **WHEN** the export screen opened from the deterioration rule and the person sets "From" to 1 August
- **THEN** "Make PDF" builds the PDF from 1 August to 24 September

### Requirement: Offline and out of logs

The export MUST work with no network connection. The app MUST NOT write any entry field, weight value or PDF content to the system log. The app MUST NOT write them to standard output. An error in the build of the PDF MUST carry no entry field and no weight value.

#### Scenario: Airplane mode
- **WHEN** the device has no network and the person taps "Make PDF"
- **THEN** the share sheet opens with the PDF

#### Scenario: Build error
- **WHEN** the build of the PDF fails on a day with the entry "Crisps and half a loaf"
- **THEN** the error the app writes contains no part of "Crisps and half a loaf" and the app shows "The PDF could not be made. Try again."

### Requirement: The document and the paginator live in a package

`ExportDocument` MUST be a value that holds the PDF's content. That content is the first-page lines, the days with their state lines and entry lines, and the weigh-in page. `Paginator.paginate(document:pageHeight:measure:)` MUST split an `ExportDocument` into pages. `ExportDocument` and `Paginator` MUST live in a package that imports no UIKit. The `measure` parameter MUST be a function that returns a line's height. The app MUST supply a measurer built on UIKit.

The paginator MUST decide where each page ends and which day heading each page repeats. A test MUST paginate a document with a stub measurer. That test MUST assert that a day's heading repeats on the page that continues the day.

#### Scenario: Pagination with a stub measurer
- **WHEN** a test paginates a day with forty entries, a stub measurer that returns 20 points for every line, and a page height of 400 points
- **THEN** the paginator returns more than one page, and every page that continues that day starts with its heading

#### Scenario: No UIKit in the package
- **WHEN** the package that holds `ExportDocument` and `Paginator` builds
- **THEN** it imports no UIKit, and the app supplies the measurer

### Requirement: Accessibility of the export

Every control on the export screen MUST have a VoiceOver label. A control with no visible text MUST have a label a person can say with Voice Control. Text on the export screen MUST use system text styles. Text on the export screen MUST scale with Dynamic Type. The PDF MUST hold selectable text, not an image of text.

The PDF MUST use fixed text sizes. The body MUST be 11 pt, a day heading 14 pt and the title 18 pt. Those sizes MUST NOT change with Dynamic Type. The asterisk MUST be a text character in the PDF. The PDF's meaning MUST NOT depend on colour.

The PDF MUST be a tagged PDF. The PDF MUST tag the heading "Record" as an H1. The PDF MUST tag each day heading as an H2. Each day's entries MUST be one tagged list with one list item per entry. Each item's text MUST read, in order: the time, the asterisk when starred, the What, the Where, the Context. With "Include context" off, the item's text MUST end at the Where.

When the system's PDF renderer can write the tag, the PDF MUST declare the language en-GB. The team MUST test that during the export change before it commits to the tag. The design states the risk. A screen reader MUST read the days in date order. A screen reader MUST read each entry in one pass, not one column at a time.

#### Scenario: Screen reader on the PDF
- **WHEN** a screen reader opens the PDF
- **THEN** it reads "Record" as a heading, then each day heading as a level 2 heading in date order, then that day's entries as one list

#### Scenario: One pass per entry
- **WHEN** a screen reader reaches an entry at 21:40 with the star on, What "Crisps and half a loaf", Where "Home" and Context "Row with my sister"
- **THEN** it reads one list item: "21:40 * Crisps and half a loaf Home Row with my sister"

#### Scenario: The tag tree of a day
- **WHEN** a day has three entries and a PDF reader shows the tag tree
- **THEN** one list with three list items follows the day's H2, and no other structure

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
