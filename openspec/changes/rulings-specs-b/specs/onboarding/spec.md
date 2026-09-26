# onboarding

## MODIFIED Requirements

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

The "Continue" control MUST stay active. When the person taps "Continue" with a question unanswered, the app MUST move VoiceOver focus to the first unanswered question. The app MUST show "Please answer this one." under that question. The app MUST NOT advance. The message MUST use the primary or the secondary text colour, never red, as `product-rules` requires for validation text. The app MUST post the message as a VoiceOver announcement. This also applies under the self-harm question.

When every shown question has an answer and the person taps "Continue", the app MUST pass the answers to `safeguarding`. `safeguarding` decides whether onboarding continues. The number fields MUST use the numeric keypad. The app MUST NOT ask about vomiting, laxatives, missed medicine or any other compensation.

#### Scenario: The questions
- **WHEN** a reviewer lists every question on "A few questions first"
- **THEN** the list is the six questions above and the second self-harm question, and none asks about vomiting or laxatives

#### Scenario: One answer missing
- **WHEN** the person answers five questions, leaves the pregnancy question unanswered and taps "Continue"
- **THEN** the screen stays, VoiceOver focus moves to the pregnancy question, and "Please answer this one." shows under it

#### Scenario: The self-harm question unanswered
- **WHEN** the person answers every other question, leaves the self-harm question unanswered and taps "Continue"
- **THEN** the screen stays, VoiceOver focus moves to the self-harm question, "Please answer this one." shows under it in the primary or the secondary text colour and not in red, and VoiceOver announces "Please answer this one."

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

The limits are the named constants MIN_HEIGHT_CM = 100, MAX_HEIGHT_CM = 250 and MIN_WEIGHT_KG = 30 in `ProgrammeConstants`. The height field MUST accept MIN_HEIGHT_CM to MAX_HEIGHT_CM, or the same range in feet and inches. The weight field MUST accept MIN_WEIGHT_KG and above, or the same in stone and pounds, with no upper bound. When the height is outside its range, the field MUST show "Enter a height between %1$@ and %2$@." The app fills the two placeholders with the lower and the upper limit, in the chosen unit. When the weight is below MIN_WEIGHT_KG, the field MUST show "Enter a weight of %@ or more." The app fills the placeholder with the limit, in the chosen unit.

Each limit MUST come from strings with one count each, as the catalogue rules in `content` require. These strings are "%lld", "%lld cm" and "%lld kg", and for the imperial units "%lld ft" with "%lld in", and "%lld st" with "%lld lb". The app joins the two parts of an imperial limit with one space. With "cm" chosen, the app fills the lower height limit from "%lld" and the upper height limit from "%lld cm". So the height message reads "Enter a height between 100 and 250 cm." With "ft in" chosen, it reads "Enter a height between 3 ft 4 in and 8 ft 2 in." With "kg" chosen, the weight message reads "Enter a weight of 30 kg or more." With "st lb" chosen, it reads "Enter a weight of 4 st 11 lb or more."

The app MUST compute each imperial limit from its cm or kg constant, with the conversions above. The app MUST NOT hold an imperial limit as a constant of its own. The app MUST round each imperial limit inward, to a whole inch or a whole pound. It rounds the lower height limit and the weight limit up, and it rounds the upper height limit down. So the field accepts every value that the message shows. The app then splits the inches into feet and inches, and the pounds into stone and pounds. Ash ruled this on 26 September 2026 (r13-11).

Each message MUST use the primary or the secondary text colour, never red, as `product-rules` requires for validation text. The app MUST post the message as a VoiceOver announcement.

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

#### Scenario: Height outside the range in ft in
- **WHEN** the person chooses "ft in", enters 3 ft 2 in and taps "Continue"
- **THEN** the height field shows "Enter a height between 3 ft 4 in and 8 ft 2 in." and the screen stays

#### Scenario: Weight below the range in st lb
- **WHEN** the person chooses "st lb", enters 4 st 5 lb and taps "Continue"
- **THEN** the weight field shows "Enter a weight of 4 st 11 lb or more." and the screen stays

#### Scenario: The shown limits are accepted
- **WHEN** the person enters 3 ft 4 in and 4 st 11 lb and taps "Continue"
- **THEN** neither field shows a message, because 3 ft 4 in is 101.6 cm and 4 st 11 lb is 30.39 kg

#### Scenario: A limit message in a neutral colour
- **WHEN** the person enters 20 kg and taps "Continue"
- **THEN** "Enter a weight of 30 kg or more." shows in the primary or the secondary text colour and not in red, and VoiceOver announces it

#### Scenario: No upper weight bound
- **WHEN** the person enters 170 cm and 320 kg and taps "Continue"
- **THEN** the weight field shows no message and the app passes a BMI of 110.73 to `safeguarding`

#### Scenario: BMI on no screen
- **WHEN** a reviewer walks every screen of the app after onboarding
- **THEN** no screen shows a BMI, the height or the onboarding weight
