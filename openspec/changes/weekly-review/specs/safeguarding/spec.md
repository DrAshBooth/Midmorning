# safeguarding

## ADDED Requirements

### Requirement: Re-screening at every weekly review and check-in

Every weekly review and every check-in MUST ask the self-harm item with both steps. `weekly-review` and `staying-on-track` place the item. "Done" MUST be available with any answer, including no answer. When the person answers "Yes" and then "No", the app MUST show the support line under the item. Under the line the app MUST show the support sheet's items inline, with Samaritans first. The review MUST continue.

When the person answers "Yes" and then "Yes", the app MUST show the not-right-now page at once. The page shows the self-harm reason.

When the person answers "No" or "I'd rather not say", the review MUST continue with no other response. "Done" MUST close the review or the check-in with the item answered or not. The app MUST NOT move focus to the item. The app MUST NOT show a count of questions left. When the person taps "Done" or leaves without an answer, the store MUST keep `selfHarmAnswered: false` for that review. The next review MUST ask again.

With any answer the store MUST keep `selfHarmAnswered: true` for that review. The store MUST NOT keep the answer. The app MUST NOT show a count of answers or a history of them. The app MUST NOT cancel or pause a reminder because of any answer.

#### Scenario: Thoughts with a method at review
- **WHEN** the person answers "Yes" and then "Yes" at the week 3 review
- **THEN** the app shows the not-right-now page with the self-harm reason and the scheduler keeps every reminder

#### Scenario: Thoughts without a method at review
- **WHEN** the person answers "Yes" and then "No" at the week 3 review
- **THEN** the review shows "That deserves a person. Samaritans are there any time, on 116 123." with Samaritans first, and continues

#### Scenario: No at review
- **WHEN** the person answers "No" at the week 3 review
- **THEN** the review continues with no message

#### Scenario: Review left open
- **WHEN** the person closes the week 3 review before the item and opens the week 4 review
- **THEN** the week 4 review asks the item

#### Scenario: Done without an answer
- **WHEN** the person taps "Done" at the week 3 review with the self-harm item unanswered
- **THEN** the review closes, the row holds `selfHarmAnswered: false`, and the week 4 review asks the item

#### Scenario: The store after a review
- **WHEN** a reviewer inspects the week 3 review row after any answer
- **THEN** the row holds `selfHarmAnswered: true` and no answer

### Requirement: The deterioration rule

`weekly-review` freezes each week's starred count into its Review row at review time. At each weekly review the app MUST read the frozen counts of the last four reviews, the current one last. The rule fires when three conditions hold:

- each of the last three counts exceeds the count before it
- the latest count is at least 4
- the latest count is at least twice the first of the four

DETERIORATION_WEEKS = 3 is a named constant in `ProgrammeConstants`.

When the rule fires, the app MUST show the GP suggestion page with the reason "Your starred entries have gone up for %lld weeks in a row.", filled from DETERIORATION_WEEKS. It reads "Your starred entries have gone up for three weeks in a row." When fewer than four reviews exist, the app MUST NOT apply the rule. The app MUST show the page from the rule at most once per weekly review.

Every weekly review MUST offer the button "I'm getting worse". When the person taps it, the app MUST show the GP suggestion page at once. The page shows the reason "You said things are getting worse." The app MUST show the page at each tap, also after the rule showed it in that review.

#### Scenario: Three rising weeks
- **WHEN** the frozen counts for weeks 2 to 5 are 3, 4, 5 and 6 and the week 5 review opens
- **THEN** the app shows the GP suggestion page with "Your starred entries have gone up for three weeks in a row."

#### Scenario: Two rising weeks
- **WHEN** the frozen counts for weeks 2 to 5 are 4, 4, 5 and 6 and the week 5 review opens
- **THEN** the app shows no GP suggestion page

#### Scenario: Rising from a low count
- **WHEN** the frozen counts for weeks 2 to 5 are 0, 1, 2 and 3 and the week 5 review opens
- **THEN** the app shows no GP suggestion page, because the latest count is below 4

#### Scenario: Rising but not doubled
- **WHEN** the frozen counts for weeks 2 to 5 are 5, 6, 7 and 8 and the week 5 review opens
- **THEN** the app shows no GP suggestion page, because 8 is less than twice 5

#### Scenario: I'm getting worse
- **WHEN** the person taps "I'm getting worse" at the week 3 review
- **THEN** the app shows the GP suggestion page with "You said things are getting worse."

#### Scenario: Getting worse after the rule fired
- **WHEN** the deterioration rule showed the GP suggestion page at the week 5 review, the person tapped "Done", and the person then taps "I'm getting worse"
- **THEN** the app shows the GP suggestion page again with "You said things are getting worse." as its one reason

## MODIFIED Requirements

### Requirement: No question about vomiting or laxatives

The app MUST NOT ask about vomiting, laxatives, missed medicine or any other compensation at onboarding. The app MUST NOT ask about them at a weekly review, a check-in, taking stock or any other screen. The store MUST have no field for compensation. The app MUST NOT exclude a person for compensation. Ash ruled this on 24 September 2026 and confirmed it on 25 September 2026.

In place of a question, the app MUST tell the person in two places. Onboarding screen 1 and the "Talk to your GP" item in Get support MUST both show: "Some people make themselves sick, use laxatives, or miss insulin or another medicine after eating. If that happens more than about twice a week, this programme isn't the right tool on its own. Talk to your GP first." `content` bundles a stage-2 card, "Making up for it doesn't work". The team revisits this decision before beta. The proposal says so.

#### Scenario: Screening
- **WHEN** a reviewer lists every question at onboarding
- **THEN** none names vomiting, laxatives or compensation

#### Scenario: Weekly review
- **WHEN** a reviewer lists every question at a weekly review
- **THEN** none names vomiting, laxatives or compensation

#### Scenario: The store
- **WHEN** a reviewer lists every field in the store's model
- **THEN** no field holds compensation

#### Scenario: The sentence in Get support
- **WHEN** the person opens the support sheet and reads "Talk to your GP"
- **THEN** the sentence about making yourself sick, using laxatives or missing medicine is above the GP paragraph
