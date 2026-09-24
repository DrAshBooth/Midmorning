import SwiftUI
import RecordCore

/// The new-entry screen: time, What, the star, Save and Cancel. No title.
struct NewEntryView: View {
    let store: RecordStore
    let day: DateInterval
    let onSave: (Entry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var openedAt = Date()
    @State private var time = Date()
    @State private var what = ""
    @State private var feltLikeABinge = false
    @FocusState private var whatIsFocused: Bool

    private var range: ClosedRange<Date> {
        RecordDay.previous(day, calendar: .current).start...openedAt
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("", selection: $time, in: range, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .accessibilityLabel("Time")
                LabeledContent("What") {
                    TextField("", text: $what, axis: .vertical)
                        .focused($whatIsFocused)
                        .accessibilityLabel("What")
                        .multilineTextAlignment(.trailing)
                }
                Toggle("felt like a binge", isOn: $feltLikeABinge)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
        }
        .privacySensitive()
        .onAppear {
            openedAt = Date()
            time = openedAt
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                whatIsFocused = true
            }
        }
    }

    private func save() {
        let now = Date()
        guard let entry = try? store.add(
            time: min(time, now),
            what: what,
            feltLikeABinge: feltLikeABinge,
            createdAt: now,
            utcOffsetSeconds: TimeZone.current.secondsFromGMT(for: now)
        ) else { return }
        dismiss()
        onSave(entry)
    }
}
