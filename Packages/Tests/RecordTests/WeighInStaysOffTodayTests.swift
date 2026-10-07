import Foundation
import XCTest
@testable import Programme
import AppLock

/// weigh-in spec, "The weigh-in stays off Today, widgets and notifications"
/// (mm-t22.10). "A widget" is `deferred: mm-t25.15` (`v1-programme
/// /deferred.md`: no widget target exists yet). The other two scenarios:
///
/// - "Today on the weigh-in day": structural — `TodayView.swift` names no
///   weigh-in fact of its own; this change touches it only to add the
///   `WeighInRoute` navigation destination.
/// - "App switcher": already covered, for every screen including this
///   change's own `WeighInScreenView` (pushed inside Today's own
///   `NavigationStack`), by `app-lock`'s cover window, which shows the
///   cover whenever `scenePhase != .active`, with the app lock on or off.
///   Ruling r16-02 (mm-t12b.27) removed Today's own `.privacySensitive()`
///   and `.redacted(reason:)`, because on iOS 27 they made Today blank; the
///   cover window is now the one layer that hides Today.
final class WeighInStaysOffTodayTests: XCTestCase {
    func testTodayViewNamesNoWeighInFact() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let text = try String(contentsOf: repoRoot.appendingPathComponent("App/Midmorning/TodayView.swift"), encoding: .utf8)
        for forbidden in ["weightKg", "WeighInFact", "RollingAverage", "weighIn(dateKey", "weighIns()"] {
            XCTAssertFalse(text.contains(forbidden), "TodayView.swift reads \(forbidden); the weigh-in spec says Today MUST NOT show a weight value or the rolling average")
        }
        XCTAssertFalse(text.contains(".privacySensitive()"), "ruling r16-02: on iOS 27 this modifier makes Today blank")
        let inactive = AppLifecycle.reduce(.launch(appLockEnabled: false), event: .didBecomeInactive)
        XCTAssertEqual(inactive.coverMode, .privacyOnly, "the app switcher snapshot shows the cover, also with the app lock off")
        XCTAssertNotEqual(inactive.coverWindowMode, .hidden)
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
