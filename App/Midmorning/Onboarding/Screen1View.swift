import SwiftUI
import Programme

/// "What this is and isn't" (onboarding spec, "Screen 1: what this is and
/// isn't"). Only a tap on "Continue" advances the screen; no timer, no
/// swipe, no preselection, no animation.
struct Screen1View: View {
    var onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(Screen1Content.lines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                    }
                    Button(Screen1Content.continueLabel) { onContinue() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle(Screen1Content.title)
            .navigationBarTitleDisplayMode(.inline)
            .getSupport()
        }
    }
}
