import SwiftUI
import Record

/// A route pushed onto Today's own navigation stack (product-rules spec,
/// "Appearance": "A screen that shows the record MUST open with a push onto
/// the navigation stack").
enum EarlierDaysRoute: Hashable {
    case list
}

/// "Earlier days": the list of record days from the earliest day with an
/// entry or a state to the day before the previous record day, most recent
/// first, with a row for a day that has neither (record spec, "Earlier
/// record days").
struct EarlierDaysListView: View {
    let store: RecordStore
    @State private var dayKeys: [String] = []

    var body: some View {
        List(dayKeys, id: \.self) { key in
            NavigationLink(value: key) {
                Text(DayHeading.dateOnly(forDayKey: key))
            }
        }
        .recordListStyle()
        .navigationTitle("today.earlierDays")
        .getSupport()
        .onAppear(perform: load)
    }

    private func load() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let previous = RecordDay.previous(RecordDay.interval(containing: Date(), calendar: calendar), calendar: calendar)
        let previousKey = RecordDay.key(containing: previous.start, calendar: calendar)
        let content = (try? store.dateKeysWithContent(before: previousKey)) ?? []
        dayKeys = EarlierDays.list(dateKeysWithContent: content, previousRecordDayKey: previousKey)
    }
}

/// One earlier record day: its entries under the same rules as a day on
/// Today, and controls to move to the previous and the next record day, and
/// back to Today (record spec, "Earlier record days"). No control creates an
/// entry here.
struct EarlierDayDetailView: View {
    let store: RecordStore
    /// The record day stage 2 opened, or `nil` while stage 2 is closed: the
    /// plan and the gap bands show from that day on.
    let stage2OpenedDayKey: String?
    @Binding var navigationPath: NavigationPath
    @State private var dayKey: String
    @State private var section: DaySection?

    init(store: RecordStore, initialDayKey: String, stage2OpenedDayKey: String?, navigationPath: Binding<NavigationPath>) {
        self.store = store
        self.stage2OpenedDayKey = stage2OpenedDayKey
        self._navigationPath = navigationPath
        self._dayKey = State(initialValue: initialDayKey)
    }

    var body: some View {
        List {
            if let section {
                if let stateLine = section.stateLine {
                    Text(stateLine)
                }
                if section.isExpanded {
                    ForEach(section.entries) { entry in
                        EntryRow(entry: entry)
                    }
                } else {
                    Text(section.entries.count == 1 ? "1 entry" : "\(section.entries.count) entries")
                }
            }
        }
        .recordListStyle()
        .navigationTitle(Text(DayHeading.dateOnly(forDayKey: dayKey)))
        .toolbar {
            // "Today" and "Get support" (safeguarding spec, "Get support on
            // every screen") share the trailing position; "Get support"
            // sits last, as the true trailing control, from `.getSupport()`
            // below.
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("today.earlierDays.today") {
                    navigationPath.removeLast(navigationPath.count)
                }
            }
        }
        .getSupport()
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    move(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("today.earlierDays.previousDay")
                Spacer()
                Button {
                    move(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .accessibilityLabel("today.earlierDays.nextDay")
            }
            .padding()
        }
        .onAppear(perform: load)
        .onChange(of: dayKey) { _, _ in load() }
    }

    private func move(by delta: Int) {
        guard let date = DayHeading.dayKeyDate(dayKey) else { return }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let interval = RecordDay.interval(containing: date.addingTimeInterval(12 * 3600), calendar: calendar)
        let newInterval = delta > 0 ? RecordDay.next(interval, calendar: calendar) : RecordDay.previous(interval, calendar: calendar)
        dayKey = RecordDay.key(containing: newInterval.start, calendar: calendar)
    }

    private func load() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = DayHeading.dayKeyDate(dayKey) ?? Date()
        let interval = RecordDay.interval(containing: date.addingTimeInterval(12 * 3600), calendar: calendar)
        let planShows = stage2OpenedDayKey.map { dayKey >= $0 } ?? false
        section = DaySection.load(dayKey: dayKey, interval: interval, role: .earlier, store: store, stage2Open: planShows, stage2OpenedDayKey: stage2OpenedDayKey)
    }
}
