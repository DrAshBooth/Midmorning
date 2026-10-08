import SwiftUI
import Record
import Programme
import Export

/// "Export your record to take with you" (safeguarding spec, "The GP
/// suggestion page", "The not-right-now page"; export spec, "The export
/// offered by the deterioration rule"). Pushes the real export screen onto
/// the page's own `NavigationStack`, with the default range and no text
/// about why it opened (`mm-t42.13`, `mm-t42.8`).
struct ExportControlButton: View {
    let store: RecordStore

    /// The link has a hit area of at least 44 by 44 points
    /// (`minimumHitArea`); as plain text it was 20 points high.
    var body: some View {
        NavigationLink {
            ExportScreenView(store: store)
        } label: {
            Text(CommonLabels.exportControl.string).minimumHitArea()
        }
    }
}
