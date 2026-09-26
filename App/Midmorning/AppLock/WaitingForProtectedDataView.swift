import SwiftUI

/// Shown while `UIApplication.isProtectedDataAvailable` is false — before
/// the first unlock after a restart (data-and-privacy spec, "File
/// protection": "Launch before the first unlock"; "Launch safety": "the app
/// MUST open the store container only when protected data is available").
/// No control: the app lock's own settings live in the store this screen
/// cannot yet open, so it offers neither "Unlock" nor "Delete everything",
/// only the plain cover the app-lock spec's "The cover" already shows while
/// merely inactive.
struct WaitingForProtectedDataView: View {
    @State private var isShowingSupportSheet = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("applock.cover.title")
                    .font(.title2)
                // Safeguarding: "Get support on every screen" — the
                // placeholder sheet needs no store, so it stays reachable
                // even while the app cannot yet open one.
                Button("settings.getSupport") { isShowingSupportSheet = true }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $isShowingSupportSheet) {
            GetSupportPlaceholderSheet()
        }
    }
}
