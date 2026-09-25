import Foundation

/// Which system authentication request the app makes. Requirement:
/// "Fallback to the device passcode" and "Face ID only or Touch ID only".
/// The App target maps this to an `LAPolicy`: `.biometricsAndPasscode` to
/// `deviceOwnerAuthentication` (offers the device passcode), `.biometricsOnly`
/// to `deviceOwnerAuthenticationWithBiometrics` (never offers it).
public enum AuthenticationPolicy: Sendable, Equatable {
    case biometricsAndPasscode
    case biometricsOnly

    /// Scenario: "Turn on" (Face ID only, no "Enter Passcode"). Scenario:
    /// "Face ID fails" (Face ID only off, the request offers the passcode).
    public static func policy(faceOrTouchOnly: Bool) -> AuthenticationPolicy {
        faceOrTouchOnly ? .biometricsOnly : .biometricsAndPasscode
    }
}

/// The pure comparison "Face ID only or Touch ID only" states: "The app MUST
/// compare the enrolment state with the kept hash before each system
/// authentication request. When the enrolment state has changed, the app
/// MUST stay locked." The App target computes each hash from
/// `LAContext.domainState` (iOS 18 and later) or `evaluatedPolicyDomainState`
/// (iOS 17); this function only compares the two hashes it is given.
public enum EnrolmentState {
    /// `nil` for `kept` means no baseline is saved yet, so nothing has
    /// changed. Scenario: "Enrolment changed". Scenario: "Not shown before
    /// an enrolment change".
    public static func hasChanged(current: String, kept: String?) -> Bool {
        guard let kept else { return false }
        return current != kept
    }
}
