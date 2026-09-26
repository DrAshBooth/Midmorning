# settings

## Purpose

The settings screen holds every switch, time and choice the person can change, in one place, one tap from Today. Each item's owning capability defines what it does. This spec defines where the item lives, its label, its default and whether it syncs.

## ADDED Requirements

### Requirement: The Weigh-in group

The Weigh-in group MUST hold "Weigh-in day" (a weekday or "I won't be weighing", syncs) and "Unit" ("kg" or "st lb", default "kg", syncs).

#### Scenario: Change the unit
- **WHEN** the person changes the unit to "st lb"
- **THEN** the weigh-in screen and the export show weights in stone and pounds from then on
