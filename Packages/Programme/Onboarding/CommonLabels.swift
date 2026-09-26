import Foundation
import Constants

/// Small controls and answers this change's screens repeat verbatim, each
/// named by a spec ("Continue", "Done", "Talk to your GP" and the rest are
/// all quoted directly in the onboarding and safeguarding specs). One
/// shared constant keeps every screen agreeing, the same way `GPParagraph`
/// and `SupportSheet` keep their own repeated strings in one place.
///
/// The controls are keys in the app's string catalogue (content spec,
/// "Strings live in catalogues"). The last group is text that the clinical
/// reviewer signs off: support sheet names, screening answers and the
/// caution sheet. Decision mm-t11.41 names its source, so it stays here
/// until mm-t11.45 moves it.
public enum CommonLabels {
    public static let continueLabel: CatalogueText = .key("common.continue")
    public static let done: CatalogueText = .key("common.done")
    public static let cancel: CatalogueText = .key("common.cancel")
    public static let close: CatalogueText = .key("common.close")
    public static let call: CatalogueText = .key("common.call")
    public static let copyNumber: CatalogueText = .key("common.copyNumber")
    public static let copied: CatalogueText = .key("common.copied")
    public static let yes: CatalogueText = .key("common.yes")
    public static let no: CatalogueText = .key("common.no")
    public static let chosen: CatalogueText = .key("common.chosen")
    public static let exportControl: CatalogueText = .key("safeguarding.exportControl")
    public static let gpParagraphAccessibilityLabel: CatalogueText = .key("safeguarding.gpParagraph.accessibilityLabel")

    // Signed-off text: waits for decision mm-t11.41 (mm-t11.45).
    public static let ratherNotSay = "I'd rather not say"
    public static let doesNotApplyToMe = "Doesn't apply to me"
    public static let treatmentYesWithAgreement = "Yes, and they are happy for me to use this"
    public static let talkToYourGP = "Talk to your GP"
    public static let beatWebchat = "Beat webchat"
    public static let samaritansName = "Samaritans"
    public static let cautionSheetBody = "Your height and weight put you close to the range where this programme isn't the right tool. You can continue. If your weight falls, the app will say so and point you to your GP. If you're unsure, talk to your GP first."
}
