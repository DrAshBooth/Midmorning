import SwiftUI
import Record
import Plan

/// One planned meal row on Today (regular-eating-plan spec, "Today shows the
/// plan beside the record"; "A missed planned meal gets one prompt"). The
/// same background, height, spacing and text style as `EntryRow`; no tick,
/// cross, colour, count or percentage.
struct PlannedMealRowView: View {
    let row: PlanRowModel
    let dateKey: String
    let onAddIt: (Date) -> Void
    let onSkip: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(row.label).font(.body.monospacedDigit())
                Text(row.time).font(.body.monospacedDigit())
                content
                Spacer(minLength: 0)
            }
            if let nextLine = row.nextLine {
                Text(nextLine).font(.body)
            }
            if let prompt = row.prompt {
                Text(MissedMealPrompt.line(for: prompt, timeText: clockTimeText))
                    .font(.body)
                promptButtons(for: prompt)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(PlannedMealAccessibility.label(
            slotLabel: row.label, time: row.time,
            matchedEntryAccessibilityLabel: row.matchedEntry?.accessibilityLabel,
            isSkipped: isSkipped, prompt: row.prompt, timeText: clockTimeText
        ))
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
        case .matched(let entryTime, let what):
            Text(entryTime).font(.body.monospacedDigit())
            if !what.isEmpty { Text(what) }
            if row.matchedEntry?.feltLikeABinge == true { Text(verbatim: "*") }
        }
    }

    @ViewBuilder
    private func promptButtons(for form: MissedMealPrompt.Form) -> some View {
        HStack(spacing: 8) {
            Button("plan.skipped") { onSkip(row.slotIndex) }
                .frame(minHeight: 44)
            switch form {
            case .skippedOrNotRecorded:
                Button("plan.addIt") { onAddIt(row.sortTime) }
                    .frame(minHeight: 44)
            case .skippedOrWasThat:
                // "That was it" is a visible placeholder; matching the
                // candidate entry is deferred to mm-t33.14 (3.3
                // problem-solving), the same pattern this change's other
                // placeholders (record-full's "Get support") use.
                Button("plan.thatWasIt") {}
                    .frame(minHeight: 44)
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
    func accessibilityCustomActions(for row: PlanRowModel, onAddIt: @escaping (Date) -> Void, onSkip: @escaping (Int) -> Void) -> some View {
        if let prompt = row.prompt {
            switch prompt {
            case .skippedOrNotRecorded:
                self
                    .accessibilityAction(named: Text("plan.skipped")) { onSkip(row.slotIndex) }
                    .accessibilityAction(named: Text("plan.addIt")) { onAddIt(row.sortTime) }
            case .skippedOrWasThat:
                self
                    .accessibilityAction(named: Text("plan.skipped")) { onSkip(row.slotIndex) }
                    .accessibilityAction(named: Text("plan.thatWasIt")) {}
            }
        } else {
            self
        }
    }
}
