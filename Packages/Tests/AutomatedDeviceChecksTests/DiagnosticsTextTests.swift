import Foundation
import XCTest
import Constants
import Record
import RecordTestSupport

/// Ruling r13-19 (mm-t43.30): the text part of "Diagnostics" on mm-t41.15
/// (the same check as "Diagnostics" on mm-t42.14). Settings spec, "The
/// About group", scenario "Diagnostics": "the page shows eight counts and
/// no entry, weight or plan". This test fills a real store with an entry,
/// a weigh-in and a plan, reads the counts as `SettingsView` does, and
/// proves that the page shows the eight counts and no record content.
/// The route (Settings, then "Diagnostics") is
/// `AutomatedChecks.testDiagnosticsShowsTheEightCounts` in
/// tools/skeleton-checks.
@MainActor
final class DiagnosticsTextTests: XCTestCase {
    private let labels: [(key: String, english: String)] = [
        ("diagnostics.launchFailures", "Launch failures"),
        ("diagnostics.lastSuccessfulSyncDay", "Last successful sync day"),
        ("diagnostics.schemaVersion", "Schema version"),
        ("diagnostics.contentVersion", "Content version"),
        ("diagnostics.pendingReminders", "Pending reminders"),
        ("diagnostics.queueLength", "Queue length"),
        ("diagnostics.lastReconcileOutcome", "Last reconcile outcome"),
        ("diagnostics.crashCount", "Crash count"),
    ]

    func testThePageShowsTheEightCountsAndNothingElse() throws {
        for label in labels {
            XCTAssertEqual(ScreenText.english(.key(label.key)), label.english)
        }
        let source = try ScreenText.source("DiagnosticsView.swift")
        XCTAssertEqual(source.components(separatedBy: "LabeledContent(").count - 1, 8, "the page has eight rows")
        for label in labels {
            XCTAssertTrue(source.contains("LabeledContent(\"\(label.key)\""), "the page shows \(label.english)")
        }
        for other in ["Text(", "ForEach(", "List("] {
            XCTAssertFalse(source.contains(other), "the page shows nothing but the eight rows (\(other))")
        }
        try ScreenText.assertScreen("SettingsView.swift", shows: ["NavigationLink(\"settings.about.diagnostics\")", "DiagnosticsView(counts: diagnosticsCounts)"])
    }

    func testTheCountsHoldNoEntryWeightOrPlan() throws {
        let store = try makeTemporaryStore()
        let now = Date()
        try store.add(time: now, what: "Toast and tea", feltLikeABinge: true, createdAt: now, utcOffsetSeconds: 3600,
                      whereText: "Mum's", context: "Row with my sister")
        _ = try store.saveWeighIn(dateKey: "2026-09-21", weightKg: 70.4, unit: "kg", at: now)
        try store.setSlotLabel("Cake", index: 3, changedAt: now)
        let counts = try store.diagnosticsCounts(contentVersion: 1)
        let values = [
            String(counts.launchFailures), ScreenText.english(counts.lastSuccessfulSyncDay), counts.schemaVersion,
            String(counts.contentVersion), String(counts.pendingReminders), String(counts.queueLength),
            ScreenText.english(counts.lastReconcileOutcome.text), String(counts.crashCount),
        ]
        XCTAssertEqual(Mirror(reflecting: counts).children.count, 8, "the counts hold eight values")
        for content in ["Toast and tea", "Mum's", "Row with my sister", "70.4", "70,4", "Cake"] {
            XCTAssertFalse(values.contains { $0.contains(content) }, "no count shows \(content)")
        }
    }
}
