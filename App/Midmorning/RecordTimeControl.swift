import SwiftUI
import Record

/// The time control of the new-entry and edit screens (record spec, "The
/// new-entry screen's controls"; "Edit an entry"): the record-day segments,
/// then the system hour-and-minute wheel.
///
/// The wheel keeps only a clock time. Each turn of the wheel and each change
/// of segment resolves that clock time against the selected record day with
/// `NewEntryTime.wheelTime`, so a time before the day start lands on the
/// calendar date after the segment's date, and a time outside the record
/// day or after `notAfter` goes back inside it. The selected segment is the
/// one that holds `time`, so the segments and the wheel never disagree.
///
/// For VoiceOver the whole control is one adjustable element, "Time", whose
/// value reads the date and time. Each swipe moves a quarter hour through
/// all the segments, and one custom action per segment moves to that record
/// day (record spec, "Accessibility of the additions"; product-rules spec:
/// "The record and urge flows MUST be complete with VoiceOver").
struct RecordTimeControl: View {
    struct Segment: Hashable {
        let interval: DateInterval
        let startHour: Int
        /// The weekday and date only, for example "Thursday 24 September".
        let title: String
    }

    /// Earliest first. Two on a new entry, one on an edit.
    let segments: [Segment]
    @Binding var time: Date
    let notAfter: Date
    /// The zone the wheel shows and resolves in: the device zone on a new
    /// entry, the entry's own UTC offset on an edit.
    let calendar: Calendar

    private var selectedIndex: Int {
        segments.lastIndex { $0.interval.start <= time } ?? 0
    }

    var body: some View {
        if segments.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                if segments.count > 1 {
                    Picker("", selection: segmentSelection) {
                        ForEach(segments.indices, id: \.self) { index in
                            Text(segments[index].title).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    Text(segments[0].title)
                        .foregroundStyle(.secondary)
                }
                wheel
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.calendar, calendar)
                    .environment(\.timeZone, calendar.timeZone)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("entry.time.accessibilityLabel")
            .accessibilityValue(Self.spokenTime(time, calendar: calendar))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: time = NewEntryTime.stepped(time, by: 1, within: allSegmentsRange, calendar: calendar)
                case .decrement: time = NewEntryTime.stepped(time, by: -1, within: allSegmentsRange, calendar: calendar)
                @unknown default: break
                }
            }
            .accessibilityActions {
                if segments.count > 1 {
                    ForEach(segments.indices, id: \.self) { index in
                        Button(segments[index].title) { select(index) }
                    }
                }
            }
        }
    }

    /// The system wheel. When the selected record day's times all fall on one
    /// calendar date, the wheel also takes the range, so it greys out the
    /// times it cannot offer. When they cross midnight, a range would pin
    /// the wheel to one calendar date and snap an after-midnight time back,
    /// so the binding alone keeps the time inside the record day.
    @ViewBuilder
    private var wheel: some View {
        let range = NewEntryTime.range(of: segments[selectedIndex].interval, notAfter: notAfter)
        if calendar.isDate(range.lowerBound, inSameDayAs: range.upperBound) {
            DatePicker("", selection: wheelSelection, in: range, displayedComponents: [.hourAndMinute])
        } else {
            DatePicker("", selection: wheelSelection, displayedComponents: [.hourAndMinute])
        }
    }

    private var allSegmentsRange: ClosedRange<Date> {
        let lower = segments[0].interval.start
        let upper = NewEntryTime.range(of: segments[segments.count - 1].interval, notAfter: notAfter).upperBound
        return lower...max(lower, upper)
    }

    private var segmentSelection: Binding<Int> {
        Binding(get: { selectedIndex }, set: select)
    }

    private var wheelSelection: Binding<Date> {
        Binding(
            get: { time },
            set: { picked in time = resolved(picked, in: segments[selectedIndex]) }
        )
    }

    private func select(_ index: Int) {
        guard segments.indices.contains(index) else { return }
        time = resolved(time, in: segments[index])
    }

    private func resolved(_ clock: Date, in segment: Segment) -> Date {
        let parts = calendar.dateComponents([.hour, .minute], from: clock)
        return NewEntryTime.wheelTime(
            hour: parts.hour ?? 0, minute: parts.minute ?? 0,
            segment: segment.interval, dayStartHour: segment.startHour,
            notAfter: notAfter, near: time, calendar: calendar
        )
    }

    /// The time control's VoiceOver value, for example "Thursday 24
    /// September, 21:35" (record spec, "Accessibility of the record").
    static func spokenTime(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE d MMMM, HH:mm"
        return formatter.string(from: date)
    }
}
