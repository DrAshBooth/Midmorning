import SwiftUI
import UIKit

/// The system share sheet over one file (export spec, "Share sheet only":
/// "On 'Make PDF' the app MUST build the PDF on the device and present it
/// in the system share sheet.").
///
/// `UIActivityViewController` must be presented modally on iPhone. Inside a
/// SwiftUI `.sheet` it shows an empty sheet on iOS 27, with no destination
/// (found by `AutomatedChecks.testTheExportShareSheetShowsNoCopy`). So this
/// view is an empty view that the export screen puts in its background. Its
/// own view controller presents the share sheet while `isPresented` is
/// true, and calls `onDismiss` when the share sheet closes, after a share or
/// a cancel ("The app MUST delete the file when the share sheet closes").
///
/// The sheet does not offer Copy (r13-14, mm-t42.27). Copy would put the
/// whole-record PDF on the general pasteboard with no expiry, and Universal
/// Clipboard can carry it to other devices (data-and-privacy: the app MUST
/// NOT send the person's data to the pasteboard).
struct ShareSheetView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let items: [Any]
    var onDismiss: () -> Void = {}

    /// The activities the export share sheet never offers.
    static let excludedActivityTypes: [UIActivity.ActivityType] = [.copyToPasteboard]

    final class Coordinator {
        var isShowing = false
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        guard isPresented, !items.isEmpty, !context.coordinator.isShowing else { return }
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = Self.excludedActivityTypes
        let isPresented = $isPresented
        let onDismiss = onDismiss
        let coordinator = context.coordinator
        controller.completionWithItemsHandler = { _, _, _, _ in
            coordinator.isShowing = false
            isPresented.wrappedValue = false
            onDismiss()
        }
        coordinator.isShowing = true
        // The presentation waits for the current view update to finish.
        DispatchQueue.main.async {
            host.present(controller, animated: true)
        }
    }
}
