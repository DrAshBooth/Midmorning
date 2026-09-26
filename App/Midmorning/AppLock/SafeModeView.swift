import SwiftUI
import Record
import Export

/// Safe mode's own Today (data-and-privacy spec, "Launch safety": "In safe
/// mode the app MUST show Today with Export and Get support."). A minimal
/// screen, not the full `TodayView`: safe mode's whole point is to reach a
/// working screen with none of the ordinary launch work running again — no
/// onboarding gate, no reminder scheduler call (`AppLockRootView` never
/// builds `RunningRootView` for this phase, so
/// `ReminderCoordinator.recomputeAndApply` is never called). The app lock
/// still applies: `SafeModeRootView` shows the cover over this screen
/// (mm-t42.21). `mm-t42.13`
/// connects the real export screen; `mm-t42.20` proves the three-launch
/// entry end to end, over `Record.LaunchSafety`.
struct SafeModeView: View {
    let store: RecordStore

    var body: some View {
        NavigationStack {
            List {
                NavigationLink(ExportContent.screenTitle) {
                    ExportScreenView(store: store)
                }
            }
            .navigationTitle("today.title")
            .getSupport()
        }
    }
}
