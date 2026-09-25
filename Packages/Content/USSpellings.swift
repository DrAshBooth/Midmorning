import Foundation

/// US spellings the content test checks every card and catalogue string
/// against. The requirement "Plain UK English" needs a list the repository
/// holds; this is that list. It covers the common `-ize`/`-ise`,
/// `-or`/`-our`, `-er`/`-re` and `-og`/`-ogue` pairs a reviewer is likely to
/// type from habit.
public enum USSpellings {
    public static let list: [String] = [
        "realize", "realizes", "realized", "realizing",
        "recognize", "recognizes", "recognized", "recognizing",
        "organize", "organizes", "organized", "organizing",
        "apologize", "apologizes", "apologized", "apologizing",
        "color", "colors", "colored", "coloring",
        "favorite", "favorites",
        "behavior", "behaviors",
        "center", "centers", "centered",
        "meter", "meters",
        "liter", "liters",
        "practicing",
        "defense", "defenses",
        "license", "licenses",
        "catalog", "catalogs",
        "program", "programs",
        "traveled", "traveling", "traveler", "travelers",
        "modeling", "modeled",
        "canceled", "canceling",
        "gray",
        "mom", "moms",
        "toward",
        "analyze", "analyzes", "analyzed", "analyzing",
    ]

    /// The first US spelling `text` holds as a whole word, or `nil`.
    public static func firstMatch(in text: String) -> String? {
        WordMatcher.firstMatch(in: text, entries: list)
    }
}
