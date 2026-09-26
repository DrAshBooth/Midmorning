import SwiftUI
import Programme

/// The not-right-now page (safeguarding spec, "The not-right-now page").
/// `mm-t22` (weigh-in), `mm-t32` (weekly-review) and `mm-t21`
/// (programme-engine) open this from their own triggers; this change builds
/// the page itself. "Done" returns the app to the screen beneath.
struct NotRightNowPageView: View {
    let reasons: [ExclusionReason]
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(NotRightNowPage.heading)
                        .font(.largeTitle.bold())

                    ForEach(NotRightNowPage.ordered(reasons), id: \.self) { reason in
                        if let paragraph = NotRightNowPage.paragraph(for: reason) {
                            Text(paragraph)
                        }
                    }

                    Text(CommonLabels.talkToYourGP)
                        .font(.title2.bold())
                    GPParagraphView(variant: GPParagraph.variant(for: reasons))

                    ExportStubButton()
                    Text(NotRightNowPage.recordStaysLine)
                    Text(NotRightNowPage.remindersLine(for: reasons))

                    Button(CommonLabels.done) { onDone() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .getSupport(fromSelfHarmReason: reasons.contains(.selfHarm))
        }
    }
}
