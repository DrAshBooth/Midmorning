import SwiftUI
import Record

/// The Where control: the four fixed chips, the person's custom places, and
/// "Add a place" (record spec, "Where chips"). A flow layout wraps the
/// chips onto more lines and never scrolls to the side.
struct WhereChipsView: View {
    @Binding var selection: String?
    let customPlaces: [String]
    var onSaveFromKeyboard: (() -> Void)?
    let onAddPlace: (String) -> Void

    @State private var isAddingPlace = false
    @State private var newPlaceText = ""
    @State private var addFieldFocused = false

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(WhereChip.fixed, id: \.rawValue) { chip in
                chipButton(chip.rawValue)
            }
            ForEach(customPlaces, id: \.self) { place in
                chipButton(place)
            }
            if isAddingPlace {
                RecordOneLineField(
                    text: $newPlaceText,
                    isFocused: $addFieldFocused,
                    onReturn: commitNewPlace,
                    accessibilityLabelText: NSLocalizedString("entry.where.addAPlace", comment: ""),
                    onSaveFromKeyboard: onSaveFromKeyboard.map { save in { commitNewPlace(); save() } }
                )
                .frame(width: 140)
                .onChange(of: addFieldFocused) { _, focused in
                    if !focused { commitNewPlace() }
                }
            } else {
                Button {
                    isAddingPlace = true
                    newPlaceText = ""
                    addFieldFocused = true
                } label: {
                    Text("entry.where.addAPlace")
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear { addFieldFocused = false }
    }

    private func commitNewPlace() {
        let trimmed = newPlaceText.trimmingCharacters(in: .whitespacesAndNewlines)
        isAddingPlace = false
        guard !trimmed.isEmpty else { return }
        onAddPlace(trimmed)
        selection = trimmed
    }

    private func chipButton(_ text: String) -> some View {
        Button {
            selection = WhereSelection.afterTap(current: selection, tapped: text)
        } label: {
            Text(text)
        }
        .buttonStyle(.bordered)
        .tint(selection == text ? Color.accentColor : Color(uiColor: .systemGray4))
        .accessibilityAddTraits(selection == text ? .isSelected : [])
    }
}
