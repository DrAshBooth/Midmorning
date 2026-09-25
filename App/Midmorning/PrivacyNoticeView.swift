import SwiftUI

/// The in-app privacy notice the Privacy group's "Privacy" row opens
/// (data-and-privacy spec, "The privacy notice"; settings spec, "The
/// Privacy group"). The controller, the lawful basis and the Article 9 text
/// come from mm-t43.23; this screen shows a placeholder for those three
/// until that bead lands. The team publishes the same content at a public
/// URL (mm-t43.6); that publication, and the legal text itself, are outside
/// this package.
struct PrivacyNoticeView: View {
    let contactEmail: String

    @State private var isShowingSupportSheet = false

    var body: some View {
        Form {
            Section("settings.privacyNotice.controller.heading") {
                Text("settings.privacyNotice.controller.body")
            }
            Section("settings.privacyNotice.lawfulBasis.heading") {
                Text("settings.privacyNotice.lawfulBasis.body")
            }
            Section("settings.privacyNotice.apple.heading") {
                Text("settings.privacyNotice.apple.body")
            }
            Section("settings.privacyNotice.analytics.heading") {
                Text("settings.privacyNotice.analytics.body")
            }
            Section("settings.privacyNotice.yourData.heading") {
                Text("settings.privacyNotice.yourData.body")
                Text("settings.privacyNotice.backup.body")
            }
            Section("settings.privacyNotice.contact.heading") {
                Text(contactEmail)
                Text("settings.privacyNotice.contact.whoReads")
            }
            Section("settings.privacyNotice.complaints.heading") {
                Text("settings.privacyNotice.complaints.body")
            }
        }
        .navigationTitle("settings.privacyNotice.title")
        .toolbar {
            // Decision 94: the trailing position of the navigation bar
            // (safeguarding spec, "Get support on every screen").
            ToolbarItem(placement: .confirmationAction) {
                Button("settings.getSupport") { isShowingSupportSheet = true }
            }
        }
        .sheet(isPresented: $isShowingSupportSheet) {
            GetSupportPlaceholderSheet()
        }
    }
}
