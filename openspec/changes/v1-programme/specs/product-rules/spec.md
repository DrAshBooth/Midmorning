# product-rules

## Purpose

These rules govern every screen, string, notification and widget in Midmorning. They come from the PRD's never list, its tone rules, its design principles for the record and its name rules. Where a feature spec and this spec conflict, this spec applies.

## ADDED Requirements

### Requirement: The never list

The app MUST NOT show calories, macros, portions, nutrition scores or daily food totals. The app MUST NOT set or show a goal weight, a BMI after onboarding, or any progress framing of weight. The app MUST NOT reward fewer entries, longer gaps or "clean" days with a streak, a badge or a score. The app MUST NOT colour-code a food or an entry as good or bad.

The app MUST NOT accept a food photo. The app MUST NOT compare the person to other people. The app MUST NOT generate advice at runtime.

#### Scenario: A day with many entries
- **WHEN** a record day has fifteen entries
- **THEN** the app shows the day at the same visual weight as a day with five, with no total and no count except the count line of a collapsed day, as the `record` capability states

#### Scenario: A week with fewer starred entries
- **WHEN** the weekly review finds fewer starred entries than the week before
- **THEN** the review states the two numbers and shows no praise, badge, streak or score

#### Scenario: Weight over time
- **WHEN** the person opens the weigh-in screen
- **THEN** the app shows the rolling average and no goal, target line, BMI, colour or change since last time

### Requirement: Tone of every string

Every string MUST pass this question before any other: can a person who has just binged read this as judgement? The app MUST NOT praise restriction. The app MUST NOT shame eating.

The app MUST NOT cheer ("you've got this"). The app MUST NOT use medical language. The app MUST describe a lapse as a lapse. The clinical reviewer MUST review every string before release.

#### Scenario: A missed planned meal
- **WHEN** a planned meal passes with no entry
- **THEN** the app shows one missed planned meal prompt with no word of blame

#### Scenario: A starred entry
- **WHEN** the person saves a starred entry
- **THEN** the app shows no message about it

### Requirement: Vocabulary

The app MUST use these words: "entry", "What", "Today", "felt like a binge", "plan", "planned meal", "weigh-in", "urge", "worksheet". The app MUST NOT use "log", "meal log", "food diary", "intake", "portion", "serving", "calories", "tracker" or "user" in any string. On Today, the new-entry screen, widgets and notifications, the app MUST use "binge" only in "felt like a binge" and "I binged". Onboarding, cards, the taking stock questionnaire and Get support MUST use "binge eating" or "binge eat" as the PRD does. A card can also say "a binge". The app MUST NOT use "binger", "bingeing", "binge episode" or the bare plural "binges".

#### Scenario: The new-entry screen
- **WHEN** the person opens the new-entry screen
- **THEN** its labels are "What" and "felt like a binge" and no label names food, a meal or a diary

### Requirement: Nothing looks like a nutrition app

The app MUST NOT use a plate, fork, apple, scale or tape-measure image anywhere. This includes the app icon, widgets and App Store screenshots. The app MUST NOT show food photography. The app's visual language MUST read as a notes or calendar app. The app MUST NOT reveal what it is for to a person who glances at any screen. The star control's label "felt like a binge" on the new-entry screen is an exception. The urge screen's "I binged" control is the other. `urge-toolkit` owns that control. Each is body text, not a heading or an image.

#### Scenario: The app icon
- **WHEN** the app icon appears on a lock screen or home screen
- **THEN** it shows no food, scale, body or health image and no word about eating

#### Scenario: A glance at Today
- **WHEN** a person sees Today from a metre away
- **THEN** they see times and short text and no image or heading that names eating, weight or health

### Requirement: The product name and the plan slot

The product name is "Midmorning". The plan slot is "Mid-morning". The app MUST write the product name without a hyphen and the slot with one. The app MUST NOT show the product name in a notification beside a meal word. Explicit wording, when the person turns it on, is the one exception. The app MUST NOT reference Fairburn, Oxford, CREDO or any book in any string.

#### Scenario: A discreet reminder
- **WHEN** the mid-morning planned meal is at 10:30 and explicit wording is off
- **THEN** the notification reads "Midmorning, 10:30" and nothing else

#### Scenario: An explicit reminder
- **WHEN** explicit wording is on
- **THEN** the notification names the slot, for example "Mid-morning, 10:30", and still names no food

### Requirement: What a notification never shows

A notification MUST NOT show entry text or any record content. A notification MUST NOT show the words food, meal, binge or weight unless explicit wording is on. With explicit wording on, a notification MUST still show no entry text and no weight value.

#### Scenario: Lock-screen preview
- **WHEN** a reminder appears on the lock screen with explicit wording off
- **THEN** it shows "Midmorning" and a time only

### Requirement: The person can put it down

Every feature the person can turn on MUST have a switch to turn it off. The weekly summary and the pattern sentences MUST each be opt-out. "Pause for today" MUST be reachable from Today in one tap. The app MUST NOT frame any part of the record as a commitment the person has broken.

#### Scenario: Pause
- **WHEN** the person taps "Pause for today"
- **THEN** reminders stop for the record day, the store keeps the day as paused, and the app draws no conclusion from it

### Requirement: Accessibility everywhere

