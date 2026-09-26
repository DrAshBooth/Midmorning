import SwiftUI
import Record
import Programme

/// The restart re-screen (safeguarding spec, "Re-screening at a restart"):
/// height, weight, pregnancy, treatment and the self-harm item, with no age
/// question. It shares onboarding screen 2's questions, messages, focus
/// moves and range checks (`ScreeningQuestionSections`, `ScreeningForm`).
/// `RestartRescreen.evaluate` decides the outcome. With the caution flag set
/// and no rule that excludes, the caution sheet shows before the start-day
/// choice ("The BMI rules, with the caution sheet, apply to the new height
/// and weight.").
struct RescreenView: View {
    let store: RecordStore
    var onExcluded: ([ExclusionReason]) -> Void
    var onNoExclusion: () -> Void

    @StateObject private var answers = OnboardingAnswers()
    @State private var issue: ScreeningFormIssue?
    @State private var isShowingCautionSheet = false
    @AccessibilityFocusState private var focusedField: ScreeningField?

    var body: some View {
        NavigationStack {
            Form {
                ScreeningQuestionSections(answers: answers, asksAge: false, issue: issue, focusedField: $focusedField)
            }
            .navigationTitle("programme.rescreen.title")
            .safeAreaInset(edge: .bottom) {
                FullWidthConfirmButton(CommonLabels.continueLabel, action: attemptContinue)
                    .padding()
                    .background(.bar)
            }
            .getSupport()
            .sheet(isPresented: $isShowingCautionSheet) {
                CautionSheetView(onContinue: {
                    isShowingCautionSheet = false
                    onNoExclusion()
                })
            }
        }
    }

    private func attemptContinue() {
        issue = ScreeningForm.firstIssue(answers.formInput(asksAge: false))
        if let issue {
            focusedField = issue.field
            return
        }
        guard let heightCm = answers.heightCm, let weightKg = answers.weightKg,
              let pregnancy = answers.pregnancyAnswer, let treatment = answers.treatmentAnswer,
              let selfHarmFirst = answers.selfHarmFirst
        else { return }
        let rescreenAnswers = RescreenAnswers(
            heightCm: heightCm, weightKg: weightKg,
            pregnancy: pregnancy, treatment: treatment,
            selfHarmFirst: selfHarmFirst, selfHarmSecond: answers.selfHarmSecond
        )
        let result = RestartRescreen.evaluate(rescreenAnswers, now: Date())
        if result.excluded {
            if result.remindersPausedByWeightReason {
                try? store.pauseReminders(at: Date())
            }
            onExcluded(result.reasons)
        } else {
            try? store.setProfile(heightCm: result.newHeightCm, onboardingBMI: result.newOnboardingBMI, cautionFlag: result.newCautionFlag, askedAt: result.newAskedAt, changedAt: result.newAskedAt)
            if result.newCautionFlag {
                isShowingCautionSheet = true
            } else {
                onNoExclusion()
            }
        }
    }
}
