import Foundation

/// The fixed content the four onboarding screens show verbatim (onboarding
/// spec). Keeping it here, not only in the App target's views, lets a
/// `swift test` run prove wording, order and the "Not weight loss, three
/// times" and "What is a treatment claim" constraints, because the App
/// target itself has no test target `./verify` runs.
public enum Screen1Content {
    public static let title = "What this is and isn't"
    public static let lines: [String] = [
        "Midmorning is a 12-week self-help programme for people who binge eat. It uses ideas from CBT.",
        "It is not a diet, and it is not for weight loss.",
        "It is not therapy, and it does not replace your GP or anyone treating you.",
        SupportSheet.compensationLine,
        "If you have had anorexia or another restrictive eating problem in the past, talk to your GP before you start. The weekly weigh-in may not be right for you.",
        "No person and no AI reads what you write. The app counts your starred entries, times and places to build your weekly review, on this device only.",
        "If you need a person, Get support is on every screen.",
    ]
    public static let continueLabel = "Continue"
}

public enum Screen2Content {
    public static let title = "A few questions first"
    public static let ageQuestion = "How old are you?"
    public static let heightQuestion = "Your height"
    public static let weightQuestion = "Your weight"
    public static let heightWeightIntro = "We ask for your height and weight to check this programme is safe for you. The app never shows them again and never sets a goal from them."
    public static let treatmentQuestion = "Are you getting help from a clinic or a therapist for your eating at the moment?"
    public static let pregnancyQuestion = "We ask everyone the same questions. Pregnancy changes what eating needs to look like, so: are you pregnant at the moment?"
    public static let unansweredMessage = "Please answer this one."
    public static let continueLabel = "Continue"
}

public enum Screen3Content {
    public static let title = "Your start"
    public static let startDayQuestion = "When do you want to start?"

    public static let threeSentences: [String] = [
        "Each time you eat or drink, you add an entry: the time and a few words on what it was.",
        "\"Toast and tea\" is a complete entry.",
        "There is one star, \"felt like a binge\", and only you decide when it applies.",
    ]
    public static let exampleTime = "13:05"
    public static let exampleWhat = "Toast and tea"
    public static let exampleVoiceOverLabel = "\(exampleTime), \(exampleWhat)"

    public static let weighInDayHeading = "Weigh-in day"
    public static let wontBeWeighingChoice = "I won't be weighing"
    public static let weighInExplanation = "Once a week, on this day, the app asks for your weight and shows the trend. There is no goal and no target."
    public static let quietHoursHeading = "Quiet hours"
    public static let unansweredMessage = "Please answer this one."
}

public enum Screen4Content {
    public static let title = "Permissions"
    public static let widgetInstructions = "Touch and hold your Lock Screen, tap Customise, then Lock Screen, then add Midmorning."
    public static let yourRecordHeading = "Your record"
    public static let yourRecordSentence = "Your record, plan and weigh-ins are private and sensitive."
    public static let thisDeviceOnly = "This device only"
    public static let iCloudLaterVersion = "iCloud sync comes in a later version."

    public static let notificationsExplanation = "Midmorning sends reminders for your plan and your reviews. You choose which ones and when in Settings. Each reminder shows the app name and a time, nothing more."
    public static let allowNotifications = "Allow notifications"

    public static let widgetExplanation = "Add the Lock Screen widget to record in one tap."
    public static let showMeHow = "Show me how"

    public static let startLabel = "Start"
}

/// Every user-facing string the four onboarding screens show, for the
/// "No goal", "Not weight loss, three times" and "No account" reviewer
/// scenarios to scan as a single list.
public enum OnboardingStrings {
    public static let all: [String] =
        Screen1Content.lines + [
            Screen2Content.ageQuestion, Screen2Content.heightQuestion, Screen2Content.weightQuestion,
            Screen2Content.heightWeightIntro, Screen2Content.treatmentQuestion, Screen2Content.pregnancyQuestion,
        ] + Screen3Content.threeSentences + [
            Screen3Content.weighInExplanation, Screen3Content.weighInDayHeading, Screen3Content.wontBeWeighingChoice,
        ] + [
            Screen4Content.yourRecordSentence, Screen4Content.iCloudLaterVersion,
            Screen4Content.notificationsExplanation, Screen4Content.widgetExplanation,
        ]

    /// "Not weight loss, three times": these three sentences, one on each
    /// of screens 1, 2 and 3, each saying the programme is not for weight loss.
    public static let notWeightLossSentences: [String] = [
        "It is not a diet, and it is not for weight loss.",
        "The app never shows them again and never sets a goal from them.",
        "There is no goal and no target.",
    ]

    /// A phrase that would offer a goal weight, a target or a change in
    /// weight. None of `all` may contain one, outside the fixed negative
    /// sentences above.
    public static let forbiddenGoalPhrases = ["goal weight", "lose weight", "weight loss goal", "target weight", "your target"]
}
