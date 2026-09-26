import Foundation
import Content

/// The content bundle the app ships, read once per launch (content spec,
/// "The app bundles the cards"). The bundle is part of the app and does not
/// change while the app runs, so a view reads this value and does not read
/// and decode the files again on each render.
enum ShippedContent {
    static let bundle: ContentBundle? = try? BundleLoader.loadShipped()
}
