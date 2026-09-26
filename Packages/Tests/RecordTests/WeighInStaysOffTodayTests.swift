import Foundation
import XCTest
@testable import Programme

/// weigh-in spec, "The weigh-in stays off Today, widgets and notifications"
/// (mm-t22.10). "A widget" is `deferred: mm-t25.15` (`v1-programme
/// /deferred.md`: no widget target exists yet). The other two scenarios:
///
/// - "Today on the weigh-in day": structural — `TodayView.swift` names no
///   weigh-in fact of its own; this change touches it only to add the
///   `WeighInRoute` navigation destination.
/// - "App switcher": already covered, for every screen including this
///   change's own `WeighInScreenView` (pushed inside Today's own
///   `NavigationStack`), by `TodayView.swift`'s existing
///   `.privacySensitive()`/`.redacted(reason: scenePhase == .active ? [] :
///   .privacy)` (record-full, 1.2b) and by `app-lock`'s own `CoverView`
///   overlay, which shows `.privacyOnly` whenever `scenePhase != .active`
///   regardless of the app lock setting. Neither needed new code from this
///   change.
final class WeighInStaysOffTodayTests: XCTestCase {
    func testTodayViewNamesNoWeighInFact() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let text = try String(contentsOf: repoRoot.appendingPathComponent("App/Midmorning/TodayView.swift"), encoding: .utf8)
        for forbidden in ["weightKg", "WeighInFact", "RollingAverage", "weighIn(dateKey", "weighIns()"] {
            XCTAssertFalse(text.contains(forbidden), "TodayView.swift reads \(forbidden); the weigh-in spec says Today MUST NOT show a weight value or the rolling average")
        }
        XCTAssertTrue(text.contains(".redacted(reason:"), "the app switcher snapshot is already redacted while inactive")
    }

    /// The weigh-in day reminder's own discreet text is the shared
    /// `DiscreetText`/`ReminderKind` machinery every reminder kind uses: its
    /// body is always the time (never a weight), and its explicit title
    /// names only the reminder, never a number.
    func testTheWeighInDayReminderCarriesNoWeightValue() {
        XCTAssertEqual(DiscreetText.body(time: "07:30"), "07:30")
        XCTAssertEqual(ReminderKind.weighInDay.explicitTitle().english, "Weigh-in day")
    }
}
