import SwiftUI
import UIKit
import UserNotifications
import Record
import Programme
import Constants

/// The Reminders group's own screen, one tap from the settings screen
/// (settings spec, "The Reminders group"). First cut: "Worksheet review",
/// "Check-in" and "Break through Focus for planned meals" are absent; the
/// settings remainder beads under 3.3, 3.6 and 2.5 add them.
struct RemindersSettingsView: View {
    let store: RecordStore

    @State private var switches: [RecordStore.ReminderSwitch: Bool] = [:]
    @State private var setTodaysPlanTime = ClockTime.date(from: RecordStore.ReminderTime.setTodaysPlan.defaultTime)
    @State private var closeTheDayTime = ClockTime.date(from: RecordStore.ReminderTime.closeTheDay.defaultTime)
    @State private var weighInTime = ClockTime.date(from: RecordStore.ReminderTime.weighIn.defaultTime)
    @State private var weeklyReviewTime = ClockTime.date(from: RecordStore.ReminderTime.weeklyReview.defaultTime)
    @State private var explicitWordingOn = RecordStore.Defaults.explicitWordingOn
    @State private var remindAgainMinutes = RecordStore.Defaults.remindAgainMinutes
    @State private var quietHoursOn = RecordStore.Defaults.quietHours.isOn
    @State private var quietHoursStart = ClockTime.date(from: RecordStore.Defaults.quietHours.start)
    @State private var quietHoursEnd = ClockTime.date(from: RecordStore.Defaults.quietHours.end)
    @State private var pausedAt: Date?
    /// The live permission (`NotificationPermissionAccess`); until the first
    /// read answers, the group shows no permission section.
    @State private var notificationPermission: NotificationPermission = .granted

