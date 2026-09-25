import SwiftUI
import UIKit

/// The shared appearance rule of every screen (product-rules spec,
/// "Appearance", decision 92). Every screen after `record-full` uses these
/// modifiers and adds no appearance modifier of its own. The team changes
/// the accent colour in the `AccentColor` asset only.
enum Appearance {
    /// The row background's assumed colour, for a caller that documents a
    /// contrast ratio: `.systemBackground` under the plain list style, white
    /// in light mode and black in dark mode.
    static let accentContrastNote = "AccentColor: light 1F4E79 vs white 8.7:1; dark 7CB4E6 vs black 9.5:1; Increase Contrast 5078A0 vs white 4.6:1 and vs black 4.5:1."
}

public extension View {
    /// The plain list style, with no grouped-style section fill, for every
    /// list in the app.
    func recordListStyle() -> some View {
        self.listStyle(.plain)
    }

    /// The system sheet at the large detent, for a screen that asks the
    /// person for an answer (product-rules spec, "Appearance": "A screen
    /// that asks the person for an answer MUST open as a sheet").
    func recordSheetDetent() -> some View {
        self.presentationDetents([.large])
    }
}

/// A field that fills the width of its row, with its label above it and its
/// text at the leading edge (product-rules spec, "Appearance"). The visible
/// label is hidden from VoiceOver; `accessibilityLabelText` carries the
/// spoken label once, on the field itself.
struct RecordField: View {
    let label: Text
    @Binding var text: String
    var isFocused: Binding<Bool>?
    var onReturn: (() -> Void)?
    var accessibilityLabelText: String
    var onSaveFromKeyboard: (() -> Void)?

    init(
        label: Text,
        text: Binding<String>,
        isFocused: Binding<Bool>? = nil,
        onReturn: (() -> Void)? = nil,
        accessibilityLabelText: String,
        onSaveFromKeyboard: (() -> Void)? = nil
    ) {
        self.label = label
        self._text = text
        self.isFocused = isFocused
        self.onReturn = onReturn
        self.accessibilityLabelText = accessibilityLabelText
        self.onSaveFromKeyboard = onSaveFromKeyboard
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            label
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            PredictiveTextView(text: $text, isFocused: isFocused, onReturn: onReturn, accessibilityLabelText: accessibilityLabelText, onSaveFromKeyboard: onSaveFromKeyboard)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A text field that keeps autocorrection and sentence capitalisation on and
/// turns off the keyboard's inline predictions (product-rules spec,
/// "Appearance"; record spec, decision 89). SwiftUI's `TextField` and
/// `TextEditor` expose no modifier for `UITextInputTraits.inlinePredictionType`,
/// so this wraps `UITextView` directly. `onReturn`, when set, makes Return
/// call it instead of inserting a line break, for a one-line field such as
/// "Add a place".
struct PredictiveTextView: UIViewRepresentable {
    @Binding var text: String
    var isFocused: Binding<Bool>?
    var onReturn: (() -> Void)?
    var accessibilityLabelText: String?
    /// When set, the keyboard's own toolbar shows a trailing "Save" control
    /// that calls this (record spec, "The new-entry screen's controls":
    /// "the keyboard's toolbar MUST show a control 'Save' at its trailing
    /// end"). SwiftUI's `.toolbar(placement: .keyboard)` only attaches to a
    /// native `TextField`/`TextEditor`'s first responder, not to a
    /// representable's own `UITextView`, so this sets `inputAccessoryView`
    /// directly.
    var onSaveFromKeyboard: (() -> Void)?

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.autocorrectionType = .yes
        view.autocapitalizationType = .sentences
        view.spellCheckingType = .yes
        view.inlinePredictionType = .no
        view.returnKeyType = onReturn != nil ? .done : .default
        view.text = text
        view.accessibilityLabel = accessibilityLabelText
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        if onSaveFromKeyboard != nil {
            view.inputAccessoryView = context.coordinator.makeAccessoryToolbar()
        }
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text { uiView.text = text }
        if uiView.accessibilityLabel != accessibilityLabelText { uiView.accessibilityLabel = accessibilityLabelText }
        let wantsFocus = isFocused?.wrappedValue ?? false
        if wantsFocus, !uiView.isFirstResponder {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        } else if !wantsFocus, uiView.isFirstResponder {
            DispatchQueue.main.async { uiView.resignFirstResponder() }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: PredictiveTextView
        init(_ parent: PredictiveTextView) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) { parent.text = textView.text }
        func textViewDidBeginEditing(_ textView: UITextView) { parent.isFocused?.wrappedValue = true }
        func textViewDidEndEditing(_ textView: UITextView) { parent.isFocused?.wrappedValue = false }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n", let onReturn = parent.onReturn {
                onReturn()
                return false
            }
            return true
        }

        func makeAccessoryToolbar() -> UIToolbar {
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
            let save = UIBarButtonItem(title: NSLocalizedString("entry.save", comment: ""), style: .done, target: self, action: #selector(saveTapped))
            save.accessibilityTraits = .button
            toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), save]
            toolbar.sizeToFit()
            return toolbar
        }

        @objc func saveTapped() { parent.onSaveFromKeyboard?() }
    }
}

/// A one-line text field for a short value such as "Add a place" — the same
/// traits as `PredictiveTextView`, laid out on one line with no growth.
struct RecordOneLineField: View {
    @Binding var text: String
    var isFocused: Binding<Bool>?
    var onReturn: (() -> Void)?
    let accessibilityLabelText: String
    var onSaveFromKeyboard: (() -> Void)?

    var body: some View {
        PredictiveTextView(text: $text, isFocused: isFocused, onReturn: onReturn, accessibilityLabelText: accessibilityLabelText, onSaveFromKeyboard: onSaveFromKeyboard)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A layout that wraps a set of chips onto more lines and never scrolls to
/// the side (product-rules spec, "Appearance").
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0, rowWidth + spacing + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += (rowWidth > 0 ? spacing : 0) + size.width
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        let width = maxWidth.isFinite ? maxWidth : rowWidth
        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
