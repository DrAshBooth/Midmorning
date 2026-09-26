import SwiftUI
import Record
import Programme

/// "Programme": the week line, the seven stage rows, and "Start week 1
/// again" (programme spec, "The Programme screen shows where the person
/// is"). A view over `ProgrammeScreenModel`; it holds no rule of its own.
struct ProgrammeScreenView: View {
    let store: RecordStore

    @State private var screen: ProgrammeScreenModel?
    @State private var isShowingRestartChoice = false

    var body: some View {
        List {
            if let screen {
                Section {
                    Text(screen.weekLine).font(.title2.bold())
                }
                Section {
                    ForEach(screen.rows, id: \.stage) { row in
                        if row.isTappable {
                            NavigationLink(value: row.stage) {
                                StageRowContent(row: row)
                            }
                        } else {
                            StageRowContent(row: row)
                        }
                    }
                }
                Section {
                    Button("programme.startWeek1Again") {
                        isShowingRestartChoice = true
                    }
                }
            }
        }
        .recordListStyle()
        .navigationTitle("programme.title")
        .getSupport()
        .sheet(isPresented: $isShowingRestartChoice) {
            RestartChoiceView(store: store) { reload() }
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        let snapshot = ProgrammeModel.load(store: store)
        screen = ProgrammeScreenBuilder.build(
            state: snapshot.state, constants: .default, restartAt: snapshot.restartAt,
            stagesWithToolInBuild: ProgrammeModel.stagesWithToolInBuild
        )
    }
}

/// One stage row's content: the title, the "Now" marker, and the rule
/// string, "Comes in a later version", or the tool names, as one
/// accessibility element (programme spec, "Accessibility of the Programme
/// screen").
private struct StageRowContent: View {
    let row: StageRow

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(row.title).font(.body)
                if row.isNow {
                    Text("programme.now").font(.body.bold())
                }
            }
            if row.comesInALaterVersion {
                Text(StageRuleText.comesInALaterVersion).font(.footnote).foregroundStyle(.secondary)
            } else if let ruleString = row.ruleString {
                Text(ruleString).font(.footnote).foregroundStyle(.secondary)
            } else {
                ForEach(row.toolNames, id: \.self) { name in
                    Text(name).font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
    }
}
