import SwiftUI
import UserNotifications
import Record
import Programme
import AppLock

/// "Permissions" (onboarding spec, "Screen 4: your record", "Screen 4:
/// permissions" and "Finish"). "Start" stays active and completes onboarding
/// at once, because "Your record" has one choice in the first cut.
struct Screen4View: View {
    @ObservedObject var answers: OnboardingAnswers
    let store: RecordStore
    var onStart: () -> Void

    @State private var isShowingWidgetSheet = false
    /// Read once, when the screen appears (`BiometryDetector`).
    @State private var biometry: Biometry?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(Screen4Content.yourRecordHeading)) {
                    Text(Screen4Content.yourRecordSentence)
                    // The only choice in the first cut, shown as chosen with
                    // no image (product-rules spec, "Appearance": the app
                    // adds only four SF Symbols — plus, pin, lock, chevron —
                    // and a checkmark is not one of them).
                    LabeledContent(Screen4Content.thisDeviceOnly, value: CommonLabels.chosen)
                    Text(Screen4Content.iCloudLaterVersion).font(.footnote).foregroundStyle(.secondary)
                }

                Section {
                    Text(Screen4Content.notificationsExplanation)
                    Button(Screen4Content.allowNotifications) { requestNotifications() }
                }

                // onboarding spec, "Screen 4: permissions": the switch, with
                // the label `app-lock` defines, and the lock sentence under
                // it, both for the device's own `Biometry`. With no device
                // passcode the switch is off and disabled, with the
                // passcode message under it (app-lock spec, "The app lock
                // is on by default").
                Section {
                    Toggle(lockStrings.lockLabel, isOn: lockStrings.isLockEnabled ? $answers.appLockOn : .constant(false))
                        .disabled(!lockStrings.isLockEnabled)
                    Text(lockStrings.isLockEnabled ? lockStrings.onboardingSentence : BiometryLabels.noPasscodeMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text(Screen4Content.widgetExplanation)
                    Button(Screen4Content.showMeHow) { isShowingWidgetSheet = true }
                }
            }
            .navigationTitle(Screen4Content.title)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                FullWidthConfirmButton(Screen4Content.startLabel, action: start)
                    .padding()
                    .background(.bar)
            }
            .getSupport()
            .onAppear {
                if biometry == nil { biometry = BiometryDetector.current() }
            }
            .sheet(isPresented: $isShowingWidgetSheet) {
                NavigationStack {
                    Text(Screen4Content.widgetInstructions)
                        .padding()
                        .navigationTitle(Screen4Content.showMeHow)
                        .toolbar {
                            // One tap closes the sheet to screen 4, which
                            // shows Get support (safeguarding spec, "Get
                            // support on every screen").
                            ToolbarItem(placement: .cancellationAction) {
                                Button(CommonLabels.close) { isShowingWidgetSheet = false }
                            }
                        }
                }
            }
        }
    }

    /// The label, the enabled state and the sentence for the device's own
    /// `Biometry`, from `app-lock`'s one label function (mm-t14.31).
    private var lockStrings: BiometryStrings {
        BiometryLabels.strings(for: biometry ?? .passcodeOnly)
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            DispatchQueue.main.async { answers.notificationsRequested = true }
        }
    }

    private func start() {
        do {
            try store.setLocalSettingValue(answers.appLockOn ? "true" : "false", key: AppLockSettingsKeys.enabled)
            // "Notifications denied" / "Notifications not asked": onboarding
            // completes with every reminder switch on regardless (`reminders`
            // owns the switches themselves; this change writes none yet).
            try store.setOnboardingCompleted(true)
            try store.setSyncOn(false)
        } catch {
            // The store carries no entry data to lose here; onboarding
            // cannot proceed without a working store, matching
            // `MidmorningApp`'s own "the store did not open" fault handling.
        }
        onStart()
    }
}
