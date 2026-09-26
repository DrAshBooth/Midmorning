import Foundation

/// Every programme threshold in one value. `Record`, `Plan` and `Programme`
/// read a threshold from here and never repeat its value as a literal.
/// `.default` is the shipped set. A test builds a modified value; a test
/// never edits `.default` (openspec/changes/v1-programme/specs/programme/spec.md,
/// "The constants live in one value").
public struct ProgrammeConstants: Sendable, Equatable {
    /// The default hour of "Day starts at". The setting owns the live value;
    /// this constant never stands in for it and never changes across versions.
    public var defaultDayStartHour: Int
    public var programmeWeeks: Int
    public var minHeightCm: Int
    public var maxHeightCm: Int
    public var minWeightKg: Int
    public var recordedDaysForStage2: Int
    public var daysOnPlanForStage3: Int
    public var recordDaysForStage3Fallback: Int
    public var recordedDaysForStage4Fallback: Int
    public var weekOfTakingStock: Int
    public var weekOfStayingOnTrack: Int
    public var maxAwakeGapHours: Int
    public var maxOtherRemindersPerDay: Int
    public var snoozeMinutes: Int
    public var maxSnoozes: Int
    public var rollingAverageWeeks: Int
    public var urgeTimerMinutes: Int
    public var deteriorationWeeks: Int
    public var checkInWeeks: [Int]
    public var patternWindowDays: Int
    public var patternMinStarred: Int
    public var patternMinGroup: Int
    /// The four values "Lock after" can pick. The default is 0.
    public var lockGraceSecondsChoices: [Int]
    public var plannedMealWindowBeforeMinutes: Int
    public var plannedMealWindowAfterMinutes: Int
    public var reminderHorizonDays: Int
    /// The scheduler's own cap on pending local notification requests
    /// (reminders spec, "Scheduling is local, lazy and bounded":
    /// "The scheduler MUST keep at most 60 pending notification requests").
    public var maxPendingReminderRequests: Int

    public init(
        defaultDayStartHour: Int = 4,
        programmeWeeks: Int = 12,
        minHeightCm: Int = 100,
        maxHeightCm: Int = 250,
        minWeightKg: Int = 30,
        recordedDaysForStage2: Int = 5,
        daysOnPlanForStage3: Int = 7,
        recordDaysForStage3Fallback: Int = 14,
        recordedDaysForStage4Fallback: Int = 7,
        weekOfTakingStock: Int = 6,
        weekOfStayingOnTrack: Int = 10,
        maxAwakeGapHours: Int = 4,
        maxOtherRemindersPerDay: Int = 2,
        snoozeMinutes: Int = 15,
        maxSnoozes: Int = 2,
        rollingAverageWeeks: Int = 4,
        urgeTimerMinutes: Int = 20,
        deteriorationWeeks: Int = 3,
        checkInWeeks: [Int] = [4, 8, 12],
        patternWindowDays: Int = 28,
        patternMinStarred: Int = 5,
        patternMinGroup: Int = 3,
        lockGraceSecondsChoices: [Int] = [0, 30, 120, 300],
        plannedMealWindowBeforeMinutes: Int = 60,
        plannedMealWindowAfterMinutes: Int = 90,
        reminderHorizonDays: Int = 6,
        maxPendingReminderRequests: Int = 60
    ) {
        self.defaultDayStartHour = defaultDayStartHour
        self.programmeWeeks = programmeWeeks
        self.minHeightCm = minHeightCm
        self.maxHeightCm = maxHeightCm
        self.minWeightKg = minWeightKg
        self.recordedDaysForStage2 = recordedDaysForStage2
        self.daysOnPlanForStage3 = daysOnPlanForStage3
        self.recordDaysForStage3Fallback = recordDaysForStage3Fallback
        self.recordedDaysForStage4Fallback = recordedDaysForStage4Fallback
        self.weekOfTakingStock = weekOfTakingStock
        self.weekOfStayingOnTrack = weekOfStayingOnTrack
        self.maxAwakeGapHours = maxAwakeGapHours
        self.maxOtherRemindersPerDay = maxOtherRemindersPerDay
        self.snoozeMinutes = snoozeMinutes
        self.maxSnoozes = maxSnoozes
        self.rollingAverageWeeks = rollingAverageWeeks
        self.urgeTimerMinutes = urgeTimerMinutes
        self.deteriorationWeeks = deteriorationWeeks
        self.checkInWeeks = checkInWeeks
        self.patternWindowDays = patternWindowDays
        self.patternMinStarred = patternMinStarred
        self.patternMinGroup = patternMinGroup
        self.lockGraceSecondsChoices = lockGraceSecondsChoices
        self.plannedMealWindowBeforeMinutes = plannedMealWindowBeforeMinutes
        self.plannedMealWindowAfterMinutes = plannedMealWindowAfterMinutes
        self.reminderHorizonDays = reminderHorizonDays
        self.maxPendingReminderRequests = maxPendingReminderRequests
    }

    /// The shipped set. A test never edits this value; it builds a modified
    /// `ProgrammeConstants` instead (spec: "A test MUST NOT edit `.default`").
    public static let `default` = ProgrammeConstants()
}
