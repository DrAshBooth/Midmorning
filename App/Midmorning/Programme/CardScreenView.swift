import SwiftUI
import Record
import Content

/// One card, full screen (content spec, "The card screen and the card
/// list"). A view over `Content.CardScreen`; it adds nothing the value does
/// not already carry, and truncates nothing. Records the card view and the
/// person's own card answer, when the card that opened it is a Today card
/// (a stage 1 card's "Read").
struct CardScreenView: View {
    let store: RecordStore
    let cardId: String
    /// Non-nil only when a Today card's "Read" pushed this screen, so the
    /// card's answer row records "Read" (programme spec, "The card's answer
    /// is kept in the record").
    var recordsAnswerOnAppear: Bool = false

    @State private var screen: Content.CardScreen?
    /// `true` when the bundle carries the "Draft" flag (content spec,
    /// "Clinical sign-off per content version": "When the bundle carries
    /// the 'Draft' flag, the app MUST show 'Draft' at the top of every
    /// card.").
    @State private var isDraft = false
    @State private var isShowingSafari = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let screen {
                    if isDraft {
                        Text("programme.card.draft")
                            .font(.headline)
                    }
                    Text(screen.title)
                        .font(.title.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text(screen.body).font(.body)
                    if !screen.oneThing.isEmpty {
                        Text(Content.CardScreen.oneThingHeading)
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        Text(screen.oneThing).font(.body)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(screen?.title ?? "")
        .getSupport()
        .onAppear(perform: load)
    }

    private func load() {
        guard let bundle = ShippedContent.bundle, let card = bundle.card(id: cardId) else { return }
        screen = Content.CardScreen(card: card)
        isDraft = bundle.isDraft
        try? store.recordCardSeen(cardId: cardId, contentVersion: bundle.contentVersion, language: bundle.language, seenAt: Date())
        if recordsAnswerOnAppear {
            try? store.setCardAnswer("Read", id: cardId, changedAt: Date())
        }
    }
}
