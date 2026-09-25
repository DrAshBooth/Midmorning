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
}

/// Fills a rule string's positional placeholders, for example turning
/// "Opens after %1$lld recorded days. You have %2$lld." into "Opens after 5
/// recorded days. You have 2." `Programme` owns this fill at runtime; the
/// content test uses the same function so its scenarios use one code path.
public enum PositionalFormat {
    public static func fill(_ text: String, with values: [Int]) -> String {
        String(format: text, arguments: values.map { $0 as CVarArg })
    }
}
