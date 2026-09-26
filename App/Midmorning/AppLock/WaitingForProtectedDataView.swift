import SwiftUI

/// Shown while `UIApplication.isProtectedDataAvailable` is false — before
/// the first unlock after a restart (data-and-privacy spec, "File
/// protection": "Launch before the first unlock"; "Launch safety": "the app
/// MUST open the store container only when protected data is available").
/// Data-and-privacy spec, "File protection": "When protected data is
/// unavailable, the app MUST show the cover." So this screen shows
/// "Midmorning" only, the same as the cover of the inactive app. It has no
/// control: the app lock's own settings live in the store this screen
/// cannot open yet, so it offers neither "Unlock" nor "Delete everything".
/// It has no "Get support" either (mm-t41.22): app-lock spec, "The cover":
/// "The cover MUST NOT show Get support, because the cover names nothing",
/// and safeguarding spec, "Get support on every screen": "Get support MUST
/// appear only after the person authenticates."
struct WaitingForProtectedDataView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            Text("applock.cover.title")
                .font(.title2)
        }
    }
}
