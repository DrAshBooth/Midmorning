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
        XCTAssertTrue(Screen3Content.weighInExplanation.english.contains(OnboardingStrings.notWeightLossSentences[2]))
    }

    /// "No goal": no string in onboarding offers a goal weight, a target or
    /// a change in weight.
    func testNoGoalPhraseAnywhereInOnboarding() {
        let joined = OnboardingStrings.all.map(\.english).joined(separator: " ").lowercased()
        for phrase in OnboardingStrings.forbiddenGoalPhrases {
            XCTAssertFalse(joined.contains(phrase), "\"\(phrase)\" should not appear in onboarding")
        }
    }

    /// "Fields on the four screens": no onboarding string is a name, an
    /// email, a phone-number or a password prompt, or an offer to sign in.
    func testNoAccountFieldAnywhere() {
        let joined = OnboardingStrings.all.map(\.english).joined(separator: " ").lowercased()
        for phrase in ["email address", "phone number", "password", "sign in", "your name"] {
            XCTAssertFalse(joined.contains(phrase), "\"\(phrase)\" should not appear in onboarding")
        }
    }

    /// Screen 3, "Your start": every string comes from the app's catalogue
    /// (content spec, "Strings live in catalogues") and reads the onboarding
    /// spec's words. Scenarios "The three sentences" and "VoiceOver on the
    /// example".
    func testScreen3ReadsTheSpecsWordsFromTheCatalogue() {
        XCTAssertEqual(Screen3Content.threeSentences.map(\.english), [
            "Each time you eat or drink, you add an entry: the time and a few words on what it was.",
            "\"Toast and tea\" is a complete entry.",
            "There is one star, \"felt like a binge\", and only you decide when it applies.",
        ])
        XCTAssertEqual(Screen3Content.exampleTime, "13:05")
        XCTAssertEqual(Screen3Content.exampleWhat.english, "Toast and tea")
        XCTAssertEqual(Screen3Content.exampleVoiceOverLabel.english, "13:05, Toast and tea")
        XCTAssertEqual(Screen3Content.title.english, "Your start")
        XCTAssertEqual(Screen3Content.startDayQuestion.english, "When do you want to start?")
        XCTAssertEqual(Screen3Content.weighInDayHeading.english, "Weigh-in day")
        XCTAssertEqual(Screen3Content.wontBeWeighingChoice.english, "I won't be weighing")
        XCTAssertEqual(Screen3Content.weighInExplanation.english, "Once a week, on this day, the app asks for your weight and shows the trend. There is no goal and no target.")
        XCTAssertEqual(Screen3Content.quietHoursHeading.english, "Quiet hours")
        XCTAssertEqual(Screen3Content.unansweredMessage.english, "Please answer this one.")
    }

    /// The shared controls read the specs' words from the app's catalogue.
    func testTheSharedControlsReadTheSpecsWords() {
        let labels = [
            CommonLabels.continueLabel, CommonLabels.done, CommonLabels.cancel, CommonLabels.close, CommonLabels.call,
            CommonLabels.copyNumber, CommonLabels.copied, CommonLabels.yes, CommonLabels.no, CommonLabels.chosen,
            CommonLabels.exportControl, CommonLabels.gpParagraphAccessibilityLabel,
        ]
        XCTAssertEqual(labels.map(\.english), [
            "Continue", "Done", "Cancel", "Close", "Call", "Copy number", "Copied", "Yes", "No", "Chosen",
            "Export your record to take with you", "The GP paragraph",
        ])
    }

    func testScreen1ContentIsTheSevenLinesInOrder() {
        XCTAssertEqual(Screen1Content.lines.count, 7)
        XCTAssertEqual(Screen1Content.lines.last, "If you need a person, Get support is on every screen.")
    }
}
