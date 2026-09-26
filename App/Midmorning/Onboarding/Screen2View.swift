import SwiftUI
import Programme
import Constants

/// "A few questions first" (onboarding spec, "Screen 2: the screening
/// questions" and "The one-time BMI"). "Continue" stays active. When a
/// question is unanswered or a value is outside its range, the screen shows
/// the message under that question, moves VoiceOver focus to it and does
/// not advance (`ScreeningForm.firstIssue`).
struct Screen2View: View {
    @ObservedObject var answers: OnboardingAnswers
    var onContinue: () -> Void

    @State private var issue: ScreeningFormIssue?
    @AccessibilityFocusState private var focusedField: ScreeningField?

    var body: some View {
        NavigationStack {
            Form {
                ScreeningQuestionSections(answers: answers, asksAge: true, issue: issue, focusedField: $focusedField)
            }
            .navigationTitle(Screen2Content.title)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                FullWidthConfirmButton(CommonLabels.continueLabel, action: attemptContinue)
                    .padding()
                    .background(.bar)
            }
            .getSupport()
        }
    }

    private func attemptContinue() {
        issue = ScreeningForm.firstIssue(answers.formInput(asksAge: true))
        if let issue {
            focusedField = issue.field
            return
        }
        onContinue()
    }
}
