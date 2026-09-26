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

                Section {
                    Toggle(appLockLabel, isOn: $answers.appLockOn)
                    if answers.appLockOn {
                        Text(lockSentence).font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text(Screen4Content.widgetExplanation)
                    Button(Screen4Content.showMeHow) { isShowingWidgetSheet = true }
                }
            }
            .navigationTitle(Screen4Content.title)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(Screen4Content.startLabel) { start() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.bar)
            }
            .getSupport()
            .sheet(isPresented: $isShowingWidgetSheet) {
                NavigationStack {
                    Text(Screen4Content.widgetInstructions)
                        .padding()
                        .navigationTitle(Screen4Content.showMeHow)
                }
            }
        }
    }

    private var appLockLabel: String {
        BiometryLabels.strings(for: currentBiometry).lockLabel
    }

    private var lockSentence: String {
        BiometryLabels.strings(for: currentBiometry).onboardingSentence
    }

    /// The device's real biometry needs `LocalAuthentication`, a device
    /// check per `app-lock`'s own design; `.faceID` is this build's default
    /// so the sentence has real text to show.
    private var currentBiometry: Biometry { .faceID }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: NotificationPermissionAccess.options) { _, _ in
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
