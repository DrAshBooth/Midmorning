import Foundation
import XCTest
import Constants
import Content

/// Ruling r13-19 (mm-t43.30): two text checks on mm-t21.24.
///
/// - mm-t21.35 (commit 5062ef7): "on Today, the stage 1 card row shows the
///   card title ('Read' and 'Close'), the plan card shows 'Your plan isn't
///   set yet. It takes about two minutes.', and the stage 2 opening card
///   shows its sentence." The Instruments part of that check (no
///   `BundleLoader.load` call while Today scrolls) stays a device check.
/// - mm-t21.29 (commit 13a84d5): "on a team build with no sign-off file ...
///   The line 'Draft' shows above the card title. Settings, About, still
///   shows 'Draft' beside the content version." This test proves the
///   draft rule and the words; the layout ("above", "beside") is
///   `AutomatedChecks.testDraftShowsAboveTheCardTitle` on the simulator.
///
/// The tests read the content bundle that the app ships
/// (`BundleLoader.loadShipped`, as `ShippedContent` and `SettingsView` do)
/// and the App files that show the words.
final class ProgrammeScreenTextTests: XCTestCase {
    private func shippedBundle() throws -> ContentBundle {
        try BundleLoader.loadShipped(environment: [:])
    }

    func testTodaysCardRowsShowTheirWords() throws {
        let bundle = try shippedBundle()
        let stage1Cards = bundle.activeCards(in: .stage(1))
        XCTAssertGreaterThanOrEqual(stage1Cards.count, 2, "two stage 1 cards come to Today")
        for card in stage1Cards {
            XCTAssertFalse(card.title.isEmpty, "the stage 1 card \(card.id) has a title")
        }
        XCTAssertEqual(bundle.string(id: "todaycard.plan")?.text, "Your plan isn't set yet. It takes about two minutes.")
        XCTAssertEqual(bundle.string(id: "opening.stage2")?.text, "You can now plan when to eat. The app reminds you at each planned meal.")
        XCTAssertEqual(ScreenText.english(.key("programme.card.read")), "Read")
        XCTAssertEqual(ScreenText.english(.key("programme.card.close")), "Close")
        XCTAssertEqual(ScreenText.english(.key("programme.card.open")), "Open")
        XCTAssertEqual(ScreenText.english(.key("programme.card.setItUp")), "Set it up")
        try ScreenText.assertScreen("Programme/TodayCardSlotView.swift", shows: [
            "bundle?.card(id: card.id)?.title",
            "bundle?.string(id: \"todaycard.plan\")?.text",
            "bundle?.string(id: \"opening.stage\\($0.rawValue)\")?.text",
            "Text(title)",
            "Text(line)",
            "case .stage1: return \"programme.card.read\"",
            "Button(action: onClose) { Text(\"programme.card.close\").minimumHitArea() }",
        ])
        try ScreenText.assertScreen("TodayView.swift", shows: ["TodayCardSlotView(card: pendingCard"])
    }

    func testADraftBundleShowsDraftOnTheCardAndInAbout() throws {
        // A team build with no sign-off file: the bundle's three content
        // files, and nothing else.
        let shipped = AppFiles.repositoryRoot.appendingPathComponent("Packages/Content/Resources")
        let unsigned = FileManager.default.temporaryDirectory.appendingPathComponent("unsigned-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: unsigned, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: unsigned) }
        for name in ["manifest.json", "cards.json", "strings.json"] {
            try FileManager.default.copyItem(at: shipped.appendingPathComponent(name), to: unsigned.appendingPathComponent(name))
        }
        XCTAssertTrue(try BundleLoader.load(from: unsigned, environment: [:]).isDraft, "a bundle with no sign-off file is a draft")
        XCTAssertEqual(ScreenText.english(.key("programme.card.draft")), "Draft")
        XCTAssertEqual(ScreenText.english(.key("settings.about.draftBadge")), "Draft")
        // Source text only: the card screen's stack lists "Draft" before the
        // title. AutomatedChecks.testDraftShowsAboveTheCardTitle checks the
        // layout on the simulator.
        let card = try ScreenText.source("Programme/CardScreenView.swift")
        let draftLine = try XCTUnwrap(ScreenText.range(of: "Text(\"programme.card.draft\")", in: card), "the card screen shows \"Draft\"")
        let title = try XCTUnwrap(ScreenText.range(of: "Text(screen.title)", in: card), "the card screen shows the title")
        XCTAssertLessThan(draftLine.lowerBound, title.lowerBound, "the card screen's stack lists \"Draft\" before the card title")
        try ScreenText.assertScreen("Programme/CardScreenView.swift", shows: ["isDraft = bundle.isDraft"])
        try ScreenText.assertScreen("SettingsView.swift", shows: ["if contentInfo?.isDraft == true", "Text(\"settings.about.draftBadge\")"])
    }
}
