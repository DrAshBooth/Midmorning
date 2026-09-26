import SwiftUI
import Record
import Programme
import Constants

/// "Your start" (onboarding spec, "Screen 3: the start day", "Screen 3:
/// weigh-in day and quiet hours" and "Screen 3: the record in three
/// sentences"). One screen, three sections, one "Continue".
struct Screen3View: View {
    @ObservedObject var answers: OnboardingAnswers
    let store: RecordStore
    var now: Date = .now
    var calendar: Calendar = .current
    var onContinue: () -> Void

    @State private var weighInDayInvalid = false
    @AccessibilityFocusState private var weighInDayFocused: Bool

    private let weekdays: [Programme.Weekday] = Programme.Weekday.mondayFirst

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(Screen3Content.startDayQuestion.string)) {
                    Picker(Screen3Content.startDayQuestion.string, selection: $answers.startDayChoice) {
                        Text(StartDayChoice.label(for: .today, now: now, calendar: calendar, schedule: dayStartSchedule).string).tag(StartDayChoice.Choice.today)
                        Text(StartDayChoice.label(for: .tomorrow, now: now, calendar: calendar, schedule: dayStartSchedule).string).tag(StartDayChoice.Choice.tomorrow)
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    ForEach(0..<Screen3Content.threeSentences.count, id: \.self) { index in
                        Text(Screen3Content.threeSentences[index].string)
                    }
                    HStack {
                        Text(Screen3Content.exampleTime)
                        Text(Screen3Content.exampleWhat.string)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Screen3Content.exampleVoiceOverLabel.string)
                    Text(DayBoundaryLine.text(startHour: dayStartHour).string)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(header: Text(Screen3Content.weighInDayHeading.string)) {
                    Picker(Screen3Content.weighInDayHeading.string, selection: weighInSelection) {
                        ForEach(weekdays, id: \.self) { weekday in
                            Text(weekday.name).tag(Optional(WeighInSelection.weekday(weekday.rawValue)))
                        }
                        Text(Screen3Content.wontBeWeighingChoice.string).tag(Optional(WeighInSelection.wontBeWeighing))
                    }
                    .pickerStyle(.inline)
                    Text(Screen3Content.weighInExplanation.string).font(.footnote).foregroundStyle(.secondary)
                    if weighInDayInvalid {
                        Text(Screen3Content.unansweredMessage.string).foregroundStyle(.red)
                    }
                }
                .accessibilityFocused($weighInDayFocused)

                Section(header: Text(Screen3Content.quietHoursHeading.string)) {
                    Toggle(Screen3Content.quietHoursHeading.string, isOn: $answers.quietHoursOn)
                    if answers.quietHoursOn {
                        DatePicker("settings.reminders.quietHours.start", selection: timeBinding($answers.quietHoursStart), displayedComponents: .hourAndMinute)
                        DatePicker("settings.reminders.quietHours.end", selection: timeBinding($answers.quietHoursEnd), displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle(Screen3Content.title.string)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                FullWidthConfirmButton(CommonLabels.continueLabel, action: attemptContinue)
                    .padding()
                    .background(.bar)
            }
            .getSupport()
        }
    }

    private enum WeighInSelection: Hashable {
        case weekday(Int)
        case wontBeWeighing
    }

    private var weighInSelection: Binding<WeighInSelection?> {
        Binding<WeighInSelection?>(
            get: {
                if answers.wontBeWeighing { return .wontBeWeighing }
                return answers.weighInWeekday.map(WeighInSelection.weekday)
            },
            set: { newValue in
                switch newValue {
                case .weekday(let weekday):
                    answers.weighInWeekday = weekday
                    answers.wontBeWeighing = false
                case .wontBeWeighing:
                    answers.wontBeWeighing = true
                    answers.weighInWeekday = nil
                case nil:
                    answers.weighInWeekday = nil
                    answers.wontBeWeighing = false
                }
            }
        )
    }

    private var dayStartSchedule: DayStartSchedule {
        (try? store.dayStartSchedule()) ?? .standard
    }

    private var dayStartHour: Int {
        let schedule = dayStartSchedule
        return schedule.hour(effectiveOn: RecordDay.key(containing: now, calendar: calendar, schedule: schedule))
    }

    private func attemptContinue() {
        guard answers.weighInWeekday != nil || answers.wontBeWeighing else {
            weighInDayInvalid = true
            weighInDayFocused = true
            return
        }
        weighInDayInvalid = false
        onContinue()
    }

    /// A "HH:mm" string as a `Date` binding, for `DatePicker`.
    private func timeBinding(_ text: Binding<String>) -> Binding<Date> {
        Binding<Date>(
            get: { ClockTime.date(from: text.wrappedValue, calendar: calendar) },
            set: { text.wrappedValue = ClockTime.string(from: $0, calendar: calendar) }
        )
    }
}
