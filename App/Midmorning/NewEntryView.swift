import SwiftUI
import RecordCore

/// The new-entry screen: time, What, the star, Save and Cancel. No title.
struct NewEntryView: View {
    let store: RecordStore
    let day: DateInterval
    let onSave: (Entry) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
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
            // Rows sit in the reading order the spec fixes (What, the star,
            // Time), so the visual order equals the VoiceOver order. Save and
            // Cancel stay in the navigation bar, which VoiceOver reads first;
            // decision 106 settles their place.
            Form {
                LabeledContent {
                    TextField("", text: $what, axis: .vertical)
                        .focused($whatIsFocused)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("What")
                } label: {
                    // The field carries the label, so VoiceOver says "What" once.
                    Text("What").accessibilityHidden(true)
                }
                // A neutral system grey, not the default green: the star is
                // marked, not highlighted. Grey keeps the knob visible in light
                // and dark mode; the primary colour hid it in dark mode.
                Toggle("felt like a binge", isOn: $feltLikeABinge)
                    .tint(Color(uiColor: .systemGray))
                    // Redaction greys the label but not the switch, so the
                    // switch hides itself: the app switcher shows no star.
                    .opacity(scenePhase == .active ? 1 : 0)
                DatePicker("", selection: $time, in: range, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .accessibilityLabel("Time")
                    .accessibilityValue(Self.spokenTime(time))
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
        // The sheet sits above Today's redaction, so it redacts itself: the
        // app switcher shows no entry text, no star and no field label.
        .privacySensitive()
        .redacted(reason: scenePhase == .active ? [] : .privacy)
        .onAppear {
            openedAt = Date()
            time = openedAt
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                whatIsFocused = true
            }
        }
    }

    /// The time control's VoiceOver value, for example "Thursday 24 September, 21:35".
    static func spokenTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "EEEE d MMMM, HH:mm"
        return f.string(from: date)
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
