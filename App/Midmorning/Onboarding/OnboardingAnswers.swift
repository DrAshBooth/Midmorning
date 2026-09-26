import Foundation
import Programme
import Record

/// Height unit choice on screen 2 (onboarding spec, "Screen 2: the
/// screening questions").
enum HeightUnitChoice: String, CaseIterable {
    case centimetres = "cm"
    case feetInches = "ft in"
}

enum WeightUnitChoice: String, CaseIterable {
    case kilograms = "kg"
    case stonePounds = "st lb"
}

/// Everything onboarding collects across its four screens, held only until
/// "Start" writes the four values the store keeps (onboarding spec, "What
/// onboarding keeps and what it never keeps": the app never keeps the typed
/// age, weight, or a screening answer beyond the four kept values).
@MainActor
final class OnboardingAnswers: ObservableObject {
    // Screen 2
    @Published var ageText = ""
    @Published var heightUnit: HeightUnitChoice = .centimetres
    @Published var heightCmText = ""
    @Published var heightFeetText = ""
    @Published var heightInchesText = ""
    @Published var weightUnit: WeightUnitChoice = .kilograms
    @Published var weightKgText = ""
    @Published var weightStoneText = ""
    @Published var weightPoundsText = ""
    @Published var treatmentAnswer: TreatmentAnswer?
    @Published var pregnancyAnswer: PregnancyAnswer?
    @Published var selfHarmFirst: SelfHarmFirstAnswer?
    @Published var selfHarmSecond: SelfHarmSecondAnswer?

    // Screen 3
    @Published var startDayChoice: StartDayChoice.Choice = .today
    @Published var weighInWeekday: Int?
    @Published var wontBeWeighing = false
    @Published var quietHoursOn = true
    @Published var quietHoursStart = "22:00"
    @Published var quietHoursEnd = "07:00"

    // Screen 4
    @Published var appLockOn = true
    @Published var notificationsRequested = false

    var age: Int? { Int(ageText) }

    var heightCm: Double? {
        switch heightUnit {
        case .centimetres:
            return Double(heightCmText)
        case .feetInches:
            guard let feet = Int(heightFeetText), let inches = Int(heightInchesText) else { return nil }
            return BMI.heightCm(feet: feet, inches: inches)
        }
    }

    var weightKg: Double? {
        switch weightUnit {
        case .kilograms:
            return Double(weightKgText)
        case .stonePounds:
            guard let stone = Int(weightStoneText), let pounds = Int(weightPoundsText) else { return nil }
            return BMI.weightKg(stone: stone, pounds: pounds)
        }
    }

    var bmi: Double? {
        guard let heightCm, let weightKg else { return nil }
        return BMI.value(heightCm: heightCm, weightKg: weightKg)
    }

    var selfHarmOutcome: SelfHarmOutcome {
        guard let selfHarmFirst else { return .noFollowUp }
        return SelfHarmItem.outcome(first: selfHarmFirst, second: selfHarmSecond)
    }

    /// Screen 2's six questions plus the conditional second self-harm
    /// question are all answered.
    var screen2Complete: Bool {
        age != nil && heightCm != nil && weightKg != nil
            && treatmentAnswer != nil && pregnancyAnswer != nil && selfHarmFirst != nil
            && (selfHarmFirst != .yes || selfHarmSecond != nil)
    }

    var weighInDayChoice: RecordStore.WeighInDayChoice? {
        if wontBeWeighing { return .wontBeWeighing }
        return weighInWeekday.map(RecordStore.WeighInDayChoice.weekday)
    }

    /// A fresh set of answers, after "Done" on the exclusion page returns to
    /// screen 1 (onboarding spec, "The app keeps nothing from an exclusion").
    func reset() {
        ageText = ""
        heightUnit = .centimetres
        heightCmText = ""
        heightFeetText = ""
        heightInchesText = ""
        weightUnit = .kilograms
        weightKgText = ""
        weightStoneText = ""
        weightPoundsText = ""
        treatmentAnswer = nil
        pregnancyAnswer = nil
        selfHarmFirst = nil
        selfHarmSecond = nil
        startDayChoice = .today
        weighInWeekday = nil
        wontBeWeighing = false
        quietHoursOn = true
        quietHoursStart = "22:00"
        quietHoursEnd = "07:00"
        appLockOn = true
        notificationsRequested = false
    }
}
