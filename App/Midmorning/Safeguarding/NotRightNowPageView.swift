import SwiftUI
import Record
import Programme

/// The not-right-now page (safeguarding spec, "The not-right-now page").
/// `mm-t22` (weigh-in), `mm-t32` (weekly-review) and `mm-t21`
/// (programme-engine) open this from their own triggers; this change builds
/// the page itself. "Done" returns the app to the screen beneath.
struct NotRightNowPageView: View {
    let store: RecordStore
    let reasons: [ExclusionReason]
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(NotRightNowPage.heading)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)

                    ForEach(NotRightNowPage.ordered(reasons), id: \.self) { reason in
                        if let paragraph = NotRightNowPage.paragraph(for: reason) {
                            Text(paragraph)
                        }
                    }

                    Text(CommonLabels.talkToYourGP)
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    GPParagraphView(variant: GPParagraph.variant(for: reasons))

                    ExportControlButton(store: store)
                    Text(NotRightNowPage.recordStaysLine)
                    Text(NotRightNowPage.remindersLine(for: reasons))

                    FullWidthConfirmButton(CommonLabels.done, action: onDone)
                }
                .padding()
            }
            .getSupport(fromSelfHarmReason: reasons.contains(.selfHarm))
        }
        // safeguarding spec: the page has one control, "Done", and the app
        // does not show it again until a rule fires again. A reminder tap
        // that emptied Today's navigation path would close the page with no
        // "Done". So a reminder route waits until "Done". This is an
        // interim build: Ash decides this case on mm-t45.23 (label human).
        .holdsReminderRoutes()
    }
}
