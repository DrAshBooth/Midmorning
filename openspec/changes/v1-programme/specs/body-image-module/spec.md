# body-image-module

## Purpose

The body image module gives the person cards on body checking, body avoidance and "feeling fat", and one tool: Feeling fat notes. Its displayed name is "Body image". Every string the person sees calls the module "Body image". Only this spec and its capability directory keep the name body-image-module.

The work on checking and avoidance is content-led in V1. The module has no tool that counts checks, asks for a mirror or a measurement, rates the body or takes a photo. A tool of that kind is the part of the method most likely to become body scrutiny inside an app.

## ADDED Requirements

### Requirement: The module opens from taking stock

The `programme` capability opens the module's tool when taking stock is complete. The `weekly-review` capability owns taking stock and its module recommendation. The app MUST let the person open the body image module whatever the recommendation says. The app MUST show the module's cards before taking stock, because the app never blocks reading ahead. The app MUST NOT show Feeling fat notes before taking stock.

#### Scenario: Taking stock recommends the module
- **WHEN** taking stock at week 6 recommends the body image module
- **THEN** the app shows the module with its cards and Feeling fat notes

#### Scenario: Taking stock does not recommend the module
- **WHEN** taking stock at week 6 does not recommend the body image module
- **THEN** the app shows the same module, with the same cards and Feeling fat notes, and no text about the recommendation

#### Scenario: Before taking stock
- **WHEN** the person opens the body image module in week 3
- **THEN** the app shows the module's cards and no Feeling fat notes

### Requirement: The module's displayed name is "Body image"

Every string the person sees MUST name the module "Body image". This covers the module screen's title, the stage 6 module title, the Programme screen row and the settings screen's link. It also covers a card title that names the module and the taking stock recommendation strings. Those are "From your answers, Body image is the one to open first." and "Open Body image".

The `programme`, `settings`, `content` and `weekly-review` capabilities own those strings. Those capabilities MUST use this name. The name body-image-module MUST appear only in this spec and its capability directory.

#### Scenario: The module screen
- **WHEN** the person opens the module from the Programme screen
- **THEN** the Programme screen row reads "Body image" and the module screen's title is "Body image"

#### Scenario: The recommendation
- **WHEN** taking stock recommends the module
- **THEN** the recommendation reads "From your answers, Body image is the one to open first." with the control "Open Body image"

#### Scenario: A reviewer lists every string
- **WHEN** a reviewer lists every string the app shows that names the module
- **THEN** each one reads "Body image"

### Requirement: Cards on checking, avoidance and "feeling fat"

The `content` capability owns the module's cards, their count, their length and their tone. The app MUST group the cards under three headings: "Checking", "Avoidance" and "Feeling fat". The app MUST let the person read any card at any time.

A card MUST carry at most one in-app link. That link MUST open Feeling fat notes. A card on checking or avoidance MUST end with the one thing to do, as `content` defines it. The card MUST NOT ask the person to count anything.

#### Scenario: Open the checking cards
- **WHEN** the person opens "Checking"
- **THEN** the app shows the checking cards and no control that saves a check

#### Scenario: A "feeling fat" card
- **WHEN** the person reads the last card under "Feeling fat"
- **THEN** the card ends with the one thing to do and offers one link to Feeling fat notes

#### Scenario: Read a card again
- **WHEN** the person has read every card and opens "Avoidance" again
- **THEN** the app shows the cards with no tick, count or label about earlier reading

### Requirement: No checking or avoidance tool

The app MUST NOT include a control that saves, counts or times a body check. The app MUST NOT ask the person to look in a mirror, weigh, measure or pinch. The app MUST NOT ask the person to compare any part of the body. The app MUST NOT ask for a body image rating, a shape rating or a satisfaction number. The app MUST NOT accept a photo anywhere in the module. The app MUST NOT show a body outline, a silhouette, a mirror or a tape-measure image in the module.

#### Scenario: A reviewer checks the module
- **WHEN** a reviewer walks every screen of the module on the simulator
- **THEN** no screen has a control that counts a check, a request to look or measure, a rating, a photo control or a body image

