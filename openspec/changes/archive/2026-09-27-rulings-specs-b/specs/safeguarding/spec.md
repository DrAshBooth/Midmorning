# safeguarding

## MODIFIED Requirements

### Requirement: The GP suggestion page

The page MUST show the heading "It might help to see your GP". Under it the page MUST show one reason with its line, or two when Rules B and C both apply. The reasons are:

- Falling weight: "Your weight has come down since you started." with "Your plan stays on. It's worth a word with your GP."
- Quick change: "Your weight has changed quickly over the last four weeks." with "Your plan stays on. It's worth a word with your GP."
- Deterioration: "Your starred entries have gone up each week lately." with "That's worth talking through with your GP. Your plan stays on." This reason holds no number. Ash ruled this on 26 September 2026 (r13-09).
- Getting worse: "You said things are getting worse." with "That's worth talking through with your GP. Your plan stays on."

A reason's line MUST NOT give a cause for the weight change. The page suggests the GP and says nothing about why.

Under the reason the page MUST show: "This is not a diagnosis, and nothing here is closed to you." The page MUST then show "Talk to your GP" with the GP paragraph and its "Copy" control. The page MUST show "Export your record to take with you" as a control that opens `export`. The page MUST show Get support and one control, "Done". "Done" MUST return the app to the screen beneath.

The app MUST NOT pause a reminder, close a tool or hide the record because of this page. The app MUST NOT write to `remindersPausedAt` from this page. The page MUST NOT show a number, a weight value or a count.

The app MUST show the page from the deterioration rule at most once per weekly review. The app MUST show the page at each tap on "I'm getting worse", also after the rule showed it. The app MUST NOT show the page again until a rule fires again or the person taps "I'm getting worse".

#### Scenario: From the weigh-in
- **WHEN** the page opens from Rule C
- **THEN** it shows the heading, the quick change reason and its line, the diagnosis line, the GP paragraph, the export control, Get support and "Done"

#### Scenario: Nothing closes
- **WHEN** the person taps "Done" on the page
- **THEN** the screen beneath returns, every open tool stays open and the scheduler keeps every reminder

#### Scenario: At the review
- **WHEN** the page opens from the deterioration rule at the week 5 review and the person taps "Done"
- **THEN** the review continues

#### Scenario: The deterioration reason
- **WHEN** the page opens from the deterioration rule
- **THEN** the reason reads "Your starred entries have gone up each week lately." and the page shows no number

### Requirement: The deterioration rule

`weekly-review` freezes each week's starred count into its Review row at review time. At each weekly review the app MUST read the frozen counts of the last four reviews, the current one last. The rule fires when three conditions hold:

- each of the last three counts exceeds the count before it
- the latest count is at least 4
- the latest count is at least twice the first of the four

DETERIORATION_WEEKS = 3 is a named constant in `ProgrammeConstants`.

When the rule fires, the app MUST show the GP suggestion page with the reason "Your starred entries have gone up each week lately." The reason MUST NOT hold a number. Ash ruled this on 26 September 2026 (r13-09). When fewer than four reviews exist, the app MUST NOT apply the rule. The app MUST show the page from the rule at most once per weekly review.

Every weekly review MUST offer the button "I'm getting worse". When the person taps it, the app MUST show the GP suggestion page at once. The page shows the reason "You said things are getting worse." The app MUST show the page at each tap, also after the rule showed it in that review.

#### Scenario: Three rising weeks
- **WHEN** the frozen counts for weeks 2 to 5 are 3, 4, 5 and 6 and the week 5 review opens
- **THEN** the app shows the GP suggestion page with "Your starred entries have gone up each week lately."

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
