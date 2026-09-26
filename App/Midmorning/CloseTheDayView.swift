import SwiftUI
import Record

/// The close-the-day screen (reminders spec, "Close the day"): the day's
/// column, "Add an entry", "One word for how today felt", "Didn't record"
/// and "Done". No count of entries and no text about their absence.
struct CloseTheDayView: View {
    let store: RecordStore
    let dateKey: String
    var onSaved: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var entries: [RecordRow] = []
    @State private var feelingWord = ""
    @State private var didntRecord = false
    @State private var showingNewEntry = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(entries) { entry in
                        EntryRow(entry: entry)
                    }
                    Button("closeTheDay.addEntry") { showingNewEntry = true }
                } header: {
                    Text(DayHeading.dateOnly(forDayKey: dateKey))
                }

                Section {
                    TextField("closeTheDay.feelingWord", text: $feelingWord)
                        .accessibilityLabel("closeTheDay.feelingWord")
                }

                Section {
                    Toggle("today.didntRecord", isOn: $didntRecord)
                        .onChange(of: didntRecord) { _, on in
                            try? store.setDayState(.didntRecord, on: on, dateKey: dateKey, changedAt: Date())
                        }
                }
            }
            .navigationTitle("closeTheDay.title")
            // safeguarding spec, "Get support on every screen": the
            // confirming action is a full-width button below the content,
            // and Get support alone holds the trailing position.
            .safeAreaInset(edge: .bottom) {
                FullWidthConfirmButton("closeTheDay.done", action: save)
                    .padding()
                    .background(.bar)
            }
            .getSupport()
            .sheet(isPresented: $showingNewEntry) {
                NewEntryView(store: store, day: RecordDay.interval(containing: Date(), calendar: .current), initialTime: nil) { _ in
                    load()
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        entries = (try? store.entries(dayKey: dateKey)) ?? []
        feelingWord = (try? store.feelingWord(dateKey: dateKey)) ?? ""
        didntRecord = (try? store.dayStates(dateKey: dateKey).contains(.didntRecord)) ?? false
    }

    private func save() {
        try? store.setFeelingWord(feelingWord, dateKey: dateKey, changedAt: Date())
        onSaved()
        dismiss()
    }
}
