import Foundation
import SwiftData

/// Reserved neutral name; holds no rows in V1. A custom place is a
/// `ListItem` of kind "customPlace" (design.md, "Model names, singletons and
/// the account binding").
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Place {
    public var id: UUID = UUID()

    public init(id: UUID = UUID()) {
        self.id = id
    }
}
