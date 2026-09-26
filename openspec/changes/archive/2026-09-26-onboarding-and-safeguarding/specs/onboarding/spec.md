# onboarding

## ADDED Requirements

### Requirement: Four screens, once, in order

The app MUST show onboarding the first time the app opens after install. From the sync change, the app checks iCloud for a record before screen 1. The "Restore before onboarding" requirement states that. Onboarding MUST have exactly four screens in this order: "What this is and isn't", "A few questions first", "Your start", "Permissions". The app MUST NOT show onboarding again after the person completes it.

After Delete-all the app MUST show onboarding again (`data-and-privacy` owns Delete-all). The app MUST NOT ask the screening questions again after onboarding. The exceptions are the self-harm item at every weekly review and check-in, and the restart re-screen that `safeguarding` defines. Every onboarding screen MUST show Get support in the navigation bar (`safeguarding` owns the button). The four screens MUST NOT need a network connection.

The four screens together MUST ask the person to type at most five numbers. Every other input MUST be one tap. A reviewer walks the four screens with every default on the simulator. The target for that walk is under three minutes.

Every control on the four screens MUST have a VoiceOver label. Every text on the four screens MUST scale with Dynamic Type. The team MUST declare an accessibility label in App Store Connect only after a device check of that label. The check MUST have a dated screenshot. `safeguarding` states that gate.

#### Scenario: First launch
- **WHEN** the app opens for the first time after install and iCloud holds no record
- **THEN** the app shows "What this is and isn't" and no other screen, and writes the install moment to Local.store

#### Scenario: Second launch
- **WHEN** the person completed onboarding on Thursday and opens the app on Friday
- **THEN** the app shows Today, as `programme` defines the home screen, and no onboarding screen

#### Scenario: No network
- **WHEN** the device is in airplane mode
- **THEN** the person can pass all four screens and the store keeps the commitment

#### Scenario: Typed numbers
- **WHEN** a reviewer counts every number field on the four screens with "ft in" and "st lb" chosen
- **THEN** the count is five: age, feet, inches, stone and pounds

#### Scenario: Accessibility labels
- **WHEN** the team declares the VoiceOver accessibility label in App Store Connect
- **THEN** the change's README holds a dated screenshot of the VoiceOver check on the four screens

### Requirement: No account

The app MUST NOT ask for a name, an email address, a phone number or a password. The app MUST NOT offer Sign in with Apple or any other sign-in. The app MUST NOT need an iCloud account to complete onboarding. The record and the programme MUST work with no account of any kind.

#### Scenario: Fields on the four screens
- **WHEN** a reviewer lists every input on the four screens
- **THEN** no input asks for a name, an email address, a phone number, a password or a sign-in

#### Scenario: Device signed out of iCloud
- **WHEN** the device has no iCloud account and the person chooses "This device only" and completes onboarding
- **THEN** the app shows Today and the person can save an entry

### Requirement: Screen 1: what this is and isn't

The screen MUST show these lines, in this order, and no other claim about the programme:

- "Midmorning is a 12-week self-help programme for people who binge eat. It uses ideas from CBT."
- "It is not a diet, and it is not for weight loss."
- "It is not therapy, and it does not replace your GP or anyone treating you."
- "Some people make themselves sick, use laxatives, or miss insulin or another medicine after eating. If that happens more than about twice a week, this programme isn't the right tool on its own. Talk to your GP first."
- "If you have had anorexia or another restrictive eating problem in the past, talk to your GP before you start. The weekly weigh-in may not be right for you."
- "No person and no AI reads what you write. The app counts your starred entries, times and places to build your weekly review, on this device only."
- "If you need a person, Get support is on every screen."

The screen MUST show one control, "Continue", after the last line. The app MUST NOT advance the screen on a timer or on a swipe. Only a tap on "Continue" advances the screen. The app MUST NOT preselect "Continue". The app MUST NOT animate "Continue".

The "Continue" control MUST sit below the last line at every text size. The app MUST NOT ask a question about vomiting, laxatives or missed medicine on this screen or any other. `safeguarding` states that rule.

#### Scenario: The screen opens
- **WHEN** "What this is and isn't" opens
- **THEN** it shows the seven lines, "Continue" and Get support, and nothing else about the programme

#### Scenario: Nothing happens without a tap
- **WHEN** the person reads the screen for 60 seconds and taps nothing
- **THEN** the app still shows "What this is and isn't"

#### Scenario: Largest text size
- **WHEN** the person uses the largest accessibility text size
- **THEN** "Continue" is below the last line and the person scrolls to reach it

