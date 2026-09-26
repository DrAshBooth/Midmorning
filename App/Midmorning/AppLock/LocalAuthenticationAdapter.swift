import Foundation
import LocalAuthentication
import CryptoKit
import AppLock
import Constants

/// Reads `mach_continuous_time`, ticks that advance through sleep, and
/// converts them to seconds with `mach_timebase_info` (app-lock spec, "When
/// the app asks": "measure the grace period with `mach_continuous_time`,
/// which counts through sleep, not with the calendar").
struct MachContinuousClock: ContinuousClockReading {
    func continuousSeconds() -> TimeInterval {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        let ticks = mach_continuous_time()
        guard info.denom != 0 else { return TimeInterval(ticks) }
        let nanoseconds = Double(ticks) * Double(info.numer) / Double(info.denom)
        return nanoseconds / 1_000_000_000
    }
}

/// Wraps one `LAContext` per system authentication request. Requirement:
/// "Fallback to the device passcode" — `.biometricsAndPasscode` maps to
/// `deviceOwnerAuthentication`, which offers the device passcode.
/// Requirement: "Face ID only or Touch ID only" — `.biometricsOnly` maps to
/// `deviceOwnerAuthenticationWithBiometrics`, which never does. Untestable
/// under `swift test` (LocalAuthentication needs a device or a simulator
/// with enrolled biometrics); the app-lock change's device-check bead lists
/// every scenario this type's real behaviour must prove.
struct LAContextAuthenticator: AuthenticationPerforming {
    func authenticate(reason: CatalogueText, policy: AppLock.AuthenticationPolicy) async -> Bool {
        let context = LAContext()
        let laPolicy: LAPolicy = policy == .biometricsOnly
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        var error: NSError?
        guard context.canEvaluatePolicy(laPolicy, error: &error) else { return false }
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(laPolicy, localizedReason: reason.string) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}

/// Detects what the device offers, for the label function and for enabling
/// "Face ID only"/"Touch ID only". Requirement: "The app lock is on by
/// default" — `Biometry`'s four values. With `.none` the app lock is off
/// (`AppLockLaunch.isEnabled`), so only the "no passcode" error gives
/// `.none`. Any other failure gives `.passcodeOnly` and keeps the app lock
/// on.
enum BiometryDetector {
    static func current(context: LAContext = LAContext()) -> Biometry {
        var biometricError: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &biometricError) {
            switch context.biometryType {
            case .faceID: return .faceID
            case .touchID: return .touchID
            default: break
            }
        }
        var passcodeError: NSError?
        if LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &passcodeError) {
            return .passcodeOnly
        }
        let noPasscode = passcodeError?.domain == LAErrorDomain
            && passcodeError?.code == LAError.Code.passcodeNotSet.rawValue
        return noPasscode ? .none : .passcodeOnly
    }
}

/// The enrolment-state hash "Face ID only or Touch ID only" keeps in
/// `Local.store`, so the app can tell a re-enrolment apart from an
/// unchanged one. The spec names `LAContext.domainState.biometry.stateHash`
/// on iOS 18 and later; this reads the long-stable
/// `evaluatedPolicyDomainState` on every OS version instead and hashes it
/// with SHA-256, so the type checks against every SDK this change builds
/// against. A device check (the epic's device-check bead) confirms the
/// real enrolment-change scenarios; `EnrolmentState.hasChanged` (`AppLock`)
/// is the pure comparison a test already drives with fixed hashes.
enum EnrolmentHash {
    static func current(context: LAContext = LAContext()) -> String? {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return nil }
        guard let domainState = context.evaluatedPolicyDomainState else { return nil }
        let digest = SHA256.hash(data: domainState)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
