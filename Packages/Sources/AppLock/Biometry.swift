import Foundation
import Constants

/// What the device offers for the system authentication request
/// (app-lock spec, "The app lock is on by default"). `.none` means the
/// device has no passcode at all, so the app lock cannot turn on.
public enum Biometry: Sendable, Equatable, CaseIterable {
    case faceID
    case touchID
    case passcodeOnly
    case none
}

/// Every string the label function returns for one `Biometry` value: the
/// Privacy group's app-lock switch label (or its disabled message), whether
/// the switch is enabled, and, for a biometric device, the "only" setting's
/// label and its turn-on warning. One function returns all of these so the
/// onboarding screen and the settings screen always show the same words for
/// the same device (app-lock spec, "The app lock is on by default"). Each
/// string is a catalogue key, never English (content spec, "Strings live in
/// catalogues"); the App target fills it from Localizable.xcstrings.
public struct BiometryStrings: Sendable, Equatable {
    public let lockLabel: CatalogueText
    public let isLockEnabled: Bool
    public let onlyLabel: CatalogueText?
    public let enrolmentWarning: CatalogueText?
    /// The sentence onboarding's "Screen 4: permissions" shows under the app
    /// lock switch (onboarding spec: "The label function that `app-lock`
    /// defines returns it... The onboarding capability's lock sentence MUST
    /// take its Face ID or Touch ID word from the same function."). `nil`
    /// with no device passcode, because the app lock cannot turn on then.
    public let onboardingSentence: CatalogueText?

    public init(lockLabel: CatalogueText, isLockEnabled: Bool, onlyLabel: CatalogueText?, enrolmentWarning: CatalogueText?, onboardingSentence: CatalogueText?) {
        self.lockLabel = lockLabel
        self.isLockEnabled = isLockEnabled
        self.onlyLabel = onlyLabel
        self.enrolmentWarning = enrolmentWarning
        self.onboardingSentence = onboardingSentence
    }
}

/// The one label function the app-lock spec names: "The label function MUST
/// take a `Biometry` value as its input... The same function MUST return
/// every string that names the biometric." Onboarding and the settings
/// screen both call `strings(for:)`, never their own copy of a string.
public enum BiometryLabels {
    /// Requirement: "The app lock is on by default" — "Under the disabled
    /// switch the app MUST show..."
    public static let noPasscodeMessage: CatalogueText = .key("applock.noPasscode")

    /// The system authentication request's reason string. Requirement:
    /// "When the app asks".
    public static let unlockReason: CatalogueText = .key("applock.unlockReason")

    public static func strings(for biometry: Biometry) -> BiometryStrings {
        switch biometry {
        case .faceID:
            return BiometryStrings(
                lockLabel: .key("applock.lockLabel.faceID"),
                isLockEnabled: true,
                onlyLabel: .key("applock.onlyLabel.faceID"),
                enrolmentWarning: .key("applock.enrolmentWarning.faceID"),
                onboardingSentence: .key("applock.onboardingSentence.faceID")
            )
        case .touchID:
            return BiometryStrings(
                lockLabel: .key("applock.lockLabel.touchID"),
                isLockEnabled: true,
                onlyLabel: .key("applock.onlyLabel.touchID"),
                enrolmentWarning: .key("applock.enrolmentWarning.touchID"),
                onboardingSentence: .key("applock.onboardingSentence.touchID")
            )
        case .passcodeOnly:
            return BiometryStrings(
                lockLabel: .key("applock.lockLabel.passcode"),
                isLockEnabled: true,
                onlyLabel: nil,
                enrolmentWarning: nil,
                onboardingSentence: .key("applock.onboardingSentence.passcode")
            )
        case .none:
            return BiometryStrings(
                lockLabel: noPasscodeMessage,
                isLockEnabled: false,
                onlyLabel: nil,
                enrolmentWarning: nil,
                onboardingSentence: nil
            )
        }
    }

    /// Requirement: "Face ID only or Touch ID only" — "The control MUST be
    /// disabled when no biometric is enrolled or the app lock is off."
    public static func isFaceOrTouchOnlyAvailable(biometry: Biometry, appLockEnabled: Bool) -> Bool {
        guard appLockEnabled else { return false }
        switch biometry {
        case .faceID, .touchID: return true
        case .passcodeOnly, .none: return false
        }
    }
}
