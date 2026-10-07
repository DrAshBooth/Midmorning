import Foundation
import XCTest

/// The call record that the UI tests read (mm-t14.28, items "Cancel the
/// call" and mm-t14.29). The simulator has no app for a `tel://` URL, so
/// the UI tests prove "no call starts" from the record that
/// `NumberRow.startCall` writes in a Debug build (`CallRecorder`). These
/// source checks prove the two conditions that make that proof honest:
/// `startCall` is the app's only route to a call, and a Release build does
/// not hold the record.
final class SupportCallSourceTests: XCTestCase {
    /// Every Swift file under `App/Midmorning`, by its path under that
    /// folder.
    private func appSwiftFiles() throws -> [String] {
        let root = AppFiles.appSources
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
            throw XCTSkip("Cannot read \(root.path)")
        }
        let rootPath = root.standardizedFileURL.path + "/"
        return walker.compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
            .map { $0.standardizedFileURL.path.replacingOccurrences(of: rootPath, with: "") }
            .sorted()
    }

    /// The app has one route to a call: the `tel://` URL in
    /// `NumberRow.startCall`. So a record of each `startCall` is a record of
    /// each call that the app asks iOS to start.
    func testStartCallIsTheOnlyRouteToACall() throws {
        var files: [String] = []
        for path in try appSwiftFiles() {
            let source = try ScreenText.source(path)
            if source.contains("tel:") || source.contains("telprompt:") { files.append(path) }
        }
        XCTAssertEqual(files, ["Safeguarding/BeatContactsView.swift"], "only BeatContactsView.swift makes a call URL")
        let source = try ScreenText.source("Safeguarding/BeatContactsView.swift")
        XCTAssertEqual(source.components(separatedBy: "tel:").count - 1, 1, "BeatContactsView.swift makes one call URL")
        guard let start = source.range(of: "static func startCall(") else {
            return XCTFail("BeatContactsView.swift has no startCall")
        }
        let body = source[start.upperBound...]
        let end = body.range(of: "struct BeatWebchatButton")?.lowerBound ?? body.endIndex
        let startCall = String(body[..<end])
        XCTAssertTrue(startCall.contains("tel://"), "the call URL is in startCall")
        XCTAssertTrue(startCall.contains("UIApplication.shared.open(url)"), "startCall still opens the call URL")
    }

    /// The record is in Debug builds only: `CallRecorder.swift` is inside
    /// one `#if DEBUG`, with no `#else`, and the one use of `CallRecorder`
    /// in `startCall` is inside `#if DEBUG` too.
    func testTheCallRecordIsInDebugBuildsOnly() throws {
        let recorder = try ScreenText.source("Safeguarding/CallRecorder.swift")
        XCTAssertTrue(recorder.hasPrefix("#if DEBUG "), "CallRecorder.swift starts with #if DEBUG")
        XCTAssertTrue(recorder.hasSuffix(" #endif"), "CallRecorder.swift ends with #endif")
        XCTAssertEqual(recorder.components(separatedBy: "#if").count - 1, 1, "CallRecorder.swift has one #if")
        XCTAssertFalse(recorder.contains("#else") || recorder.contains("#elseif"), "CallRecorder.swift has no #else")

        var users: [String] = []
        for path in try appSwiftFiles() where path != "Safeguarding/CallRecorder.swift" {
            if try ScreenText.source(path).contains("CallRecorder") { users.append(path) }
        }
        XCTAssertEqual(users, ["Safeguarding/BeatContactsView.swift"], "only BeatContactsView.swift uses CallRecorder")
        let source = try ScreenText.source("Safeguarding/BeatContactsView.swift")
        XCTAssertEqual(source.components(separatedBy: "CallRecorder").count - 1, 1, "BeatContactsView.swift uses CallRecorder once")
        XCTAssertTrue(source.contains("#if DEBUG CallRecorder.record(url) #endif UIApplication.shared.open(url)"),
                      "startCall writes the record inside #if DEBUG, then opens the call URL")
    }

    /// The app project sets `DEBUG` only in its Debug configurations, so a
    /// Release build compiles nothing inside `#if DEBUG`.
    func testOnlyTheDebugConfigurationSetsDebug() throws {
        let project = try String(contentsOf: AppFiles.project, encoding: .utf8)
        var configurations: [(name: String, settings: [String])] = []
        var settings: [String]?
        for line in project.components(separatedBy: .newlines) {
            let text = line.trimmingCharacters(in: .whitespaces)
            if text.hasSuffix("isa = XCBuildConfiguration;") { settings = []; continue }
            guard settings != nil else { continue }
            if text.hasPrefix("name = ") {
                configurations.append((String(text.dropFirst(7).dropLast()), settings ?? []))
                settings = nil
            } else {
                settings?.append(text)
            }
        }
        func setsDebug(_ settings: [String]) -> Bool {
            settings.contains { line in
                (line.hasPrefix("SWIFT_ACTIVE_COMPILATION_CONDITIONS") || line.hasPrefix("OTHER_SWIFT_FLAGS"))
                    && line.split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "_" }).contains("DEBUG")
            }
        }
        let release = configurations.filter { $0.name == "Release" }
        XCTAssertFalse(release.isEmpty, "the project has a Release configuration")
        for configuration in release {
            XCTAssertFalse(setsDebug(configuration.settings), "a Release configuration sets DEBUG")
        }
        XCTAssertTrue(configurations.contains { $0.name == "Debug" && setsDebug($0.settings) }, "a Debug configuration sets DEBUG, so the UI tests' build holds the record")
    }
}
