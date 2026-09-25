# Deferred from the first TestFlight cut

Ash chose the first cut on 25 September 2026. A row here names scenarios that the first cut does not build. The spec keeps each requirement.

A first-cut build change's tasks list each such scenario as `deferred: <bead id>`, with the id of the bead that builds it. A row for part of a requirement names that bead. A row for a whole spec ("every requirement") belongs to the owning epic's own requirement beads.

When Ash archives an owning change, Ash moves its rows to that change's README. A row with several owners moves only with its last owner.

| Spec | Requirement | First-cut behaviour | Owning build change | Beads that build it |
| --- | --- | --- | --- | --- |
| data-and-privacy | every sync, account, restore and Erasure requirement, and "Every install has one device row" | Onboarding offers "This device only" as the one choice with "iCloud sync comes in a later version." | 4.1b sync | the requirement beads under mm-t41b |
| onboarding | "Screen 4: the iCloud choice" and "Restore before onboarding" | "This device only" is the one choice; no CloudKit read | 4.1b sync | mm-t14.10 and mm-t41b.8 |
| widgets-and-intents | every requirement except "Notification actions are entry points" and "The action queue" | Entry points are the app and the notification actions only | 2.5 widgets-and-intents | the requirement beads under mm-t25 |
| reminders | Worksheet review and check-in reminders | The app schedules neither type | 3.3 problem-solving, 3.6 staying-on-track | mm-t33.13, mm-t36.14 |
| reminders | Time Sensitive is opt-in | The switch is absent; the entitlement waits | 2.5 widgets-and-intents | mm-t25.1 |
| weekly-review | "Taking stock" and "The taking stock questionnaire and the module recommendation" | The review of week 6 is a plain review | 3.2b taking-stock, with 3.4 and 3.5 | the requirement beads under mm-t32b |
| urge-toolkit | every requirement | The Urge button is absent | 3.1 urge-toolkit | the requirement beads under mm-t31 |
| problem-solving | every requirement | Absent | 3.3 problem-solving | the requirement beads under mm-t33 |
| dieting-module | every requirement | Absent | 3.4 food-rules | the requirement beads under mm-t34 |
| body-image-module | every requirement | Absent | 3.5 body-image-module | the requirement beads under mm-t35 |
| staying-on-track | every requirement | Absent. "Start week 1 again" is a `programme` requirement and stays in the first cut | 3.6 staying-on-track | the requirement beads under mm-t36 |
| app-lock | A new entry before authentication: the widget, intent and control scenarios | The first cut builds the other scenarios | 2.5 widgets-and-intents | mm-t25.15 |
| content | Each stage has three to five cards | Only stage 1 and 2 cards in the bundle; the content version is 1 | 3.1 urge-toolkit, 3.2b taking-stock, 3.3 problem-solving, 3.4 food-rules, 3.5 body-image-module, 3.6 staying-on-track | mm-t31.15, mm-t32b.3, mm-t33.16, mm-t34.13, mm-t35.12, mm-t36.15 |
| content | Every bundled string family has ids | The families that later changes own are absent from the bundle | 2.5 widgets-and-intents, 3.1 urge-toolkit, 3.3 problem-solving, 3.4 food-rules, 3.6 staying-on-track | mm-t25.15, mm-t31.16, mm-t33.17, mm-t34.15, mm-t36.20 |
| content | One in-app link on a card | Only stage 1 and 2 cards in the bundle | 3.5 body-image-module | mm-t35.12 |
| content | Plain UK English | Only stage 1 and 2 cards in the bundle | 3.1 urge-toolkit | mm-t31.15 |
| content | The card catalogue | Only stage 1 and 2 cards in the bundle; the content version is 1 | 3.4 food-rules, 3.5 body-image-module | mm-t34.13, mm-t35.12 |
| data-and-privacy | CKRecord types and model names are neutral | The first cut builds the other scenarios | 4.1b sync | mm-t41b.11 |
| data-and-privacy | Card answers live in the record | The first cut builds the other scenarios | 4.1b sync | mm-t41b.11 |
| data-and-privacy | Delete from this device | The first cut builds the other scenarios | 4.1b sync | mm-t41b.11 |
| data-and-privacy | Delete-all: "Widget after Delete-all" | The first cut builds the other scenarios | 2.5 widgets-and-intents | mm-t25.15 |
| data-and-privacy | Delete-all: the erasure marker, the zone deletion and "Delete everything offline" | Local deletion only | 4.1b sync | mm-t41b.10 |
| data-and-privacy | File protection | The first cut builds the other scenarios | 2.5 widgets-and-intents | mm-t25.15 |
| data-and-privacy | Release gates and the App Store submission | Not part of the first TestFlight build | 4.3b app-store-submission | mm-t43.12 |
| data-and-privacy | The Diagnostics counts come from the device | The first cut builds the other scenarios | 4.1b sync | mm-t41b.11 |
| data-and-privacy | The app excludes the whole store directory from backups | The first cut builds the other scenarios | 4.1b sync | mm-t41b.11 |
| data-and-privacy | The app holds no analytics of its own | The first cut builds the other scenarios | 4.1b sync | mm-t41b.11 |
| data-and-privacy | The schema is frozen and grows by addition only | The first cut builds the other scenarios | 2.5 widgets-and-intents | mm-t25.15 |
| data-and-privacy | The store lives in the app's own container | The first cut builds the other scenarios | 2.5 widgets-and-intents | mm-t25.15 |
| data-and-privacy | What never leaves the device | The first cut builds the other scenarios | 2.5 widgets-and-intents, 4.1b sync | mm-t25.15, mm-t41b.11 |
| onboarding | Screen 4: permissions | The first cut builds the other scenarios | 2.5 widgets-and-intents | mm-t25.15 |
| programme | A gate change never closes a stage | Constants do not change during the first cohort | 3.6 staying-on-track | mm-t36.16 |
| programme | A stage opening shows one card | The first cut builds the other scenarios | 2.5 widgets-and-intents | mm-t25.15 |
| programme | Reading ahead is never blocked | The first cut builds the other scenarios | 3.3 problem-solving | mm-t33.16 |
| programme | The card's answer is kept in the record | The first cut builds the other scenarios | 4.1b sync | mm-t41b.11 |
| programme | The constants live in one value | The first cut builds the other scenarios | 3.1 urge-toolkit | mm-t31.17 |
| programme | The seven stages and their tools | Rows show their opening rule; no tool opens beyond stage 2 | 3.1 urge-toolkit, 3.2b taking-stock, 3.3 problem-solving, 3.4 food-rules, 3.5 body-image-module, 3.6 staying-on-track | mm-t31.15, mm-t32b.3, mm-t33.16, mm-t34.13, mm-t35.12, mm-t36.15 |
| record | The Today stack | The first cut builds the other scenarios | 3.1 urge-toolkit, 3.3 problem-solving | mm-t31.17, mm-t33.16 |
| regular-eating-plan | A missed planned meal gets one prompt | Two forms only: "Skipped" and "Add it" | 3.3 problem-solving | mm-t33.14 |
| regular-eating-plan | Weekday and weekend templates | The first cut builds the other scenarios | 4.1b sync | mm-t41b.11 |
| reminders | Discreet text by default | The first cut builds the other scenarios | 3.6 staying-on-track | mm-t36.18 |
| reminders | Reminder types and their switches | The first cut builds the other scenarios | 2.5 widgets-and-intents, 3.3 problem-solving | mm-t25.15, mm-t33.15 |
| reminders | Scheduling is local, lazy and bounded | The app registers no background refresh task | 3.6 staying-on-track | mm-t36.17 |
| reminders | The cap of two other reminders a day | The first cut builds the other scenarios | 3.3 problem-solving | mm-t33.15 |
| reminders | The scheduler pipeline | The first cut builds the other scenarios | 3.6 staying-on-track | mm-t36.21 |
| reminders | The weekly review reminder | The first cut builds the other scenarios | 3.6 staying-on-track | mm-t36.15 |
| safeguarding | Re-screening at a restart | The restart control re-screens; no check-in exists | 3.6 staying-on-track | mm-t36.19 |
| settings | The Privacy group | Absent until the owning change adds each control | 2.5 widgets-and-intents, 4.1b sync | mm-t25.16, mm-t41b.9 |
| settings | The Record group | Absent until the owning change adds each control | 3.3 problem-solving, 3.4 food-rules, 3.5 body-image-module | mm-t33.15, mm-t34.14, mm-t35.13 |
| settings | The Reminders group | Absent until the owning change adds each control | 2.5 widgets-and-intents, 3.3 problem-solving, 3.6 staying-on-track | mm-t25.16, mm-t33.15, mm-t36.18 |
| weekly-review | Accessibility of the review | The first cut builds the other scenarios | 3.2b taking-stock | mm-t32b.5 |
| weekly-review | The summary built from the record | The first cut builds the other scenarios | 3.6 staying-on-track | mm-t36.21 |
| weekly-review | When a weekly review is due | The first cut builds the other scenarios | 3.6 staying-on-track | mm-t36.15 |
| weigh-in | The weigh-in day | The first cut builds the other scenarios | 4.1b sync | mm-t41b.11 |
| weigh-in | The weigh-in stays off Today, widgets and notifications | The first cut builds the other scenarios | 2.5 widgets-and-intents | mm-t25.15 |
| widgets-and-intents | The action queue | The first cut builds the other scenarios | 2.5 widgets-and-intents | mm-t25.15 |
