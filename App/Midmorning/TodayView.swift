import SwiftUI
import RecordCore

/// The record day's entries as a time-ordered column, like the paper record.
struct TodayView: View {
    let store: RecordStore

    @Environment(\.scenePhase) private var scenePhase
    @State private var day = RecordDay.interval(containing: Date(), calendar: .current)
    @State private var todayEntries: [Entry] = []
    @State private var previousEntries: [Entry] = []
    @State private var isNight = false
    @State private var showingNewEntry = false
    @State private var scrollTarget: UUID?

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    if !previousEntries.isEmpty {
                        Section(header: heading(for: RecordDay.previous(day, calendar: .current), night: false)) {
                            ForEach(previousEntries) { EntryRow(entry: $0).listRowSeparator(.hidden) }
                        }
                    }
                    Section(header: heading(for: day, night: isNight)) {
                        ForEach(todayEntries) { EntryRow(entry: $0).listRowSeparator(.hidden) }
                    }
                }
                .listStyle(.plain)
                .onChange(of: scrollTarget) { _, target in
                    if let target { proxy.scrollTo(target) }
                }
            }
            .navigationTitle("today.title")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("entry.new.accessibilityLabel")
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewEntryView(store: store, day: day) { saved in
                    reload()
                    scrollTarget = saved.id
                }
            }
        }
        .privacySensitive()
        .redacted(reason: scenePhase == .active ? [] : .privacy)
        .onAppear(perform: reload)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { reload() }
        }
        .task(id: day.end) {
            // Refresh at 04:00 while Today is on screen.
            let wait = day.end.timeIntervalSinceNow
            if wait > 0, (try? await Task.sleep(for: .seconds(wait))) != nil { reload() }
        }
    }

    private func reload() {
        let now = Date()
        day = RecordDay.interval(containing: now, calendar: .current)
        isNight = RecordDay.isNight(now, calendar: .current)
        let previous = RecordDay.previous(day, calendar: .current)
        todayEntries = (try? store.entries(dayKey: RecordDay.key(containing: now, calendar: .current))) ?? []
        previousEntries = (try? store.entries(dayKey: RecordDay.key(containing: previous.start, calendar: .current))) ?? []
    }

    private func heading(for interval: DateInterval, night: Bool) -> Text {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "EEEE d MMMM"
        return Text(formatter.string(from: interval.start) + (night ? ", night" : ""))
    }
}

/// One row: time, the asterisk when starred, What when not empty. Every row
/// has the same layout whatever the time since the previous entry.
struct EntryRow: View {
    let entry: Entry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            HStack(spacing: 2) {
                Text(entry.clockTime)
                if entry.feltLikeABinge {
                    Text(verbatim: "*")
                }
            }
            .font(.body.monospacedDigit())
            .foregroundStyle(.primary)
            if !entry.what.isEmpty {
                Text(entry.what)
                    .font(.body)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.accessibilityLabel)
    }
}
