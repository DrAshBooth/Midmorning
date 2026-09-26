import Foundation
import XCTest
@testable import Record
@testable import Programme

/// weigh-in spec, "The trend feeds safeguarding" (mm-t22.11): every weigh-in
/// and every rolling average, from the real store, reaches
/// `safeguarding`'s underweight check. The App target's own
/// `WeighInScreenView.afterSave` does the same conversion
/// (`RecordStore.WeighInRow` to `Programme.WeighInFact`) after a real save;
/// this proves the conversion and the composition over the real store, the
/// same pattern `ProgrammeFactsWiringTests` uses ahead of an App-target seam.
@MainActor
final class WeighInSafeguardingFactsTests: XCTestCase {
    private func makeStore() throws -> RecordStore {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try RecordStore(directory: directory)
    }

    private var utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 8) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func dayKey(_ year: Int, _ month: Int, _ day: Int) -> String {
        RecordDay.key(containing: at(year, month, day), calendar: utc)
    }

    /// Every kept weigh-in as `Programme`'s own fact type, the conversion
    /// `WeighInScreenView.afterSave` performs.
    private func facts(from store: RecordStore) throws -> [WeighInFact] {
        try store.weighIns().map { WeighInFact(dayKey: $0.dateKey, weightKg: $0.weightKg) }
    }

    /// Scenario: The rolling average falls.
    func testTheRollingAverageFalls() throws {
        let store = try makeStore()
        try store.saveWeighIn(dateKey: dayKey(2026, 9, 28), weightKg: 70.0, unit: "kg", at: at(2026, 9, 28))
        try store.saveWeighIn(dateKey: dayKey(2026, 10, 5), weightKg: 68.0, unit: "kg", at: at(2026, 10, 5))
        try store.saveWeighIn(dateKey: dayKey(2026, 10, 12), weightKg: 66.0, unit: "kg", at: at(2026, 10, 12))
        try store.saveWeighIn(dateKey: dayKey(2026, 10, 19), weightKg: 64.0, unit: "kg", at: at(2026, 10, 19))
        let series = RollingAverage.series(try facts(from: store), calendar: utc)
        XCTAssertEqual(series.count, 4, "safeguarding reads every weigh-in and every average")
        XCTAssertLessThan(series.last!.averageKg, series.first!.averageKg, "the rolling average falls")
    }

    /// Scenario: Rule A applies after a weigh-in.
    func testRuleAAppliesAfterAWeighIn() throws {
        let store = try makeStore()
        try store.setProfile(heightCm: 170, onboardingBMI: 24.2, cautionFlag: false, askedAt: at(2026, 1, 1))
        try store.saveWeighIn(dateKey: dayKey(2026, 9, 28), weightKg: 53.0, unit: "kg", at: at(2026, 9, 28))
        let profile = try store.profile()!
        let series = RollingAverage.series(try facts(from: store), calendar: utc)
        let earlier = RollingAverage.averageAtLeastDaysEarlier(28, before: series.last!.dayKey, in: series, calendar: utc)
        let input = UnderweightCheckInput(heightCm: profile.heightCm, onboardingBMI: profile.onboardingBMI, cautionFlag: profile.cautionFlag, currentAverageKg: series.last!.averageKg, averageAtLeast28DaysEarlierKg: earlier)
        let rules = UnderweightCheck.rulesThatApply(input)
        XCTAssertEqual(UnderweightCheck.notRightNowReasons(rules), [.weight])
    }

    /// Scenario: Rule B or Rule C applies after a weigh-in.
    func testRuleBOrRuleCAppliesAfterAWeighIn() throws {
        let store = try makeStore()
        try store.setProfile(heightCm: 170, onboardingBMI: 20.76, cautionFlag: false, askedAt: at(2026, 1, 1))
        try store.saveWeighIn(dateKey: dayKey(2026, 9, 28), weightKg: 56.0, unit: "kg", at: at(2026, 9, 28))
        let profile = try store.profile()!
        let series = RollingAverage.series(try facts(from: store), calendar: utc)
        let earlier = RollingAverage.averageAtLeastDaysEarlier(28, before: series.last!.dayKey, in: series, calendar: utc)
        let input = UnderweightCheckInput(heightCm: profile.heightCm, onboardingBMI: profile.onboardingBMI, cautionFlag: profile.cautionFlag, currentAverageKg: series.last!.averageKg, averageAtLeast28DaysEarlierKg: earlier)
        let rules = UnderweightCheck.rulesThatApply(input)
        XCTAssertEqual(UnderweightCheck.gpSuggestionReasons(rules), [.fallingWeight])
    }

    /// Scenario: No weigh-in, no check.
    func testNoWeighInNoCheck() throws {
        let store = try makeStore()
        XCTAssertTrue(try store.weighIns().isEmpty, "the App target's own guard (\"run only when at least one weigh-in exists\") reads this before ever building an UnderweightCheckInput")
    }
}
