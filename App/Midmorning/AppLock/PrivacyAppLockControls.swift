import SwiftUI
import AppLock

/// The app-lock items the Privacy group of the settings screen shows
/// (settings spec, "The Privacy group"; app-lock spec, "The app lock is on
/// by default", "Lock after", "Face ID only or Touch ID only"). `settings`
/// (1.3, mm-t13) is not merged in this worktree, so this view is a fixture
/// built and tested on its own, standalone, over `AppLockController` — not
/// embedded in a real settings screen (the change README, "Built over
/// fixture facts"). mm-t13's own wiring bead embeds these three rows in the
/// real Privacy group once it exists.
struct PrivacyAppLockControls: View {
    @ObservedObject var controller: AppLockController
    let biometry: Biometry

    @State private var isShowingFaceOrTouchOnlyWarning = false

    private var strings: BiometryStrings { BiometryLabels.strings(for: biometry) }

    var body: some View {
        Section {
            appLockRow
            if let onlyLabel = strings.onlyLabel {
                faceOrTouchOnlyRow(label: onlyLabel)
            }
            lockAfterRow
        } footer: {
            if !strings.isLockEnabled {
                Text(strings.lockLabel)
            }
        }
        .confirmationDialog(
            strings.onlyLabel ?? "",
            isPresented: $isShowingFaceOrTouchOnlyWarning,
            titleVisibility: .visible
        ) {
            Button("applock.faceOrTouchOnly.turnOn") {
                controller.confirmTurnOnFaceOrTouchOnly()
            }
            Button("applock.cancel", role: .cancel) {}
        } message: {
            Text(strings.enrolmentWarning ?? "")
        }
    }

    private var appLockRow: some View {
        Toggle(isOn: Binding(
            get: { controller.state.appLockEnabled },
            set: { newValue in
                if newValue {
                    controller.turnOnAppLock()
                } else {
                    Task { await controller.tapTurnOffAppLock() }
                }
            }
        )) {
            Text(strings.lockLabel)
        }
        .disabled(!strings.isLockEnabled)
    }

    private func faceOrTouchOnlyRow(label: String) -> some View {
        Toggle(isOn: Binding(
            get: { controller.state.faceOrTouchOnlyEnabled },
            set: { newValue in
                if newValue {
                    isShowingFaceOrTouchOnlyWarning = true
                } else {
                    Task { await controller.tapTurnOffFaceOrTouchOnly() }
                }
            }
        )) {
            Text(label)
        }
        .disabled(!BiometryLabels.isFaceOrTouchOnlyAvailable(biometry: biometry, appLockEnabled: controller.state.appLockEnabled))
    }

    private var lockAfterRow: some View {
        Picker(
            "applock.privacy.lockAfter.label",
            selection: Binding(
                get: { Int(controller.state.lockAfterSeconds) },
                set: { controller.setLockAfterSeconds(TimeInterval($0)) }
            )
        ) {
            ForEach(LockGrace.choices, id: \.self) { seconds in
                Text(LockGrace.label(forSeconds: seconds)).tag(seconds)
            }
        }
    }
}
