import SwiftUI
import Record
import Programme

/// The weigh-in screen (weigh-in spec, "The weigh-in day", "The app accepts
/// a weight on the weigh-in day only", "The number and its unit", "The
/// rolling average", "The chart", "The one-line explanation", "What the
/// weigh-in never shows", "The trend feeds safeguarding"). Reached from the
/// "Getting started" stage screen's "Weigh-in" row (decision 93) and from a
/// tap on the weigh-in day reminder.
struct WeighInScreenView: View {
    let store: RecordStore
    var now: () -> Date = Date.init
    var calendar: Calendar = .current

    @State private var weighInWeekday: Int?
    @State private var unit: WeightUnit = .kg
    @State private var inputState: WeighInInputState = .chooseDay
    @State private var series: [RollingAveragePoint] = []
    @State private var currentDayKey = ""

    @State private var weightKgText = ""
    @State private var weightStoneText = ""
    @State private var weightPoundsText = ""
    @State private var belowRangeMessage: String?

    @State private var notRightNowReasons: [ExclusionReason]?
    @State private var gpSuggestionReasons: [GPSuggestionReason]?

    var body: some View {
        Form {
            switch inputState {
            case .chooseDay:
                chooseDaySection

            case .entry(let prefill):
                Section {
                    weightField
                    if let belowRangeMessage {
                        Text(verbatim: belowRangeMessage).foregroundStyle(.red)
                    }
                    Button("entry.save", action: save)
                        .disabled(!hasCompleteInput)
                }
                .onAppear { prefillIfNeeded(prefill) }

            case .fixedForToday:
                EmptyView()

            case .refusal(let nextDayKey):
                Section {
                    Text(verbatim: WeighInRefusalText.text(
                        dayName: weighInWeekday.flatMap(Weekday.init)?.name ?? "",
                        nextDate: WeighInDayRule.formattedDate(dayKey: nextDayKey, calendar: calendar)
                    ))
                }
            }

            if showsChart {
                Section {
                    WeighInChartView(points: series, unit: unit, calendar: calendar)
                        .listRowInsets(EdgeInsets())
                        .padding()
                    Text(verbatim: WeighInExplanation.text(unit: unit))
                }
            }

            if weighInWeekday != nil {
                Section {
                    weighInDayPicker
                    unitPicker
                }
            }
        }
        .recordListStyle()
        .navigationTitle(WeighInContent.title)
        .getSupport()
        .onAppear(perform: reload)
        .fullScreenCover(isPresented: Binding(get: { notRightNowReasons != nil }, set: { if !$0 { notRightNowReasons = nil } })) {
            NotRightNowPageView(store: store, reasons: notRightNowReasons ?? []) { notRightNowReasons = nil }
        }
        .fullScreenCover(isPresented: Binding(get: { gpSuggestionReasons != nil }, set: { if !$0 { gpSuggestionReasons = nil } })) {
            GPSuggestionPageView(store: store, reasons: gpSuggestionReasons ?? []) { gpSuggestionReasons = nil }
        }
    }

    // MARK: Sections

