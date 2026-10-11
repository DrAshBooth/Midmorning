# app-lock

## MODIFIED Requirements

### Requirement: Face ID only or Touch ID only

The Privacy group of the settings screen MUST show "Face ID only" on a device with Face ID enrolled. It MUST show "Touch ID only" on a device with Touch ID enrolled. Both strings come from the label function. The setting is off by default and is the `face-or-touch-only` value in `Local.store`. The settings capability owns the group. When no biometric is enrolled, the Privacy group MUST NOT show a "Face ID only" or "Touch ID only" control. Ash ruled this on 9 October 2026 (r19-04). The control MUST be disabled when the app lock is off.

Before it turns on, the app MUST show a warning with "Turn on" and "Cancel". The warning reads "If Face ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on." on a Face ID device. On a Touch ID device it reads "If Touch ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on." "Cancel" MUST leave it off. The app MUST make the system authentication request before it turns the setting off.

With the setting on, the app MUST use the biometrics-only policy, `deviceOwnerAuthenticationWithBiometrics`. The app MUST NOT offer the device passcode in any system authentication request. The app MUST keep the enrolment state hash it last saw in `Local.store`. On iOS 18 and later the hash is `LAContext.domainState.biometry.stateHash`. On iOS 17 it is a hash of `evaluatedPolicyDomainState`.

While the setting is on, the app MUST compare the enrolment state with the kept hash before each system authentication request. When the enrolment state has changed, the app MUST stay locked. The cover MUST then offer "Delete from this device" and "Delete everything", with "Unlock" off the screen. The next requirement defines "Delete from this device". The cover MUST NOT offer a support link, a contact or an email address.

When the person taps "Turn on" in the warning, the app MUST make a system authentication request with the biometrics-only policy before it saves a hash. When authentication succeeds, the app MUST turn the setting on. The app MUST then save the current enrolment state hash in `Local.store` as the kept hash. When the person cancels the request or authentication fails, the setting MUST stay off, and the app MUST NOT save a hash. During a biometry lockout the request fails, so the setting stays off. When the device gives no enrolment state hash after the request succeeds, the setting MUST stay off. The request at "Turn on" comes while the setting is off, so the app makes no comparison with the kept hash before it. An old kept hash MUST NOT stop that request, because the app saves a new hash after it. This save is not a reset. The app then compares the enrolment state with that hash, as above. Apart from this save, the app MUST NOT reset the kept enrolment state hash except through Delete-all. Delete-all deletes it with `Local.store`, as the data-and-privacy capability states. Ash ruled this on 26 September 2026. Ash ruled on 7 October 2026 that "Turn on" makes the biometrics-only request before the save (r15-03).

#### Scenario: Turn on
- **WHEN** the person turns on "Face ID only", taps "Turn on" and Face ID succeeds
- **THEN** the setting is on, `Local.store` holds the current `stateHash` as the kept hash, and the next system authentication request offers Face ID and no "Enter Passcode"

#### Scenario: Cancel the request at Turn on
- **WHEN** the person turns on "Face ID only", taps "Turn on" and cancels the system authentication request
- **THEN** "Face ID only" stays off and the app saves no hash

#### Scenario: Face ID fails at Turn on
- **WHEN** the person turns on "Face ID only", taps "Turn on" and Face ID fails twice
- **THEN** the request offers no "Enter Passcode", "Face ID only" stays off and the app saves no hash

#### Scenario: Turn on during a lockout
- **WHEN** the system has locked Face ID out and the person taps "Turn on" for "Face ID only"
- **THEN** the request fails, "Face ID only" stays off and the kept hash does not change

#### Scenario: Cancel the turn-on
- **WHEN** the person turns on "Face ID only" and taps "Cancel"
- **THEN** "Face ID only" stays off

#### Scenario: Touch ID device
- **WHEN** the person opens the Privacy group on a device with Touch ID enrolled and turns the setting on
- **THEN** the control reads "Touch ID only" and the warning reads "If Touch ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on."

#### Scenario: Face ID fails with Face ID only
- **WHEN** "Face ID only" is on and Face ID fails twice
- **THEN** the system authentication request offers no passcode and the app stays locked

#### Scenario: Enrolment changed
- **WHEN** "Face ID only" is on and the person adds a second face in the iOS Settings app, then opens the app
- **THEN** the `stateHash` differs from the kept one, and the cover shows "Midmorning", "Delete from this device" and "Delete everything", makes no authentication request and stays locked

#### Scenario: Turn on again after an enrolment change
- **WHEN** "Face ID only" is off after an earlier turn-on, the person adds a second face in the iOS Settings app, turns "Face ID only" on again with "Turn on", Face ID succeeds at that request, and the app then locks
- **THEN** the kept hash is the new `stateHash`, and the cover shows "Unlock" and "Delete everything" and no "Delete from this device"

#### Scenario: Delete everything after an enrolment change
- **WHEN** the cover shows no "Unlock" and the person taps "Delete everything" and confirms
- **THEN** the app deletes everything, writes the erasure marker and starts onboarding at the next launch

#### Scenario: No biometric enrolled
- **WHEN** the device has a passcode and no biometric enrolled
- **THEN** the Privacy group shows no "Face ID only" or "Touch ID only" control

