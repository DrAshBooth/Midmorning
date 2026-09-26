import Foundation

/// The eight counts the Diagnostics page shows, and nothing else (settings
/// spec, "The About group"; data-and-privacy spec, "The Diagnostics counts
/// come from the device"). A value, not a live query, so a screen renders it
/// with no store access of its own.
public struct DiagnosticsCounts: Sendable, Equatable {
    public struct ReconcileOutcome: Sendable, Equatable {
        public let winners: Int
        public let losers: Int

        public init(winners: Int, losers: Int) {
            self.winners = winners
            self.losers = losers
        }
    }

    public let launchFailures: Int
    /// "Never" with sync off or before the first sync; `4.1b` writes a day
    /// key here once sync sends.
    public let lastSuccessfulSyncDay: String
    public let schemaVersion: String
    public let contentVersion: Int
    public let pendingReminders: Int
    public let queueLength: Int
    public let lastReconcileOutcome: ReconcileOutcome
    public let crashCount: Int

    public init(
        launchFailures: Int,
        lastSuccessfulSyncDay: String,
        schemaVersion: String,
        contentVersion: Int,
        pendingReminders: Int,
        queueLength: Int,
        lastReconcileOutcome: ReconcileOutcome,
        crashCount: Int
    ) {
        self.launchFailures = launchFailures
        self.lastSuccessfulSyncDay = lastSuccessfulSyncDay
        self.schemaVersion = schemaVersion
        self.contentVersion = contentVersion
        self.pendingReminders = pendingReminders
        self.queueLength = queueLength
        self.lastReconcileOutcome = lastReconcileOutcome
        self.crashCount = crashCount
    }

    /// "Never": the settings spec's own word for no successful sync yet.
    public static let noSyncYet = "Never"
}

/// The two counts `2.4` (reminders) and `2.5` (widgets-and-intents) own:
/// the notification centre's pending-request count and the action queue's
/// length. The App target reads both from the device and passes them to
/// `RecordStore.diagnosticsCounts`; `ZeroDiagnosticsSourceCounts` is the
/// value for a caller that has no device to read, such as a test.
public protocol DiagnosticsSourceCounts: Sendable {
    var pendingReminders: Int { get }
    var queueLength: Int { get }
}

public struct ZeroDiagnosticsSourceCounts: DiagnosticsSourceCounts, Sendable {
    public init() {}
    public var pendingReminders: Int { 0 }
    public var queueLength: Int { 0 }
}