#### Scenario: A note asks nothing about the body
- **WHEN** the person opens a new Feeling fat note
- **THEN** the screen asks "What was happening?" and "What was the feeling underneath?" and nothing about weight, shape or a body part

### Requirement: A Feeling fat note

The app MUST let the person create a note with a time, a "What was happening?" text and a "What was the feeling underneath?" text. The time MUST default to the moment the new note opens. The app MUST let the person edit the time within the previous and current record day. The store MUST write the note's record day key at save from the note's time, as `record` defines.

The note's record day MUST NOT change after save. An edit of the time MUST NOT change it. A note is one synced row with its own `changedAt` and a `deleted` flag with a moment. An edit MUST write into the winning row. The `data-and-privacy` capability owns the conflict rule and retention.

Both texts MUST be free text. Both texts MUST accept an empty text. The app MUST NOT offer a list of emotions, a picker or autocomplete. The app MUST NOT show a placeholder in either field.

The app MUST let the person edit a note after saving. When the person saves, the app MUST close the screen with the system's standard dismissal and show no message.

#### Scenario: Save a note
- **WHEN** the person opens a new note at 21:10, types "Got dressed for dinner out" and "Dreading being looked at" and saves
- **THEN** the app saves one note with the time 21:10 and both texts, and the screen closes with no message

#### Scenario: Save with one field empty
- **WHEN** the person types "Got dressed for dinner out", leaves the second field empty and saves
- **THEN** the app saves the note with an empty "What was the feeling underneath?" text

#### Scenario: Edit a note
- **WHEN** the person opens the 21:10 note and changes the second text to "Dreading being looked at. Lonely."
- **THEN** Feeling fat notes shows the note at 21:10 with the new text

#### Scenario: Time range
- **WHEN** the person opens the time control on a note
- **THEN** the control offers times from the start of the previous record day to the current moment, and nothing outside that range

### Requirement: Optional link to an entry

The app MUST let the person link a note to one entry, or to none. The app MUST offer the entries whose stored key is the note's record day or the previous one. The app MUST show a linked entry on the note as its time and its What. The app MUST NOT require a link.

The note holds the entry's id, and the app resolves the link on read. The store MUST NOT use a SwiftData relationship for it. When the entry's winning version carries the `deleted` flag, the app MUST show the note without the link. The app MUST NOT write to the note because of that.

#### Scenario: Link an entry
- **WHEN** the person taps "Link an entry" on the 21:10 note and picks the entry at 20:30 with What "Pasta"
- **THEN** the note shows "20:30, Pasta" under its texts

#### Scenario: No link
- **WHEN** the person saves a note without a link
- **THEN** the note shows its time and texts and no text about a missing link

#### Scenario: Linked entry deleted
- **WHEN** the person deletes the 20:30 entry from the record
- **THEN** the note stays and shows no link and no message, and the app writes nothing to the note

### Requirement: The list of notes

Feeling fat notes MUST show the notes grouped by their stored record day key, latest day first. Within a day the list MUST sort the notes by time, earliest first. Each note MUST show its time and its texts when they are not empty. The list MUST NOT show a count of notes, a chart, a pattern sentence or a summary. The list MUST NOT show a day heading for a day with no notes. When there are no notes, the app MUST show the control that opens a new note, and nothing else.

#### Scenario: Two days of notes
- **WHEN** Feeling fat notes has a note on Monday 16 November and two on Tuesday 17 November
- **THEN** the list shows Tuesday's heading and its two notes in time order, then Monday's heading and its note

#### Scenario: No notes
- **WHEN** Feeling fat notes has no notes
- **THEN** the list shows the control that opens a new note and no text about the absence of notes

#### Scenario: Many notes in a week
- **WHEN** Feeling fat notes has fourteen notes in one week
- **THEN** the list shows them at the same visual weight as a week with two, with no count and no summary

### Requirement: Feeling fat notes is opt-out and deletable

The app MUST show a switch on the module screen, labelled "Feeling fat notes", on by default. The switch MUST live on the module screen only. The settings screen MUST link to it. `settings` owns that link. When the switch is off, the app MUST hide the notes and their control. The app MUST keep the notes while the switch is off.

