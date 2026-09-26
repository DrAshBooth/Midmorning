import XCTest
@testable import Programme

/// Onboarding spec, "Not weight loss, three times" (mm-t14.13) and "No
/// account" (mm-t14.2).
final class OnboardingContentTests: XCTestCase {
    /// "Three sentences on three screens": the three sentences appear on
    /// screens 1, 2 and 3, each in different words.
    func testThreeSentencesOnThreeScreens() {
        XCTAssertTrue(Screen1Content.lines.contains(OnboardingStrings.notWeightLossSentences[0]))
        XCTAssertTrue(Screen2Content.heightWeightIntro.contains(OnboardingStrings.notWeightLossSentences[1]))
        XCTAssertTrue(Screen3Content.weighInExplanation.contains(OnboardingStrings.notWeightLossSentences[2]))
    }

    /// "No goal": no string in onboarding offers a goal weight, a target or
    /// a change in weight.
    func testNoGoalPhraseAnywhereInOnboarding() {
        let joined = OnboardingStrings.all.joined(separator: " ").lowercased()
        for phrase in OnboardingStrings.forbiddenGoalPhrases {
            XCTAssertFalse(joined.contains(phrase), "\"\(phrase)\" should not appear in onboarding")
        }
    }

    /// "Fields on the four screens": no onboarding string is a name, an
    /// email, a phone-number or a password prompt, or an offer to sign in.
    func testNoAccountFieldAnywhere() {
        let joined = OnboardingStrings.all.joined(separator: " ").lowercased()
        for phrase in ["email address", "phone number", "password", "sign in", "your name"] {
            XCTAssertFalse(joined.contains(phrase), "\"\(phrase)\" should not appear in onboarding")
        }
    }

    func testScreen1ContentIsTheSevenLinesInOrder() {
        XCTAssertEqual(Screen1Content.lines.count, 7)
        XCTAssertEqual(Screen1Content.lines.last, "If you need a person, Get support is on every screen.")
    }
}
