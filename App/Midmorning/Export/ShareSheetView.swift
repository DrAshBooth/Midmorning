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
/// When this view leaves the screen while the share sheet shows, the share
/// sheet closes at once, with no animation, and `onDismiss` runs. A SwiftUI
/// sheet did this by itself; a UIKit presentation does not. The case: with
/// the app lock on, the person taps "Delete everything" or "Delete from this
/// device" on the cover while the share sheet is under it. The deleted
/// screen then replaces the export screen, and the share sheet must not stay
/// over it with the PDF of the deleted record (mm-t45.1, review).
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

    /// The share sheet of one presentation, from "Make PDF" to the close.
    final class Coordinator {
        /// The share sheet while it shows. UIKit keeps it while it is
        /// presented, so this reference does not.
        weak var shareSheet: UIActivityViewController?
        var isShowing = false
        /// The `onDismiss` of the current presentation. It runs once.
        private var pendingDismiss: (() -> Void)?

        func begin(_ shareSheet: UIActivityViewController, onDismiss: @escaping () -> Void) {
            self.shareSheet = shareSheet
            isShowing = true
            pendingDismiss = onDismiss
        }

        func finish() {
            isShowing = false
            shareSheet = nil
            let onDismiss = pendingDismiss
            pendingDismiss = nil
            onDismiss?()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        let coordinator = context.coordinator
        guard isPresented, !items.isEmpty, !coordinator.isShowing else { return }
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = Self.excludedActivityTypes
        let isPresented = $isPresented
        controller.completionWithItemsHandler = { [weak coordinator] _, _, _, _ in
            isPresented.wrappedValue = false
            coordinator?.finish()
        }
        coordinator.begin(controller, onDismiss: onDismiss)
        // The presentation waits for the current view update to finish.
        // The view can leave the screen before then; the share sheet then
        // does not show.
        DispatchQueue.main.async { [weak coordinator] in
            guard let coordinator, coordinator.isShowing, coordinator.shareSheet === controller else { return }
            guard host.viewIfLoaded?.window != nil else {
                isPresented.wrappedValue = false
                coordinator.finish()
                return
            }
            host.present(controller, animated: true)
        }
    }

    /// The view leaves the screen: the share sheet closes at once, with
    /// everything it presented (Save to Files, Print, Markup), and
    /// `onDismiss` deletes the file.
    static func dismantleUIViewController(_ host: UIViewController, coordinator: Coordinator) {
        guard coordinator.isShowing else { return }
        // A presentation that has not started yet does not start.
        coordinator.isShowing = false
        if let shareSheet = coordinator.shareSheet {
            shareSheet.completionWithItemsHandler = nil
            // A view controller presents one view controller at a time, so
            // this closes the share sheet and nothing under it.
            shareSheet.presentingViewController?.dismiss(animated: false)
        }
        // SwiftUI is in a view update here, and `onDismiss` can change the
        // state of the view that leaves.
        DispatchQueue.main.async {
            coordinator.finish()
        }
    }
}
