import SwiftUI
import UIKit
import Record
import Content
import AppLock
import Programme

/// The settings screen: one screen, one tap from Today (settings spec, "One
/// screen, one tap from Today"). Shows its groups in the spec's order:
/// Reminders, Record, Weigh-in, Privacy, About; `plain system styling`
/// throughout, until `record-full` (1.2b) lands `Appearance.swift` and the
/// shared accent colour asset.
struct SettingsView: View {
    let store: RecordStore
    /// data-and-privacy spec, "Delete-all". Defaults to the real seam built
    /// from the app's own file locations (`RealDeleteAllSeam
    /// .usingAppFileLocations()`), the same paths `AppLockRootView`'s
    /// controller uses for the cover's two controls.
    var deleteAllSeam: DeleteAllSeam = RealDeleteAllSeam.usingAppFileLocations()

    // The app's one real `AppLockController` (built once in
    // `AppLockRootView`, above Today), shared through the environment so the
    // Privacy section's rows and the cover agree on the lock state
    // (mm-t13.9).
    @EnvironmentObject private var appLockController: AppLockController
    /// Tells `AppLockRootView` this screen's own "Delete everything" tap
    /// finished, so the app can show the deleted screen the same way the
    /// cover's own "Delete everything" does (data-and-privacy spec,
    /// "Delete-all").
    @EnvironmentObject private var deletionNotifier: DeletionNotifier

    @State private var dayStartsAt = ClockTime.date(hour: RecordDay.startHour, minute: 0)
    @State private var gapBandsOn = true
    @State private var weeklySummaryOn = true
    @State private var weighInWeekday: Int?
    @State private var weighInUnit: WeightUnit = .kg
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingSupportSheet = false
    @State private var contentInfo: ContentBundle?
    @State private var contactEmail = ""
    @State private var biometry: Biometry = .none
    @State private var diagnosticsCounts = DiagnosticsCounts(
        launchFailures: 0, lastSuccessfulSyncDay: DiagnosticsCounts.noSyncYet, schemaVersion: "", contentVersion: 0,
        pendingReminders: 0, queueLength: 0, lastReconcileOutcome: .init(winners: 0, losers: 0), crashCount: 0
    )

