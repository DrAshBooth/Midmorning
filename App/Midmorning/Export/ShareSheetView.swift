import SwiftUI
import UIKit

/// The system share sheet over one file (export spec, "Share sheet only":
/// "On 'Make PDF' the app MUST build the PDF on the device and present it
/// in the system share sheet."). `UIActivityViewController` is UIKit-only;
/// SwiftUI has no share-sheet view, so this wraps it the same way
/// `SafariView` wraps `SFSafariViewController`.
///
/// The sheet does not offer Copy (r13-14, mm-t42.27). Copy would put the
/// whole-record PDF on the general pasteboard with no expiry, and Universal
/// Clipboard can carry it to other devices (data-and-privacy: the app MUST
/// NOT send the person's data to the pasteboard).
struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    /// The activities the export share sheet never offers.
    static let excludedActivityTypes: [UIActivity.ActivityType] = [.copyToPasteboard]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = Self.excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
