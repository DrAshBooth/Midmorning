import Foundation

/// The programme's seven stages, in the fixed order the app MUST hold them
/// (programme spec, "The seven stages and their tools"). Each stage adds
/// tools on top of the tools before it; a tool stays open in every later
/// stage by construction, because `ProgrammeState.openStages` is the set of
/// stages 1 through the highest open stage's own gate, evaluated
/// independently per stage (a later stage's gate never needs an earlier
/// stage to close).
public enum Stage: Int, Sendable, CaseIterable, Comparable {
    case gettingStarted = 1
    case regularEating = 2
    case alternatives = 3
    case problemSolving = 4
    case takingStock = 5
    case modules = 6
    case stayingOnTrack = 7

    public static func < (lhs: Stage, rhs: Stage) -> Bool { lhs.rawValue < rhs.rawValue }

    /// In stage order, as "Order on the Programme screen" lists them.
    public static let orderedByStage: [Stage] = [.gettingStarted, .regularEating, .alternatives, .problemSolving, .takingStock, .modules, .stayingOnTrack]

    public var title: String {
        switch self {
        case .gettingStarted: return "Getting started"
        case .regularEating: return "Regular eating"
        case .alternatives: return "Alternatives"
        case .problemSolving: return "Problem solving"
        case .takingStock: return "Taking stock"
        case .modules: return "Modules"
        case .stayingOnTrack: return "Staying on track"
        }
    }

    /// The rows in the "Tools" group of this stage's own stage screen
    /// (programme spec, "The stage screen"). Stage 6 lists two rows because
    /// both modules open together.
    public var tools: [StageTool] {
        switch self {
        case .gettingStarted: return [.weighIn]
        case .regularEating: return [.plan]
        case .alternatives: return [.alternativesList]
        case .problemSolving: return [.problemSolving]
        case .takingStock: return [.takingStock]
        case .modules: return [.foodRules, .bodyImage]
        case .stayingOnTrack: return [.stayingOnTrack]
        }
    }

    /// The opening card's sentence, from `ProgrammeConstants`-independent
    /// bundled text (programme spec, "A stage opening shows one card": "The
    /// opening sentences are"). Stage 1 has no opening card.
    public var openingSentence: String? {
        switch self {
        case .gettingStarted: return nil
        case .regularEating: return "You can now plan when to eat. The app reminds you at each planned meal."
        case .alternatives: return "Urge is now on Today. Set up your alternatives list when you have a few minutes."
        case .problemSolving: return "The app can now show patterns from your record. The worksheet is ready."
        case .takingStock: return "Taking stock is ready. It takes one sitting."
        case .modules: return "Both modules are open. Start with either one."
        case .stayingOnTrack: return "Staying on track is open. Write your maintenance plan when you are ready."
        }
    }
}
