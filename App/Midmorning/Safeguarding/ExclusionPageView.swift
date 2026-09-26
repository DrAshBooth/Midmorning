import SwiftUI
import Programme

/// The exclusion page (safeguarding spec, "The exclusion page"). Onboarding
/// opens this when a screening rule excludes; "Done" returns the app to
/// "What this is and isn't".
struct ExclusionPageView: View {
    let reasons: [ExclusionReason]
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(ExclusionPage.heading)
                        .font(.largeTitle.bold())
                    Text(ExclusionPage.intro)

                    ForEach(ExclusionPage.ordered(reasons), id: \.self) { reason in
                        Text(ExclusionPage.paragraph(for: reason))
                    }

                    Text(ExclusionPage.whatToDoInstead)
                        .font(.title2.bold())
                    GPParagraphView(variant: GPParagraph.variant(for: reasons))
                    BeatContactsView()

                    Text(ExclusionPage.closing)

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
