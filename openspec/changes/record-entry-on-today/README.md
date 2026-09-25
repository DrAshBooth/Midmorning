# record-entry-on-today

First vertical slice: record one entry and see it on Today

## Evidence from the simulator, 25 September 2026

Claude did rows 2.4 to 2.9 on the iPhone 17 simulator with iOS 27.0. The UI
tests and the seeder are in `tools/skeleton-checks`, and they can run again.
The seeded store holds 19:20 "Pasta" and 01:15 "Cereal" starred in the record
day of Thursday 24 September. It holds 08:10 "Porridge", 10:45 with an empty
What, 13:05 "Toast and tea" starred and 15:30 "Apple and a coffee" in the
record day of Friday 25 September.

| Row | Result | Evidence |
|-----|--------|----------|
| 2.4 | Pass. Headings "Thursday 24 September" and "Friday 25 September". Rows: 19:20 Pasta; 01:15 Cereal, starred; 08:10 Porridge; 10:45; 13:05 Toast and tea, starred; 15:30 Apple and a coffee. | `evidence/2.4-today.png` |
| 2.5 | Pass, with a UI test in place of Accessibility Inspector. Labels "13:05, Toast and tea, felt like a binge" and "10:45". | `evidence/2.4-today.png` |
| 2.6 | Pass. One tap on "New entry" opens the sheet. With the time zone set to Pacific/Guadalcanal, the headings at 03:49 were "Thursday 24 September" and "Friday 25 September, night". After reactivation at 04:00 they were "Friday 25 September" and "Saturday 26 September". | `evidence/2.6-one-tap.png`, `evidence/2.6-heading-before.png`, `evidence/2.6-heading.png` |
| 2.7 | Fail on one item. The keyboard is up on open, What has the focus and no placeholder, the sheet has no title, and the calendar enables only 24 and 25 September. The accessibility order is Cancel, Save, What, felt like a binge, Time. | `evidence/2.7-new-entry.png`, `evidence/2.7-range.png` |
| 2.8 | Pass. The sheet closes and Today shows the saved row in view, with no alert. An empty What gives a row with the time alone. | `evidence/2.8-save.png`, `evidence/2.8-save-empty.png` |
| 2.9 | Pass after a fix. The switcher shows Today and the new-entry screen with no entry text, no label and no star. After a return, What keeps its text and the focus. | `evidence/2.9-switcher.png`, `evidence/2.9-switcher-new-entry.png`, `evidence/2.9-back-from-switcher.png` |
| 2.12 | Screens only. Ash walks the path. | `evidence/2.12-*-dark.png`, `evidence/2.12-*-light.png` |

## Defects the checks found and fixed

- VoiceOver read the label of What two times, "What, What". The row's label
  text is now hidden from VoiceOver, and the field carries the label.
- The star switch used the system green. A tint in the primary colour hid the
  switch's knob in dark mode. The switch now uses the system grey, and the v1
  record spec says so.
- In the app switcher, the new-entry screen showed "What", "felt like a binge"
  and the star. The sheet now redacts itself and hides the switch when the
  scene is not active.

## Open items, each with a decision or a bead

- Cancel and Save are in the navigation bar, so VoiceOver reads them first.
  Decision 106 settles this.
- The time control carries the label "Time" and the value "Friday 25
  September, 18:26". The compact picker also has a date button and a time
  button with the system's own text ("25 Sep 2026", "18:26"). VoiceOver on a
  device must show which elements it reads. Decision 88 weighs the control's
  form.
- The keyboard shows the prediction bar in What. Decision 89 weighs this.
- Xcode's accessibility audit marks the day headings "contrast nearly
  passed". They use the system's default section-header colour. Bead
  mm-t12b.2 carries this.
- The audit marks Cancel and Save for contrast and for Dynamic Type. They are
  the system's navigation-bar buttons, drawn in black on the system glass. On
  a device at the largest text size, a long press must show the large content
  viewer.
- The app icon is blank. Bead mm-t43.26 adds the icon.

## Before the archive

Ash does these on a device, then runs `openspec archive record-entry-on-today`
and closes mm-t10.

1. With VoiceOver on, open the new-entry screen. Focus is on What, and VoiceOver
   says "What" one time. Record what VoiceOver reads on the time control.
2. With a third-party keyboard as the active keyboard, open the new-entry
   screen. The system keyboard appears.
3. Walk the starred-entry path (row 2.12) and replace the draft below.

## Shame walk

Question for each screen: could a person who has just binged read this as
judgement?

Draft by Claude from the screenshots of 25 September 2026, in dark and light
mode. This draft is not the sign-off. A person walks the path on the built
app, then writes their name, the date and their answers here.

- Today before the save (`evidence/2.12-a-today-*.png`): no. The rows are
  times and words in one colour. There are no counts, colours or icons. The
  asterisk has the time's colour and weight.
- The new-entry screen with the star on
  (`evidence/2.12-b-new-entry-star-on-*.png`): no, for the switch. It turns
  grey and nothing else changes. One risk: "felt like a binge" is in view with
  the keyboard up before the person touches it. Decision 86 weighs where the
  star sits.
- Today after the save (`evidence/2.12-c-today-after-save-*.png`): no. The
  sheet closes with no message. The new row reads "18:20 *", as the other
  starred rows do.
