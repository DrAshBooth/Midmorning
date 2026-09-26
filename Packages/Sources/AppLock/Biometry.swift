import Foundation

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
/// the same device (app-lock spec, "The app lock is on by default").
public struct BiometryStrings: Sendable, Equatable {
    public let lockLabel: String
    public let isLockEnabled: Bool
    public let onlyLabel: String?
    public let enrolmentWarning: String?
    /// The sentence onboarding's "Screen 4: permissions" shows under the app
    /// lock switch (onboarding spec: "The label function that `app-lock`
    /// defines returns it... The onboarding capability's lock sentence MUST
    /// take its Face ID or Touch ID word from the same function.").
    public let onboardingSentence: String

    public init(lockLabel: String, isLockEnabled: Bool, onlyLabel: String?, enrolmentWarning: String?, onboardingSentence: String) {
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
    public static let noPasscodeMessage = "Set a passcode on your device to lock Midmorning."

    /// Info.plist's `NSFaceIDUsageDescription`. Scenario: "Face ID usage
    /// description".
    public static let faceIDUsageDescription = "Midmorning uses Face ID to unlock the app."

    /// The system authentication request's reason string. Requirement:
    /// "When the app asks".
    public static let unlockReason = "Unlock Midmorning"

    public static func strings(for biometry: Biometry) -> BiometryStrings {
        switch biometry {
        case .faceID:
            return BiometryStrings(
                lockLabel: "Lock with Face ID",
                isLockEnabled: true,
                onlyLabel: "Face ID only",
                enrolmentWarning: "If Face ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on.",
                onboardingSentence: "Midmorning asks for Face ID or your passcode when it opens."
            )
        case .touchID:
            return BiometryStrings(
                lockLabel: "Lock with Touch ID",
                isLockEnabled: true,
                onlyLabel: "Touch ID only",
                enrolmentWarning: "If Touch ID stops working, you can delete this device's copy. A copy in iCloud stays if sync is on.",
                onboardingSentence: "Midmorning asks for Touch ID or your passcode when it opens."
            )
        case .passcodeOnly:
            return BiometryStrings(
                lockLabel: "Lock with passcode",
                isLockEnabled: true,
                onlyLabel: nil,
                enrolmentWarning: nil,
                onboardingSentence: "Midmorning asks for your passcode when it opens."
            )
        case .none:
            return BiometryStrings(
                lockLabel: noPasscodeMessage,
                isLockEnabled: false,
                onlyLabel: nil,
                enrolmentWarning: nil,
                onboardingSentence: ""
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