#### Scenario: Continue
- **WHEN** the person taps "Continue"
- **THEN** the app shows "A few questions first"

### Requirement: Screen 2: the screening questions

The screen MUST ask exactly six questions, in this order:

- "How old are you?" with a number field for years.
- "Your height" with a number field and a unit choice "cm" or "ft in". With "ft in" the screen shows two number fields.
- "Your weight" with a number field and a unit choice "kg" or "st lb". With "st lb" the screen shows two number fields.
- "Are you getting help from a clinic or a therapist for your eating at the moment?" with "No", "Yes, and they are happy for me to use this" and "Yes".
- The pregnancy question: "We ask everyone the same questions. Pregnancy changes what eating needs to look like, so: are you pregnant at the moment?" with "No", "Yes" and "Doesn't apply to me".
- "Over the last two weeks, have you had thoughts that you'd be better off dead, or of hurting yourself?" with "No", "Yes" and "I'd rather not say".

When the person answers "Yes" to the last question, the screen MUST show a second question under it. That question is "Have you thought about how you would do it?" with "No" and "Yes". `safeguarding` owns both questions' wording and flags the second for the clinical reviewer. The app MUST hide the second question when the person changes the first answer.

Above the height and weight fields the screen MUST show: "We ask for your height and weight to check this programme is safe for you. The app never shows them again and never sets a goal from them."

The "Continue" control MUST stay active. When the person taps "Continue" with a question unanswered, the app MUST move VoiceOver focus to the first unanswered question. The app MUST show "Please answer this one." under that question. The app MUST NOT advance.

When every shown question has an answer and the person taps "Continue", the app MUST pass the answers to `safeguarding`. `safeguarding` decides whether onboarding continues. The number fields MUST use the numeric keypad. The app MUST NOT ask about vomiting, laxatives, missed medicine or any other compensation.

#### Scenario: The questions
- **WHEN** a reviewer lists every question on "A few questions first"
- **THEN** the list is the six questions above and the second self-harm question, and none asks about vomiting or laxatives

#### Scenario: One answer missing
- **WHEN** the person answers five questions, leaves the pregnancy question unanswered and taps "Continue"
- **THEN** the screen stays, VoiceOver focus moves to the pregnancy question, and "Please answer this one." shows under it

#### Scenario: Screening continues
- **WHEN** the person is 34, 170 cm, 60 kg, answers "No", "No" and "No", and taps "Continue"
- **THEN** the app shows "Your start"

#### Scenario: Thoughts without a method
- **WHEN** the person answers "Yes" to the first self-harm question and "No" to "Have you thought about how you would do it?"
- **THEN** the screen shows the support line that `safeguarding` defines, with Samaritans first, and "Continue" stays active

#### Scenario: Screening excludes
- **WHEN** the person is 17 and taps "Continue" with every question answered
- **THEN** the app shows the exclusion page that `safeguarding` defines

### Requirement: The one-time BMI

The app MUST convert the height to metres and the weight to kilograms. One foot is 30.48 cm. One inch is 2.54 cm. One stone is 6.35029 kg. One pound is 0.453592 kg. The app MUST compute the BMI as the weight in kilograms divided by the height in metres squared.

The app MUST pass the unrounded BMI to `safeguarding`. The app MUST NOT show the BMI on any screen at any time.

The limits are the named constants MIN_HEIGHT_CM = 100, MAX_HEIGHT_CM = 250 and MIN_WEIGHT_KG = 30 in `ProgrammeConstants`. The height field MUST accept MIN_HEIGHT_CM to MAX_HEIGHT_CM, or the same range in feet and inches. The weight field MUST accept MIN_WEIGHT_KG and above, or the same in stone and pounds, with no upper bound. When the height is outside its range, the field MUST show "Enter a height between %1$lld and %2$lld cm."

The app fills it from the two height constants, so it reads "Enter a height between 100 and 250 cm." When the weight is below MIN_WEIGHT_KG, the field MUST show "Enter a weight of %lld kg or more." The app fills it from that constant, so it reads "Enter a weight of 30 kg or more." With "ft in" or "st lb" chosen, the message MUST give the same limit in that unit.

"Continue" MUST stay active. When the person taps "Continue" with a value outside its range, the app MUST move VoiceOver focus to that field. The app MUST NOT advance.

#### Scenario: Metric input
- **WHEN** the person enters 170 cm and 60 kg
- **THEN** the app computes a BMI of 20.76 and shows it nowhere

#### Scenario: Imperial input
- **WHEN** the person enters 5 ft 7 in and 8 st 7 lb
- **THEN** the app converts to 170.18 cm and 53.98 kg and computes a BMI of 18.64

