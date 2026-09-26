import SwiftUI
import UIKit
import SafariServices
import UniformTypeIdentifiers
import Programme

/// The four Beat numbers and "Beat webchat" (safeguarding spec, "The
/// exclusion page": "The page MUST show the four Beat numbers... and 'Beat
/// webchat'."). The exclusion page shows this in a ScrollView, not a List.
/// `SupportSheetSections` shows the same rows inside its own list.
struct BeatContactsView: View {
    @State private var copiedNumber: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(SupportSheet.beatNumbers, id: \.number) { entry in
                NumberRow(label: entry.label, number: entry.number, copiedNumber: $copiedNumber)
            }
            BeatWebchatButton()
        }
    }
}

/// One number with "Call" and "Copy number" (safeguarding spec, "The
/// support sheet"). "Call" first shows the Recents warning. "Copy number"
/// puts the number on the pasteboard, local-only, with a 60-second expiry,
/// under the rules of the GP paragraph's "Copy": the control reads "Copied"
/// for two seconds, and "Copied. It clears in a minute." stays under the
/// number until the screen closes or another number is copied.
///
/// Each control has the borderless style, so in a List or Form row a tap
/// runs only the control under the finger, never every button in the row.
/// At an accessibility text size the number sits above the controls, and
/// the controls stack, so no text breaks or truncates.
struct NumberRow: View {
    let label: String
    let number: String
    /// The number that the last "Copy number" put on the pasteboard. The
    /// owner of the list holds it, so one confirmation line shows at a time.
    @Binding var copiedNumber: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isConfirmingCall = false
    @State private var showsCopiedLabel = false
    @State private var copyCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dynamicTypeSize.isAccessibilitySize {
                labelAndNumber
                VStack(alignment: .leading, spacing: 8) { controls }
            } else {
                HStack {
                    labelAndNumber
                    Spacer()
                    controls
                }
            }
            if copiedNumber == number {
                Text(SupportSheet.copiedConfirmationLine).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .confirmationDialog(SupportSheet.callRecentsWarning, isPresented: $isConfirmingCall, titleVisibility: .visible) {
            Button(CommonLabels.call) { NumberRow.startCall(number) }
            Button(CommonLabels.cancel, role: .cancel) {}
        }
        .task(id: copyCount) {
            guard copyCount > 0 else { return }
            try? await Task.sleep(for: .seconds(GPParagraphCopy.copiedLabelDurationSeconds))
            if !Task.isCancelled { showsCopiedLabel = false }
        }
    }

    private var labelAndNumber: some View {
        VStack(alignment: .leading) {
            Text(label)
            Text(number).font(.headline)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var controls: some View {
        Button(CommonLabels.call) { isConfirmingCall = true }
            .buttonStyle(.borderless)
        Button(showsCopiedLabel ? CommonLabels.copied : CommonLabels.copyNumber) { copy() }
            .buttonStyle(.borderless)
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
        showsCopiedLabel = true
        copyCount += 1
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

/// "Beat webchat": opens Beat's help page in an `SFSafariViewController`
/// over the current screen (safeguarding spec, "The support sheet").
struct BeatWebchatButton: View {
    @State private var isShowingWebchat = false

    var body: some View {
        Button(CommonLabels.beatWebchat) { isShowingWebchat = true }
            .buttonStyle(.borderless)
            .sheet(isPresented: $isShowingWebchat) {
                SafariView(urlString: SupportSheet.beatWebchatURLString)
            }
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
