import Foundation
import Constants

/// One row in a stage's "Tools" group (programme spec, "The seven stages
/// and their tools", "The stage screen"). A screen picks the row's action
/// from the case, never from its words, and shows `label`, a key in the
/// app's string catalogue (content spec, "Strings live in catalogues").
public enum StageTool: String, Sendable, Equatable, CaseIterable {
    case weighIn, plan, alternativesList, problemSolving, takingStock, foodRules, bodyImage, stayingOnTrack

    public var label: CatalogueText {
        .key("programme.tool.\(rawValue)")
    }
}