#### Scenario: Weight below the range
- **WHEN** the person enters 20 kg and taps "Continue"
- **THEN** the weight field shows "Enter a weight of 30 kg or more.", VoiceOver focus moves to the field, and the screen stays

#### Scenario: Height outside the range
- **WHEN** the person enters 90 cm and taps "Continue"
- **THEN** the height field shows "Enter a height between 100 and 250 cm." and the screen stays

#### Scenario: No upper weight bound
- **WHEN** the person enters 170 cm and 320 kg and taps "Continue"
- **THEN** the weight field shows no message and the app passes a BMI of 110.73 to `safeguarding`

#### Scenario: BMI on no screen
- **WHEN** a reviewer walks every screen of the app after onboarding
- **THEN** no screen shows a BMI, the height or the onboarding weight

### Requirement: Screen 3: the start day

The screen MUST ask "When do you want to start?" with two choices, "Today" and "Tomorrow". The choices MUST read "Today, %@" and "Tomorrow, %@", with the date from the en_GB formatter, for example "Today, Thursday 24 September". "Today" MUST be the current record day. "Tomorrow" MUST be the record day after it. The current record day comes from the device zone and the day start in force, as `record` defines. At onboarding the day start is the default, 04:00, that `settings` defines as "Day starts at".

The app MUST preselect "Today". The store MUST keep the chosen start day as a calendar date. It lives in one Settings row (key, value, changedAt), as `data-and-privacy` defines. When two devices hold a start day, the app keeps the later changedAt, so a restart's write replaces the earlier start day. `programme` counts week 1 from the start day.

#### Scenario: Default
- **WHEN** "Your start" opens at 14:00 on Thursday 24 September
- **THEN** "Today, Thursday 24 September" is selected and the screen offers "Tomorrow, Friday 25 September"

#### Scenario: Tomorrow
- **WHEN** the person chooses "Tomorrow" on Thursday 24 September and completes onboarding
- **THEN** the store keeps Friday 25 September as the start day

#### Scenario: A later start day wins
- **WHEN** one device holds the start day Thursday 24 September written at 14:00 and a restart on another device writes Monday 5 October at 09:00 the next week, and they sync
- **THEN** every device reads Monday 5 October as the start day

#### Scenario: After midnight
- **WHEN** "Your start" opens at 01:00 on Friday 25 September with the default day start
- **THEN** "Today" reads "Today, Thursday 24 September" and "Tomorrow" reads "Tomorrow, Friday 25 September"

### Requirement: Screen 3: weigh-in day and quiet hours

The screen MUST show "Weigh-in day" with the seven weekdays as one-tap choices. Under the weekdays the screen MUST show one more choice, "I won't be weighing". The app MUST NOT preselect a weekday or "I won't be weighing". Under the choices the screen MUST show: "Once a week, on this day, the app asks for your weight and shows the trend. There is no goal and no target." The screen MUST show a "Quiet hours" switch with a start time and an end time. The switch MUST default to on.

The times MUST default to 22:00 and 07:00. The "Continue" control MUST stay active. When the person taps "Continue" with no choice under "Weigh-in day", the app MUST move VoiceOver focus to "Weigh-in day". The app MUST then show "Please answer this one." under the choices. The app MUST NOT advance.

The store MUST keep the weigh-in day or the "I won't be weighing" choice. The store MUST keep the quiet hours switch and the two times. The choice syncs as the weigh-in day does. `data-and-privacy` lists it. `reminders` honours quiet hours. `weigh-in` uses the weigh-in day.

With "I won't be weighing" chosen, the scheduler MUST NOT schedule a weigh-in day reminder. Every weekly review and every check-in MUST leave the weigh-in part out. The weigh-in screen MUST stay open. The weigh-in screen MUST show "Choose a weigh-in day". The person can pick a day there later.

`weigh-in`, `reminders`, `weekly-review` and `staying-on-track` state those rules. `safeguarding` runs the underweight check only when a weigh-in exists.

#### Scenario: No weigh-in day chosen
- **WHEN** the person taps "Continue" without tapping a weekday or "I won't be weighing"
- **THEN** the screen stays, VoiceOver focus moves to "Weigh-in day", and "Please answer this one." shows under the choices

#### Scenario: Weigh-in day chosen
- **WHEN** the person taps "Sunday" and completes onboarding
- **THEN** the store keeps Sunday as the weigh-in day

#### Scenario: Default quiet hours
- **WHEN** the person changes nothing under "Quiet hours" and completes onboarding
- **THEN** the store keeps quiet hours on, from 22:00 to 07:00

