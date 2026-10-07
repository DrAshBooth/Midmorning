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
/// The share sheet is closed when its completion handler runs and the share
/// sheet is no longer on screen (`ShareSheetController`). From iOS 13 that
/// handler also runs when the person cancels a destination that shows over
/// the share sheet (for example Mail), and the share sheet then stays on
/// screen. The person can choose a second destination, so the file must
/// stay (mm-t45.1, review). A dismissal alone does not close it either:
/// Print removes the share sheet first, and the handler runs when the print
/// options close. Print needs the file until then.
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

    /// The system share sheet. It calls `onClose` once, when the person is
    /// done with it: its completion handler ran, and it is no longer on
    /// screen.
    final class ShareSheetController: UIActivityViewController {
        var onClose: (() -> Void)?
        /// The completion handler ran while the share sheet still showed.
        /// For one second after that, a dismissal is the close that follows
        /// the destination. After that second, a share sheet that still
        /// shows stays: the person cancelled the destination.
        private var closesOnDismissal = false

        /// Sets the completion handler. The handler can run again after a
        /// cancelled destination, so the share sheet sets it again each time
        /// it stays. The handler keeps the share sheet until the close
        /// (`detach`): Print releases the share sheet before its handler
        /// runs.
        func installCompletionHandler() {
            completionWithItemsHandler = { _, _, _, _ in
                self.handleCompletion()
            }
        }

        /// Stops every later call of `onClose` and lets the share sheet go.
        func detach() {
            onClose = nil
            completionWithItemsHandler = nil
            closesOnDismissal = false
        }

        private var isOnScreen: Bool {
            presentingViewController != nil && !isBeingDismissed && viewIfLoaded?.window != nil
        }

        private func handleCompletion() {
            guard onClose != nil else { return }
            guard isOnScreen else { return close() }
            closesOnDismissal = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self, self.closesOnDismissal else { return }
                self.closesOnDismissal = false
                if self.isOnScreen {
                    self.installCompletionHandler()
                } else {
                    self.close()
                }
            }
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            guard closesOnDismissal, isBeingDismissed || presentingViewController == nil else { return }
            closesOnDismissal = false
            close()
        }

        private func close() {
            let onClose = self.onClose
            detach()
            onClose?()
        }
    }

    /// The share sheet of one presentation, from "Make PDF" to the close.
    final class Coordinator {
        /// The share sheet while it shows. UIKit keeps it while it is
        /// presented, so this reference does not.
        weak var shareSheet: ShareSheetController?
        var isShowing = false
        /// The `onDismiss` of the current presentation. It runs once.
        private var pendingDismiss: (() -> Void)?

        func begin(_ shareSheet: ShareSheetController, onDismiss: @escaping () -> Void) {
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
        let controller = ShareSheetController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = Self.excludedActivityTypes
        let isPresented = $isPresented
        controller.onClose = { [weak coordinator, weak controller] in
            guard let coordinator, coordinator.isShowing, coordinator.shareSheet === controller else { return }
            isPresented.wrappedValue = false
            coordinator.finish()
        }
        controller.installCompletionHandler()
        coordinator.begin(controller, onDismiss: onDismiss)
        // The presentation waits for the current view update to finish.
        // The view can leave the screen before then; the share sheet then
        // does not show.
        DispatchQueue.main.async { [weak coordinator] in
            guard let coordinator, coordinator.isShowing, coordinator.shareSheet === controller else { return }
            guard host.viewIfLoaded?.window != nil else {
                controller.detach()
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
            shareSheet.detach()
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
