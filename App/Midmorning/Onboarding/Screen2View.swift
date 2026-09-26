import SwiftUI
import Programme
import Constants

/// "A few questions first" (onboarding spec, "Screen 2: the screening
/// questions"). "Continue" stays active; an unanswered question moves
/// VoiceOver focus to itself and shows "Please answer this one." under it,
/// without advancing.
struct Screen2View: View {
    @ObservedObject var answers: OnboardingAnswers
    var onContinue: () -> Void

    private enum Field: Hashable {
        case age, height, weight, treatment, pregnancy, selfHarmFirst, selfHarmSecond
    }

    @State private var invalidField: Field?
    @State private var heightMessage: String?
    @State private var weightMessage: String?
    @AccessibilityFocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(Screen2Content.ageQuestion, text: $answers.ageText)
                        .keyboardType(.numberPad)
                        .accessibilityFocused($focusedField, equals: .age)
                    if invalidField == .age { Text(Screen2Content.unansweredMessage).foregroundStyle(.red) }
                } header: { Text(Screen2Content.ageQuestion) }

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
                    if let heightMessage { Text(heightMessage).foregroundStyle(.red) }
                } header: { Text(Screen2Content.heightQuestion) }
                .accessibilityFocused($focusedField, equals: .height)

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
                    if let weightMessage { Text(weightMessage).foregroundStyle(.red) }
                } header: { Text(Screen2Content.weightQuestion) }
                .accessibilityFocused($focusedField, equals: .weight)

                Section {
                    Text(Screen2Content.heightWeightIntro).font(.footnote).foregroundStyle(.secondary)
                }

                Section {
                    Picker(Screen2Content.treatmentQuestion, selection: $answers.treatmentAnswer) {
                        Text(CommonLabels.no).tag(TreatmentAnswer?.some(.no))
                        Text(CommonLabels.treatmentYesWithAgreement).tag(TreatmentAnswer?.some(.yesWithAgreement))
                        Text(CommonLabels.yes).tag(TreatmentAnswer?.some(.yes))
                    }
                    .pickerStyle(.inline)
                    if invalidField == .treatment { Text(Screen2Content.unansweredMessage).foregroundStyle(.red) }
                } header: { Text(Screen2Content.treatmentQuestion) }
                .accessibilityFocused($focusedField, equals: .treatment)

                Section {
                    Picker(Screen2Content.pregnancyQuestion, selection: $answers.pregnancyAnswer) {
                        Text(CommonLabels.no).tag(PregnancyAnswer?.some(.no))
                        Text(CommonLabels.yes).tag(PregnancyAnswer?.some(.yes))
                        Text(CommonLabels.doesNotApplyToMe).tag(PregnancyAnswer?.some(.doesNotApply))
                    }
                    .pickerStyle(.inline)
                    if invalidField == .pregnancy { Text(Screen2Content.unansweredMessage).foregroundStyle(.red) }
                } header: { Text(Screen2Content.pregnancyQuestion) }
                .accessibilityFocused($focusedField, equals: .pregnancy)

                Section {
                    Picker(ScreeningQuestionCatalog.questions[5], selection: $answers.selfHarmFirst) {
                        Text(CommonLabels.no).tag(SelfHarmFirstAnswer?.some(.no))
                        Text(CommonLabels.yes).tag(SelfHarmFirstAnswer?.some(.yes))
                        Text(CommonLabels.ratherNotSay).tag(SelfHarmFirstAnswer?.some(.ratherNotSay))
                    }
                    .pickerStyle(.inline)
                    if invalidField == .selfHarmFirst { Text(Screen2Content.unansweredMessage).foregroundStyle(.red) }

                    if answers.selfHarmFirst == .yes {
                        Picker(ScreeningQuestionCatalog.selfHarmSecondQuestion, selection: $answers.selfHarmSecond) {
                            Text(CommonLabels.no).tag(SelfHarmSecondAnswer?.some(.no))
                            Text(CommonLabels.yes).tag(SelfHarmSecondAnswer?.some(.yes))
                        }
                        .pickerStyle(.inline)
                        if invalidField == .selfHarmSecond { Text(Screen2Content.unansweredMessage).foregroundStyle(.red) }
                    }

                    if showsSelfHarmSupport {
                        Text(SelfHarmItem.supportLine)
                    }
                } header: { Text(ScreeningQuestionCatalog.questions[5]) }
                .accessibilityFocused($focusedField, equals: .selfHarmFirst)

                if showsSelfHarmSupport {
                    SelfHarmInlineSupport()
                }
            }
            .navigationTitle(Screen2Content.title)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(CommonLabels.continueLabel) { attemptContinue() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.bar)
            }
            .getSupport()
            .onChange(of: answers.selfHarmFirst) { _, newValue in
                if newValue != .yes { answers.selfHarmSecond = nil }
            }
        }
    }

    /// "Yes" and then "No" to the self-harm item (safeguarding spec, "The
    /// self-harm item").
    private var showsSelfHarmSupport: Bool {
        answers.selfHarmFirst == .yes && answers.selfHarmSecond == .no
    }

    private func attemptContinue() {
        heightMessage = nil
        weightMessage = nil
        invalidField = nil

        guard answers.age != nil else { return fail(.age) }
        guard let heightCm = answers.heightCm else { return fail(.height) }
        guard let weightKg = answers.weightKg else { return fail(.weight) }

        let heightValidity = ScreeningLimits.validate(heightCm: heightCm)
        if heightValidity != .valid {
            heightMessage = ScreeningLimits.heightMessage()
            return fail(.height)
        }
        let weightValidity = ScreeningLimits.validate(weightKg: weightKg)
        if weightValidity != .valid {
            weightMessage = ScreeningLimits.weightMessage()
            return fail(.weight)
        }
        guard answers.treatmentAnswer != nil else { return fail(.treatment) }
        guard answers.pregnancyAnswer != nil else { return fail(.pregnancy) }
        guard answers.selfHarmFirst != nil else { return fail(.selfHarmFirst) }
        if answers.selfHarmFirst == .yes, answers.selfHarmSecond == nil { return fail(.selfHarmSecond) }

        onContinue()
    }

    private func fail(_ field: Field) {
        invalidField = field
        focusedField = field
    }
}
