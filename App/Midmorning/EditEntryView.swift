import SwiftUI
import Record

/// The edit screen: the new-entry screen filled with the entry's values,
/// with one time segment (the entry's own record day) and "Delete entry"
/// last (record spec, "Edit an entry"; "Delete an entry").
struct EditEntryView: View {
    let store: RecordStore
    let entry: RecordRow
    let onSave: (RecordRow) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var time: Date
    @State private var what: String
    @State private var whereSelection: String?
    /// The text in "Add a place", or `nil` while that field is closed.
    @State private var pendingPlace: String?
    @State private var feltLikeABinge: Bool
    @State private var context: String
    @State private var whatIsFocused = false
    @State private var contextIsFocused = false
    @State private var customPlaces: [String] = []
    @State private var saveOutcome: SaveOutcome = .saved
    @State private var showingDeleteConfirm = false

    /// The entry's own record day, the one segment of the time control.
    private let ownDay: RecordTimeControl.Segment
    /// The entry's own UTC offset, so the wheel shows the time Today shows
    /// on the row.
    private let calendar: Calendar
    @State private var openedAt = Date()

    /// The record day's bounds come from the entry's own key, its UTC offset
    /// and the day start row in force for that key (record spec, "Edit an
    /// entry").
    init(store: RecordStore, entry: RecordRow, onSave: @escaping (RecordRow) -> Void, onDelete: @escaping () -> Void) {
        self.store = store
        self.entry = entry
        self.onSave = onSave
        self.onDelete = onDelete
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: entry.utcOffsetSeconds) ?? .current
        self.calendar = calendar
        let schedule = (try? store.dayStartSchedule()) ?? .standard
        let bounds = RecordDay.interval(forKey: entry.dayKey, calendar: calendar, schedule: schedule)
            ?? RecordDay.interval(containing: entry.time, calendar: calendar, schedule: schedule)
        self.ownDay = RecordTimeControl.Segment(
            interval: bounds,
            startHour: schedule.hour(effectiveOn: entry.dayKey),
            title: DayHeading.dateOnly(forDayKey: entry.dayKey)
        )
        self._time = State(initialValue: entry.time)
        self._what = State(initialValue: entry.what)
        self._whereSelection = State(initialValue: entry.whereText.isEmpty ? nil : entry.whereText)
        self._feltLikeABinge = State(initialValue: entry.feltLikeABinge)
        self._context = State(initialValue: entry.context)
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
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Text("entry.delete.button")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .recordSheetDetent()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("entry.cancel") {
                        pendingPlace = nil // "Cancel" MUST discard every change
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("entry.save", action: save)
                }
            }
            .confirmationDialog("entry.delete.confirmTitle", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("entry.delete.action", role: .destructive) {
                    try? store.delete(entryId: entry.id, deletedAt: Date())
                    dismiss()
                    onDelete()
                }
                Button("entry.cancel", role: .cancel) {}
            }
        }
        .privacySensitive()
        .redacted(reason: scenePhase == .active ? [] : .privacy)
        .onAppear {
            openedAt = Date()
            customPlaces = (try? store.customPlaces()) ?? []
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                whatIsFocused = true
            }
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
            WhereChipsView(selection: $whereSelection, pendingPlace: $pendingPlace, customPlaces: customPlaces, onSaveFromKeyboard: save) { newPlace in
                try? store.touchCustomPlace(newPlace, at: Date())
                customPlaces = (try? store.customPlaces()) ?? []
            }
        case .star:
            Toggle("felt like a binge", isOn: $feltLikeABinge)
                .tint(Color(uiColor: .systemGray))
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

    /// One segment, the entry's own record day; the time control MUST NOT
    /// offer a time after the current moment.
    private var timeControl: some View {
        RecordTimeControl(segments: [ownDay], time: $time, notAfter: openedAt, calendar: calendar)
    }

    private func save() {
        let now = Date()
        let place = WhereSelection.onSave(selection: whereSelection, pendingPlace: pendingPlace)
        do {
            if let kept = place.placeToKeep {
                try? store.touchCustomPlace(kept, at: now)
            }
            let updated = try store.update(
                entryId: entry.id, time: time, what: what, feltLikeABinge: feltLikeABinge,
                whereText: place.whereText, context: context, editedAt: now
            )
            pendingPlace = nil
            whereSelection = place.whereText.isEmpty ? nil : place.whereText
            dismiss()
            onSave(updated)
        } catch {
            saveOutcome = .failed
        }
    }
}
