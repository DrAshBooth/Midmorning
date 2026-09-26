import Foundation
import Constants

/// "Your start", onboarding screen 3 (onboarding spec, "Screen 3: the start
/// day", "Screen 3: weigh-in day and quiet hours" and "Screen 3: the record
/// in three sentences"). Each string is a key in the app's string catalogue,
/// never English (content spec, "Strings live in catalogues"): the App
/// target fills it with `CatalogueText.string`, and a test fills it from the
/// same catalogue. "Weigh-in day" and "I won't be weighing" also label the
/// weigh-in screen's and the settings screen's weigh-in day controls.
public enum Screen3Content {
    public static let title: CatalogueText = .key("onboarding.screen3.title")
    public static let startDayQuestion: CatalogueText = .key("onboarding.startDay.question")

    public static let threeSentences: [CatalogueText] = [
        .key("onboarding.record.sentence1"),
        .key("onboarding.record.sentence2"),
        .key("onboarding.record.sentence3"),
    ]
    /// The example row's time, "13:05": a time, not a word, in the app's
    /// one "HH:mm" form.
    public static let exampleTime = ClockTime.string(hour: 13, minute: 5)
    public static let exampleWhat: CatalogueText = .key("onboarding.example.what")
    /// Scenario "VoiceOver on the example": "13:05, Toast and tea".
    public static let exampleVoiceOverLabel: CatalogueText = .list([.verbatim(exampleTime), exampleWhat])

    public static let weighInDayHeading: CatalogueText = .key("weighIn.day")
    public static let wontBeWeighingChoice: CatalogueText = .key("weighIn.wontBeWeighing")
    public static let weighInExplanation: CatalogueText = .key("onboarding.weighIn.explanation")
    /// The same "Quiet hours" key the Reminders group shows.
    public static let quietHoursHeading: CatalogueText = .key("settings.reminders.quietHours")
    public static let unansweredMessage: CatalogueText = .key("onboarding.unanswered")
}
