import SwiftUI
import Programme

/// "Get support" in the navigation bar's trailing position, wired to open
/// the support sheet (safeguarding spec, "Get support on every screen").
/// Every full screen this change adds applies this modifier; the cover and
/// a sheet that closes in one tap to a screen already showing the control
/// are the spec's own exemptions and apply this to neither.
struct GetSupportModifier: ViewModifier {
    var fromSelfHarmReason: Bool = false
    @State private var showingSupportSheet = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSupportSheet = true
                    } label: {
                        Text("today.getSupport")
                    }
                    .accessibilityLabel("today.getSupport")
                }
            }
            .sheet(isPresented: $showingSupportSheet) {
                SupportSheetView(fromSelfHarmReason: fromSelfHarmReason)
            }
    }
}

extension View {
    /// Adds "Get support" to this screen's navigation bar (safeguarding
    /// spec, "Get support on every screen"). Pass `fromSelfHarmReason: true`
    /// on a screen that opened from a self-harm answer, so the sheet lists
    /// Samaritans first.
    func getSupport(fromSelfHarmReason: Bool = false) -> some View {
        modifier(GetSupportModifier(fromSelfHarmReason: fromSelfHarmReason))
    }
}
