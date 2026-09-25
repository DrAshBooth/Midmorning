import SwiftUI
import Record

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
    @State private var isShowingSupportSheet = false

    var body: some View {
        Form {
            if pausedAt != nil {
                Section {
                    Text("settings.reminders.pausedLine")
                    Button("settings.reminders.turnOn", action: turnRemindersOn)
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
                    .onChange(of: setTodaysPlanTime) { store.trySetReminderTime($1, .setTodaysPlan) }
                DatePicker("settings.reminders.time.closeTheDay", selection: $closeTheDayTime, displayedComponents: .hourAndMinute)
                    .onChange(of: closeTheDayTime) { store.trySetReminderTime($1, .closeTheDay) }
                DatePicker("settings.reminders.time.weighIn", selection: $weighInTime, displayedComponents: .hourAndMinute)
                    .onChange(of: weighInTime) { store.trySetReminderTime($1, .weighIn) }
                DatePicker("settings.reminders.time.weeklyReview", selection: $weeklyReviewTime, displayedComponents: .hourAndMinute)
                    .onChange(of: weeklyReviewTime) { store.trySetReminderTime($1, .weeklyReview) }
            } header: {
                Text("settings.reminders.whenHeader")
            } footer: {
                Text("settings.reminders.middayCaption")
            }

            Section {
                Toggle("settings.reminders.explicitWording", isOn: $explicitWordingOn)
                    .onChange(of: explicitWordingOn) { _, on in try? store.setExplicitWordingOn(on) }
                Picker("settings.reminders.remindAgainLabel", selection: $remindAgainMinutes) {
                    Text("settings.reminders.remindAgain.15").tag(15)
                    Text("settings.reminders.remindAgain.30").tag(30)
                }
                .onChange(of: remindAgainMinutes) { _, minutes in try? store.setRemindAgainMinutes(minutes) }
            }

            Section {
                Toggle("settings.reminders.quietHours", isOn: $quietHoursOn)
                    .onChange(of: quietHoursOn) { _, on in try? store.setQuietHoursOn(on) }
                DatePicker("settings.reminders.quietHours.start", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                    .onChange(of: quietHoursStart) { store.trySetQuietHoursStart($1) }
                DatePicker("settings.reminders.quietHours.end", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                    .onChange(of: quietHoursEnd) { store.trySetQuietHoursEnd($1) }
            }
        }
        .navigationTitle("settings.reminders.title")
        .toolbar {
            // Decision 94: the trailing position of the navigation bar
            // (safeguarding spec, "Get support on every screen").
            ToolbarItem(placement: .confirmationAction) {
                Button("settings.getSupport") { isShowingSupportSheet = true }
            }
        }
        .sheet(isPresented: $isShowingSupportSheet) {
            GetSupportPlaceholderSheet()
        }
        .onAppear(perform: load)
    }

    private func binding(for kind: RecordStore.ReminderSwitch) -> Binding<Bool> {
        Binding(
            get: { switches[kind] ?? true },
            set: { on in
                switches[kind] = on
                try? store.setReminderSwitch(on, kind)
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
    }

    private func turnRemindersOn() {
        try? store.turnRemindersOn()
        pausedAt = nil
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
