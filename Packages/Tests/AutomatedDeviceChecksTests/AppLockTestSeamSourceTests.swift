import Foundation
import XCTest

/// The app-lock test seam (`App/Midmorning/AppLock/AppLockTestSeam.swift`)
/// lets the UI tests in `tools/skeleton-checks/HarnessUITests` script the
/// system authentication request and the enrolment state hash (rulings
/// r13-19 and r16-01, epic mm-t45). A Release build must hold no part of
/// it. These tests prove that from the source:
/// - every line of the seam's file is inside `#if DEBUG`;
/// - each line in another App file that names the seam is inside
///   `#if DEBUG`, and only the two calls that the seam replaces name it;
/// - the Release configuration of the app project does not set `DEBUG`.
final class AppLockTestSeamSourceTests: XCTestCase {
    /// The names that only the seam has.
    private let seamNames = ["AppLockTestSeam", "ScriptedAuthenticator", "MIDMORNING_APP_LOCK_SCRIPT"]

    /// The App files that may name the seam: the seam itself, and the two
    /// places that it replaces (the authenticator and the enrolment hash).
    private let filesThatMayNameTheSeam: Set<String> = [
        "AppLock/AppLockTestSeam.swift",
        "AppLock/AppLockControllerFactory.swift",
        "AppLock/LocalAuthenticationAdapter.swift",
    ]

    /// One line of an App file with no comments, and whether the compiler
    /// sees it only when `DEBUG` is set: the line is inside the first branch
    /// of a `#if DEBUG` block.
    struct SourceLine {
        let text: String
        let debugOnly: Bool
        let isDirective: Bool
    }

    /// Splits `swift` into lines with no comments and marks each one.
    /// `ScreenText.withoutComments` keeps the line break after a `//`
    /// comment, so the lines stay as in the file.
    static func lines(of swift: String) -> [SourceLine] {
        enum Branch { case debug, notDebug, other }
        var stack: [Branch] = []
        var result: [SourceLine] = []
        for raw in ScreenText.withoutComments(swift).components(separatedBy: "\n") {
            let text = raw.trimmingCharacters(in: .whitespaces)
            let words = text.split(separator: " ").map(String.init)
            var isDirective = true
            switch words.first {
            case "#if":
                stack.append(words.dropFirst().joined(separator: " ") == "DEBUG" ? .debug : .other)
            case "#elseif", "#else":
                if let last = stack.popLast() { stack.append(last == .debug ? .notDebug : last) }
            case "#endif":
                _ = stack.popLast()
            default:
                isDirective = false
            }
            result.append(SourceLine(text: text, debugOnly: stack.contains(.debug), isDirective: isDirective))
        }
        return result
    }

