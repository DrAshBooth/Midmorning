import SwiftUI
import Programme

/// The GP suggestion page (safeguarding spec, "The GP suggestion page").
/// `mm-t22` (the underweight check), `mm-t32` (the deterioration rule and
/// "I'm getting worse") open this from their own triggers; this change
/// builds the page itself.
struct GPSuggestionPageView: View {
    let reasons: [GPSuggestionReason]
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(GPSuggestionPage.heading)
                        .font(.largeTitle.bold())

                    ForEach(Array(reasons.enumerated()), id: \.offset) { _, reason in
                        Text(GPSuggestionPage.line(for: reason))
                        Text(GPSuggestionPage.supportingLine(for: reason))
                            .foregroundStyle(.secondary)
                    }

                    Text(GPSuggestionPage.diagnosisLine)

                    Text(CommonLabels.talkToYourGP)
                        .font(.title2.bold())
                    GPParagraphView(variant: .standard)

                    ExportStubButton()

                    Button(CommonLabels.done) { onDone() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .getSupport()
        }
    }
}
