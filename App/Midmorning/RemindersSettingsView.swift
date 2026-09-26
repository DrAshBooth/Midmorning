import SwiftUI
import UIKit
import UserNotifications
import Record
import Programme

/// The Reminders group's own screen, one tap from the settings screen
/// (settings spec, "The Reminders group"). First cut: "Worksheet review",
/// "Check-in" and "Break through Focus for planned meals" are absent; the
/// settings remainder beads under 3.3, 3.6 and 2.5 add them.
struct RemindersSettingsView: View {
    let store: RecordStore

    @State private var switches: [RecordStore.ReminderSwitch: Bool] = [:]
    @State private var setTodaysPlanTime = ClockTime.date(hour: 7, minute: 30)
    @State private var closeTheDayTime = ClockTime.date(hour: 21, minute: 45)
    @State private var weighInTime = ClockTime.date(hour: 7, minute: 30)
    @State private var weeklyReviewTime = ClockTime.date(hour: 18, minute: 0)
    @State private var explicitWordingOn = false
    @State private var remindAgainMinutes = 15
    @State private var quietHoursOn = true
    @State private var quietHoursStart = ClockTime.date(hour: 22, minute: 0)
    @State private var quietHoursEnd = ClockTime.date(hour: 7, minute: 0)
    @State private var pausedAt: Date?
    /// `mm-t24.21` wires the real `UNUserNotificationCenter` permission read
    /// in; a fresh install reads as not determined.
    @State private var notificationPermission: NotificationPermission = .notDetermined

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
                DatePicker("settings.reminders.time.closeTheDay", selection: $closeTheDayTime, displayedComponents: .hourAndMinute)
                    .onChange(of: closeTheDayTime) { store.trySetReminderTime($1, .closeTheDay); ReminderCoordinator.recomputeAndApply(store: store) }
                DatePicker("settings.reminders.time.weighIn", selection: $weighInTime, displayedComponents: .hourAndMinute)
                    .onChange(of: weighInTime) { store.trySetReminderTime($1, .weighIn); ReminderCoordinator.recomputeAndApply(store: store) }
                DatePicker("settings.reminders.time.weeklyReview", selection: $weeklyReviewTime, displayedComponents: .hourAndMinute)
                    .onChange(of: weeklyReviewTime) { store.trySetReminderTime($1, .weeklyReview) }
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            DispatchQueue.main.async { loadNotificationPermission() }
        }
    }

    private func openIOSSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func loadNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let permission: NotificationPermission
            switch settings.authorizationStatus {
            case .notDetermined: permission = .notDetermined
            case .denied: permission = .denied
            default: permission = .granted
            }
            DispatchQueue.main.async { notificationPermission = permission }
        }
    }
}

private extension RecordStore {
    func trySetReminderTime(_ date: Date, _ kind: ReminderTime) {
        try? setReminderTime(ClockTime.text(from: date), kind)
    }

    func trySetQuietHoursStart(_ date: Date) {
        try? setQuietHoursStart(ClockTime.text(from: date))
    }

    func trySetQuietHoursEnd(_ date: Date) {
        try? setQuietHoursEnd(ClockTime.text(from: date))
    }
}
