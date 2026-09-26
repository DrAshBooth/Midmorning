import SwiftUI
import Record

/// The new-entry screen: What, Where, "felt like a binge", Context, Time,
/// Save and Cancel. No title. Controls sit in `NewEntryField.order`
/// (decision 86), so the visual order equals the VoiceOver order.
struct NewEntryView: View {
    enum TimeSegment: Hashable { case previous, current }

    let store: RecordStore
    let day: DateInterval
    /// Set by "Add it" on the missed planned meal prompt (regular-eating-
    /// plan spec, "A missed planned meal gets one prompt": "'Add it' MUST
    /// open the new-entry screen with the time set to the planned meal's
    /// time"). `nil` opens with the current time, as from "Add an entry".
    var initialTime: Date?
    let onSave: (RecordRow) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var openedAt = Date()
    @State private var time = Date()
    @State private var what = ""
    @State private var whereSelection: String?
    @State private var feltLikeABinge = false
    @State private var context = ""
    @State private var whatIsFocused = false
    @State private var contextIsFocused = false
    @State private var customPlaces: [String] = []
    @State private var selectedSegment: TimeSegment = .current
    @State private var saveOutcome: SaveOutcome = .saved

    private var previousDayInterval: DateInterval { RecordDay.previous(day, calendar: .current) }
    private var segmentInterval: DateInterval { selectedSegment == .previous ? previousDayInterval : day }
    private var wheelRange: ClosedRange<Date> {
        let lower = segmentInterval.start
        let upper = min(segmentInterval.end, openedAt)
        return lower...max(lower, upper)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if case .failed = saveOutcome {
                        Text(SaveOutcome.failureMessage)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(NewEntryField.order, id: \.self) { field in
                        fieldView(field)
                    }
                }
                .padding()
            }
            .recordSheetDetent()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("entry.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("entry.save", action: save)
                }
            }
        }
        // The sheet sits above Today's redaction, so it redacts itself: the
        // app switcher shows no entry text, no star and no field label.
        .privacySensitive()
        .redacted(reason: scenePhase == .active ? [] : .privacy)
        .onAppear {
            openedAt = Date()
            time = min(initialTime ?? openedAt, wheelRange.upperBound)
            customPlaces = (try? store.customPlaces()) ?? []
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                whatIsFocused = true
            }
        }
        .onChange(of: selectedSegment) { _, _ in
            time = min(max(time, wheelRange.lowerBound), wheelRange.upperBound)
        }
    }

    @ViewBuilder
    private func fieldView(_ field: NewEntryField) -> some View {
        switch field {
        case .what:
            RecordField(
                label: Text("entry.what"),
                text: $what,
                isFocused: $whatIsFocused,
                accessibilityLabelText: NSLocalizedString("entry.what", comment: ""),
                onSaveFromKeyboard: save
            )
        case .whereField:
            WhereChipsView(selection: $whereSelection, customPlaces: customPlaces, onSaveFromKeyboard: save) { newPlace in
                try? store.touchCustomPlace(newPlace, at: Date())
                customPlaces = (try? store.customPlaces()) ?? []
            }
        case .star:
            // A neutral system grey, not the default green: the star is
            // marked, not highlighted. Grey keeps the knob visible in
            // light and dark mode; the primary colour hid it there.
            Toggle("felt like a binge", isOn: $feltLikeABinge)
                .tint(Color(uiColor: .systemGray))
                // Redaction greys the label but not the switch, so the
                // switch hides itself: the app switcher shows no star.
                .opacity(scenePhase == .active ? 1 : 0)
        case .context:
            RecordField(
                label: Text(ContextLabel.text(starOn: feltLikeABinge)),
                text: $context,
                isFocused: $contextIsFocused,
                accessibilityLabelText: ContextLabel.text(starOn: feltLikeABinge),
                onSaveFromKeyboard: save
            )
        case .time:
            timeControl
        }
    }

    private var timeControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("", selection: $selectedSegment) {
                Text(DayHeading.dateOnly(previousDayInterval.start)).tag(TimeSegment.previous)
                Text(DayHeading.dateOnly(day.start)).tag(TimeSegment.current)
            }
            .pickerStyle(.segmented)
            .accessibilityHidden(true) // the wheel below carries the spoken value
            DatePicker("", selection: $time, in: wheelRange, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.wheel)
                .labelsHidden()
                .accessibilityLabel("entry.time.accessibilityLabel")
                .accessibilityValue(Self.spokenTime(time))
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
        do {
            let entry = try store.add(
                time: min(time, now),
                what: what,
                feltLikeABinge: feltLikeABinge,
                createdAt: now,
                utcOffsetSeconds: TimeZone.current.secondsFromGMT(for: now),
                whereText: whereSelection ?? "",
                context: context
            )
            dismiss()
            onSave(entry)
        } catch {
            saveOutcome = .failed
        }
    }
}