    var body: some View {
        Form {
            if pausedAt != nil {
                Section {
                    Text("settings.reminders.pausedLine")
                    Button("settings.reminders.turnOn", action: turnRemindersOn)
                }
            }

            if notificationPermission == .notDetermined {
                Section {
                    Text("settings.reminders.notDetermined.line")
                    Button("settings.reminders.notDetermined.allowControl", action: requestNotificationPermission)
                }
            } else if notificationPermission == .denied {
                Section {
                    Text("settings.reminders.denied.line")
                    Button("settings.reminders.denied.iosSettingsControl", action: openIOSSettings)
                }
            }

            Section {
                Toggle("settings.reminders.switch.plannedMeals", isOn: binding(for: .plannedMeals))
                Toggle("settings.reminders.switch.setTodaysPlan", isOn: binding(for: .setTodaysPlan))
                Toggle("settings.reminders.switch.midday", isOn: binding(for: .midday))
                Toggle("settings.reminders.switch.closeTheDay", isOn: binding(for: .closeTheDay))
                Toggle("settings.reminders.switch.weighInDay", isOn: binding(for: .weighInDay))
                Toggle("settings.reminders.switch.weeklyReview", isOn: binding(for: .weeklyReview))
            } header: {
                Text("settings.reminders.whichHeader")
            } footer: {
                Text("settings.reminders.eachDeviceCaption")
            }

            Section {
                DatePicker("settings.reminders.time.setTodaysPlan", selection: $setTodaysPlanTime, displayedComponents: .hourAndMinute)
                    .onChange(of: setTodaysPlanTime) { store.trySetReminderTime($1, .setTodaysPlan); ReminderCoordinator.recomputeAndApply(store: store) }
                quietHoursLine(for: setTodaysPlanTime)
                DatePicker("settings.reminders.time.closeTheDay", selection: $closeTheDayTime, displayedComponents: .hourAndMinute)
                    .onChange(of: closeTheDayTime) { store.trySetReminderTime($1, .closeTheDay); ReminderCoordinator.recomputeAndApply(store: store) }
                quietHoursLine(for: closeTheDayTime)
                DatePicker("settings.reminders.time.weighIn", selection: $weighInTime, displayedComponents: .hourAndMinute)
                    .onChange(of: weighInTime) { store.trySetReminderTime($1, .weighIn); ReminderCoordinator.recomputeAndApply(store: store) }
                quietHoursLine(for: weighInTime)
                DatePicker("settings.reminders.time.weeklyReview", selection: $weeklyReviewTime, displayedComponents: .hourAndMinute)
                    .onChange(of: weeklyReviewTime) { store.trySetReminderTime($1, .weeklyReview); ReminderCoordinator.recomputeAndApply(store: store) }
                quietHoursLine(for: weeklyReviewTime)
            } header: {
                Text("settings.reminders.whenHeader")
            } footer: {
                Text("settings.reminders.middayCaption")
            }

            Section {
                Toggle("settings.reminders.explicitWording", isOn: $explicitWordingOn)
                    .onChange(of: explicitWordingOn) { _, on in try? store.setExplicitWordingOn(on); ReminderCoordinator.recomputeAndApply(store: store) }
                Picker("settings.reminders.remindAgainLabel", selection: $remindAgainMinutes) {
                    Text("settings.reminders.remindAgain.15").tag(15)
                    Text("settings.reminders.remindAgain.30").tag(30)
                }
                // The store's change signal makes the scheduler register the
                // snooze title again and compute the schedule.
                .onChange(of: remindAgainMinutes) { _, minutes in try? store.setRemindAgainMinutes(minutes) }
            }

            Section {
                Toggle("settings.reminders.quietHours", isOn: $quietHoursOn)
                    .onChange(of: quietHoursOn) { _, on in try? store.setQuietHoursOn(on); ReminderCoordinator.recomputeAndApply(store: store) }
                DatePicker("settings.reminders.quietHours.start", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                    .onChange(of: quietHoursStart) { store.trySetQuietHoursStart($1); ReminderCoordinator.recomputeAndApply(store: store) }
                DatePicker("settings.reminders.quietHours.end", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                    .onChange(of: quietHoursEnd) { store.trySetQuietHoursEnd($1); ReminderCoordinator.recomputeAndApply(store: store) }
            }
        }
        .navigationTitle("settings.reminders.title")
        .getSupport()
        .onAppear(perform: load)
    }

    /// reminders spec, "Quiet hours": "When the person sets a reminder time
    /// inside quiet hours, the Reminders group MUST show 'This time is in
    /// quiet hours. The reminder will not be sent.'" The group keeps the
    /// time.
    @ViewBuilder
    private func quietHoursLine(for time: Date) -> some View {
        let quietHours = QuietHours(isOn: quietHoursOn, start: ClockTime.string(from: quietHoursStart), end: ClockTime.string(from: quietHoursEnd))
        if quietHours.contains(ClockTime.string(from: time)) {
            Text("settings.reminders.quietHoursNotSent")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func binding(for kind: RecordStore.ReminderSwitch) -> Binding<Bool> {
        Binding(
            get: { switches[kind] ?? true },
            set: { on in
                switches[kind] = on
                try? store.setReminderSwitch(on, kind)
                // reminders spec, "Reminder types and their switches": "When
                // a switch is off, the scheduler MUST cancel every pending
                // reminder of that type."
                ReminderCoordinator.recomputeAndApply(store: store)
            }
        )
    }

    private func load() {
        for kind in RecordStore.ReminderSwitch.allCases {
            switches[kind] = (try? store.reminderSwitchOn(kind)) ?? true
        }
        if let time = try? store.reminderTime(.setTodaysPlan) { setTodaysPlanTime = ClockTime.date(from: time) }
        if let time = try? store.reminderTime(.closeTheDay) { closeTheDayTime = ClockTime.date(from: time) }
        if let time = try? store.reminderTime(.weighIn) { weighInTime = ClockTime.date(from: time) }
        if let time = try? store.reminderTime(.weeklyReview) { weeklyReviewTime = ClockTime.date(from: time) }
        explicitWordingOn = (try? store.explicitWordingOn()) ?? false
        remindAgainMinutes = (try? store.remindAgainMinutes()) ?? 15
        quietHoursOn = (try? store.quietHoursOn()) ?? true
        if let time = try? store.quietHoursStart() { quietHoursStart = ClockTime.date(from: time) }
        if let time = try? store.quietHoursEnd() { quietHoursEnd = ClockTime.date(from: time) }
        pausedAt = try? store.remindersPausedAt()
        loadNotificationPermission()
    }

    private func turnRemindersOn() {
        try? store.turnRemindersOn()
        pausedAt = nil
        // reminders spec, "Reminder types and their switches": "the app
        // MUST clear `remindersPausedAt`" and settings spec, "The Reminders
        // group": "the scheduler computes the schedule again."
        ReminderCoordinator.recomputeAndApply(store: store)
    }

    /// "Allow notifications" (reminders spec, "Reminder types and their
    /// switches"). A device check proves the real system dialog and the
    /// resulting schedule (the epic's device-check bead).
    private func requestNotificationPermission() {
        NotificationPermissionAccess.request { permission in
            notificationPermission = permission
            ReminderCoordinator.recomputeAndApply(store: store)
        }
    }

    private func openIOSSettings() {
        NotificationPermissionAccess.openSettings()
    }

    private func loadNotificationPermission() {
        NotificationPermissionAccess.read { notificationPermission = $0 }
    }
}

private extension RecordStore {
    func trySetReminderTime(_ date: Date, _ kind: ReminderTime) {
        try? setReminderTime(ClockTime.string(from: date), kind)
    }

    func trySetQuietHoursStart(_ date: Date) {
        try? setQuietHoursStart(ClockTime.string(from: date))
    }

    func trySetQuietHoursEnd(_ date: Date) {
        try? setQuietHoursEnd(ClockTime.string(from: date))
    }
}
