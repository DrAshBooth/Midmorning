# settings

1.3 from `openspec/changes/v1-programme/tasks.md`: the settings screen, the Reminders sub-screen, the Record and Privacy groups' first-cut rows, the privacy notice screen, and the About group's "Draft content" row.

## Verify

Cold `./verify` (fresh `Packages/.build` and Xcode `DerivedData`, in this worktree): 11 seconds. Warm `./verify`: 1 second. Both are well inside the 240-second budget.

## Scope: four of the settings screen's five groups

This change builds Reminders, Record, Privacy and About. The Weigh-in group waits for `weigh-in` (2.2), which owns it (task 2.2 in `v1-programme`'s `tasks.md`). Two requirements this change touches have no scenario of their own built here, so this change's delta adds neither requirement heading to `openspec/specs` yet:

- "The Record group": this change builds "Day starts at" and "Gap bands" (decision 65), proved by pure-function tests with fixed dates in `SettingsScreenTests.swift`. The requirement's one scenario, "Turn pattern sentences off", is `mm-t33.15`'s (`problem-solving`, 3.3); that bead's own delta adds the requirement heading.
- "The Privacy group": this change builds "Delete everything" (over a stub `DeleteAllSeam`) and the "Privacy" link to the notice. The requirement's two scenarios, "Sync off" and "iCloud full", are `mm-t41b.9`'s (`sync`, 4.1b); that bead's own delta adds the requirement heading.

## Appearance: plain system styling until `record-full` lands `Appearance.swift`

`record-full` (1.2b, `mm-t12b`) builds `Appearance.swift` and the shared `AccentColor` asset in a worktree building in parallel with this one. Every screen this change adds uses the system's own list style, text styles and tint, with no custom colour. Once `Appearance.swift` merges, `SettingsView.swift`, `RemindersSettingsView.swift` and `PrivacyNoticeView.swift` adopt its tint; nothing else in these screens needs to change, because none of them sets a colour of its own today.

## Get support: a placeholder sheet

`onboarding-and-safeguarding` (1.4) owns the real support sheet (`mm-t14.24`) and the cross-screen wiring bead for it (`mm-t14.23`), neither built yet. The settings screen, the Reminders screen and the privacy notice screen each show a "Get support" control in the trailing position of the navigation bar; it opens `GetSupportPlaceholderSheet`, a plain sheet titled "Get support" with no content yet. `mm-t14.24` replaces the sheet; the three "Get support" toolbar items stay as they are.

## The rules checklist

Every item below is a dated yes for 25 September 2026, written by the agent that built this change.

- mm-pr1, The never list — yes. This change shows no count, total, streak, score or colour-coded value; the About group's counts (app version, content version) are release metadata, not record content, and the requirement itself lists them.
- mm-pr2, Tone of every string — yes. Every string this change adds is plain and factual (a control label, a setting's name, a privacy topic); none praises, cheers or shames. The privacy notice's placeholder sections state only that the team confirms them before release.
- mm-pr3, Vocabulary — yes. This change uses "reminder", "planned meal", "weigh-in", "entry" only inside "Delete everything" (which does not name an entry), and "settings screen"; it uses no "log", "meal log", "food diary", "intake", "portion", "calories", "tracker" or "user" anywhere.
- mm-pr4, Nothing looks like a nutrition app — yes. Every screen uses plain system list rows and system SF Symbols the app already ships (`plus`, `chevron`, the system disclosure indicator); this change adds no plate, fork, apple, scale, tape measure or food photograph.
- mm-pr5, The product name and the plan slot — yes. This change writes neither "Midmorning" nor "Mid-morning" in any string it adds.
- mm-pr6, What a notification never shows — yes. This change schedules no notification; it only stores the settings a later change's scheduler reads.
- mm-pr7, The person can put it down — yes. Every switch this change adds has its own off state, and every reminder switch, gap bands and explicit wording default to values the person can change; the Reminders group's paused line and "Turn reminders on" control let the person resume without penalty.
- mm-pr8, Accessibility everywhere — yes. Every control is a plain `Toggle`, `Button`, `NavigationLink`, `DatePicker` or `LabeledContent` with a catalogue-key label; VoiceOver's label equals the visible label by construction, and text uses system text styles, so Dynamic Type applies without extra code. `settings: Accessibility of the settings screen` (mm-t13.7) is this change's own accessibility bead.
- mm-pr9, Dates and times in strings — yes. Every reminder time this change stores and shows uses the 24-hour clock ("07:30", "21:45"); no formatter reads the device locale.
- mm-pr10, Offline and private by default — yes. Every read and write in this change is a local `RecordStore` call over `Record.store` and `Local.store`; the privacy notice and the About group read only the bundled content, over no network.
- mm-pr11, No AI at runtime — yes. This change computes no sentence; every string is a bundled or catalogued literal.
- mm-pr12, Appearance — yes, with the noted gap above. Every list uses the plain system style; every sheet is the system sheet; this change sets no custom colour, corner radius, shadow or font. It defines no accent colour of its own, because `record-full`'s `AccentColor` asset does not exist in this worktree yet; see "Appearance" above.

### Get support on every screen

This change adds three full screens: the settings screen, the Reminders screen and the privacy notice screen. Each shows a "Get support" control in the trailing position of its navigation bar, opening the placeholder sheet the "Get support: a placeholder sheet" section above names. `onboarding-and-safeguarding` (1.4) supplies the real sheet without moving any of the three controls.

## Device checks

Listed on the epic's device-check bead (`mm-t13.8`); Ash performs each on a built app and adds its date and screenshot here.

- "Reach the settings screen" (settings spec, "One screen, one tap from Today"): tap "Settings" in Today's bottom toolbar; the settings screen opens.
- "Privacy notice" (data-and-privacy spec, "The privacy notice"): open the settings screen, tap "Privacy"; the notice holds the controller placeholder, the contact, who reads the contact inbox, Apple, the App Analytics line, the backup line and the ICO line.
- "VoiceOver on a switch" (settings spec, "Accessibility of the settings screen"): with VoiceOver on, read the Record group's "Gap bands" row (this change's own built switch, in place of "Weekly summary", which `weekly-review`, 3.2, adds); it reads the label, "switch", and "on" or "off".

## Scope note: `about.contact`

The About group's "Contact" row and the privacy notice's contact section both read the content catalogue key `about.contact`, which holds the placeholder `contact@example.invalid` (decision 99) until `mm-t43.17` confirms the real support address. `mm-t43.28` then confirms the email as final. `CatalogueRulesTests.isValidContactValue` already accepts either form, so neither test changes when the address does.
