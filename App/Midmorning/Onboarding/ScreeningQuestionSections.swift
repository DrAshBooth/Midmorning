import SwiftUI
import Programme

/// The screening questions as Form sections, shared by onboarding screen 2
/// and the restart re-screen (onboarding spec, "Screen 2: the screening
/// questions"; safeguarding spec, "Re-screening at a restart": the
/// re-screen asks height and weight with the wording that onboarding
/// defines, shows the line above them, and asks pregnancy, treatment and
/// the self-harm item with both steps, but not the age).
///
/// Each question is a section with the question as its header. When
/// `ScreeningForm.firstIssue` stops "Continue", the section of that question
/// shows the issue's message and gets VoiceOver focus. After "Yes" and then
/// "No" to the self-harm item, the support line shows under the item and
/// the support sheet's items follow inline, with Samaritans first.
struct ScreeningQuestionSections: View {
    @ObservedObject var answers: OnboardingAnswers
    let asksAge: Bool
    let issue: ScreeningFormIssue?
    var focusedField: AccessibilityFocusState<ScreeningField?>.Binding

    var body: some View {
        if asksAge {
            Section {
                TextField(Screen2Content.ageQuestion, text: $answers.ageText)
                    .keyboardType(.numberPad)
                message(for: .age)
            } header: { Text(Screen2Content.ageQuestion) }
            .accessibilityFocused(focusedField, equals: .age)
        }

        // "Above the height and weight fields the screen MUST show" this line.
        Section {
            Text(Screen2Content.heightWeightIntro).font(.footnote).foregroundStyle(.secondary)
        }

        Section {
            Picker("unit.label", selection: $answers.heightUnit) {
                ForEach(HeightUnitChoice.allCases, id: \.self) { Text($0.labelKey).tag($0) }
            }
            .pickerStyle(.segmented)
            if answers.heightUnit == .centimetres {
                TextField("unit.cm", text: $answers.heightCmText)
                    .keyboardType(.numberPad)
                    .accessibilityLabel("screening.height.centimetres")
            } else {
                HStack {
                    TextField("unit.ft", text: $answers.heightFeetText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("screening.height.feet")
                    TextField("unit.in", text: $answers.heightInchesText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("screening.height.inches")
                }
            }
            message(for: .height)
        } header: { Text(Screen2Content.heightQuestion) }
        .accessibilityFocused(focusedField, equals: .height)

        Section {
            Picker("unit.label", selection: $answers.weightUnit) {
                ForEach(WeightUnitChoice.allCases, id: \.self) { Text($0.labelKey).tag($0) }
            }
            .pickerStyle(.segmented)
            if answers.weightUnit == .kilograms {
                TextField("unit.kg", text: $answers.weightKgText)
                    .keyboardType(.numberPad)
                    .accessibilityLabel("screening.weight.kilograms")
            } else {
                HStack {
                    TextField("unit.st", text: $answers.weightStoneText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("screening.weight.stone")
                    TextField("unit.lb", text: $answers.weightPoundsText)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("screening.weight.pounds")
                }
            }
            message(for: .weight)
        } header: { Text(Screen2Content.weightQuestion) }
        .accessibilityFocused(focusedField, equals: .weight)

        Section {
            Picker(Screen2Content.treatmentQuestion, selection: $answers.treatmentAnswer) {
                Text(CommonLabels.no.string).tag(TreatmentAnswer?.some(.no))
                Text(CommonLabels.treatmentYesWithAgreement).tag(TreatmentAnswer?.some(.yesWithAgreement))
                Text(CommonLabels.yes.string).tag(TreatmentAnswer?.some(.yes))
            }
            .pickerStyle(.inline)
            message(for: .treatment)
        } header: { Text(Screen2Content.treatmentQuestion) }
        .accessibilityFocused(focusedField, equals: .treatment)

        Section {
            Picker(Screen2Content.pregnancyQuestion, selection: $answers.pregnancyAnswer) {
                Text(CommonLabels.no.string).tag(PregnancyAnswer?.some(.no))
                Text(CommonLabels.yes.string).tag(PregnancyAnswer?.some(.yes))
                Text(CommonLabels.doesNotApplyToMe).tag(PregnancyAnswer?.some(.doesNotApply))
            }
            .pickerStyle(.inline)
            message(for: .pregnancy)
        } header: { Text(Screen2Content.pregnancyQuestion) }
        .accessibilityFocused(focusedField, equals: .pregnancy)

        Section {
            Picker(ScreeningQuestionCatalog.questions[5], selection: $answers.selfHarmFirst) {
                Text(CommonLabels.no.string).tag(SelfHarmFirstAnswer?.some(.no))
                Text(CommonLabels.yes.string).tag(SelfHarmFirstAnswer?.some(.yes))
                Text(CommonLabels.ratherNotSay).tag(SelfHarmFirstAnswer?.some(.ratherNotSay))
            }
            .pickerStyle(.inline)
            message(for: .selfHarmFirst)
        } header: { Text(ScreeningQuestionCatalog.questions[5]) }
        .accessibilityFocused(focusedField, equals: .selfHarmFirst)
        .onChange(of: answers.selfHarmFirst) { _, newValue in
            // "The app MUST hide the second question when the person changes
            // the first answer."
            if newValue != .yes { answers.selfHarmSecond = nil }
        }

        if answers.selfHarmFirst == .yes {
            Section {
                Picker(ScreeningQuestionCatalog.selfHarmSecondQuestion, selection: $answers.selfHarmSecond) {
                    Text(CommonLabels.no.string).tag(SelfHarmSecondAnswer?.some(.no))
                    Text(CommonLabels.yes.string).tag(SelfHarmSecondAnswer?.some(.yes))
                }
                .pickerStyle(.inline)
                message(for: .selfHarmSecond)
                if answers.selfHarmSecond == .no {
                    Text(SelfHarmItem.supportLine)
                }
            } header: { Text(ScreeningQuestionCatalog.selfHarmSecondQuestion) }
            .accessibilityFocused(focusedField, equals: .selfHarmSecond)

            if answers.selfHarmSecond == .no {
                SelfHarmInlineSupport()
            }
        }
    }

    @ViewBuilder
    private func message(for field: ScreeningField) -> some View {
        if let issue, issue.field == field {
            Text(issue.problem.message()).foregroundStyle(.red)
        }
    }
}

/// Each unit segment's label, a key in Localizable.xcstrings (content spec,
/// "Strings live in catalogues"). The weigh-in screen shows the same keys.
private extension HeightUnitChoice {
    var labelKey: LocalizedStringKey {
        switch self {
        case .centimetres: return "unit.cm"
        case .feetInches: return "unit.ftIn"
        }
    }
}

private extension WeightUnitChoice {
    var labelKey: LocalizedStringKey {
        switch self {
        case .kilograms: return "unit.kg"
        case .stonePounds: return "unit.stLb"
        }
    }
}
