import SwiftUI
import Record
import AppLock

/// The page the container failure shows (data-and-privacy spec, "Launch
/// safety": "When the container throws for any reason other than
/// unavailable protected data, the app MUST show one page... with Get
/// support, 'Try again' and 'Delete everything'... The app MUST NOT delete
/// the store without the person's confirmation."). `onTryAgain` asks
/// `AppLockRootView` to attempt the open again; `onDeleted` switches to the
/// deleted screen once the confirmed deletion finishes.
struct StoreOpenFailureView: View {
    let seam: DeleteAllSeam
    var onTryAgain: () -> Void
    var onDeleted: () -> Void

    @State private var isShowingSupportSheet = false
    @State private var isShowingDeleteConfirmation = false
    @State private var deleteOutcome: DeleteAllOutcome?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("applock.storeOpenFailure.message")
                    .multilineTextAlignment(.center)
                Button("applock.storeOpenFailure.tryAgain", action: onTryAgain)
                    .buttonStyle(.borderedProminent)
                Button("today.getSupport") { isShowingSupportSheet = true }
                    .buttonStyle(.bordered)
                Button("settings.privacy.deleteEverything", role: .destructive) {
                    isShowingDeleteConfirmation = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                // data-and-privacy spec, "Delete-all" (ruling r14-01): one
                // line under the controls after a failed deletion.
                if deleteOutcome == .failed {
                    Text(DeleteAllOutcome.failureMessage.string)
                        .foregroundStyle(.secondary)
                }
            }
            .dynamicTypeSize(...(.accessibility5))
            .padding()
        }
        .sheet(isPresented: $isShowingSupportSheet) {
            SupportSheetView()
        }
        // Ruling r16-03 (mm-t12b.28): an alert shows "Delete everything"
        // and "Cancel"; from iOS 26 a confirmation dialog shows no "Cancel".
        .alert(
            "applock.deleteEverything.confirm.title",
            isPresented: $isShowingDeleteConfirmation
        ) {
            Button("settings.privacy.deleteEverything", role: .destructive) {
                // The deleted screen only after a deletion that succeeded;
                // on failure this page stays and shows the failure line.
                deleteOutcome = DeleteAllOutcome.of { try seam.deleteEverything() }
                if deleteOutcome == .deleted { onDeleted() }
            }
            Button("entry.cancel", role: .cancel) {}
        } message: {
            Text("applock.deleteEverything.confirm.message")
        }
    }
}
