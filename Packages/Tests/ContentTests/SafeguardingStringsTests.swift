import XCTest
@testable import Content

/// "the GP paragraph and its variants" (mm-t11.33), "the support sheet
/// strings" (mm-t11.34), "the not-right-now page strings" (mm-t11.35),
/// "the GP suggestion page strings" (mm-t11.36) and "the exclusion page
/// reason strings" (mm-t11.38). `safeguarding` owns every string's text;
/// content bundles it.
final class SafeguardingStringsTests: XCTestCase {
    // MARK: - mm-t11.33: the GP paragraph and its variants

    func testGPParagraphDefaultText() {
        XCTAssertEqual(
            Shipped.bundle.string(id: "gp.default")?.text,
            "I'd like to talk about my eating. I've been having times when I eat a lot and feel out of control. I've been following a self-help programme on my phone and I have a record I can show you. Can we talk about what support there is?"
        )
    }

    func testGPParagraphSelfHarmVariantAddsOneSentence() {
        let base = Shipped.bundle.string(id: "gp.default")!.text
        let selfHarm = Shipped.bundle.string(id: "gp.selfharm")!.text
        XCTAssertTrue(selfHarm.hasPrefix(base))
        XCTAssertEqual(selfHarm, base + " I've been having thoughts of hurting myself and I'd like to talk about that.")
    }

    func testGPParagraphUnder18Variant() {
        XCTAssertEqual(Shipped.bundle.string(id: "gp.under18")?.text, "I'd like to talk about my eating. Is there someone for people my age I can see?")
    }

    // MARK: - mm-t11.34: the support sheet strings

    func testSupportSheetOrderAndCoreText() {
        XCTAssertEqual(Shipped.bundle.string(id: "support.beat.title")?.text, "Beat helpline")
        XCTAssertEqual(Shipped.bundle.string(id: "support.beat.description")?.text, "Beat is the UK charity for people who struggle with eating.")
        XCTAssertEqual(Shipped.bundle.string(id: "support.beat.england")?.text, "England 0808 801 0677")
        XCTAssertEqual(Shipped.bundle.string(id: "support.beat.scotland")?.text, "Scotland 0808 801 0432")
        XCTAssertEqual(Shipped.bundle.string(id: "support.beat.wales")?.text, "Wales 0808 801 0433")
        XCTAssertEqual(Shipped.bundle.string(id: "support.beat.ni")?.text, "Northern Ireland 0808 801 0434")
        XCTAssertEqual(Shipped.bundle.string(id: "support.samaritans.number")?.text, "116 123")
        XCTAssertEqual(Shipped.bundle.string(id: "support.samaritans.welsh")?.text, "Samaritans in Welsh: 0808 164 0123.")
        XCTAssertEqual(Shipped.bundle.string(id: "support.lifeline.number")?.text, "0808 808 8000")
        XCTAssertEqual(Shipped.bundle.string(id: "support.nhs111.number")?.text, "111")
        XCTAssertEqual(Shipped.bundle.string(id: "support.emergency.title")?.text, "999")
    }

    func testSupportGPCompensationSentence() {
        XCTAssertEqual(
            Shipped.bundle.string(id: "support.gp.compensation")?.text,
            "Some people make themselves sick, use laxatives, or miss insulin or another medicine after eating. If that happens more than about twice a week, this programme isn't the right tool on its own. Talk to your GP first."
        )
    }

    func testTheCallWarningLineNamesNoPhoneBill() {
        // "The line MUST NOT mention a phone bill, because the helplines
        // are free and unitemised." No bundled string mentions one.
        let bill = Shipped.bundle.strings.filter { $0.id.hasPrefix("support.") }
            .first { WordMatcher.contains($0.text, entry: "phone bill") }
        XCTAssertNil(bill)
    }

    // MARK: - mm-t11.35: the not-right-now page strings

    func testNotRightNowSelfHarmAndWeightText() {
        XCTAssertEqual(
            Shipped.bundle.string(id: "notrightnow.selfharm")?.text,
            "You said you've had thoughts of hurting yourself. That deserves a person, not a programme. Samaritans are there any time, on 116 123. If you are in danger now, call 999."
        )
        XCTAssertEqual(
            Shipped.bundle.string(id: "notrightnow.weight")?.text,
            "Your weight has fallen to a point where this programme isn't the right tool for you. This is not a judgement about you. This is not a diagnosis. Your GP can look at this with you."
        )
    }

    /// Scenario: The not-right-now ids
    func testNotRightNowIdsAreExactlyTheseTwo() {
        let ids = Shipped.bundle.strings.map(\.id).filter { $0.hasPrefix("notrightnow.") }
        XCTAssertEqual(Set(ids), ["notrightnow.selfharm", "notrightnow.weight"])
    }

