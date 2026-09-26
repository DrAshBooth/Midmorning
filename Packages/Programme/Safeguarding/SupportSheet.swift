import Foundation

/// The support sheet's fixed content and order (safeguarding spec, "The
/// support sheet"). Every number and link is bundled here, never fetched
/// from a network. A reviewer checks each number, its hours and the webchat
/// URL against the service's own website before every release and writes a
/// dated line in the change README (the "Release check" scenario).
public enum SupportSheet {
    public struct NumberEntry: Sendable, Equatable {
        public let label: String
        public let number: String
        public init(label: String, number: String) {
            self.label = label
            self.number = number
        }
    }

    public enum Item: Sendable, Equatable, CaseIterable {
        case beatHelpline, beatWebchat, samaritans, lifelineNI, nhs111, emergency999, talkToYourGP
    }

    public static let title = "Get support"

    public static let beatIntro = "Beat is the UK charity for people who struggle with eating."
    public static let beatNumbers: [NumberEntry] = [
        NumberEntry(label: "England", number: "0808 801 0677"),
        NumberEntry(label: "Scotland", number: "0808 801 0432"),
        NumberEntry(label: "Wales", number: "0808 801 0433"),
        NumberEntry(label: "Northern Ireland", number: "0808 801 0434"),
    ]
    public static let beatHoursLine = "Opening hours are on Beat's website."
    // A reviewer confirms this URL against Beat's own website before every
    // release (the "Release check" scenario); the change README holds the
    // dated line.
    public static let beatWebchatURLString = "https://www.beateatingdisorders.org.uk/get-information-and-support/get-help-for-myself/i-need-support-now/one-to-one-webchat/"

    public static let samaritansNumber = "116 123"
    public static let samaritansLine = "Any time, about anything."
    public static let samaritansWelshNumber = "0808 164 0123"

    public static let lifelineNumber = "0808 808 8000"
    public static let lifelineLine = "Any time."

    public static let nhs111Number = "111"
    public static let nhs111Line = "When you need help and it's not an emergency."
    public static let nhs111RegionLine = "England, Scotland and Wales. In Northern Ireland, call your GP out-of-hours service."

    public static let emergencyNumber = "999"
    public static let emergencyLine = "If you are in danger now."

    /// The sentence about making yourself sick, using laxatives or missing
    /// medicine, shown above the GP paragraph in "Talk to your GP" (onboarding
    /// screen 1 shows the same sentence).
    public static let compensationLine = "Some people make themselves sick, use laxatives, or miss insulin or another medicine after eating. If that happens more than about twice a week, this programme isn't the right tool on its own. Talk to your GP first."

    public static let callRecentsWarning = "This call will show in your phone's Recents."
    public static let copiedConfirmationLine = "Copied. It clears in a minute."
    public static let pasteboardExpirySeconds: TimeInterval = 60

    /// The list's default order.
    public static let defaultOrder: [Item] = [.beatHelpline, .beatWebchat, .samaritans, .lifelineNI, .nhs111, .emergency999, .talkToYourGP]

    /// From a self-harm reason, "Samaritans" MUST be the first item.
    public static func order(fromSelfHarmReason: Bool) -> [Item] {
        guard fromSelfHarmReason else { return defaultOrder }
        return [.samaritans] + defaultOrder.filter { $0 != .samaritans }
    }
}
