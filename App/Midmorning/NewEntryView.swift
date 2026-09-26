import SwiftUI
import Record

/// The new-entry screen: What, Where, "felt like a binge", Context, Time,
/// Save and Cancel. No title. Controls sit in `NewEntryField.order`
/// (decision 86), so the visual order equals the VoiceOver order.
struct NewEntryView: View {
    let store: RecordStore
    /// Set by "Add it" on the missed planned meal prompt (regular-eating-
    /// plan spec, "A missed planned meal gets one prompt": "'Add it' MUST
    /// open the new-entry screen with the time set to the planned meal's
    /// time"). `nil` opens with the current time, as from "Add an entry".
    var initialTime: Date?
    let onSave: (RecordRow) -> Void
    /// app-lock spec, "A new entry before authentication" (ruling r13-04,
    /// mm-t15.19). Set only for the new-entry screen of a pending route.
    /// Save calls it first and saves only on `true`. On `false` nothing
    /// saves and the typed text stays. While it is set, a place added in
    /// "Add a place" stays in memory until Save succeeds (`unsavedPlaces`),
    /// so the store gets nothing before the authentication.
    var authenticateBeforeSave: (@MainActor () async -> Bool)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var openedAt = Date()
    @State private var time = Date()
    @State private var what = ""
    @State private var whereSelection: String?
    /// The text in "Add a place", or `nil` while that field is closed.
    @State private var pendingPlace: String?
    @State private var feltLikeABinge = false
    @State private var context = ""
    @State private var whatIsFocused = false
    @State private var contextIsFocused = false
    @State private var customPlaces: [String] = []
    /// The places added on a pending route's screen, not saved yet.
    @State private var unsavedPlaces = UnsavedPlaces()
    /// The previous and the current record day, under the day start in
    /// force when the screen opens (record spec, "The record day").
    @State private var segments: [RecordTimeControl.Segment] = []
    @State private var saveOutcome: SaveOutcome = .saved
    @State private var isAuthenticatingSave = false

    /// The device zone, on the Gregorian calendar (product-rules spec,
    /// "Dates and times in strings").
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if case .failed = saveOutcome {
                        Text(SaveOutcome.failureMessage.string)
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
                    Button("entry.cancel") {
                        pendingPlace = nil // Cancel keeps no place typed in "Add a place"
                        dismiss()
                    }
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
            loadSegments()
            time = openingTime()
            customPlaces = (try? store.customPlaces()) ?? []
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                whatIsFocused = true
            }
        }
    }

    private func loadSegments() {
        let schedule = (try? store.dayStartSchedule()) ?? .standard
        let current = RecordDay.interval(containing: openedAt, calendar: calendar, schedule: schedule)
        let previous = RecordDay.previous(current, calendar: calendar, schedule: schedule)
        segments = [previous, current].map { interval in
            let key = RecordDay.key(containing: interval.start, calendar: calendar, schedule: schedule)
            return RecordTimeControl.Segment(interval: interval, startHour: schedule.hour(effectiveOn: key), title: DayHeading.dateOnly(interval.start))
        }
    }

    /// The moment the screen opens, or the planned meal's time from "Add
    /// it", kept inside the two record days and never after now. The
    /// current record day's segment is then the selected one (record spec,
    /// "The new-entry screen's controls").
    private func openingTime() -> Date {
        guard let first = segments.first else { return openedAt }
        let range = first.interval.start...max(first.interval.start, openedAt)
        return min(max(initialTime ?? openedAt, range.lowerBound), range.upperBound)
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
            WhereChipsView(selection: $whereSelection, pendingPlace: $pendingPlace, customPlaces: unsavedPlaces.chips(savedPlaces: customPlaces), onSaveFromKeyboard: save) { newPlace in
                // Return, or the end of editing in "Add a place". The cover
                // closes the keyboard after a cancelled request at Save,
                // which ends editing too: on a pending route's screen the
                // place stays in memory (ruling r13-04, mm-t15.19).
                if authenticateBeforeSave != nil {
                    unsavedPlaces.add(newPlace, at: Date())
                    return
                }
                try? store.touchCustomPlace(newPlace, at: Date())
                customPlaces = (try? store.customPlaces()) ?? []
            }
        case .star:
            // A neutral system grey, not the default green: the star is
            // marked, not highlighted. Grey keeps the knob visible in
            // light and dark mode; the primary colour hid it there.
            Toggle("entry.feltLikeABinge", isOn: $feltLikeABinge)
                .tint(Color(uiColor: .systemGray))
                // Redaction greys the label but not the switch, so the
                // switch hides itself: the app switcher shows no star.
                .opacity(scenePhase == .active ? 1 : 0)
        case .context:
            RecordField(
                label: Text(ContextLabel.text(starOn: feltLikeABinge).string),
                text: $context,
                isFocused: $contextIsFocused,
                accessibilityLabelText: ContextLabel.text(starOn: feltLikeABinge).string,
                onSaveFromKeyboard: save
            )
        case .time:
            timeControl
        }
    }

    private var timeControl: some View {
        RecordTimeControl(segments: segments, time: $time, notAfter: openedAt, calendar: calendar)
    }

    /// Save, and "Save" from the keyboard. A pending route's screen asks
    /// for authentication first, once at a time.
    private func save() {
        guard let authenticateBeforeSave else { return saveEntry() }
        guard !isAuthenticatingSave else { return }
        isAuthenticatingSave = true
        Task {
            let canSave = await authenticateBeforeSave()
            isAuthenticatingSave = false
            if canSave { saveEntry() }
        }
    }

    private func saveEntry() {
        let now = Date()
        let place = WhereSelection.onSave(selection: whereSelection, pendingPlace: pendingPlace)
        do {
            try? store.touchCustomPlaces(unsavedPlaces)
            unsavedPlaces = UnsavedPlaces()
            if let kept = place.placeToKeep {
                try? store.touchCustomPlace(kept, at: now)
            }
            let entry = try store.add(
                time: min(time, now),
                what: what,
                feltLikeABinge: feltLikeABinge,
                createdAt: now,
                utcOffsetSeconds: TimeZone.current.secondsFromGMT(for: now),
                whereText: place.whereText,
                context: context
            )
            pendingPlace = nil
            whereSelection = place.whereText.isEmpty ? nil : place.whereText
            dismiss()
            onSave(entry)
        } catch {
            saveOutcome = .failed
        }
    }
}
