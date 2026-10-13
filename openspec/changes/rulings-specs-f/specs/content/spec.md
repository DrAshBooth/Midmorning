# content

## MODIFIED Requirements

### Requirement: Clinical sign-off per content version

The repository MUST hold one sign-off file for each content version that ships. A sign-off file MUST hold the content version, the bundle hash and the date. It MUST hold the reviewer's name, the reviewer's role and the list of ids reviewed. It MUST hold the field `kind`. The value of `kind` MUST be "owner" or "clinical". A sign-off of the kind "clinical" MUST name a clinical psychologist with CBT-E training as the reviewer. A sign-off of the kind "owner" MUST name the owner of the product as the reviewer, with the role "owner". A sign-off file of either kind MUST hold the reviewer's answer to the tone question for every card. The content test MUST fail when a sign-off file has no `kind` field. It MUST then name the file. Ash ruled this on 13 October 2026 (r25-01).

A sign-off file matches the bundle when its content version and its hash equal the bundle's. When the environment variable MIDMORNING_RELEASE is 1 and no sign-off file matches, the content test MUST fail. When MIDMORNING_RELEASE is not 1 and no sign-off file matches, the content test MUST pass. It MUST then set the "Draft" flag in the bundle. When a sign-off file of either kind matches, the content test MUST clear the "Draft" flag. The release lane MUST run the content test with MIDMORNING_RELEASE=1.

A tester build is a build that TestFlight carries. The App Store build is the launch build. A tester build MAY carry a content version whose matching sign-off has the kind "owner". The App Store build MUST carry a content version whose matching sign-off has the kind "clinical". When the environment variable MIDMORNING_LAUNCH is 1 and the matching sign-off does not have the kind "clinical", the content test MUST fail. It MUST then name the content version and the kind. The launch lane MUST run the content test with MIDMORNING_RELEASE=1 and MIDMORNING_LAUNCH=1. The archive script MUST take the option `--launch` for the App Store build. That option MUST set MIDMORNING_LAUNCH=1 for the content test. Without `--launch`, the script MUST archive a tester build. The team MUST NOT submit an App Store build whose content version has no sign-off of the kind "clinical".

When the bundle carries the "Draft" flag, the app MUST show "Draft" at the top of every card. The app MUST show "Draft" only when no sign-off file matches. The app MUST show nothing about the kind of the sign-off. The team MUST NOT ship a build that shows "Draft" to any person outside the team. The archive script MUST refuse to upload a build whose bundle carries the "Draft" flag.

#### Scenario: Release without sign-off
- **WHEN** MIDMORNING_RELEASE is 1, the bundle carries content version 3, and the repository holds no sign-off file for version 3
- **THEN** the content test fails and names version 3

#### Scenario: Release with a sign-off for an older hash
- **WHEN** MIDMORNING_RELEASE is 1 and the sign-off file for version 3 holds a hash that differs from the bundle's hash
- **THEN** the content test fails and names version 3

#### Scenario: A local test run without sign-off
- **WHEN** MIDMORNING_RELEASE is not set and the repository holds no sign-off file for version 4
- **THEN** the content test passes, sets the "Draft" flag, and every card shows "Draft" at the top

#### Scenario: Sign-off present
- **WHEN** the sign-off file for version 3 holds the bundle's hash, the kind "clinical", the reviewer's name, role and date, every id and the tone answer for every card
- **THEN** the content test passes the sign-off check and no card shows "Draft"

#### Scenario: The archive script and a Draft bundle
- **WHEN** the team runs the archive script on a build whose bundle carries the "Draft" flag
- **THEN** the script stops before the upload and names the flag

#### Scenario: A tester build on the owner's sign-off
- **WHEN** MIDMORNING_RELEASE is 1, the bundle carries content version 5, and the sign-off file for version 5 holds the bundle's hash, the kind "owner", the owner's name, the role "owner", the date Tuesday 13 October 2026, every id and the tone answer for every card
- **THEN** the content test passes the sign-off check and no card shows "Draft"

#### Scenario: The launch lane with an owner's sign-off
- **WHEN** MIDMORNING_RELEASE is 1, MIDMORNING_LAUNCH is 1, the bundle carries content version 5, and the matching sign-off file for version 5 holds the kind "owner"
- **THEN** the content test fails and names version 5 and the kind "owner"

#### Scenario: The launch lane with the clinical sign-off
- **WHEN** MIDMORNING_RELEASE is 1, MIDMORNING_LAUNCH is 1, the bundle carries content version 5, and the matching sign-off file for version 5 holds the kind "clinical"
- **THEN** the content test passes the sign-off check and no card shows "Draft"

#### Scenario: A sign-off file without a kind
- **WHEN** the sign-off file for version 5 holds the bundle's hash, the reviewer's name, role and date, every id and the tone answer for every card, and no `kind` field
- **THEN** the content test fails and names the file "content-signoff-v5.json"

#### Scenario: The archive script for a tester build
- **WHEN** the team runs the archive script without `--launch`, and the matching sign-off file for the bundle's content version holds the kind "owner"
- **THEN** the script runs the content test with MIDMORNING_RELEASE=1 and without MIDMORNING_LAUNCH, the test passes, and the script archives the tester build

#### Scenario: The archive script with --launch
- **WHEN** the team runs the archive script with `--launch`, and the matching sign-off file for the bundle's content version holds the kind "owner"
- **THEN** the script runs the content test with MIDMORNING_RELEASE=1 and MIDMORNING_LAUNCH=1, the test fails and names the kind "owner", and the script stops before the upload