    var body: some View {
        Form {
            Section {
                NavigationLink("settings.reminders.title") {
                    RemindersSettingsView(store: store)
                }
            }

            Section("settings.group.record") {
                DatePicker("settings.record.dayStartsAt", selection: $dayStartsAt, displayedComponents: .hourAndMinute)
                    .onChange(of: dayStartsAt) { saveDayStartsAt() }
                Toggle(ReviewContent.weeklySummarySwitchLabel, isOn: $weeklySummaryOn)
                    .onChange(of: weeklySummaryOn) { _, on in try? store.setWeeklySummaryOn(on) }
                Toggle("settings.record.gapBands", isOn: $gapBandsOn)
                    .onChange(of: gapBandsOn) { _, on in try? store.setGapBandsOn(on) }
            }

            Section("settings.group.weighIn") {
                Picker(Screen3Content.weighInDayHeading, selection: weighInDaySelection) {
                    ForEach(Weekday.allCases, id: \.self) { weekday in
                        Text(weekday.name).tag(Optional(weekday.rawValue))
                    }
                    Text(Screen3Content.wontBeWeighingChoice).tag(Optional<Int>.none)
                }
                .accessibilityLabel(Screen3Content.weighInDayHeading)
                Picker(WeighInContent.unitLabel, selection: $weighInUnit) {
                    Text(WeighInContent.kgChoice).tag(WeightUnit.kg)
                    Text(WeighInContent.stLbChoice).tag(WeightUnit.stLb)
                }
                .accessibilityLabel(WeighInContent.unitLabel)
                .onChange(of: weighInUnit) { _, unit in try? store.setWeighInUnit(unit.rawValue) }
            }

            Section("settings.group.privacy") {
                NavigationLink("settings.privacy.link") {
                    PrivacyNoticeView(contactEmail: contactEmail)
                }
                // data-and-privacy spec, "The app holds no analytics of its
                // own": "Share App Analytics with Apple" opens the app's own
                // page in the iOS Settings app — the one public API Apple
                // gives for this (`UIApplication.openSettingsURLString`).
                // Apple has no supported deep link straight to Privacy &
                // Security, Analytics & Improvements; a decision for Ash
                // (see mm-t41.4's own comment) covers the gap between this
                // and the requirement's literal wording.
                Button("settings.privacy.shareAppAnalytics") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("settings.privacy.deleteEverything", role: .destructive) {
                    isShowingDeleteConfirmation = true
                }
            }

            // The app lock's own switch, "Face ID only"/"Touch ID only" and
            // "Lock after" (app-lock spec, "The app lock is on by default",
            // "Face ID only or Touch ID only", "Lock after": each names "The
            // Privacy group of the settings screen"). `PrivacyAppLockControls`
            // renders its own section against the real `AppLockController`
            // (mm-t13.9).
            PrivacyAppLockControls(controller: appLockController, biometry: biometry)

            Section("settings.group.about") {
                LabeledContent("settings.about.appVersion", value: Self.appVersion)
                    .accessibilityElement(children: .combine)
                HStack {
                    Text("settings.about.contentVersion")
                    Spacer()
                    Text(contentVersionText)
                    if contentInfo?.isDraft == true {
                        Text("settings.about.draftBadge")
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                LabeledContent("settings.about.contact", value: contactEmail)
                    .accessibilityElement(children: .combine)
                NavigationLink("settings.about.diagnostics") {
                    DiagnosticsView(counts: diagnosticsCounts)
                }
            }
        }
        .navigationTitle("settings.title")
        .toolbar {
            // Decision 94: the trailing position of the navigation bar.
            ToolbarItem(placement: .confirmationAction) {
                Button("settings.getSupport") { isShowingSupportSheet = true }
            }
        }
        .confirmationDialog(
            "applock.deleteEverything.confirm.title",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("settings.privacy.deleteEverything", role: .destructive) {
                if (try? deleteAllSeam.deleteEverything()) != nil {
                    deletionNotifier.onEverythingDeleted()
                }
            }
            Button("entry.cancel", role: .cancel) {}
        } message: {
            Text("applock.deleteEverything.confirm.message")
        }
        .sheet(isPresented: $isShowingSupportSheet) {
            GetSupportPlaceholderSheet()
        }
        .onAppear(perform: load)
    }

    private func load() {
        let dayKey = RecordDay.key(containing: Date(), calendar: .current)
        if let hour = try? store.dayStartHour(effectiveOn: dayKey) {
            dayStartsAt = ClockTime.date(hour: hour, minute: 0)
        }
        gapBandsOn = (try? store.gapBandsOn()) ?? true
        weeklySummaryOn = (try? store.weeklySummaryOn()) ?? true
        switch try? store.weighInDayChoice() {
        case .weekday(let weekday): weighInWeekday = weekday
        case .wontBeWeighing, nil: weighInWeekday = nil
        }
        weighInUnit = WeightUnit(rawValue: (try? store.weighInUnit()) ?? "kg") ?? .kg
        if let bundle = try? BundleLoader.loadShipped() {
            contentInfo = bundle
            contactEmail = bundle.string(id: "about.contact")?.text ?? ""
        }
        biometry = BiometryDetector.current()
        if let counts = try? store.diagnosticsCounts(contentVersion: contentInfo?.contentVersion ?? 0) {
            diagnosticsCounts = counts
        }
    }

    private func saveDayStartsAt() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: dayStartsAt)
        try? store.setDayStartHour(hour, now: Date(), calendar: calendar)
    }

    /// settings spec, "The Weigh-in group": the same label and choices as
    /// the weigh-in screen's own control, over the same synced row
    /// (`RecordStore.WeighInDayChoice`).
    private var weighInDaySelection: Binding<Int?> {
        Binding(
            get: { weighInWeekday },
            set: { newValue in
                weighInWeekday = newValue
                if let newValue {
                    try? store.setWeighInDayChoice(.weekday(newValue))
                } else {
                    try? store.setWeighInDayChoice(.wontBeWeighing)
                }
                ReminderCoordinator.recomputeAndApply(store: store)
            }
        )
    }

    private var contentVersionText: String {
        contentInfo.map { String($0.contentVersion) } ?? "—"
    }

    private static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}

/// A minimal stand-in for the support sheet (safeguarding spec, "The support
/// sheet"). `onboarding-and-safeguarding` (1.4, mm-t14.24) builds the real
/// sheet with the Beat, Samaritans, Lifeline and NHS 111 numbers, the call
/// and copy controls and the webchat link; every full screen this change
/// adds calls this placeholder until it lands.
struct GetSupportPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Text("settings.getSupport")
            }
            .navigationTitle("settings.getSupport")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("entry.cancel") { dismiss() }
                }
            }
        }
    }
}