#### Scenario: Quiet hours changed
- **WHEN** the person sets 23:30 and 06:00 and completes onboarding
- **THEN** the store keeps quiet hours on, from 23:30 to 06:00

#### Scenario: Quiet hours off
- **WHEN** the person turns the "Quiet hours" switch off and completes onboarding
- **THEN** the store keeps quiet hours off

### Requirement: Screen 3: the record in three sentences

The screen MUST explain the record in exactly these three sentences: "Each time you eat or drink, you add an entry: the time and a few words on what it was." "\"Toast and tea\" is a complete entry." "There is one star, \"felt like a binge\", and only you decide when it applies." Under the sentences the screen MUST show one example entry as a Today row. Its time is "13:05" and its What is "Toast and tea". The example row MUST use the row style that `record` defines for Today. The example MUST NOT be starred. The app MUST NOT save the example as an entry.

Under the example row the screen MUST show one line about the record day. `settings` defines the "Day starts at" setting. The line MUST be "A day runs from %1$@ to %2$@.". The en_GB formatter fills it with the chosen time and the minute before it.

With 04:00 the line reads "A day runs from 04:00 to 03:59.". With 05:00 the line reads "A day runs from 05:00 to 04:59.". At onboarding the setting holds its default, 04:00, so the line reads "A day runs from 04:00 to 03:59.".

#### Scenario: The three sentences
- **WHEN** "Your start" opens
- **THEN** it shows the three sentences, the example row "13:05" "Toast and tea" and "A day runs from 04:00 to 03:59."

#### Scenario: The day line follows the setting
- **WHEN** "Day starts at" is 05:00 and "Your start" opens
- **THEN** the line reads "A day runs from 05:00 to 04:59."

#### Scenario: VoiceOver on the example
- **WHEN** VoiceOver reads the example row
- **THEN** it reads "13:05, Toast and tea"

#### Scenario: The example is not an entry
- **WHEN** the person completes onboarding and opens Today
- **THEN** Today shows no entry for 13:05 "Toast and tea"

### Requirement: Screen 4: your record

The screen MUST show a section "Your record" before the permissions sections. The section MUST show: "Your record, plan and weigh-ins are private and sensitive." In the first cut the section MUST show one control, "This device only", as chosen. Under it the section MUST show: "iCloud sync comes in a later version." The section MUST NOT show an iCloud choice, a switch or any other control.

The app MUST keep the choice as the sync choice in Local.store, as off. `data-and-privacy` owns sync. Sync MUST stay off in the first cut. The section MUST NOT need an iCloud account. The "Screen 4: the iCloud choice" requirement replaces this section from the sync change.

#### Scenario: The section opens
- **WHEN** "Permissions" opens in the first cut
- **THEN** "Your record" shows the sentence, "This device only" as chosen, "iCloud sync comes in a later version." and no other control

#### Scenario: This device only
- **WHEN** the person taps "Start"
- **THEN** Local.store holds the sync choice as off and the store syncs nothing

#### Scenario: Signed out of iCloud
- **WHEN** the device has no iCloud account and "Permissions" opens
- **THEN** "Your record" shows the same section, with nothing about signing in

### Requirement: Screen 4: permissions

After "Your record" the screen MUST show three sections in this order: notifications, app lock, widget. The notifications section MUST show: "Midmorning sends reminders for your plan and your reviews. You choose which ones and when in Settings. Each reminder shows the app name and a time, nothing more." It MUST show one control, "Allow notifications", that opens the system permission request. The app lock section MUST show the app lock switch with the label `app-lock` defines, on by default.

Under the switch the section MUST show the lock sentence for the device's `Biometry` value. The label function that `app-lock` defines returns it. With `faceID` the sentence is "Midmorning asks for Face ID or your passcode when it opens." With `touchID` it is "Midmorning asks for Touch ID or your passcode when it opens." With `passcodeOnly` it is "Midmorning asks for your passcode when it opens." `app-lock` owns the lock's behaviour.

The widget section MUST show: "Add the Lock Screen widget to record in one tap." with a control "Show me how". "Show me how" MUST open a short sheet with the system steps to add a Lock Screen widget. The screen MUST show one control, "Start", that completes onboarding. The app MUST NOT make "Start" depend on any permission.

When the person denies notifications, the app MUST complete onboarding with every reminder switch on. The scheduler MUST schedule nothing while the notification permission is denied. `reminders` owns the switches and the scheduler.

#### Scenario: Notifications denied
- **WHEN** the person taps "Allow notifications", denies the system permission request and taps "Start"
- **THEN** onboarding completes, every reminder switch is on and the scheduler has no pending request