When the person turns the switch on again, the app MUST show the notes again. The app MUST let the person delete any note with the system's standard delete action. A delete MUST write the note's `deleted` flag with the moment. The app MUST NOT hard-delete a note. The app MUST hide a deleted note on read.

The app MUST let the person delete every note with one control, "Delete every note", after one confirmation. That control MUST write the `deleted` flag on each note the list shows. The `data-and-privacy` capability owns Delete-all. Delete-all MUST delete every note.

#### Scenario: Turn the notes off
- **WHEN** the person turns off "Feeling fat notes"
- **THEN** the module shows the cards and the switch, and no control for a note

#### Scenario: Turn the notes on again
- **WHEN** the person turns "Feeling fat notes" off and then on
- **THEN** the list shows every note it had before

#### Scenario: From the settings screen
- **WHEN** the person follows the settings screen's link for "Feeling fat notes"
- **THEN** the app opens the module screen, titled "Body image", with the switch on it, and the settings screen holds no switch of its own

#### Scenario: Delete one note
- **WHEN** the person deletes the 21:10 note
- **THEN** the list no longer shows it, the note's row carries `deleted` with the moment, and the app shows no message

#### Scenario: Delete every note
- **WHEN** the person taps "Delete every note" and confirms
- **THEN** every device hides every note and the list shows the control that opens a new note

### Requirement: Feeling fat notes sends nothing and asks nothing

The app MUST NOT schedule a reminder or any notification for Feeling fat notes. The app MUST NOT ask the person to write a note at any time or after any entry. The app MUST NOT put a note's text in a notification, a log or an error. The app MUST keep the notes in the store, with the record's protection. The app MUST hide a note's text when the app is not active. The `data-and-privacy` capability owns sync of the notes to the person's private iCloud.

#### Scenario: After a starred entry
- **WHEN** the person saves a starred entry
- **THEN** the app shows nothing about Feeling fat notes

#### Scenario: App switcher
- **WHEN** the person opens the App Switcher while Feeling fat notes is on screen
- **THEN** the app's snapshot shows no note text

#### Scenario: Store error
- **WHEN** the store fails to save a note with the text "Dreading being looked at"
- **THEN** the error the store throws contains no part of that text

#### Scenario: No network
- **WHEN** the device has no network connection
- **THEN** the person can read every card and create, edit and delete a note

### Requirement: Vocabulary of the module's tool

The visible strings of Feeling fat notes are "Feeling fat notes", "What was happening?", "What was the feeling underneath?", "Link an entry", "Delete every note", "Save" and "Cancel". The app MUST use the word "fat" only in "feeling fat" and "Feeling fat notes". The app MUST NOT use the words weight, shape, size, mirror, check, measure or diary in the tool. The clinical reviewer MUST review every string in the module before release.

#### Scenario: The new note screen
- **WHEN** the person opens a new note
- **THEN** its labels are "What was happening?", "What was the feeling underneath?" and "Link an entry", and no label names weight, shape or a body part

#### Scenario: A reviewer reads every string
- **WHEN** a reviewer lists every string in the module's tool
- **THEN** each string is one of the visible strings above, or a time, or the person's own text

### Requirement: Accessibility of the module

Every control in the module MUST have a VoiceOver label. Every control MUST meet the hit-area rule that `product-rules` defines. Each note MUST be one accessibility element. Its label MUST hold the time, then each text when not empty. Then it MUST hold the linked entry's time and What, when linked. A comma and a space MUST separate the parts.

Every text MUST scale with Dynamic Type. Meaning MUST NOT depend on colour alone.

#### Scenario: Label of a note with a link
- **WHEN** VoiceOver reads the 21:10 note with the texts "Got dressed for dinner out" and "Dreading being looked at" linked to "20:30, Pasta"
- **THEN** it reads "21:10, Got dressed for dinner out, Dreading being looked at, 20:30, Pasta"

#### Scenario: Largest text size
- **WHEN** the person sets the largest accessibility text size
- **THEN** the cards and Feeling fat notes show all text without truncation
