import SwiftUI
import Record
import Content
import Programme

/// One row in Today's card slot: the opening card, a stage 1 card, or the
/// plan card (programme spec, "A stage opening shows one card", "Two stage 1
/// cards come to Today", "A card when the plan is not set"). The card uses
/// the same text style as an entry row and never returns after either
/// control; the caller writes the answer and reloads.
struct TodayCardSlotView: View {
    let card: PendingCard
    let onPrimary: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.body)
            ForEach(bodyLines, id: \.self) { line in
                Text(line).font(.body)
            }
            HStack {
                Button(primaryLabel, action: onPrimary)
                Spacer()
                Button("programme.card.close", action: onClose)
            }
            // Two controls in one List row: each needs its own tap target.
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
        .listRowSeparator(.hidden)
    }

    private var stage: Stage? { card.openingStage }

    private var title: String {
        switch card.kind {
        case .opening: return stage?.title ?? ""
        case .stage1: return (try? BundleLoader.loadShipped().card(id: card.id)?.title) ?? ""
        case .plan: return ""
        }
    }

    private var bodyLines: [String] {
        switch card.kind {
        case .opening: return [stage?.openingSentence ?? ""].compactMap { $0.isEmpty ? nil : $0 }
        case .stage1: return []
        case .plan: return ["Your plan isn't set yet. It takes about two minutes."]
        }
    }

    private var primaryLabel: LocalizedStringKey {
        switch card.kind {
        case .opening: return "programme.card.open"
        case .stage1: return "programme.card.read"
        case .plan: return "programme.card.setItUp"
        }
    }
}
