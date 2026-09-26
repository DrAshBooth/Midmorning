import SwiftUI
import Record
import Programme

/// The four screens, once, in order (onboarding spec, "Four screens, once,
/// in order"). Nothing here needs a network connection. Leaving the app
/// before "Start" loses every answer; a fresh launch always starts this
/// view fresh at screen 1, with no answer kept.
struct OnboardingRootView: View {
    let store: RecordStore
    var onFinished: () -> Void

    @StateObject private var answers = OnboardingAnswers()
    @State private var step: Step = .screen1
    @State private var exclusion: ExclusionWrapper?
    @State private var isShowingCautionSheet = false

    private enum Step { case screen1, screen2, screen3, screen4 }

    var body: some View {
        Group {
            switch step {
            case .screen1:
                Screen1View(onContinue: { step = .screen2 })
            case .screen2:
                Screen2View(answers: answers, onContinue: handleScreen2Continue)
            case .screen3:
                Screen3View(answers: answers, store: store, onContinue: { step = .screen4 })
            case .screen4:
                Screen4View(answers: answers, store: store, onStart: finish)
            }
        }
        .fullScreenCover(item: $exclusion) { wrapper in
            ExclusionPageView(reasons: wrapper.reasons) {
                exclusion = nil
                answers.reset()
                step = .screen1
            }
        }
        .sheet(isPresented: $isShowingCautionSheet) {
            CautionSheetView(onContinue: {
                isShowingCautionSheet = false
                step = .screen3
            })
        }
        .onAppear {
            // "First launch": the app writes the install moment to
            // Local.store the first time onboarding shows.
            if (try? store.installMoment()) == nil {
                try? store.setInstallMoment(.now)
            }
        }
    }

    /// Screen 2 has a valid answer to every shown question. The screening
    /// decides what follows. The four kept values stay in `answers` until
    /// "Start"; an exclusion or an unfinished onboarding writes nothing
    /// (onboarding spec, "Finish"; safeguarding spec, "The app keeps nothing
    /// from an exclusion").
    private func handleScreen2Continue() {
        guard
            let age = answers.age,
            let heightCm = answers.heightCm,
            let weightKg = answers.weightKg,
            let pregnancy = answers.pregnancyAnswer,
            let treatment = answers.treatmentAnswer
        else { return }

        answers.keptScreening = nil
        let outcome = OnboardingScreening.evaluate(
            age: age, heightCm: heightCm, weightKg: weightKg,
            pregnancy: pregnancy, treatment: treatment, selfHarm: answers.selfHarmOutcome, now: .now
        )
        switch outcome {
        case .excluded(let reasons):
            exclusion = ExclusionWrapper(reasons: reasons)
        case .cautionSheet(let kept):
            answers.keptScreening = kept
            isShowingCautionSheet = true
        case .continues(let kept):
            answers.keptScreening = kept
            step = .screen3
        }
    }

    /// "Start": writes the four kept screening values (onboarding spec,
    /// "What onboarding keeps and what it never keeps") and the commitment.
    /// The typed age and weight themselves are never written.
    private func finish() {
        if let kept = answers.keptScreening {
            try? store.setProfile(heightCm: kept.heightCm, onboardingBMI: kept.onboardingBMI, cautionFlag: kept.cautionFlag, askedAt: kept.askedAt)
        }
        if let dayKey = try? computeStartDayKey() {
            try? store.setStartDayKey(dayKey)
        }
        if let choice = answers.weighInDayChoice {
            try? store.setWeighInDayChoice(choice)
        }
        try? store.setQuietHoursOn(answers.quietHoursOn)
        try? store.setQuietHoursStart(answers.quietHoursStart)
        try? store.setQuietHoursEnd(answers.quietHoursEnd)
        onFinished()
    }

    private func computeStartDayKey() throws -> String {
        StartDayChoice.dayKey(for: answers.startDayChoice, now: .now, calendar: .current, schedule: try store.dayStartSchedule())
    }
}

private struct ExclusionWrapper: Identifiable {
    let id = UUID()
    let reasons: [ExclusionReason]
}
