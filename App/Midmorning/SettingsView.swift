import SwiftUI
import Record
import Content

/// The settings screen: one screen, one tap from Today (settings spec, "One
/// screen, one tap from Today"). Shows its groups in the spec's order:
/// Reminders, Record, Privacy, About. The Weigh-in group joins between
/// Record and Privacy once `weigh-in` (2.2) builds it; `plain system
/// styling` throughout, until `record-full` (1.2b) lands `Appearance.swift`
/// and the shared accent colour asset.
struct SettingsView: View {
    let store: RecordStore
    var deleteAllSeam: DeleteAllSeam = StubDeleteAllSeam()

    @State private var dayStartsAt = ClockTime.date(hour: RecordDay.startHour, minute: 0)
    @State private var gapBandsOn = true
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingSupportSheet = false
    @State private var contentInfo: ContentBundle?
    @State private var contactEmail = ""

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
                Toggle("settings.record.gapBands", isOn: $gapBandsOn)
                    .onChange(of: gapBandsOn) { _, on in try? store.setGapBandsOn(on) }
            }

            // The Weigh-in group: `weigh-in` (2.2) adds it here.

            Section("settings.group.privacy") {
                NavigationLink("settings.privacy.link") {
                    PrivacyNoticeView(contactEmail: contactEmail)
                }
                Button("settings.privacy.deleteEverything", role: .destructive) {
                    isShowingDeleteConfirmation = true
                }
            }

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
                // "Face ID only" (`app-lock`, mm-t15.13) and "Diagnostics"
                // (`local-delete-all`, mm-t41.13) join this group once each
                // change lands.
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
            "settings.privacy.deleteEverything",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("settings.privacy.deleteEverything", role: .destructive) {
                try? deleteAllSeam.deleteEverything()
            }
            Button("entry.cancel", role: .cancel) {}
        } message: {
            Text("settings.privacy.deleteEverything.message")
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
        if let bundle = try? BundleLoader.loadShipped() {
            contentInfo = bundle
            contactEmail = bundle.string(id: "about.contact")?.text ?? ""
        }
    }

    private func saveDayStartsAt() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: dayStartsAt)
        try? store.setDayStartHour(hour, now: Date(), calendar: calendar)
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
