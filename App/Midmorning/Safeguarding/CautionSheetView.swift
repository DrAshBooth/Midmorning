import SwiftUI
import Programme

/// The caution sheet (safeguarding spec, "Screening rules for BMI"): shown
/// before onboarding continues when the caution flag is set and no rule
/// excludes.
struct CautionSheetView: View {
    var onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(CommonLabels.cautionSheetBody)

                    Text(CommonLabels.talkToYourGP)
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    GPParagraphView(variant: .standard)

                    FullWidthConfirmButton(CommonLabels.continueLabel, action: onContinue)
                }
                .padding()
            }
            .getSupport()
        }
        .interactiveDismissDisabled()
    }
}
