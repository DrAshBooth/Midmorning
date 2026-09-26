import Foundation

/// Small controls and answers this change's screens repeat verbatim, each
/// named by a spec ("Continue", "Done", "Talk to your GP" and the rest are
/// all quoted directly in the onboarding and safeguarding specs). One
/// shared constant keeps every screen agreeing, the same way `GPParagraph`
/// and `SupportSheet` keep their own repeated strings in one place.
public enum CommonLabels {
    public static let continueLabel = "Continue"
    public static let done = "Done"
    public static let cancel = "Cancel"
    public static let close = "Close"
    public static let call = "Call"
    public static let copyNumber = "Copy number"
    public static let copied = "Copied"
    public static let yes = "Yes"
    public static let no = "No"
    public static let ratherNotSay = "I'd rather not say"
    public static let doesNotApplyToMe = "Doesn't apply to me"
    public static let treatmentYesWithAgreement = "Yes, and they are happy for me to use this"
    public static let talkToYourGP = "Talk to your GP"
    public static let beatWebchat = "Beat webchat"
    public static let exportControl = "Export your record to take with you"
    public static let gpParagraphAccessibilityLabel = "The GP paragraph"
    public static let samaritansName = "Samaritans"
    public static let chosen = "Chosen"
    public static let cautionSheetBody = "Your height and weight put you close to the range where this programme isn't the right tool. You can continue. If your weight falls, the app will say so and point you to your GP. If you're unsure, talk to your GP first."
}
