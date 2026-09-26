import SwiftUI
import AppLock

/// The app-lock items the Privacy group of the settings screen shows
/// (app-lock spec, "The app lock is on by default", "Lock after", "Face ID
/// only or Touch ID only"). `SettingsView` embeds this over the app's one
/// real `AppLockController`, shared through the environment from
/// `AppLockRootView` (mm-t13.9), as its own section beside the Privacy
/// group's "Privacy" link and "Delete everything".
struct PrivacyAppLockControls: View {
    @ObservedObject var controller: AppLockController
    let biometry: Biometry

    @State private var isShowingFaceOrTouchOnlyWarning = false

    private var strings: BiometryStrings { BiometryLabels.strings(for: biometry) }

    var body: some View {
        Section {
            appLockRow
            if let onlyLabel = strings.onlyLabel?.string {
                faceOrTouchOnlyRow(label: onlyLabel)
            }
            lockAfterRow
        } footer: {
            if !strings.isLockEnabled {
                Text(strings.lockLabel.string)
            }
        }
        .confirmationDialog(
            strings.onlyLabel?.string ?? "",
            isPresented: $isShowingFaceOrTouchOnlyWarning,
            titleVisibility: .visible
        ) {
            Button("applock.faceOrTouchOnly.turnOn") {
                controller.confirmTurnOnFaceOrTouchOnly()
            }
            Button("applock.cancel", role: .cancel) {}
        } message: {
            Text(strings.enrolmentWarning?.string ?? "")
        }
    }

    private var appLockRow: some View {
        // Requirement "The app lock is on by default": "When the device has
        // no passcode, the switch MUST be off and disabled." Each change
        // below is kept in `Local.store` by the controller (mm-8jr).
        Toggle(isOn: Binding(
            get: { controller.state.appLockEnabled && strings.isLockEnabled },
            set: { newValue in
                if newValue {
                    controller.turnOnAppLock()
                } else {
                    Task { await controller.tapTurnOffAppLock() }
                }
            }
        )) {
            Text(strings.lockLabel.string)
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
                Text(LockGrace.label(forSeconds: seconds).string).tag(seconds)
            }
        }
    }
}
