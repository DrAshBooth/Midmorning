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
    /// The four values the store keeps from the screening, held here until
    /// "Start" writes them (onboarding spec, "Finish": "The app MUST NOT
    /// keep answers from an unfinished onboarding.").
    @Published var keptScreening: ScreeningKeptValues?

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

    var age: Int? { Int(ageText.trimmingCharacters(in: .whitespaces)) }

    /// The typed height, parsed. Inches accept 0 to 11.
    var height: TypedMeasure {
        switch heightUnit {
        case .centimetres:
            return TypedMeasureParser.heightCm(centimetres: heightCmText)
        case .feetInches:
            return TypedMeasureParser.heightCm(feet: heightFeetText, inches: heightInchesText)
        }
    }

    /// The typed weight, parsed. Pounds accept 0 to 13.
    var weight: TypedMeasure {
        switch weightUnit {
        case .kilograms:
            return TypedMeasureParser.weightKg(kilograms: weightKgText)
        case .stonePounds:
            return TypedMeasureParser.weightKg(stone: weightStoneText, pounds: weightPoundsText)
        }
    }

    var heightCm: Double? { height.value }

    var weightKg: Double? { weight.value }

    /// The answers as `ScreeningForm` reads them. The restart re-screen
    /// passes `asksAge: false`, because it never asks the age again.
    func formInput(asksAge: Bool) -> ScreeningFormInput {
        ScreeningFormInput(
            ageText: asksAge ? ageText : nil,
            height: height,
            weight: weight,
            treatmentAnswered: treatmentAnswer != nil,
            pregnancyAnswered: pregnancyAnswer != nil,
            selfHarmFirst: selfHarmFirst,
            selfHarmSecondAnswered: selfHarmSecond != nil
        )
    }

    var selfHarmOutcome: SelfHarmOutcome {
        guard let selfHarmFirst else { return .noFollowUp }
        return SelfHarmItem.outcome(first: selfHarmFirst, second: selfHarmSecond)
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
        keptScreening = nil
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
