import Foundation
import XCTest

/// weigh-in spec, "What the weigh-in never shows" (mm-t22.8). Every string
/// the weigh-in screen shows is either quoted verbatim from the spec
/// (`WeighInContent`, `Screen3Content`, `WeighInRefusalText`,
/// `WeighInExplanation`, none of which names "up", "down", "lost" or
/// "gained") or a plain number or date, so the vocabulary rule holds by
/// construction; this structural test covers the rest of the requirement:
/// no goal, target, BMI, arrow or difference shown, and a quiet save (no
/// confirmation, sound, haptic, colour change or animation of this
/// screen's own).
final class WeighInNeverShowsTests: XCTestCase {
    private func sourceText(_ relativePath: String) throws -> String {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // RecordTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // Packages
            .deletingLastPathComponent() // repo root
        return try String(contentsOf: repoRoot.appendingPathComponent(relativePath), encoding: .utf8)
    }

    func testTheScreenAddsNoConfirmationSoundHapticOrAnimation() throws {
        let text = try sourceText("App/Midmorning/WeighIn/WeighInScreenView.swift")
        for forbidden in ["FeedbackGenerator", "playSystemSound", "withAnimation", ".animation(", ".alert(", ".confirmationDialog(", ".sound"] {
            XCTAssertFalse(text.contains(forbidden), "WeighInScreenView.swift uses \(forbidden), which the save flow MUST NOT add")
        }
    }

    func testNoTextShowsBMIHeightOrAGoal() throws {
        for file in ["App/Midmorning/WeighIn/WeighInScreenView.swift", "App/Midmorning/WeighIn/WeighInChartView.swift"] {
            let text = try sourceText(file)
            for line in text.components(separatedBy: "\n") where line.contains("Text(") || line.contains("Button(") {
                for forbidden in ["BMI", "onboardingBMI", "heightCm", "goalWeight", "targetLine"] {
                    XCTAssertFalse(line.contains(forbidden), "\(file) shows \(forbidden) on a Text/Button line: \(line)")
                }
            }
        }
    }

    func testTheChartAddsNoGoalTargetOrArrowImage() throws {
        let text = try sourceText("App/Midmorning/WeighIn/WeighInChartView.swift")
        for forbidden in ["RuleMark", "systemName: \"arrow", "GoalLine", "TargetLine"] {
            XCTAssertFalse(text.contains(forbidden), "WeighInChartView.swift uses \(forbidden), which the chart MUST NOT show")
        }
    }
}