    private var chooseDaySection: some View {
        Section(header: Text(WeighInContent.chooseADayHeading).accessibilityAddTraits(.isHeader)) {
            ForEach(Weekday.allCases, id: \.self) { weekday in
                Button(weekday.name) { chooseWeighInDay(weekday.rawValue) }
            }
            Text(verbatim: Screen3Content.weighInExplanation)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var weightField: some View {
        switch unit {
        case .kg:
            TextField(WeighInContent.kgChoice, text: $weightKgText)
                .keyboardType(.decimalPad)
                .accessibilityLabel(WeighInContent.weightLabel)
        case .stLb:
            // Two fields, each its own accessibility element (so VoiceOver
            // can focus and edit each one) rather than one combined "Weight"
            // element, which would block direct entry into either field.
            HStack {
                TextField("st", text: $weightStoneText)
                    .keyboardType(.numberPad)
                    .accessibilityLabel(WeighInContent.stoneAccessibilityLabel)
                TextField("lb", text: $weightPoundsText)
                    .keyboardType(.numberPad)
                    .accessibilityLabel(WeighInContent.poundsAccessibilityLabel)
            }
        }
    }

    private var weighInDayPicker: some View {
        Picker(Screen3Content.weighInDayHeading, selection: weighInDaySelection) {
            ForEach(Weekday.allCases, id: \.self) { weekday in
                Text(weekday.name).tag(Optional(weekday.rawValue))
            }
            Text(Screen3Content.wontBeWeighingChoice).tag(Optional<Int>.none)
        }
        .accessibilityLabel(Screen3Content.weighInDayHeading)
    }

    private var unitPicker: some View {
        Picker(WeighInContent.unitLabel, selection: $unit) {
            Text(WeighInContent.kgChoice).tag(WeightUnit.kg)
            Text(WeighInContent.stLbChoice).tag(WeightUnit.stLb)
        }
        .accessibilityLabel(WeighInContent.unitLabel)
        .onChange(of: unit) { _, newUnit in try? store.setWeighInUnit(newUnit.rawValue) }
    }

    private var weighInDaySelection: Binding<Int?> {
        Binding(
            get: { weighInWeekday },
            set: { newValue in
                if let newValue {
                    try? store.setWeighInDayChoice(.weekday(newValue))
                } else {
                    try? store.setWeighInDayChoice(.wontBeWeighing)
                }
                reload()
                ReminderCoordinator.recomputeAndApply(store: store)
            }
        )
    }

    // MARK: State

    private var showsChart: Bool {
        WeighInChartRule.showsChart(weighInWeekday: weighInWeekday, hasAnyWeighIn: !series.isEmpty)
    }

    private var hasCompleteInput: Bool {
        switch unit {
        case .kg: return Double(weightKgText) != nil
        case .stLb: return Int(weightStoneText) != nil && Int(weightPoundsText) != nil
        }
    }

    private func chooseWeighInDay(_ weekday: Int) {
        try? store.setWeighInDayChoice(.weekday(weekday))
        reload()
        ReminderCoordinator.recomputeAndApply(store: store)
    }

    private func prefillIfNeeded(_ prefill: Double?) {
        guard let prefill, weightKgText.isEmpty, weightStoneText.isEmpty else { return }
        switch unit {
        case .kg:
            weightKgText = WeighInWeight.displayKg(prefill)
        case .stLb:
            let (stone, pounds) = WeighInWeight.stoneAndPounds(fromKg: prefill)
            weightStoneText = String(stone)
            weightPoundsText = String(pounds)
        }
    }

    private func save() {
        let raw: Double
        switch unit {
        case .kg:
            guard let value = Double(weightKgText) else { return }
            raw = value
        case .stLb:
            // Pounds accept a whole number from 0 to 13 (weigh-in spec, "The
            // number and its unit").
            switch TypedMeasureParser.weightKg(stone: weightStoneText, pounds: weightPoundsText) {
            case .missing:
                return
            case .partOutOfRange:
                belowRangeMessage = WeighInWeight.belowRangeMessage
                return
            case .value(let kg):
                raw = kg
            }
        }
        switch WeighInWeight.validate(kg: raw) {
        case .belowRange:
            belowRangeMessage = WeighInWeight.belowRangeMessage
        case .valid(let kg):
            belowRangeMessage = nil
            let stored = WeighInWeight.storedKg(kg)
            try? store.saveWeighIn(dateKey: currentDayKey, weightKg: stored, unit: unit.rawValue, at: now())
            // The input keeps what the person typed; the person can still
            // change it inside the 10-minute window (weigh-in spec, "For 10
            // minutes after 'Save', the person MUST be able to change the
            // number.").
            runUnderweightCheck()
            reload()
        }
    }

    /// safeguarding spec, "The underweight check": run once, right after
    /// this save. `weigh-in`'s own screen adds no text, colour or icon of
    /// its own from the result (weigh-in spec, "The trend feeds
    /// safeguarding"); the two pages carry their own reasons.
    private func runUnderweightCheck() {
        guard let profile = try? store.profile(),
              let facts = try? store.weighIns().map({ WeighInFact(dayKey: $0.dateKey, weightKg: $0.weightKg) }),
              !facts.isEmpty
        else { return }
        let series = RollingAverage.series(facts, calendar: calendar)
        guard let latest = series.last else { return }
        let earlier = RollingAverage.averageAtLeastDaysEarlier(28, before: latest.dayKey, in: series, calendar: calendar)
        let input = UnderweightCheckInput(heightCm: profile.heightCm, onboardingBMI: profile.onboardingBMI, cautionFlag: profile.cautionFlag, currentAverageKg: latest.averageKg, averageAtLeast28DaysEarlierKg: earlier)
        let rules = UnderweightCheck.rulesThatApply(input)

        let notRightNow = UnderweightCheck.notRightNowReasons(rules)
        if !notRightNow.isEmpty {
            if notRightNow.contains(.weight) {
                try? store.pauseReminders(at: now())
                ReminderCoordinator.recomputeAndApply(store: store)
            }
            notRightNowReasons = notRightNow
            return
        }
        let gpReasons = UnderweightCheck.gpSuggestionReasons(rules)
        if !gpReasons.isEmpty {
            gpSuggestionReasons = gpReasons
        }
    }

    private func reload() {
        currentDayKey = RecordDay.key(containing: now(), calendar: calendar, schedule: (try? store.dayStartSchedule()) ?? .standard)

        switch try? store.weighInDayChoice() {
        case .weekday(let weekday): weighInWeekday = weekday
        case .wontBeWeighing, nil: weighInWeekday = nil
        }
        unit = WeightUnit(rawValue: (try? store.weighInUnit()) ?? "kg") ?? .kg

        let rows = (try? store.weighIns()) ?? []
        series = RollingAverage.series(rows.map { WeighInFact(dayKey: $0.dateKey, weightKg: $0.weightKg) }, calendar: calendar)
        let lastWeighInDayKey = rows.map(\.dateKey).max()
        let todaysRow = rows.first { $0.dateKey == currentDayKey }
        let todaysWeighIn = todaysRow.map { TodaysWeighInFact(weightKg: $0.weightKg, savedAt: $0.savedAt) }

        inputState = WeighInGate.inputState(
            weighInWeekday: weighInWeekday, currentDayKey: currentDayKey, todaysWeighIn: todaysWeighIn,
            lastWeighInDayKey: lastWeighInDayKey, now: now(), calendar: calendar
        )
    }
}