Every control MUST have a VoiceOver label. Every control with no visible text MUST have a label a person can say with Voice Control. Every text MUST scale with Dynamic Type. Meaning MUST NOT depend on colour alone. The record and urge flows MUST be complete with VoiceOver.

Every control MUST have a hit area of at least 44 by 44 points. Two controls MUST have at least 8 points between them. Every animation MUST stop or become a cross-fade when Reduce Motion is on. Secondary text and every glyph that carries meaning MUST contrast with the background at 3:1 or more. That contrast MUST hold in light mode, in dark mode and with Increase Contrast on.

#### Scenario: Urge flow with VoiceOver
- **WHEN** a person using VoiceOver taps Urge, hears the timer, reads the alternatives list and saves an outcome
- **THEN** every step has a spoken label and no step needs sight

#### Scenario: Reduce Motion
- **WHEN** Reduce Motion is on and the person opens the urge screen
- **THEN** nothing on the screen scales or slides, and every change is a cross-fade or a step

#### Scenario: Voice Control
- **WHEN** the person says "Tap Add an entry" on Today
- **THEN** the new-entry screen opens

### Requirement: Dates and times in strings

Every date the app formats MUST use the locale en_GB, the Gregorian calendar and the record's zone. The app MUST NOT use the device locale. Every formatter MUST take the locale and the calendar as parameters. Every clock time MUST use the 24-hour clock.

Every string MUST say "device", not "iPhone", except where iOS itself uses the word. The app MUST capitalise Apple screen names: Lock Screen, Home Screen, Control Centre, Notification Centre, Recents. A VoiceOver label for a control with visible text MUST equal that text.

#### Scenario: A formatted date in a test
- **WHEN** a test formats 28 September 2026 with the London calendar
- **THEN** the result is "Monday 28 September" on any machine

### Requirement: Offline and private by default

Every screen in the core loop MUST work with no network. The app MUST NOT need an account. An entry, a weight value or free text MUST NOT leave the device. The one exception is the person's own iCloud private database.

#### Scenario: Airplane mode
- **WHEN** the device has no network
- **THEN** the record, the plan, reminders, the urge toolkit, the weekly review and the weigh-in all work

### Requirement: No AI at runtime

The app MUST NOT call a language model or any generative service at runtime. Every card, question and sentence MUST be bundled text with the clinical reviewer's sign-off.

#### Scenario: A pattern sentence
- **WHEN** the app builds a pattern sentence from the record
- **THEN** it fills a reviewed template with numbers and times, and generates no other words

### Requirement: Appearance

Every screen MUST use the system text styles and the system semantic colours. The app MUST NOT use a custom font. The app MUST NOT use a custom colour, except the accent colour.

The app MUST define one accent colour, in the AccentColor asset. The asset MUST hold a light value, a dark value and an Increase Contrast value. Each value MUST contrast with the row background at 3:1 or more. The team changes the accent colour in that one asset only.

Every control MUST use the accent colour as its tint. The app MUST NOT use the accent colour on anything that is not a control. The star control on the new-entry screen is an exception. Its tint is the system grey, as `record` states. System alerts, confirmation dialogs and swipe actions MUST also keep their system colours.

These MUST use the primary text colour and MUST NOT use the accent colour:

- the asterisk of a starred entry
- the urge curve
- the line of the weigh-in chart
- the pinned note and its pin glyph

Every list MUST use the plain list style. A list section MUST NOT have a fill. Every sheet MUST be the system sheet at the large detent. The app MUST NOT set a custom corner radius, a shadow or a background image. Every transition MUST be the system's standard transition.

Every glyph the app adds MUST be an SF Symbol. The app MUST use only four symbols: plus, pin, lock and chevron. A system control keeps its own glyphs.

A screen that shows the record MUST open with a push onto the navigation stack. A screen that asks the person for an answer MUST open as a sheet. Onboarding and the cover are exceptions, because each fills the screen. The app MUST follow the system appearance, light or dark.

Every text field MUST fill the width of its row. Its label MUST sit above it. Its text MUST align to the leading edge. A set of chips MUST wrap onto more lines in a flow layout. A set of chips MUST NOT scroll to the side.

#### Scenario: One accent colour on Today
- **WHEN** Today shows a starred entry, "Add an entry", the lock control and "Get support", in light and dark mode
- **THEN** each control uses the accent colour, and each time and the asterisk use the primary text colour

#### Scenario: The star control in dark mode
- **WHEN** the device is in dark mode and the person turns the star on in the new-entry screen
- **THEN** the switch uses the system grey, its knob shows, and no other colour on the screen changes

#### Scenario: Where chips at the largest text size
- **WHEN** the text size is the largest accessibility size (AX5) and the new-entry screen shows all thirteen Where chips
- **THEN** the chips wrap onto more lines, each chip shows its full text, and nothing scrolls to the side

#### Scenario: A screen that asks for an answer
- **WHEN** the person taps "Add an entry" on Today
- **THEN** the new-entry screen opens as the system sheet at the large detent, with "What" above its field

#### Scenario: A screen that shows the record
- **WHEN** the person opens "Earlier days" from the day heading's menu and taps a day
- **THEN** the list and then the day each open with a push onto the navigation stack

#### Scenario: Dark mode follows the system
- **WHEN** the person turns on dark mode in Control Centre while Today is open
- **THEN** Today shows in dark mode at once, with the same text and the same controls
