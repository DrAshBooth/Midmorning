import SwiftUI
import Record
import Plan
import Constants

/// What the plan builder edits: a specific record day's plan, or a template
/// (regular-eating-plan spec, "Weekday and weekend templates"; "Edit tonight
/// for tomorrow, or this morning for today").
enum PlanBuilderMode: Identifiable {
    /// `titleKey` is "plan.today" or "plan.tomorrow"; `isCurrentDay` locks an
    /// answered planned meal (the current-day rule; "Tomorrow's plan" has no
    /// answers yet). A `LocalizedStringKey`, not `String`: `Text(_:)` only
    /// looks a runtime value up in the string catalogue through this type.
    case day(dateKey: String, titleKey: LocalizedStringKey, isCurrentDay: Bool)
    case template(kind: RecordStore.TemplateKind, titleKey: LocalizedStringKey)

    var id: String {
        switch self {
        case .day(let dateKey, _, _): return "day-\(dateKey)"
        case .template(let kind, _): return "template-\(kind.rawValue)"
        }
    }
}

/// The plan builder: place, time, rename and remove slots, the soft-rules
/// check, and — for the weekday template — "Copy to weekend plan"
/// (regular-eating-plan spec, "Place slots in the plan builder", "Rename a
/// slot in the plan builder", "The soft rules show and ask", "Weekday and
/// weekend templates"). Every screen after `record-full` follows the shared
/// appearance rule; decision 94 fixes "Cancel" leading, "Get support"
/// trailing and "Save" as a full-width control below the planned meals.
struct PlanBuilderView: View {
    let store: RecordStore
    let mode: PlanBuilderMode
    var onSaved: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var meals: [PlannedMeal] = []
    @State private var storedLabels: [Int: String] = [:]
    @State private var dayStartHour = RecordDay.startHour
    @State private var isFastingDay = false
    @State private var quietOn = true
    @State private var quietStart = "22:00"
    @State private var quietEnd = "07:00"
    @State private var lockedSlots: Set<Int> = []
    @State private var renamingSlot: Int?
    @State private var renameText = ""
    @State private var renameMessage: String?
    @State private var softRuleLines: [String] = []
    @State private var isShowingSoftRuleCheck = false

    private var orderedMeals: [PlannedMeal] { PlanOrdering.sorted(meals, dayStartHour: dayStartHour) }
    private var placedSlotIndexes: Set<Int> { Set(meals.map(\.slotIndex)) }
    private var unplacedSlots: [Slot] { Slot.all.filter { !placedSlotIndexes.contains($0.index) } }

