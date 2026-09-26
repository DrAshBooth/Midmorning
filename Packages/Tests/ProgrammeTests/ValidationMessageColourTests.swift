import Foundation
import XCTest

/// r13-15 (mm-t14.45): every validation message uses the neutral text
/// colour, never red, also under the self-harm question and on the weigh-in
/// screen. The focus move and a VoiceOver announcement tell the person about
/// the message. There is no App-target test runner, so this structural test
/// reads the App sources. The device check in mm-t14.28 proves the screens.
final class ValidationMessageColourTests: XCTestCase {
    private let appDirectory: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // ProgrammeTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent() // repo root
        .appendingPathComponent("App/Midmorning", isDirectory: true)

    private func source(_ relativePath: String) throws -> String {
        try String(contentsOf: appDirectory.appendingPathComponent(relativePath), encoding: .utf8)
    }

    /// No text in the App is red. The one red in the App is the swipe
    /// action's tint in `DaySectionView`, which is not text.
    func testNoTextInTheAppIsRed() throws {
        let enumerator = try XCTUnwrap(FileManager.default.enumerator(at: appDirectory, includingPropertiesForKeys: nil))
        let forbidden = ["systemRed", "Color.red", "UIColor.red", "foregroundStyle(.red", "foregroundColor(.red", "foregroundStyle(Color.red", "foregroundColor(Color.red"]
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let text = try String(contentsOf: url, encoding: .utf8)
            for (index, line) in text.components(separatedBy: "\n").enumerated() {
                for word in forbidden {
                    XCTAssertFalse(line.contains(word), "\(url.lastPathComponent):\(index + 1) uses \(word)")
                }
            }
        }
    }

    /// The shared message view uses the neutral text colour, and its
    /// announcement waits for the speech that the focus move starts.
    func testTheMessageViewIsNeutralAndTheAnnouncementIsQueued() throws {
        let text = try source("Safeguarding/ValidationMessage.swift")
        XCTAssertTrue(text.contains(".foregroundStyle(.primary)"))
        XCTAssertTrue(text.contains(".accessibilitySpeechQueueAnnouncement: true"))
        XCTAssertTrue(text.contains("UIAccessibility.post(notification: .announcement"))
    }

    /// Each validation message shows through `ValidationMessageText`, and
    /// the screen that shows it announces it.
    func testEachValidationMessageIsNeutralAndAnnounced() throws {
        let shows: [String: String] = [
            "Onboarding/ScreeningQuestionSections.swift": "ValidationMessageText(issue.problem.message())",
            "Onboarding/Screen3View.swift": "ValidationMessageText(Screen3Content.unansweredMessage.string)",
            "WeighIn/WeighInScreenView.swift": "ValidationMessageText(belowRangeMessage)",
            "Export/ExportScreenView.swift": "ValidationMessageText(errorMessage)",
        ]
        for (file, call) in shows {
            XCTAssertTrue(try source(file).contains(call), "\(file) shows its message with \(call)")
        }
        let announces: [String: String] = [
            "Onboarding/Screen2View.swift": "ValidationAnnouncement.post(issue.problem.message())",
            "Programme/RescreenView.swift": "ValidationAnnouncement.post(issue.problem.message())",
            "Onboarding/Screen3View.swift": "ValidationAnnouncement.post(Screen3Content.unansweredMessage.string)",
            "WeighIn/WeighInScreenView.swift": "ValidationAnnouncement.post(message)",
            "Export/ExportScreenView.swift": "ValidationAnnouncement.post(message)",
        ]
        for (file, call) in announces {
            XCTAssertTrue(try source(file).contains(call), "\(file) announces its message with \(call)")
        }
    }

    /// The focus moves stay: screen 2 and the re-screen move focus to the
    /// question, and screen 3 moves focus to "Weigh-in day".
    func testTheFocusMovesStay() throws {
        XCTAssertTrue(try source("Onboarding/Screen2View.swift").contains("focusedField = issue.field"))
        XCTAssertTrue(try source("Programme/RescreenView.swift").contains("focusedField = issue.field"))
        XCTAssertTrue(try source("Onboarding/Screen3View.swift").contains("weighInDayFocused = true"))
        XCTAssertTrue(try source("Onboarding/ScreeningQuestionSections.swift").contains(".accessibilityFocused(focusedField, equals: .selfHarmFirst)"))
    }
}
