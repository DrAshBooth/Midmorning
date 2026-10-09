import SwiftUI
import Record
import Plan
import Constants

/// One planned meal row on Today (regular-eating-plan spec, "Today shows the
/// plan beside the record"; "A missed planned meal gets one prompt"). The
/// same background, height, spacing and text style as `EntryRow`; no tick,
/// cross, colour, count or percentage.
struct PlannedMealRowView: View {
    let row: PlanRowModel
    let dateKey: String
    /// "Add it" and "Skipped" on the missed planned meal prompt. `nil` on an
    /// earlier day, which shows no prompt (ruling r19-03, mm-t23.25).
    let onAddIt: ((Date) -> Void)?
    let onSkip: ((Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(row.label).font(.body.monospacedDigit())
                Text(row.time).font(.body.monospacedDigit())
                content
                Spacer(minLength: 0)
            }
            // record spec, "Today shows Where and Context": the Context
            // shows under the What, as on an entry row (mm-t23.20).
            if case .matched(let entry) = row.display, !entry.context.isEmpty {
                Text(entry.context).font(.body)
            }
            if let nextLine = row.nextLine {
                Text(nextLine).font(.body)
            }
            if let prompt = row.prompt {
                Text(MissedMealPrompt.line(for: prompt, timeText: clockTimeText).string)
                    .font(.body)
                if let onSkip, let onAddIt {
                    promptButtons(onSkip: onSkip, onAddIt: onAddIt)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        // The label ends with the next-planned-meal line when the row shows
        // it (ruling r19-02, mm-t23.26).
        .accessibilityLabel(PlannedMealAccessibility.label(
            slotLabel: row.label, time: row.time,
            matchedEntryAccessibilityLabel: row.matchedEntry?.accessibilityLabel,
            isSkipped: isSkipped, prompt: row.prompt,
            nextPlannedMealLine: row.nextLine.map(CatalogueText.verbatim),
            timeText: clockTimeText
        ).string)
        .accessibilityCustomActions(for: row, onAddIt: onAddIt, onSkip: onSkip)
    }

    private var isSkipped: Bool {
        if case .skipped = row.display { return true }
        return false
    }

    @ViewBuilder
    private var content: some View {
        switch row.display {
        case .pending:
            EmptyView()
        case .skipped:
            Text("plan.skipped")
        case .matched(let entry):
            Text(entry.time).font(.body.monospacedDigit())
            if entry.starred { Text(verbatim: "*") }
            if !entry.what.isEmpty { Text(entry.what) }
            if !entry.whereText.isEmpty { Text(entry.whereText) }
        }
    }

    /// "Skipped" and "Add it". The first cut shows no "That was it" control
    /// (mm-t23.22): `PlanTodayRows` never gives a row the "was that" form,
    /// and mm-t33.14 adds the control with its action.
    /// Each button is at least 44 points tall (regular-eating-plan spec, "A
    /// missed planned meal gets one prompt"). The height is on the label,
    /// so the tap target and the accessibility frame have it too; a frame
    /// outside the button gave only the layout that height.
    private func promptButtons(onSkip: @escaping (Int) -> Void, onAddIt: @escaping (Date) -> Void) -> some View {
        HStack(spacing: 8) {
            Button { onSkip(row.slotIndex) } label: {
                Text("plan.skipped").frame(minHeight: 44).contentShape(Rectangle())
            }
            Button { onAddIt(row.sortTime) } label: {
                Text("plan.addIt").frame(minHeight: 44).contentShape(Rectangle())
            }
        }
        // Two controls in one List row: each needs its own tap target.
        .buttonStyle(.borderless)
    }

    private func clockTimeText(_ date: Date) -> String {
        RecordRow.clockTime(for: date, utcOffsetSeconds: TimeZone.current.secondsFromGMT(for: date))
    }
}

private extension View {
    @ViewBuilder
    func accessibilityCustomActions(for row: PlanRowModel, onAddIt: ((Date) -> Void)?, onSkip: ((Int) -> Void)?) -> some View {
        if row.prompt != nil, let onAddIt, let onSkip {
            self
                .accessibilityAction(named: Text("plan.skipped")) { onSkip(row.slotIndex) }
                .accessibilityAction(named: Text("plan.addIt")) { onAddIt(row.sortTime) }
        } else {
            self
        }
    }
}