    private func label(_ slotIndex: Int) -> String {
        SlotLabel.effective(stored: storedLabels[slotIndex], defaultLabel: Slot.at(index: slotIndex)?.defaultLabel ?? "")
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(orderedMeals, id: \.slotIndex) { meal in
                        plannedMealRow(meal)
                    }
                    ForEach(unplacedSlots, id: \.index) { slot in
                        Button(label(slot.index)) { place(slot) }
                    }
                }
                if case .template(.weekday, _) = mode {
                    Section {
                        Button("plan.copyToWeekend", action: copyToWeekend)
                    }
                }
                Section {
                    Button {
                        attemptSave()
                    } label: {
                        Text("entry.save").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                    .padding()
                }
                .listRowBackground(Color.clear)
            }
            .recordListStyle()
            .recordSheetDetent()
            .navigationTitle(Text(titleKey))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("entry.cancel") { dismiss() }
                }
            }
            .getSupport()
            .sheet(item: renamingSlotBinding) { renaming in
                renameSheet(for: renaming.index)
            }
            .confirmationDialog(Text(softRuleLines.joined(separator: "\n\n")), isPresented: $isShowingSoftRuleCheck, titleVisibility: .visible) {
                Button("plan.saveAnyway") { performSave() }
                Button("plan.goBack", role: .cancel) {}
            }
        }
        .onAppear(perform: load)
    }

    private var titleKey: LocalizedStringKey {
        switch mode {
        case .day(_, let key, _): return key
        case .template(_, let key): return key
        }
    }

    // MARK: Rows

    @ViewBuilder
    private func plannedMealRow(_ meal: PlannedMeal) -> some View {
        let slotLabel = label(meal.slotIndex)
        let locked = lockedSlots.contains(meal.slotIndex)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if locked {
                    Text(slotLabel)
                    Spacer()
                    Text(meal.time)
                } else {
                    DatePicker(
                        PlanBuilderAccessibility.timeControlLabel(slotLabel: slotLabel),
                        selection: timeBinding(for: meal.slotIndex),
                        displayedComponents: .hourAndMinute
                    )
                }
            }
            if let gap = gapLine(after: meal) {
                Text(gap).font(.footnote).foregroundStyle(.secondary)
            }
            if QuietHours.contains(time: meal.time, start: quietStart, end: quietEnd), quietOn {
                Text(QuietHours.reminderNotSentMessage).font(.footnote).foregroundStyle(.secondary)
            }
            HStack {
                Button("plan.rename") { beginRename(meal.slotIndex) }
                    .accessibilityLabel(PlanBuilderAccessibility.renameControlLabel(slotLabel: slotLabel))
                if !locked {
                    Spacer()
                    Button(role: .destructive) { remove(meal.slotIndex) } label: {
                        Text(PlanBuilderAccessibility.removeControlLabel(slotLabel: slotLabel))
                    }
                }
            }
            // Two controls in one List row: each needs its own tap target.
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    private func gapLine(after meal: PlannedMeal) -> String? {
        guard !isFastingDay else { return nil }
        guard let index = orderedMeals.firstIndex(where: { $0.slotIndex == meal.slotIndex }), index + 1 < orderedMeals.count else { return nil }
        let next = orderedMeals[index + 1]
        let gap = PlanOrdering.minutesAfterDayStart(time: next.time, dayStartHour: dayStartHour)
            - PlanOrdering.minutesAfterDayStart(time: meal.time, dayStartHour: dayStartHour)
        return PlanDuration.string(minutes: gap)
    }

    private func timeBinding(for slotIndex: Int) -> Binding<Date> {
        Binding(
            get: { ClockTime.date(from: meals.first { $0.slotIndex == slotIndex }?.time ?? "00:00") },
            set: { newValue in
                let text = ClockTime.text(from: newValue)
                meals = PlanCodec.placing(slotIndex, at: text, in: meals)
            }
        )
    }

    // MARK: Rename

    private struct RenamingSlot: Identifiable { let index: Int; var id: Int { index } }

    private var renamingSlotBinding: Binding<RenamingSlot?> {
        Binding(
            get: { renamingSlot.map(RenamingSlot.init) },
            set: { renamingSlot = $0?.index }
        )
    }

    @ViewBuilder
    private func renameSheet(for slotIndex: Int) -> some View {
        NavigationStack {
            Form {
                Section {
                    TextField("plan.rename", text: Binding(
                        get: { renameText },
                        set: { renameText = SlotLabel.truncated($0) }
                    ))
                    if let renameMessage {
                        Text(renameMessage).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(Text("plan.rename"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("entry.cancel") { renamingSlot = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("entry.save") { saveRename(slotIndex) }
                }
            }
        }
        .recordSheetDetent()
    }

    private func beginRename(_ slotIndex: Int) {
        renameText = label(slotIndex)
        renameMessage = nil
        renamingSlot = slotIndex
    }

    private func saveRename(_ slotIndex: Int) {
        switch SlotLabel.outcome(forSavedText: renameText) {
        case .save(let text):
            storedLabels[slotIndex] = text
            try? store.setSlotLabel(text, index: slotIndex, changedAt: Date())
            renamingSlot = nil
        case .revertToDefault:
            storedLabels[slotIndex] = nil
            try? store.setSlotLabel(nil, index: slotIndex, changedAt: Date())
            renamingSlot = nil
        case .rejected(let message):
            renameMessage = message
        }
    }

    // MARK: Place / remove / copy

    private func place(_ slot: Slot) {
        meals = PlanCodec.placing(slot.index, at: slot.defaultTime, in: meals)
    }

    private func remove(_ slotIndex: Int) {
        meals = PlanCodec.removing(slotIndex, from: meals)
    }

    /// A template change: `changeTemplate` first copies the templates onto
    /// every elapsed record day, so the current day keeps its plan (mm-t23.21).
    private func copyToWeekend() {
        try? store.changeTemplate(PlanCodec.encode(meals), kind: .weekend, now: Date(), calendar: .current)
    }

    // MARK: Save

    private func attemptSave() {
        let facts = orderedMeals.map { PlanMealFact(label: label($0.slotIndex), time: $0.time, kind: Slot.at(index: $0.slotIndex)?.kind ?? .meal) }
        let lines = SoftRules.lines(orderedMeals: facts, dayStartHour: dayStartHour, maxAwakeGapHours: 4, isFastingDay: isFastingDay)
        if lines.isEmpty {
            performSave()
        } else {
            softRuleLines = lines
            isShowingSoftRuleCheck = true
        }
    }

    private func performSave() {
        switch mode {
        case .day(let dateKey, _, _):
            let plan = try? store.resolvedPlan(dateKey: dateKey)
            try? store.setDayPlan(
                dateKey: dateKey, slotsJSON: PlanCodec.encode(meals),
                windowBeforeMinutes: plan?.windowBeforeMinutes ?? ProgrammeConstants.default.plannedMealWindowBeforeMinutes,
                windowAfterMinutes: plan?.windowAfterMinutes ?? ProgrammeConstants.default.plannedMealWindowAfterMinutes,
                setAt: plan?.setAt ?? Date(), setBy: "device", changedAt: Date()
            )
        case .template(let kind, _):
            try? store.changeTemplate(PlanCodec.encode(meals), kind: kind, now: Date(), calendar: .current)
        }
        onSaved()
        dismiss()
    }

    // MARK: Load

    private func load() {
        switch mode {
        case .day(let dateKey, _, let isCurrentDay):
            // The one resolve that Today and the scheduler also use: the
            // day's own row, or its template by the key's weekday (mm-t23.23).
            let plan = try? store.resolvedPlan(dateKey: dateKey)
            dayStartHour = plan?.dayStartHour ?? RecordDay.startHour
            meals = plan?.meals ?? []
            isFastingDay = ((try? store.dayStates(dateKey: dateKey)) ?? []).contains(.fasting)
            if isCurrentDay, let plan, let recordDay = plan.recordDay(calendar: .current) {
                let answers = (try? store.plannedMealAnswers(dateKey: dateKey)) ?? [:]
                let entries = (try? store.entries(dayKey: dateKey)) ?? []
                let matches = plan.match(entries: entries.map { PlanEntryFact(id: $0.id, time: $0.time) }, recordDay: recordDay, calendar: .current).matches
                lockedSlots = Set(meals.map(\.slotIndex).filter { !PlanEditing.canChangeOrDelete(hasMatchedEntry: matches[$0] != nil, hasSkippedAnswer: answers[$0] == "Skipped") })
            } else {
                lockedSlots = []
            }
        case .template(let kind, _):
            meals = PlanCodec.decode((try? store.templateSlotsJSON(kind)) ?? "[]")
        }
        for slot in Slot.all { storedLabels[slot.index] = try? store.slotLabel(index: slot.index) }
        quietOn = (try? store.quietHoursOn()) ?? true
        quietStart = (try? store.quietHoursStart()) ?? "22:00"
        quietEnd = (try? store.quietHoursEnd()) ?? "07:00"
    }
}
