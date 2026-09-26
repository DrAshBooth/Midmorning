import Foundation
import XCTest
import Constants

/// Ruling r13-19 (mm-t43.30): the text part of item 2 on mm-t13.8,
/// "Privacy notice". The scenario is data-and-privacy, "Privacy notice":
/// "the notice opens and holds the controller, the contact, who reads the
/// contact inbox, Apple, the App Analytics line, the backup line and the
/// ICO". This test proves that the notice screen shows each part from the
/// string catalogue that the app ships. The skeleton check
/// `AutomatedChecks.testPrivacyNotice` proves the route and that the
/// screen shows the words on the simulator.
final class PrivacyNoticeTextTests: XCTestCase {
    /// Each part of the notice: its catalogue key, and words that its
    /// English text must hold.
    private let parts: [(key: String, words: String)] = [
        ("settings.privacyNotice.controller.heading", "Who controls your data"),
        ("settings.privacyNotice.controller.body", "controller"),
        ("settings.privacyNotice.contact.heading", "Contact"),
        ("settings.privacyNotice.contact.whoReads", "reads this inbox"),
        ("settings.privacyNotice.apple.heading", "Apple"),
        ("settings.privacyNotice.apple.body", "Apple"),
        ("settings.privacyNotice.analytics.body", "App Analytics"),
        ("settings.privacyNotice.backup.body", "backup"),
        ("settings.privacyNotice.complaints.body", "(ICO)"),
    ]

    func testTheCatalogueHoldsEachPartOfTheNotice() throws {
        let catalogue = try StringCatalogue.appCatalogue()
        for part in parts {
            let english = try catalogue.render(.key(part.key))
            XCTAssertTrue(english.contains(part.words), "\(part.key) reads \"\(english)\", not \"\(part.words)\"")
        }
    }

    func testTheNoticeScreenShowsEachPart() throws {
        let source = try String(contentsOf: AppFiles.appSources.appendingPathComponent("PrivacyNoticeView.swift"), encoding: .utf8)
        for part in parts {
            XCTAssertTrue(source.contains("\"\(part.key)\""), "PrivacyNoticeView shows \(part.key)")
        }
        XCTAssertTrue(source.contains("Text(contactEmail)"), "the notice shows the contact address")
        XCTAssertTrue(source.contains(".getSupport()"), "the notice has Get support")
    }

    /// The contact address that the notice shows comes from the content
    /// bundle ("about.contact"). It must not be empty.
    func testTheContentBundleHoldsTheContactAddress() throws {
        let url = AppFiles.repositoryRoot.appendingPathComponent("Packages/Content/Resources/strings.json")
        let strings = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [[String: Any]])
        let contact = strings.first { $0["id"] as? String == "about.contact" }?["text"] as? String
        XCTAssertTrue(contact?.contains("@") == true, "about.contact is an email address")
    }
}
