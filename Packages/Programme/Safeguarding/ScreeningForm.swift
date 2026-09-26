import Foundation
import Constants

/// A number the person typed into a height or weight field, after the parse
/// (onboarding spec, "The one-time BMI"; weigh-in spec, "The number and its
/// unit").
public enum TypedMeasure: Sendable, Equatable {
    /// A field is empty, or holds no number of the kind the field asks for.
    case missing
    /// A part is outside its own range: inches outside 0 to 11, or pounds
    /// outside 0 to 13.
    case partOutOfRange
    /// The measure in centimetres or kilograms, not rounded.
    case value(Double)

    public var value: Double? {
        if case .value(let measure) = self { return measure }
        return nil
    }
}

/// The parse of the typed height and weight. The number fields use the
/// numeric keypad, so a whole number is the normal input. Centimetres and
/// kilograms also accept a decimal. Feet, inches, stone and pounds accept a
/// whole number only.
public enum TypedMeasureParser {
    public static let inchesRange = 0...11
    public static let poundsRange = 0...13

    public static func heightCm(centimetres: String) -> TypedMeasure {
        guard let cm = Double(centimetres.trimmingCharacters(in: .whitespaces)), cm.isFinite else { return .missing }
        return .value(cm)
    }

    public static func heightCm(feet: String, inches: String) -> TypedMeasure {
        guard let feet = Int(feet.trimmingCharacters(in: .whitespaces)),
              let inches = Int(inches.trimmingCharacters(in: .whitespaces))
        else { return .missing }
        guard inchesRange.contains(inches) else { return .partOutOfRange }
        return .value(BMI.heightCm(feet: feet, inches: inches))
    }

    public static func weightKg(kilograms: String) -> TypedMeasure {
        guard let kg = Double(kilograms.trimmingCharacters(in: .whitespaces)), kg.isFinite else { return .missing }
        return .value(kg)
    }

    public static func weightKg(stone: String, pounds: String) -> TypedMeasure {
        guard let stone = Int(stone.trimmingCharacters(in: .whitespaces)),
              let pounds = Int(pounds.trimmingCharacters(in: .whitespaces))
        else { return .missing }
        guard poundsRange.contains(pounds) else { return .partOutOfRange }
        return .value(BMI.weightKg(stone: stone, pounds: pounds))
    }
}

/// A question on onboarding screen 2 or on the restart re-screen, in the
/// order the screen shows them.
public enum ScreeningField: Sendable, Hashable, CaseIterable {
    case age, height, weight, treatment, pregnancy, selfHarmFirst, selfHarmSecond
}

/// What the screen shows under a question when "Continue" cannot advance.
public enum ScreeningFieldProblem: Sendable, Equatable {
    /// "Please answer this one."
    case unanswered
    /// "Enter a height between 100 and 250 cm."
    case heightOutOfRange
    /// "Enter a weight of 30 kg or more."
    case weightOutOfRange

    /// The text under the question.
    public func message(constants: ProgrammeConstants = .default) -> String {
        switch self {
        case .unanswered: return Screen2Content.unansweredMessage
        case .heightOutOfRange: return ScreeningLimits.heightMessage(constants: constants)
        case .weightOutOfRange: return ScreeningLimits.weightMessage(constants: constants)
        }
    }
}

/// The first question that stops "Continue", and why.
public struct ScreeningFormIssue: Sendable, Equatable {
    public let field: ScreeningField
    public let problem: ScreeningFieldProblem

    public init(field: ScreeningField, problem: ScreeningFieldProblem) {
        self.field = field
        self.problem = problem
    }
}

/// The screen's answers as the check reads them.
public struct ScreeningFormInput: Sendable, Equatable {
    /// The typed age. `nil` at the restart re-screen, which MUST NOT ask
    /// the age again (safeguarding spec, "Re-screening at a restart").
    public var ageText: String?
    public var height: TypedMeasure
    public var weight: TypedMeasure
    public var treatmentAnswered: Bool
    public var pregnancyAnswered: Bool
    public var selfHarmFirst: SelfHarmFirstAnswer?
    public var selfHarmSecondAnswered: Bool

    public init(ageText: String?, height: TypedMeasure, weight: TypedMeasure, treatmentAnswered: Bool, pregnancyAnswered: Bool, selfHarmFirst: SelfHarmFirstAnswer?, selfHarmSecondAnswered: Bool) {
        self.ageText = ageText
        self.height = height
        self.weight = weight
        self.treatmentAnswered = treatmentAnswered
        self.pregnancyAnswered = pregnancyAnswered
        self.selfHarmFirst = selfHarmFirst
        self.selfHarmSecondAnswered = selfHarmSecondAnswered
    }
}

/// The check that "Continue" runs on onboarding screen 2 and on the restart
/// re-screen before the screening rules (onboarding spec, "Screen 2: the
/// screening questions" and "The one-time BMI"; safeguarding spec,
/// "Re-screening at a restart": the re-screen asks height and weight with
/// the wording that onboarding defines). "Continue" stays active. The
/// screen shows the problem's message under the field, moves VoiceOver
/// focus to that field and does not advance.
public enum ScreeningForm {
    /// The first question, in screen order, that is unanswered or holds a
    /// value outside its range. `nil` when every shown question has a valid
    /// answer.
    public static func firstIssue(_ input: ScreeningFormInput, constants: ProgrammeConstants = .default) -> ScreeningFormIssue? {
        if let ageText = input.ageText, Int(ageText.trimmingCharacters(in: .whitespaces)) == nil {
            return ScreeningFormIssue(field: .age, problem: .unanswered)
        }
        switch input.height {
        case .missing:
            return ScreeningFormIssue(field: .height, problem: .unanswered)
        case .partOutOfRange:
            return ScreeningFormIssue(field: .height, problem: .heightOutOfRange)
        case .value(let cm):
            if ScreeningLimits.validate(heightCm: cm, constants: constants) != .valid {
                return ScreeningFormIssue(field: .height, problem: .heightOutOfRange)
            }
        }
        switch input.weight {
        case .missing:
            return ScreeningFormIssue(field: .weight, problem: .unanswered)
        case .partOutOfRange:
            return ScreeningFormIssue(field: .weight, problem: .weightOutOfRange)
        case .value(let kg):
            if ScreeningLimits.validate(weightKg: kg, constants: constants) != .valid {
                return ScreeningFormIssue(field: .weight, problem: .weightOutOfRange)
            }
        }
        if !input.treatmentAnswered { return ScreeningFormIssue(field: .treatment, problem: .unanswered) }
        if !input.pregnancyAnswered { return ScreeningFormIssue(field: .pregnancy, problem: .unanswered) }
        guard let first = input.selfHarmFirst else { return ScreeningFormIssue(field: .selfHarmFirst, problem: .unanswered) }
        if SelfHarmItem.showsSecondQuestion(after: first), !input.selfHarmSecondAnswered {
            return ScreeningFormIssue(field: .selfHarmSecond, problem: .unanswered)
        }
        return nil
    }
}
