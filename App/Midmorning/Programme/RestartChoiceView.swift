import SwiftUI
import Record
import Programme

/// "Start week 1 again" (programme spec, "Start week 1 again"): a re-screen
/// first when more than 84 record days have passed since the last screening
/// (safeguarding spec, "Re-screening at a restart"), then the start-day
/// choice.
struct RestartChoiceView: View {
    let store: RecordStore
    var onFinished: () -> Void

    private enum Step {
        case deciding, rescreen, choice, excluded([ExclusionReason])
    }

    @State private var step: Step = .deciding
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch step {
            case .deciding:
                ProgressView().onAppear(perform: decide)
            case .rescreen:
                RescreenView(store: store, onExcluded: { step = .excluded($0) }, onNoExclusion: { step = .choice })
            case .choice:
                choiceView
            case .excluded(let reasons):
                NotRightNowPageView(reasons: reasons) {
                    onFinished()
                    dismiss()
                }
            }
        }
    }

    private var choiceView: some View {
        NavigationStack {
            List {
                Button("programme.restart.today") { restart(.today) }
                Button("programme.restart.tomorrow") { restart(.tomorrow) }
            }
            .navigationTitle("programme.startWeek1Again")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("programme.restart.cancel") { dismiss() }
                }
            }
        }
    }

    private func decide() {
        let now = Date()
        let calendar = Calendar.current
        let dayStart = (try? store.dayStartHour(effectiveOn: RecordDay.key(containing: now, calendar: calendar))) ?? RecordDay.startHour
        let currentRecordDay = RecordDay.key(containing: now, calendar: calendar, startHour: dayStart)
        let askedAt = try? store.profile()?.askedAt
        if RestartGate.rescreenRequired(askedAt: askedAt ?? nil, now: now, currentRecordDay: currentRecordDay, dayStart: dayStart, calendar: calendar) {
            step = .rescreen
        } else {
            step = .choice
        }
    }

    private func restart(_ choice: StartDayChoice.Choice) {
        let now = Date()
        let calendar = Calendar.current
        let newStartDay = StartDayChoice.dayKey(for: choice, now: now, calendar: calendar)
        try? store.setStartDayKey(newStartDay, changedAt: now)
        try? store.setRestartAt(now, changedAt: now)
        onFinished()
        dismiss()
    }
}
