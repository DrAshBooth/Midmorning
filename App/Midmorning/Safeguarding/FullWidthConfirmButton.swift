import SwiftUI
import Constants

/// The confirming action of a screen that shows Get support: a full-width
/// button below the content (safeguarding spec, "Get support on every
/// screen": "On a screen that shows Get support, the confirming action MUST
/// be a full-width button below the content."). The frame sits on the
/// label, inside the button style, so the filled shape spans the width.
struct FullWidthConfirmButton: View {
    private let label: Text
    private let action: () -> Void

    /// A title from a Programme constant that is not catalogue text yet,
    /// such as `Screen4Content.startLabel`.
    @_disfavoredOverload
    init(_ title: String, action: @escaping () -> Void) {
        self.label = Text(title)
        self.action = action
    }

    /// A catalogue key from a package, such as `CommonLabels.done`, filled
    /// from the app's string catalogue.
    init(_ text: CatalogueText, action: @escaping () -> Void) {
        self.label = Text(text.string)
        self.action = action
    }

    /// A key in Localizable.xcstrings.
    init(_ key: LocalizedStringKey, action: @escaping () -> Void) {
        self.label = Text(key)
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            label.frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}
