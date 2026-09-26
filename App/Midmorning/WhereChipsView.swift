import SwiftUI
import Record

/// The Where control: the four fixed chips, the person's custom places, and
/// "Add a place" (record spec, "Where chips"). A flow layout wraps the
/// chips onto more lines and never scrolls to the side.
///
/// Every chip takes the accent colour. The selected chip is filled and its
/// text is semibold, so the selection never depends on colour alone
/// (product-rules spec, "Accessibility everywhere"). "Add a place" opens a
/// field under the chips that fills the row, with its label above it
/// (product-rules spec, "Appearance").
struct WhereChipsView: View {
    @Binding var selection: String?
    /// The text in "Add a place", or `nil` while the field is closed. The
    /// screen owns it, so a tap on Save in the navigation bar saves a place
    /// that is still in the field (`WhereSelection.onSave`).
    @Binding var pendingPlace: String?
    let customPlaces: [String]
    var onSaveFromKeyboard: (() -> Void)?
    let onAddPlace: (String) -> Void

    @State private var addFieldFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 8) {
                ForEach(WhereChip.fixed, id: \.rawValue) { chip in
                    chipButton(chip.rawValue, label: chip.label.string)
                }
                ForEach(customPlaces, id: \.self) { place in
                    chipButton(place, label: place)
                }
                if pendingPlace == nil {
                    Button {
                        pendingPlace = ""
                        addFieldFocused = true
                    } label: {
                        Text("entry.where.addAPlace")
                    }
                    .buttonStyle(.bordered)
                }
            }
            if pendingPlace != nil {
                RecordField(
                    label: Text("entry.where.addAPlace"),
                    text: pendingPlaceText,
                    isFocused: $addFieldFocused,
                    onReturn: commitNewPlace,
                    accessibilityLabelText: NSLocalizedString("entry.where.addAPlace", comment: ""),
                    onSaveFromKeyboard: onSaveFromKeyboard
                )
                .onChange(of: addFieldFocused) { _, focused in
                    if !focused { commitNewPlace() }
                }
            }
        }
        .onAppear { addFieldFocused = false }
    }

    private var pendingPlaceText: Binding<String> {
        Binding(get: { pendingPlace ?? "" }, set: { pendingPlace = $0 })
    }

    /// Return or a move out of the field keeps the place and selects it.
    private func commitNewPlace() {
        guard let typed = pendingPlace else { return }
        pendingPlace = nil
        let trimmed = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAddPlace(trimmed)
        selection = trimmed
    }

    @ViewBuilder
    /// `value` is the Where the entry saves; `label` is the chip's text.
    private func chipButton(_ value: String, label: String) -> some View {
        let isSelected = selection == value
        let button = Button {
            selection = WhereSelection.afterTap(current: selection, tapped: value)
        } label: {
            Text(label)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        if isSelected {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }
}
