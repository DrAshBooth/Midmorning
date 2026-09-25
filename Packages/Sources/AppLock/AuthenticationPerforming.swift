import Foundation

/// One system authentication request. The App target's implementation wraps
/// `LAContext.evaluatePolicy`; a test supplies a fake so `AppLockController`
/// is testable with no LocalAuthentication and no device.
public protocol AuthenticationPerforming: Sendable {
    /// `true` on success; `false` on a cancel or a failure. Never throws:
    /// the caller only ever needs to know whether it can proceed.
    func authenticate(reason: String, policy: AuthenticationPolicy) async -> Bool
}

/// A test's fake authenticator: returns a fixed result and records every
/// request, so a test can assert the reason string and the policy the
/// caller asked for.
public actor FakeAuthenticator: AuthenticationPerforming {
    public struct Request: Sendable, Equatable {
        public let reason: String
        public let policy: AuthenticationPolicy
    }

    private var result: Bool
    public private(set) var requests: [Request] = []

    public init(result: Bool) {
        self.result = result
    }

    public func setResult(_ result: Bool) {
        self.result = result
    }

    public func authenticate(reason: String, policy: AuthenticationPolicy) async -> Bool {
        requests.append(Request(reason: reason, policy: policy))
        return result
    }
}
