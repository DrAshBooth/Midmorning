import Foundation

/// One reviewed string in the content bundle, outside the card catalogue:
/// an opening sentence, a rule string, a Today card string, a reflection
/// question and so on. `id` is the family id from "Every bundled string
/// family has ids".
public struct StringEntry: Sendable, Equatable, Codable, Identifiable {
    public let id: String
    public let text: String
    public let plural: PluralForms?

    public init(id: String, text: String, plural: PluralForms? = nil) {
        self.id = id
        self.text = text
        self.plural = plural
    }

    /// The form the app shows for `count`: the plural form for that count
    /// when the entry has plural forms, otherwise the text. An entry holds
    /// at most one count (ruling r13-12), so one count picks the form.
    public func form(for count: Int) -> String {
        plural?.text(for: count) ?? text
    }
}

/// Fills a string's count placeholders, for example turning "Opens after
/// %lld recorded days." into "Opens after 5 recorded days." `Programme`
/// owns this fill at runtime; the content test uses the same function so its
/// scenarios use one code path. A `%@` placeholder takes text, not a count,
/// so this function never fills one.
public enum PositionalFormat {
    public static func fill(_ text: String, with values: [Int]) -> String {
        String(format: text, arguments: values.map { $0 as CVarArg })
    }
}
