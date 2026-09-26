import Foundation
import XCTest

/// Ruling r13-19 (mm-t43.30): the manifest part of the device check on
/// mm-t41.15, "App Store label and Manifest". The privacy manifest is a
/// file in this repository, so a test reads it. The scenario is
/// data-and-privacy, "Manifest": "it lists 35F9.1 and C617.1, an empty
/// NSPrivacyCollectedDataTypes, no UserDefaults reason and no
/// active-keyboard reason". The label in App Store Connect ("Data Not
/// Collected") is not in this repository, so that part stays a check for
/// Ash.
final class PrivacyManifestTests: XCTestCase {
    private func manifest() throws -> [String: Any] {
        let data = try Data(contentsOf: AppFiles.appSources.appendingPathComponent("PrivacyInfo.xcprivacy"))
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try XCTUnwrap(plist as? [String: Any], "PrivacyInfo.xcprivacy is a dictionary")
    }

    /// The accessed API categories and their reasons, as the manifest lists them.
    private func reasonsByCategory() throws -> [String: [String]] {
        let entries = try XCTUnwrap(try manifest()["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        var result: [String: [String]] = [:]
        for entry in entries {
            let category = try XCTUnwrap(entry["NSPrivacyAccessedAPIType"] as? String)
            let reasons = try XCTUnwrap(entry["NSPrivacyAccessedAPITypeReasons"] as? [String])
            result[category, default: []].append(contentsOf: reasons)
        }
        return result
    }

    /// Scenario: Manifest. The two reasons, and no other category.
    func testTheManifestListsTheTwoReasons() throws {
        XCTAssertEqual(try reasonsByCategory(), [
            "NSPrivacyAccessedAPICategorySystemBootTime": ["35F9.1"],
            "NSPrivacyAccessedAPICategoryFileTimestamp": ["C617.1"],
        ])
    }

    /// Scenario: Manifest. "an empty NSPrivacyCollectedDataTypes".
    func testTheManifestCollectsNoDataType() throws {
        let collected = try XCTUnwrap(try manifest()["NSPrivacyCollectedDataTypes"] as? [Any])
        XCTAssertTrue(collected.isEmpty, "NSPrivacyCollectedDataTypes is empty")
    }

    /// Scenario: Manifest. "no UserDefaults reason and no active-keyboard reason".
    func testTheManifestHasNoUserDefaultsOrActiveKeyboardReason() throws {
        let categories = Set(try reasonsByCategory().keys)
        XCTAssertFalse(categories.contains("NSPrivacyAccessedAPICategoryUserDefaults"))
        XCTAssertFalse(categories.contains("NSPrivacyAccessedAPICategoryActiveKeyboards"))
    }

    /// data-and-privacy spec, "The app holds no analytics of its own": the
    /// manifest declares no tracking and no tracking domain.
    func testTheManifestDeclaresNoTracking() throws {
        let manifest = try manifest()
        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
        XCTAssertEqual((manifest["NSPrivacyTrackingDomains"] as? [Any])?.count, 0)
    }

    /// The app ships the manifest: the file is in the App target's
    /// synchronised folder, and the project names no exception that
    /// removes the file from the target.
    func testTheAppTargetShipsTheManifest() throws {
        let project = try String(contentsOf: AppFiles.project, encoding: .utf8)
        XCTAssertTrue(project.contains("isa = PBXFileSystemSynchronizedRootGroup;"), "the App target builds every file in App/Midmorning")
        XCTAssertTrue(project.contains("path = Midmorning;"))
        XCTAssertFalse(project.contains("PrivacyInfo.xcprivacy"), "no membership exception names the manifest")
        XCTAssertTrue(FileManager.default.fileExists(atPath: AppFiles.appSources.appendingPathComponent("PrivacyInfo.xcprivacy").path))
    }
}

/// The App target's files, found from this file's path, so that a test
/// reads them from any working directory that `swift test` uses.
enum AppFiles {
    static let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // AutomatedDeviceChecksTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent() // the repository root
    static let appSources = repositoryRoot.appendingPathComponent("App/Midmorning")
    static let project = repositoryRoot.appendingPathComponent("App/Midmorning.xcodeproj/project.pbxproj")
}
