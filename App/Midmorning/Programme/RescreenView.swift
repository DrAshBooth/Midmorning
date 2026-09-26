import SwiftUI
import Record
import Programme

/// The restart re-screen (safeguarding spec, "Re-screening at a restart"):
/// height, weight, pregnancy, treatment and the self-harm item, with no age
/// question. Reuses `OnboardingAnswers` for its typed fields and unit
/// conversion; `RestartRescreen.evaluate` decides the outcome.
struct RescreenView: View {
    let store: RecordStore
    var onExcluded: ([ExclusionReason]) -> Void
    var onNoExclusion: () -> Void

    @StateObject private var answers = OnboardingAnswers()
    @State private var invalidMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(Screen2Content.heightWeightIntro).font(.footnote).foregroundStyle(.secondary)
                }

                Section {
                    Picker("Unit", selection: $answers.heightUnit) {
                        ForEach(HeightUnitChoice.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if answers.heightUnit == .centimetres {
                        TextField("cm", text: $answers.heightCmText).keyboardType(.numberPad)
                    } else {
                        HStack {
                            TextField("ft", text: $answers.heightFeetText).keyboardType(.numberPad)
                            TextField("in", text: $answers.heightInchesText).keyboardType(.numberPad)
                        }
                    }
                } header: { Text(Screen2Content.heightQuestion) }

                Section {
                    Picker("Unit", selection: $answers.weightUnit) {
                        ForEach(WeightUnitChoice.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if answers.weightUnit == .kilograms {
                        TextField("kg", text: $answers.weightKgText).keyboardType(.numberPad)
                    } else {
                        HStack {
                            TextField("st", text: $answers.weightStoneText).keyboardType(.numberPad)
                            TextField("lb", text: $answers.weightPoundsText).keyboardType(.numberPad)
                        }
                    }
                } header: { Text(Screen2Content.weightQuestion) }

                Section {
                    Picker(Screen2Content.treatmentQuestion, selection: $answers.treatmentAnswer) {
                        Text(CommonLabels.no).tag(TreatmentAnswer?.some(.no))
                        Text(CommonLabels.treatmentYesWithAgreement).tag(TreatmentAnswer?.some(.yesWithAgreement))
                        Text(CommonLabels.yes).tag(TreatmentAnswer?.some(.yes))
                    }
                    .pickerStyle(.inline)
                } header: { Text(Screen2Content.treatmentQuestion) }

                Section {
                    Picker(Screen2Content.pregnancyQuestion, selection: $answers.pregnancyAnswer) {
                        Text(CommonLabels.no).tag(PregnancyAnswer?.some(.no))
                        Text(CommonLabels.yes).tag(PregnancyAnswer?.some(.yes))
                        Text(CommonLabels.doesNotApplyToMe).tag(PregnancyAnswer?.some(.doesNotApply))
                    }
                    .pickerStyle(.inline)
                } header: { Text(Screen2Content.pregnancyQuestion) }

                Section {
                    Picker(ScreeningQuestionCatalog.questions[5], selection: $answers.selfHarmFirst) {
                        Text(CommonLabels.no).tag(SelfHarmFirstAnswer?.some(.no))
                        Text(CommonLabels.yes).tag(SelfHarmFirstAnswer?.some(.yes))
                        Text(CommonLabels.ratherNotSay).tag(SelfHarmFirstAnswer?.some(.ratherNotSay))
                    }
                    .pickerStyle(.inline)
                    if answers.selfHarmFirst == .yes {
                        Picker(ScreeningQuestionCatalog.selfHarmSecondQuestion, selection: $answers.selfHarmSecond) {
                            Text(CommonLabels.no).tag(SelfHarmSecondAnswer?.some(.no))
                            Text(CommonLabels.yes).tag(SelfHarmSecondAnswer?.some(.yes))
                        }
                        .pickerStyle(.inline)
                    }
                    if answers.selfHarmFirst == .yes, answers.selfHarmSecond == .no {
                        Text(SelfHarmItem.supportLine)
                    }
                } header: { Text(ScreeningQuestionCatalog.questions[5]) }

                if answers.selfHarmFirst == .yes, answers.selfHarmSecond == .no {
                    SelfHarmInlineSupport()
                }

                if let invalidMessage {
                    Text(invalidMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("programme.rescreen.title")
            .safeAreaInset(edge: .bottom) {
                Button(CommonLabels.continueLabel) { attemptContinue() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.bar)
            }
            .getSupport()
        }
    }

    private func attemptContinue() {
        invalidMessage = nil
        guard let heightCm = answers.heightCm, let weightKg = answers.weightKg,
              answers.treatmentAnswer != nil, answers.pregnancyAnswer != nil, answers.selfHarmFirst != nil,
              answers.selfHarmFirst != .yes || answers.selfHarmSecond != nil
        else {
            invalidMessage = Screen2Content.unansweredMessage
            return
        }
        let rescreenAnswers = RescreenAnswers(
            heightCm: heightCm, weightKg: weightKg,
            pregnancy: answers.pregnancyAnswer ?? .no, treatment: answers.treatmentAnswer ?? .no,
            selfHarmFirst: answers.selfHarmFirst ?? .no, selfHarmSecond: answers.selfHarmSecond
        )
        let result = RestartRescreen.evaluate(rescreenAnswers, now: Date())
        if result.excluded {
            if result.remindersPausedByWeightReason {
                try? store.pauseReminders(at: Date())
            }
            onExcluded(result.reasons)
        } else {
            try? store.setProfile(heightCm: result.newHeightCm, onboardingBMI: result.newOnboardingBMI, cautionFlag: result.newCautionFlag, askedAt: result.newAskedAt, changedAt: result.newAskedAt)
            onNoExclusion()
        }
    }
}
