import SwiftUI
import AppLock

/// The screen the app-lock spec's "The cover" requirement defines: shown the
/// moment the app is inactive or locked, over every other screen, Get
/// support included, because the cover names nothing.
///
/// `AppLockController.state.coverMode` decides what shows:
/// - `.none`: nothing; the real screen shows.
/// - `.privacyOnly`: "Midmorning" only, for the App Switcher snapshot, or
///   the plain cover the lock control shows with the app lock off (a tap
///   dismisses it, with no authentication request).
/// - `.locked`: "Midmorning", "Unlock" and "Delete everything".
/// - `.lockedAfterEnrolmentChange`: "Midmorning", "Delete from this device"
///   and "Delete everything", with no "Unlock".
struct CoverView: View {
    @ObservedObject var controller: AppLockController
    /// Until 4.1 (`local-delete-all`) replaces it, "Everything is deleted"
    /// only shows this screen; nothing is actually deleted (the change
    /// README names this a stub).
    var onEverythingDeleted: () -> Void = {}

    private enum Focus: Hashable {
        case unlock
        case deleteFromThisDevice
    }

    @AccessibilityFocusState private var focusedControl: Focus?
    @State private var isShowingDeleteEverythingConfirmation = false
    @State private var isShowingDeleteFromThisDeviceConfirmation = false
    @State private var isShowingEverythingDeleted = false

    var body: some View {
        switch controller.state.coverMode {
        case .none:
            EmptyView()
        case .privacyOnly:
            privacyCover
        case .locked:
            lockedCover(showsUnlock: true)
        case .lockedAfterEnrolmentChange:
            lockedCover(showsUnlock: false)
        }
    }

    /// "Midmorning" only: the App Switcher snapshot, and the app-lock-off
    /// cover the lock control shows.
    private var privacyCover: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            Text("applock.cover.title")
                .font(.title2)
        }
        .contentShape(Rectangle())
        .onTapGesture { controller.tapCoverToDismiss() }
    }

    private func lockedCover(showsUnlock: Bool) -> some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("applock.cover.title")
                    .font(.largeTitle)
                if showsUnlock {
                    Button("applock.cover.unlock") { Task { await tapUnlock() } }
                        .buttonStyle(.borderedProminent)
                        .accessibilityFocused($focusedControl, equals: .unlock)
                } else {
                    Button("applock.cover.deleteFromThisDevice") {
                        isShowingDeleteFromThisDeviceConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .accessibilityFocused($focusedControl, equals: .deleteFromThisDevice)
                }
                Button("applock.cover.deleteEverything") { Task { await tapDeleteEverything() } }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .dynamicTypeSize(...(.accessibility5))
            .padding()
        }
        .task(id: showsUnlock) {
            focusedControl = showsUnlock ? .unlock : .deleteFromThisDevice
        }
        .confirmationDialog(
            "applock.deleteEverything.confirm.title",
            isPresented: $isShowingDeleteEverythingConfirmation,
            titleVisibility: .visible
        ) {
            Button("applock.cover.deleteEverything", role: .destructive) {
                Task {
                    await controller.confirmDeleteEverything()
                    isShowingEverythingDeleted = true
                }
            }
            Button("applock.cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "applock.deleteFromThisDevice.confirm.title",
            isPresented: $isShowingDeleteFromThisDeviceConfirmation,
            titleVisibility: .visible
        ) {
            Button("applock.cover.deleteFromThisDevice", role: .destructive) {
                Task {
                    await controller.confirmDeleteFromThisDevice()
                    isShowingEverythingDeleted = true
                }
            }
            Button("applock.cancel", role: .cancel) {}
        } message: {
            Text("applock.deleteFromThisDevice.confirm.message")
        }
        .alert("applock.deleteEverything.done.message", isPresented: $isShowingEverythingDeleted) {
            Button("applock.done") { onEverythingDeleted() }
        }
    }

    /// "Unlock": on failure or cancel, focus returns to "Unlock" (app-lock
    /// spec, "Accessibility of the cover" — the cover itself builds the
    /// hook; the P2 accessibility bead proves it on a device).
    private func tapUnlock() async {
        let succeeded = await controller.tapUnlock()
        if !succeeded { focusedControl = .unlock }
    }

    /// "Delete everything": on success, show the confirmation; on failure
    /// or cancel, the cover stays and nothing is deleted.
    private func tapDeleteEverything() async {
        let succeeded = await controller.tapDeleteEverything()
        if succeeded {
            isShowingDeleteEverythingConfirmation = true
        } else {
            focusedControl = controller.state.enrolmentChanged ? .deleteFromThisDevice : .unlock
        }
    }
}
