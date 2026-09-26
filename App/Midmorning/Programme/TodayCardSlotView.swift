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
    /// The card's text, found once when the view is made, from the bundle
    /// the app reads once per launch (`ShippedContent`), not on each render.
    private let title: String
    private let bodyLines: [String]

    init(card: PendingCard, onPrimary: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.card = card
        self.onPrimary = onPrimary
        self.onClose = onClose
        let text = Self.text(for: card, bundle: ShippedContent.bundle)
        self.title = text.title
        self.bodyLines = text.bodyLines
    }

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
        }
        .padding(.vertical, 4)
        .listRowSeparator(.hidden)
    }

    /// The title and the body lines of `card`. The stage 1 card's title and
    /// the plan card's text come from the content bundle ("todaycard.plan";
    /// content spec, "Strings live in catalogues"). An opening card reads
    /// the bundle's "opening.stage<n>" string when the bundle holds it.
    private static func text(for card: PendingCard, bundle: ContentBundle?) -> (title: String, bodyLines: [String]) {
        switch card.kind {
        case .opening:
            let stage = card.openingStage
            let sentence = stage.flatMap { bundle?.string(id: "opening.stage\($0.rawValue)")?.text } ?? stage?.openingSentence ?? ""
            return (stage?.title ?? "", sentence.isEmpty ? [] : [sentence])
        case .stage1:
            return (bundle?.card(id: card.id)?.title ?? "", [])
        case .plan:
            let line = bundle?.string(id: "todaycard.plan")?.text ?? ""
            return ("", line.isEmpty ? [] : [line])
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