    private func appSwiftFiles() throws -> [String] {
        let root = AppFiles.appSources
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        var paths: [String] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            paths.append(String(url.path.dropFirst(root.path.count + 1)))
        }
        return paths.sorted()
    }

    private func source(_ path: String) throws -> String {
        try String(contentsOf: AppFiles.appSources.appendingPathComponent(path), encoding: .utf8)
    }

    /// Every line of the seam's file is inside `#if DEBUG`: the first line
    /// with code is `#if DEBUG`, the last is its `#endif`, and each line
    /// between them is in the `DEBUG` branch.
    func testTheSeamFileIsInsideIfDebug() throws {
        let code = Self.lines(of: try source("AppLock/AppLockTestSeam.swift")).filter { !$0.text.isEmpty }
        XCTAssertEqual(code.first?.text, "#if DEBUG", "the seam's file starts with #if DEBUG")
        XCTAssertEqual(code.last?.text, "#endif", "the seam's file ends with #endif")
        XCTAssertGreaterThan(code.count, 10, "the seam's file holds the seam")
        for line in code.dropFirst().dropLast() {
            XCTAssertTrue(line.debugOnly, "this line of AppLockTestSeam.swift is outside #if DEBUG: \(line.text)")
        }
        XCTAssertTrue(code.contains { $0.text.contains("\"MIDMORNING_APP_LOCK_SCRIPT\"") }, "the seam turns on only with its launch environment variable")
    }

    /// Each line of the App target that names the seam is inside `#if
    /// DEBUG`, and only the files that the seam replaces name it. The
    /// authenticator and the enrolment hash do name it, so the UI tests
    /// reach the seam in a Debug build.
    func testEachUseOfTheSeamIsInsideIfDebug() throws {
        var filesThatNameTheSeam: Set<String> = []
        for path in try appSwiftFiles() {
            for line in Self.lines(of: try source(path)) where seamNames.contains(where: { line.text.contains($0) }) {
                filesThatNameTheSeam.insert(path)
                XCTAssertTrue(line.debugOnly, "\(path) names the seam outside #if DEBUG: \(line.text)")
            }
        }
        XCTAssertEqual(filesThatNameTheSeam.subtracting(filesThatMayNameTheSeam), [], "only the authenticator and the enrolment hash use the seam")
        let factory = Self.lines(of: try source("AppLock/AppLockControllerFactory.swift"))
        XCTAssertTrue(factory.contains { $0.debugOnly && $0.text.contains("ScriptedAuthenticator.fromLaunchEnvironment()") },
                      "the factory uses the scripted authenticator in a Debug build")
        XCTAssertTrue(factory.contains { !$0.debugOnly && $0.text == "return LAContextAuthenticator()" },
                      "the factory uses the real authenticator in every build")
        let adapter = Self.lines(of: try source("AppLock/LocalAuthenticationAdapter.swift"))
        XCTAssertTrue(adapter.contains { $0.debugOnly && $0.text.contains("AppLockTestSeam.currentScript()") },
                      "the enrolment hash reads the script in a Debug build")
    }

    /// The marking itself: a line after `#else` of a `#if DEBUG` block is
    /// not `DEBUG` only, and a nested block keeps the outer `DEBUG`.
    func testTheDirectiveScan() {
        let lines = Self.lines(of: """
        a
        #if DEBUG
        b
        #if os(iOS)
        c
        #endif
        #else
        d
        #endif
        e // AppLockTestSeam in a comment
        """)
        let marks = Dictionary(lines.filter { !$0.isDirective }.map { ($0.text, $0.debugOnly) }, uniquingKeysWith: { first, _ in first })
        XCTAssertEqual(marks["a"], false)
        XCTAssertEqual(marks["b"], true)
        XCTAssertEqual(marks["c"], true)
        XCTAssertEqual(marks["d"], false)
        XCTAssertEqual(marks["e"], false)
        XCTAssertFalse(lines.contains { $0.text.contains("AppLockTestSeam") }, "a comment is not code")
    }

    /// The app project sets `DEBUG` only in its Debug configurations. So a
    /// Release build compiles no line inside `#if DEBUG`.
    func testTheReleaseConfigurationDoesNotSetDebug() throws {
        let project = try String(contentsOf: AppFiles.project, encoding: .utf8)
        var releaseBlocks: [String] = []
        var debugBlocks: [String] = []
        var rest = Substring(project)
        while let start = rest.range(of: "isa = XCBuildConfiguration;") {
            let after = rest[start.upperBound...]
            guard let end = after.range(of: "name = ") else { break }
            let settings = String(after[..<end.lowerBound])
            let name = after[end.upperBound...].prefix { $0 != ";" }
            if name == "Release" { releaseBlocks.append(settings) }
            if name == "Debug" { debugBlocks.append(settings) }
            rest = after[end.upperBound...]
        }
        XCTAssertFalse(releaseBlocks.isEmpty, "the project has Release configurations")
        for block in releaseBlocks {
            for setting in Self.swiftConditionSettings(in: block) {
                XCTAssertFalse(Self.namesDebug(setting), "a Release configuration sets DEBUG: \(setting)")
            }
        }
        XCTAssertTrue(debugBlocks.contains { Self.swiftConditionSettings(in: $0).contains(where: Self.namesDebug) },
                      "the Debug configuration sets DEBUG, so the UI tests' build holds the seam")
    }

    /// The settings of one configuration that can give Swift the condition
    /// `DEBUG`: the active compilation conditions and the other Swift
    /// flags, each as "NAME = value;".
    static func swiftConditionSettings(in block: String) -> [String] {
        let names = ["SWIFT_ACTIVE_COMPILATION_CONDITIONS", "OTHER_SWIFT_FLAGS"]
        return block.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { setting in names.contains { setting.hasPrefix("\($0) = ") } }
    }

    /// Whether the value of a setting names the word `DEBUG`, not only a
    /// longer name such as `DEBUG_INFORMATION_FORMAT`.
    static func namesDebug(_ setting: String) -> Bool {
        guard let equals = setting.range(of: " = ") else { return false }
        let value = setting[equals.upperBound...]
        return value.range(of: #"(^|[^A-Za-z0-9_])DEBUG([^A-Za-z0-9_]|$)"#, options: .regularExpression) != nil
    }
}