#### Scenario: Notifications not asked
- **WHEN** the person taps "Start" without tapping "Allow notifications"
- **THEN** onboarding completes, every reminder switch is on and the scheduler has no pending request

#### Scenario: App lock default
- **WHEN** the person changes nothing in the app lock section and taps "Start"
- **THEN** app lock is on

#### Scenario: App lock off
- **WHEN** the person turns the app lock switch off and taps "Start"
- **THEN** app lock is off

#### Scenario: Lock sentence on a Touch ID device
- **WHEN** "Permissions" opens on a device with Touch ID enrolled
- **THEN** the app lock section shows "Lock with Touch ID" and "Midmorning asks for Touch ID or your passcode when it opens."

### Requirement: What onboarding keeps and what it never keeps

From the screening the store MUST hold exactly four values. They are the height in centimetres, the onboarding BMI, the caution flag and `askedAt`. `askedAt` holds the moment of the screening, as `safeguarding` states. `safeguarding` sets the caution flag.

From the commitment the store MUST hold the start day and the quiet hours. It MUST hold the weigh-in day or the "I won't be weighing" choice. Local.store MUST hold the install moment, the completion flag and the sync choice as device state. `data-and-privacy` defines Local.store. From the sync change, after "Get it back" the first import supplies every synced value. The app MUST NOT write one itself.

The store MUST NOT hold the age or the weight that the person typed at onboarding. The store MUST NOT hold the pregnancy answer, the treatment answer or a self-harm answer. The store MUST NOT hold a screening date or moment other than `askedAt`.

The Profile row MUST NOT carry a creation moment. It carries `changedAt` per key and `askedAt`, and nothing else about time. `data-and-privacy` names the CKRecord system dates as the dates the store never reads. The app MUST NOT save the onboarding weight as a weigh-in.

The app MUST NOT show the height, the onboarding BMI, the caution flag or `askedAt` after screen 2. The app MUST read these four values only for the underweight check and the restart re-screen. `safeguarding` defines both. The app MUST NOT write any screening answer to the system log or an error. The four values sync with the store under the rules `data-and-privacy` defines.

#### Scenario: The store after onboarding
- **WHEN** the person completes onboarding with a start day, Sunday, default quiet hours, 170 cm and 60 kg
- **THEN** the store holds the start day, Sunday, 22:00 to 07:00, 170, 20.76, the caution flag off and `askedAt` as the screening moment, and no age, weight, other date, creation moment or yes-or-no answer

#### Scenario: First weigh-in day
- **WHEN** the person opens the weigh-in screen on the first weigh-in day
- **THEN** the screen shows no previous weight and no rolling average from onboarding

### Requirement: Not weight loss, three times

Onboarding MUST say that the programme is not for weight loss on three screens, in three different sentences. Screen 1 says "It is not a diet, and it is not for weight loss." Screen 2 says "The app never shows them again and never sets a goal from them." Screen 3 says "There is no goal and no target." The app MUST NOT show a weight, a target or a goal anywhere in onboarding except the weight field itself.

#### Scenario: Three sentences on three screens
- **WHEN** a reviewer reads all four screens
- **THEN** the reviewer finds the three sentences above on screens 1, 2 and 3

#### Scenario: No goal
- **WHEN** a reviewer lists every string in onboarding
- **THEN** no string offers a goal weight, a target or a change in weight

### Requirement: Finish

"Start" MUST stay active, with one exception. After "Get it back", "Start" stays disabled while the first import runs, as "Restore before onboarding" states. In the first cut "Your record" has one choice, so the app MUST complete onboarding at once on "Start". From the sync change, "Your record" has two choices. When the person taps "Start" with no choice, the app MUST move VoiceOver focus to "Your record". The app MUST then show "Please answer this one." under the two controls. The app MUST NOT complete onboarding.

When the person taps "Start" with the choice made, the app MUST set the completion flag in Local.store. The app MUST then show Today, as `programme` defines the home screen. The app MUST make the new-entry screen reachable at once, whichever start day the person chose.

When the person leaves the app before "Start", the app MUST show onboarding from screen 1 on the next launch. The app MUST NOT keep answers from an unfinished onboarding.

#### Scenario: Start today
- **WHEN** the person chose "Today" and taps "Start"
- **THEN** the app shows Today and one tap opens the new-entry screen

#### Scenario: Start tomorrow
- **WHEN** the person chose "Tomorrow" and taps "Start"
- **THEN** the app shows Today and one tap opens the new-entry screen

#### Scenario: Left on screen 3
- **WHEN** the person closes the app on "Your start" and opens it again
- **THEN** the app shows "What this is and isn't" with every field empty
