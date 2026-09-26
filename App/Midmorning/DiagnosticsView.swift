import SwiftUI
import Record

/// data-and-privacy spec, "The Diagnostics counts come from the device";
/// settings spec, "The About group" ("Diagnostics"). Eight plain rows and
/// nothing else — no record content, no entry text, no weight value and no
/// date of an entry, so the person can screenshot this page for TestFlight
/// feedback. `SettingsView` builds `counts` from `RecordStore
/// .diagnosticsCounts(contentVersion:)`; this view only renders the value.
struct DiagnosticsView: View {
    let counts: DiagnosticsCounts
    @State private var isShowingSupportSheet = false

    var body: some View {
        Form {
            LabeledContent("diagnostics.launchFailures", value: "\(counts.launchFailures)")
                .accessibilityElement(children: .combine)
            LabeledContent("diagnostics.lastSuccessfulSyncDay", value: counts.lastSuccessfulSyncDay)
                .accessibilityElement(children: .combine)
            LabeledContent("diagnostics.schemaVersion", value: counts.schemaVersion)
                .accessibilityElement(children: .combine)
            LabeledContent("diagnostics.contentVersion", value: "\(counts.contentVersion)")
                .accessibilityElement(children: .combine)
            LabeledContent("diagnostics.pendingReminders", value: "\(counts.pendingReminders)")
                .accessibilityElement(children: .combine)
            LabeledContent("diagnostics.queueLength", value: "\(counts.queueLength)")
                .accessibilityElement(children: .combine)
            LabeledContent("diagnostics.lastReconcileOutcome", value: reconcileOutcomeText)
                .accessibilityElement(children: .combine)
            LabeledContent("diagnostics.crashCount", value: "\(counts.crashCount)")
                .accessibilityElement(children: .combine)
        }
        .navigationTitle("diagnostics.title")
        .toolbar {
            // Safeguarding: "Get support on every screen" (decision 94: the
            // trailing position of the navigation bar, matching every other
            // full screen this change adds).
            ToolbarItem(placement: .confirmationAction) {
                Button("settings.getSupport") { isShowingSupportSheet = true }
            }
        }
        .sheet(isPresented: $isShowingSupportSheet) {
            GetSupportPlaceholderSheet()
        }
    }

    private var reconcileOutcomeText: String {
        "\(counts.lastReconcileOutcome.winners) kept, \(counts.lastReconcileOutcome.losers) removed"
    }
}
