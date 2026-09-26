import SwiftUI
import UIKit
import Record
import Content
import AppLock
import Programme
import Export
import Constants

/// The settings screen: one screen, one tap from Today (settings spec, "One
/// screen, one tap from Today"). Shows its groups in the spec's order:
/// Reminders, Record, Weigh-in, Privacy, About.
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

    /// `load()` reads the hour in force from the next record day.
    @State private var dayStartHour = RecordDay.startHour
    @State private var gapBandsOn = true
    @State private var weeklySummaryOn = true
    @State private var weighInWeekday: Int?
    @State private var weighInUnit: WeightUnit = .kg
    @State private var isShowingDeleteConfirmation = false
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
                // settings spec, "The Record group": a whole hour from
                // 00:00 to 12:00. Each control writes only from its own
                // setter, so opening the screen writes no row (mm-t13.13).
                Picker("settings.record.dayStartsAt", selection: dayStartHourSelection) {
                    ForEach(RecordDay.startHourChoices, id: \.self) { hour in
                        Text(verbatim: ClockTime.string(hour: hour, minute: 0)).tag(hour)
                    }
                }
                Toggle(ReviewContent.weeklySummarySwitchLabel, isOn: Binding(
                    get: { weeklySummaryOn },
                    set: { on in weeklySummaryOn = on; try? store.setWeeklySummaryOn(on) }
                ))
                Toggle("settings.record.gapBands", isOn: Binding(
                    get: { gapBandsOn },
                    set: { on in gapBandsOn = on; try? store.setGapBandsOn(on) }
                ))
                // settings spec, "The Record group": "'Export' as a
                // control." export spec, "Choose a date range": reachable
                // from the settings screen in one tap, and from Today in two
                // (Today's own "Settings" control is the first).
                NavigationLink(ExportContent.screenTitle) {
                    ExportScreenView(store: store)
                }
            }

            Section("settings.group.weighIn") {
                Picker(Screen3Content.weighInDayHeading, selection: weighInDaySelection) {
                    ForEach(Weekday.mondayFirst, id: \.self) { weekday in
                        Text(weekday.name).tag(Optional(weekday.rawValue))
                    }
                    Text(Screen3Content.wontBeWeighingChoice).tag(Optional<Int>.none)
                }
                .accessibilityLabel(Screen3Content.weighInDayHeading)
                Picker(WeighInContent.unitLabel, selection: Binding(
                    get: { weighInUnit },
                    set: { unit in weighInUnit = unit; try? store.setWeighInUnit(unit.rawValue) }
                )) {
                    Text(WeighInContent.kgChoice).tag(WeightUnit.kg)
                    Text(WeighInContent.stLbChoice).tag(WeightUnit.stLb)
                }
                .accessibilityLabel(WeighInContent.unitLabel)
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
        .getSupport()
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
        .onAppear(perform: load)
    }

    private func load() {
        if let hour = try? store.dayStartHourFromNextRecordDay(after: Date(), calendar: .current) {
            dayStartHour = hour
        }
        gapBandsOn = (try? store.gapBandsOn()) ?? RecordStore.Defaults.gapBandsOn
        weeklySummaryOn = (try? store.weeklySummaryOn()) ?? RecordStore.Defaults.weeklySummaryOn
        weighInWeekday = (try? store.weighInDayChoice())?.weekday
        weighInUnit = WeightUnit(rawValue: (try? store.weighInUnit()) ?? RecordStore.Defaults.weighInUnit) ?? .kg
        if let bundle = try? BundleLoader.loadShipped() {
            contentInfo = bundle
            contactEmail = bundle.string(id: "about.contact")?.text ?? ""
        }
        biometry = BiometryDetector.current()
        if let counts = try? store.diagnosticsCounts(contentVersion: contentInfo?.contentVersion ?? 0) {
            diagnosticsCounts = counts
        }
        // data-and-privacy spec, "The Diagnostics counts come from the
        // device": the pending requests and the queue file's actions.
        let contentVersion = contentInfo?.contentVersion ?? 0
        ReminderDiagnosticsSource.read { source in
            if let counts = try? store.diagnosticsCounts(contentVersion: contentVersion, sourceCounts: source) {
                diagnosticsCounts = counts
            }
        }
    }

    /// A new hour applies from the next day start (settings spec, "The
    /// Record group"). The row shows it at once, and a second choice of the
    /// same hour writes no row. The reminder horizon then uses the new day
    /// start for the days it changes.
    private var dayStartHourSelection: Binding<Int> {
        Binding(
            get: { dayStartHour },
            set: { hour in
                guard hour != dayStartHour else { return }
                dayStartHour = hour
                try? store.setDayStartHour(hour, now: Date(), calendar: .current)
                ReminderCoordinator.recomputeAndApply(store: store)
            }
        )
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
