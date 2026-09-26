import Foundation
import Constants

/// One row of the Programme screen (programme spec, "The Programme screen
/// shows where the person is"). A view renders this; it holds no rule of its
/// own. Its words are keys in the app's string catalogue; the rule string
/// is signed-off text that `StageRuleText` holds (ruling r13-02).
public struct StageRow: Sendable, Equatable {
    public var stage: Stage
    public var title: CatalogueText
    public var isNow: Bool
    public var isOpen: Bool
    /// Non-empty only for an open stage whose tool this build has.
    public var tools: [StageTool]
    /// Set only for a closed stage whose tool this build has.
    public var ruleString: String?
    /// Decision 102: true when this build lacks the stage's own tool. The
    /// row shows this fixed line in place of the rule string or the tools,
    /// carries no "Now" marker, and opens nothing on a tap.
    public var comesInALaterVersion: Bool

    public var isTappable: Bool { !comesInALaterVersion }

    /// Programme spec, "Accessibility of the Programme screen": the title,
    /// then "Now" when marked, then the rule string or "Comes in a later
    /// version" when the row shows one, comma-separated.
    public var accessibilityLabel: CatalogueText {
        var parts = [title]
        if isNow { parts.append(.key("programme.now")) }
        if comesInALaterVersion {
            parts.append(StageRuleText.comesInALaterVersion)
        } else if let ruleString {
            parts.append(.verbatim(ruleString))
        }
        return .list(parts)
    }
}

/// The Programme screen's own model: the week line and the seven stage rows,
/// in order (programme spec, "The Programme screen shows where the person
/// is").
public struct ProgrammeScreenModel: Sendable, Equatable {
    /// "Week %lld", or "Starts tomorrow" before week 1.
    public var weekLine: CatalogueText
    public var rows: [StageRow]
}

/// The stage screen's own model, pushed from a tap on a Programme screen row
/// (programme spec, "The stage screen").
public struct StageScreenModel: Sendable, Equatable {
    public var title: CatalogueText
    /// "Opened in week %lld" for an open stage, or the rule string for a
    /// closed one. `nil` when the stage's own opening record day, or the
    /// current record day, is before week 1.
    public var line: CatalogueText?
    /// Non-empty only when the stage is open.
    public var tools: [StageTool]
}

public enum ProgrammeScreenBuilder {
    /// The lowest open stage whose next stage is closed (or stage 7, when
    /// every stage is open); after a restart, the lowest week-gated stage
    /// (taking stock, then staying on track) whose gate has not passed since
    /// the restart, until every week gate has passed again; and, when that
    /// stage's own tool is not in this build, the nearest earlier open stage
    /// whose tool is (programme spec, "The Programme screen shows where the
    /// person is").
    public static func nowMarkerStage(state: ProgrammeState, restartAt: Date?, stagesWithToolInBuild: Set<Int>) -> Stage {
        var candidate = Stage.gettingStarted
        if restartAt != nil, let notYetPassed = [Stage.takingStock, .stayingOnTrack].first(where: { !state.isOpen($0) }) {
            candidate = notYetPassed
        } else {
            for stage in Stage.orderedByStage where state.isOpen(stage) {
                let next = Stage(rawValue: stage.rawValue + 1)
                if next == nil || !state.isOpen(next!) {
                    candidate = stage
                    break
                }
            }
        }
        if !stagesWithToolInBuild.contains(candidate.rawValue) {
            if let earlier = Stage.orderedByStage.reversed().first(where: {
                $0.rawValue < candidate.rawValue && state.isOpen($0) && stagesWithToolInBuild.contains($0.rawValue)
            }) {
                return earlier
            }
        }
        return candidate
    }

    public static func build(state: ProgrammeState, constants: ProgrammeConstants, restartAt: Date?, stagesWithToolInBuild: Set<Int>) -> ProgrammeScreenModel {
        let marker = nowMarkerStage(state: state, restartAt: restartAt, stagesWithToolInBuild: stagesWithToolInBuild)
        let rows = Stage.orderedByStage.map { stage -> StageRow in
            let hasTool = stagesWithToolInBuild.contains(stage.rawValue)
            let isOpen = state.isOpen(stage)
            return StageRow(
                stage: stage,
                title: stage.title,
                isNow: stage == marker,
                isOpen: isOpen,
                tools: (isOpen && hasTool) ? stage.tools : [],
                ruleString: (!isOpen && hasTool) ? StageRuleText.string(for: stage, constants: constants, recordedDaysCount: state.recordedDaysCount) : nil,
                comesInALaterVersion: !hasTool
            )
        }
        let weekLine: CatalogueText = state.week.map { .key("programme.week %lld", .count($0)) } ?? .key("programme.startsTomorrow")
        return ProgrammeScreenModel(weekLine: weekLine, rows: rows)
    }
}

public enum StageScreenBuilder {
    public static func build(
        stage: Stage,
        state: ProgrammeState,
        constants: ProgrammeConstants,
        settings: ProgrammeSettings,
        currentRecordDay: String,
        calendar: Calendar
    ) -> StageScreenModel {
        let isOpen = state.isOpen(stage)
        var line: CatalogueText?
        if isOpen {
            let openedWeek = state.stageOpenedDayKey[stage].flatMap { StageEngine.week(startDay: settings.startDay, currentRecordDay: $0, calendar: calendar) }
            let currentWeek = StageEngine.week(startDay: settings.startDay, currentRecordDay: currentRecordDay, calendar: calendar)
            if let openedWeek, currentWeek != nil {
                line = .key("programme.openedInWeek %lld", .count(openedWeek))
            }
        } else {
            line = StageRuleText.string(for: stage, constants: constants, recordedDaysCount: state.recordedDaysCount).map(CatalogueText.verbatim)
        }
        return StageScreenModel(title: stage.title, line: line, tools: isOpen ? stage.tools : [])
    }
}
