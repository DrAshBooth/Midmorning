import SwiftUI

/// The lock control decision 91 places at the leading edge of Today's
/// navigation bar: the lock glyph, no text, VoiceOver label "Lock". A tap
/// locks the app at once, with no grace period (requirement: "The lock
/// control on Today").
///
/// Built here as a standalone control, over fixture facts: mm-t24.21 wires
/// it into Today's own toolbar end to end (the change README, "Built over
/// fixture facts"). Plain system styling: `Appearance.swift` and the shared
/// accent colour asset (decision 92, mm-pr12) are `record-full`'s (mm-t12b)
/// own first child and are not in this worktree; this control adopts the
/// accent colour as its tint once that lands, per product-rules
/// "Appearance".
struct LockControlButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "lock")
        }
        .accessibilityLabel("applock.lockControl.accessibilityLabel")
    }
}
