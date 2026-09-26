import SwiftUI
import Record
import Plan
import Content
import Programme

/// A stage's own screen, pushed from a tap on its Programme screen row
/// (programme spec, "The stage screen"): the title, the line, the card
/// list, and a "Tools" group when the stage is open.
struct StageScreenView: View {
    let store: RecordStore
    let stage: Stage

    @State private var model: StageScreenModel?
    @State private var cardTitles: [(id: String, title: String)] = []
    @State private var planBuilderMode: PlanBuilderMode?

    var body: some View {
        List {
            if let model {
                if let line = model.line {
                    Section {
                        Text(line).font(.body)
                    }
                }
                Section {
                    ForEach(cardTitles, id: \.id) { card in
                        NavigationLink(value: CardRoute(cardId: card.id)) {
                            Text(card.title)
                        }
                    }
                }
                if !model.toolNames.isEmpty {
                    Section("programme.tools") {
                        ForEach(model.toolNames, id: \.self) { tool in
                            toolRow(tool)
                        }
                    }
                    .accessibilityElement(children: .contain)
                }
            }
        }
        .recordListStyle()
        .navigationTitle(model?.title ?? stage.title)
        .getSupport()
        .sheet(item: $planBuilderMode) { mode in
            PlanBuilderView(store: store, mode: mode) {}
        }
        .onAppear(perform: reload)
    }

    @ViewBuilder
    private func toolRow(_ tool: String) -> some View {
        switch tool {
        case "Plan":
            Button(tool) { planBuilderMode = .template(kind: .weekday, titleKey: "plan.weekday") }
        case "Weigh-in":
            // weigh-in spec, "The app accepts a weight on the weigh-in day
            // only": "the route is 'Programme', then 'Getting started', then
            // 'Weigh-in'" (decision 93).
            NavigationLink(tool, value: WeighInRoute())
        default:
            // Every later tool's own change connects its row (programme
            // spec, "The stage screen": "When the branch does not hold it,
            // the agent gives the row no action.").
            Text(tool)
        }
    }

    private func reload() {
        let snapshot = ProgrammeModel.load(store: store)
        model = StageScreenBuilder.build(
            stage: stage, state: snapshot.state, constants: .default, settings: snapshot.settings,
            currentRecordDay: snapshot.currentRecordDay, calendar: snapshot.calendar
        )
        let bundle = try? BundleLoader.loadShipped()
        cardTitles = (bundle?.activeCards(in: .stage(stage.rawValue)) ?? []).map { ($0.id, $0.title) }
    }
}