    func testNotRightNowHoldsNoWrittenPregnancyOrTreatmentString() {
        // "The bundle MUST NOT hold 'notrightnow.pregnancy' or
        // 'notrightnow.treatment'." Those reasons reuse the exclusion page
        // strings instead.
        XCTAssertNil(Shipped.bundle.string(id: "notrightnow.pregnancy"))
        XCTAssertNil(Shipped.bundle.string(id: "notrightnow.treatment"))
    }

    func testNotRightNowWeightPassesTheShortListDespiteHoldingDiagnosis() {
        let entry = Shipped.bundle.string(id: "notrightnow.weight")!
        XCTAssertTrue(WordMatcher.contains(entry.text, entry: "diagnosis"))
        XCTAssertEqual(ForbiddenList.firstMatch(in: entry.text, id: entry.id), nil)
    }

    // MARK: - mm-t11.36: the GP suggestion page strings

    func testGPSuggestionReasonText() {
        XCTAssertEqual(
            Shipped.bundle.string(id: "gpsuggestion.fallingweight")?.text,
            "Your weight has come down since you started. Your plan stays on. It's worth a word with your GP."
        )
        XCTAssertEqual(
            Shipped.bundle.string(id: "gpsuggestion.quickchange")?.text,
            "Your weight has changed quickly over the last four weeks. Your plan stays on. It's worth a word with your GP."
        )
        XCTAssertEqual(
            Shipped.bundle.string(id: "gpsuggestion.gettingworse")?.text,
            "You said things are getting worse. That's worth talking through with your GP. Your plan stays on."
        )
    }

    func testGPSuggestionDeteriorationFillsFromDeteriorationWeeks() {
        let entry = Shipped.bundle.string(id: "gpsuggestion.deterioration")!
        XCTAssertTrue(CatalogueRules.requiresPluralForms(entry.text))
        XCTAssertNotNil(entry.plural)
        XCTAssertEqual(
            PositionalFormat.fill(entry.plural!.other, with: [3]),
            "Your starred entries have gone up for 3 weeks in a row. That's worth talking through with your GP. Your plan stays on."
        )
    }

    // MARK: - mm-t11.38: the exclusion page reason strings

    func testExclusionReasonText() {
        XCTAssertEqual(
            Shipped.bundle.string(id: "exclusion.selfharm")?.text,
            "You said you've had thoughts of hurting yourself. That deserves a person, not a programme. Samaritans are there any time, on 116 123. If you are in danger now, call 999."
        )
        XCTAssertEqual(Shipped.bundle.string(id: "exclusion.age")?.text, "Midmorning is built for adults. Beat's Youthline is for anyone under 18: 0808 801 0711.")
        XCTAssertEqual(
            Shipped.bundle.string(id: "exclusion.weight")?.text,
            "Your height and weight put you in a range where this programme isn't the right tool for you. This is not a judgement about you. Your GP can look at this with you, and Beat can help you get there."
        )
        XCTAssertEqual(
            Shipped.bundle.string(id: "exclusion.pregnancy")?.text,
            "Pregnancy changes what eating needs to look like, and this programme isn't designed for that. Your GP or midwife can help with eating during pregnancy."
        )
        XCTAssertEqual(
            Shipped.bundle.string(id: "exclusion.treatment")?.text,
            "The people treating you are the right ones to decide what sits alongside it. Ask them about Midmorning. If they're happy, you can come back and start."
        )
    }

    func testExclusionSelfHarmAndNotRightNowSelfHarmShareTheSameText() {
        XCTAssertEqual(
            Shipped.bundle.string(id: "exclusion.selfharm")?.text,
            Shipped.bundle.string(id: "notrightnow.selfharm")?.text
        )
    }

    // MARK: - Family-wide checks

    func testAllSafeguardingStringsPassTheShortForbiddenList() {
        let entries = Shipped.bundle.strings.filter { entry in
            ForbiddenList.shortListPrefixes.contains { prefix in entry.id.hasPrefix(prefix) }
        }
        XCTAssertGreaterThan(entries.count, 30)
        XCTAssertEqual(ContentChecks.forbiddenWordsInStrings(entries), [])
    }

    func testAllSafeguardingStringsUseUKSpelling() {
        for entry in Shipped.bundle.strings where ForbiddenList.shortListPrefixes.contains(where: { entry.id.hasPrefix($0) }) {
            XCTAssertNil(USSpellings.firstMatch(in: entry.text), entry.id)
        }
    }
}
