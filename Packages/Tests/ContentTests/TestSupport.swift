import Foundation
@testable import Content

/// The shipped bundle, loaded once per test process from the source
/// `Resources` directory (not the built resource bundle), so a test sees a
/// content edit immediately.
enum Shipped {
    static let bundle: ContentBundle = {
        do {
            return try ContentBundle.load(from: RepositoryRoot.contentResourcesDirectory, environment: [:])
        } catch {
            fatalError("could not load the shipped content bundle: \(error)")
        }
    }()
}

/// A short, valid card for scenarios that need one card and do not care
/// about its content, so each scenario only sets the field it is testing.
func fixtureCard(
    id: String = "fixture.card",
    section: Card.Section = .stage(1),
    title: String = "Fixture card",
    body: String = "This is a short, ordinary card body. It holds two sentences.",
    oneThing: String = "Do the one small thing.",
    links: [CardLink] = [],
    retired: Bool = false
) -> Card {
    Card(id: id, section: section, title: title, body: body, oneThing: oneThing, links: links, retired: retired)
}
