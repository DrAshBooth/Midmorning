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

            // Each control writes only from its own setter, so opening the
            // screen writes no row and computes no schedule (mm-t24.38).
            Section {
                DatePicker("settings.reminders.time.setTodaysPlan", selection: writing($setTodaysPlanTime) { store.trySetReminderTime($0, .setTodaysPlan) }, displayedComponents: .hourAndMinute)
                quietHoursLine(for: setTodaysPlanTime)
                DatePicker("settings.reminders.time.closeTheDay", selection: writing($closeTheDayTime) { store.trySetReminderTime($0, .closeTheDay) }, displayedComponents: .hourAndMinute)
                quietHoursLine(for: closeTheDayTime)
                DatePicker("settings.reminders.time.weighIn", selection: writing($weighInTime) { store.trySetReminderTime($0, .weighIn) }, displayedComponents: .hourAndMinute)
                quietHoursLine(for: weighInTime)
                DatePicker("settings.reminders.time.weeklyReview", selection: writing($weeklyReviewTime) { store.trySetReminderTime($0, .weeklyReview) }, displayedComponents: .hourAndMinute)
                quietHoursLine(for: weeklyReviewTime)
            } header: {
                Text("settings.reminders.whenHeader")
            } footer: {
                Text("settings.reminders.middayCaption")
            }

            Section {
                Toggle("settings.reminders.explicitWording", isOn: writing($explicitWordingOn) { try? store.setExplicitWordingOn($0) })
                // The store's change signal makes the scheduler register the
                // snooze title again and compute the schedule.
                Picker("settings.reminders.remindAgainLabel", selection: writing($remindAgainMinutes, recompute: false) { try? store.setRemindAgainMinutes($0) }) {
                    Text("settings.reminders.remindAgain.15").tag(15)
                    Text("settings.reminders.remindAgain.30").tag(30)
                }
            }

            Section {
                Toggle("settings.reminders.quietHours", isOn: writing($quietHoursOn) { try? store.setQuietHoursOn($0) })
                DatePicker("settings.reminders.quietHours.start", selection: writing($quietHoursStart) { store.trySetQuietHoursStart($0) }, displayedComponents: .hourAndMinute)
                DatePicker("settings.reminders.quietHours.end", selection: writing($quietHoursEnd) { store.trySetQuietHoursEnd($0) }, displayedComponents: .hourAndMinute)
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
        let range = ReminderQuietHours.effectiveRange(on: quietHoursOn, start: ClockTime.text(from: quietHoursStart), end: ClockTime.text(from: quietHoursEnd))
        if ReminderQuietHours.contains(time: ClockTime.text(from: time), start: range.start, end: range.end) {
            Text("settings.reminders.quietHoursNotSent")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    /// A binding that writes through `write` only when the person picks a
    /// new value, then computes the schedule again unless `recompute` is
    /// `false`. `load()` sets the state directly and so writes nothing
    /// (mm-t24.38; the settings screen does the same, mm-t13.13).
    private func writing<Value: Equatable>(_ value: Binding<Value>, recompute: Bool = true, write: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { value.wrappedValue },
            set: { newValue in
                guard newValue != value.wrappedValue else { return }
                value.wrappedValue = newValue
                write(newValue)
                if recompute { ReminderCoordinator.recomputeAndApply(store: store) }
            }
        )
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
        try? setReminderTime(ClockTime.text(from: date), kind)
    }

    func trySetQuietHoursStart(_ date: Date) {
        try? setQuietHoursStart(ClockTime.text(from: date))
    }

    func trySetQuietHoursEnd(_ date: Date) {
        try? setQuietHoursEnd(ClockTime.text(from: date))
    }
}
