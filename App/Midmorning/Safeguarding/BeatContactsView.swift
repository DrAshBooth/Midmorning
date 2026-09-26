import SwiftUI
import UIKit
import SafariServices
import UniformTypeIdentifiers
import Programme

/// The four Beat numbers and "Beat webchat" (safeguarding spec, "The
/// exclusion page": "The page MUST show the four Beat numbers... and 'Beat
/// webchat'."). `SupportSheetView` embeds the same numbers inside its own
/// full list.
struct BeatContactsView: View {
    @State private var pendingCallNumber: String?
    @State private var isShowingWebchat = false
    @State private var copiedNumber: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(SupportSheet.beatNumbers, id: \.number) { entry in
                NumberRow(label: entry.label, number: entry.number, pendingCallNumber: $pendingCallNumber, copiedNumber: $copiedNumber)
            }
            Button(CommonLabels.beatWebchat) { isShowingWebchat = true }
        }
        .confirmationDialog(
            SupportSheet.callRecentsWarning,
            isPresented: Binding(get: { pendingCallNumber != nil }, set: { if !$0 { pendingCallNumber = nil } }),
            titleVisibility: .visible
        ) {
            Button(CommonLabels.call) {
                if let number = pendingCallNumber { NumberRow.startCall(number) }
                pendingCallNumber = nil
            }
            Button(CommonLabels.cancel, role: .cancel) { pendingCallNumber = nil }
        }
        .sheet(isPresented: $isShowingWebchat) {
            SafariView(urlString: SupportSheet.beatWebchatURLString)
        }
    }
}

/// One number with "Call" and "Copy number" (safeguarding spec, "The
/// support sheet"). "Call" first shows the Recents warning; "Copy number"
/// places the number on the pasteboard, local-only, with a 60-second
/// expiry, and shows "Copied. It clears in a minute." for two seconds.
struct NumberRow: View {
    let label: String
    let number: String
    @Binding var pendingCallNumber: String?
    @Binding var copiedNumber: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(label)
                    Text(number).font(.headline)
                }
                Spacer()
                Button(CommonLabels.call) { pendingCallNumber = number }
                Button(copiedNumber == number ? CommonLabels.copied : CommonLabels.copyNumber) { copy() }
            }
            if copiedNumber == number {
                Text(SupportSheet.copiedConfirmationLine).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func copy() {
        UIPasteboard.general.setItems(
            [[UTType.plainText.identifier: number]],
            options: [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(SupportSheet.pasteboardExpirySeconds),
            ]
        )
        copiedNumber = number
        UIAccessibility.post(notification: .announcement, argument: CommonLabels.copied)
    }

    /// Starts the system call flow. `tel://` with digits only, per the
    /// number's own formatting (no spaces or punctuation in the URL).
    static func startCall(_ number: String) {
        let digits = number.filter(\.isNumber)
        guard let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }
}

/// `SFSafariViewController` over the sheet (safeguarding spec, "The support
/// sheet": "MUST open Beat's help page in an SFSafariViewController...
/// MUST NOT open the page in Safari or in a WKWebView.").
struct SafariView: UIViewControllerRepresentable {
    let urlString: String

    func makeUIViewController(context: Context) -> UIViewController {
        guard let url = URL(string: urlString) else { return UIViewController() }
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
