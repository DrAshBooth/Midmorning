# content

## Purpose

Content is the clinically reviewed words the person reads: the cards, the string families, and the record of what version they saw.

## ADDED Requirements

### Requirement: The store keeps which content version the person saw

When the person opens a card, the app MUST save a card view in the store. A card view MUST hold the card's id, the content version and the moment the card opened. The app MUST keep card views under the same file protection, backup exclusion and log rules as entries. The `record` capability owns those rules. The app MUST NOT show card views to the person.

Card views MUST sync with the record. Data-and-privacy owns sync. Delete-all MUST delete card views. Data-and-privacy owns Delete-all. A card view MUST leave the device only through sync.

#### Scenario: A card opens
- **WHEN** the person opens the card "Why write it down" at 13:05 on 28 September 2026 with content version 1
- **THEN** the store holds a card view with id "stage1.why", content version 1 and the moment 13:05 on 28 September 2026

#### Scenario: The same card after an update
- **WHEN** the person opens "Why write it down" again after the content version rose to 2
- **THEN** the store holds a second card view with content version 2 and keeps the first

#### Scenario: Card views stay private
- **WHEN** the person opens a card
- **THEN** the app writes nothing about the card to the system log, and the card view leaves the device only through sync
