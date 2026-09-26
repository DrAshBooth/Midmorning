import SwiftUI
import Programme

/// "Export your record to take with you". `export` (4.2, `mm-t42`) is not
/// merged in this worktree; `mm-t42.13` connects this control to the real
/// export flow. Until then the button is present, per the spec, but does
/// nothing (the epic's own scope note).
struct ExportStubButton: View {
    var body: some View {
        Button(CommonLabels.exportControl) {}
    }
}
