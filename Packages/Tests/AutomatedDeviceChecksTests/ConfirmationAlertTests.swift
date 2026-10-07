import Foundation
import XCTest
import Constants
import Programme

/// Ruling r16-03 (mm-t12b.28): from iOS 26, a SwiftUI confirmation dialog
/// shows as a popover with no "Cancel". Each confirmation with a "Cancel"
/// is an alert, which shows both buttons. Record spec, "Delete an entry":
/// "Delete this entry?" with the choices "Delete" and "Cancel". These
/// tests prove the code from the repository. The device-check bead
/// mm-t12b.1 holds the check on a device with iOS 27.
final class ConfirmationAlertTests: XCTestCase {
    /// One confirmation: the App file, the alert's title as the code gives
    /// it, and the button with the role `.cancel`.
    private struct Confirmation {
        let file: String
        let title: String
        let cancelButton: String
    }

    private let confirmations: [Confirmation] = [
        Confirmation(file: "DaySectionView.swift", title: "\"entry.delete.confirmTitle\"", cancelButton: "Button(\"entry.cancel\", role: .cancel)"),
        Confirmation(file: "EditEntryView.swift", title: "\"entry.delete.confirmTitle\"", cancelButton: "Button(\"entry.cancel\", role: .cancel)"),
        Confirmation(file: "SettingsView.swift", title: "\"applock.deleteEverything.confirm.title\"", cancelButton: "Button(\"entry.cancel\", role: .cancel)"),
        Confirmation(file: "AppLock/StoreOpenFailureView.swift", title: "\"applock.deleteEverything.confirm.title\"", cancelButton: "Button(\"entry.cancel\", role: .cancel)"),
        Confirmation(file: "AppLock/CoverView.swift", title: "\"applock.deleteEverything.confirm.title\"", cancelButton: "Button(\"applock.cancel\", role: .cancel)"),
        Confirmation(file: "AppLock/CoverView.swift", title: "\"applock.deleteFromThisDevice.confirm.title\"", cancelButton: "Button(\"applock.cancel\", role: .cancel)"),
        Confirmation(file: "AppLock/PrivacyAppLockControls.swift", title: "strings.onlyLabel?.string", cancelButton: "Button(\"applock.cancel\", role: .cancel)"),
        Confirmation(file: "PlanBuilderView.swift", title: "Text(softRuleLines", cancelButton: "Button(\"plan.goBack\", role: .cancel)"),
        Confirmation(file: "Safeguarding/BeatContactsView.swift", title: "SupportSheet.callRecentsWarning", cancelButton: "Button(CommonLabels.cancel.string, role: .cancel)"),
    ]

    /// The source of an App file with no comments and no white space, so a
    /// match does not depend on the line breaks.
    private func compactSource(_ path: String) throws -> String {
        try ScreenText.source(path).filter { !$0.isWhitespace }
    }

    private func compact(_ text: String) -> String {
        text.filter { !$0.isWhitespace }
    }

    /// Every Swift file of the App target, by its path under
    /// `App/Midmorning`.
    private func appSwiftFiles() throws -> [String] {
        let root = AppFiles.appSources.standardizedFileURL
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        var paths: [String] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            paths.append(String(url.standardizedFileURL.path.dropFirst(root.path.count + 1)))
        }
        return paths.sorted()
    }

    /// No screen uses a confirmation dialog: a new one fails here, before
    /// iOS hides its "Cancel".
    func testNoScreenUsesAConfirmationDialog() throws {
        let files = try appSwiftFiles()
        XCTAssertTrue(files.contains("DaySectionView.swift"), "the scan reads the App files")
        for path in files {
            let source = try compactSource(path)
            XCTAssertFalse(source.contains("confirmationDialog("), "\(path) uses a confirmation dialog; use an alert (ruling r16-03)")
        }
    }

    /// Each confirmation is an alert, and the alert holds its button with
    /// the role `.cancel`.
    func testEachConfirmationIsAnAlertWithItsCancelButton() throws {
        for confirmation in confirmations {
            let source = try compactSource(confirmation.file)
            let opening = compact("alert(" + confirmation.title)
            guard let start = source.range(of: opening) else {
                XCTFail("\(confirmation.file) shows \(confirmation.title) in no alert")
                continue
            }
            let rest = source[start.upperBound...]
            let end = rest.range(of: "alert(")?.lowerBound ?? rest.endIndex
            XCTAssertTrue(rest[..<end].contains(compact(confirmation.cancelButton)), "the alert \(confirmation.title) in \(confirmation.file) has no \(confirmation.cancelButton)")
        }
    }

    /// The cancel buttons read "Cancel", and the soft-rule check's reads
    /// "Go back".
    func testTheCancelButtonsWords() {
        XCTAssertEqual(ScreenText.english(.key("entry.cancel")), "Cancel")
        XCTAssertEqual(ScreenText.english(.key("applock.cancel")), "Cancel")
        XCTAssertEqual(ScreenText.english(CommonLabels.cancel), "Cancel")
        XCTAssertEqual(ScreenText.english(.key("entry.delete.confirmTitle")), "Delete this entry?")
        XCTAssertEqual(ScreenText.english(.key("entry.delete.action")), "Delete")
        XCTAssertEqual(ScreenText.english(.key("plan.goBack")), "Go back")
    }
}
