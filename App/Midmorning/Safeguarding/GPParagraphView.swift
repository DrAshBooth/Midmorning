import SwiftUI
import UIKit
import UniformTypeIdentifiers
import Programme

/// The GP paragraph, editable, with "Copy" (safeguarding spec, "The GP
/// paragraph"). The pasteboard write, its 60-second local-only expiry and
/// the VoiceOver announcement are system-API behaviour a device check
/// proves; `GPParagraphCopy` (Programme) supplies the pure content and timings.
struct GPParagraphView: View {
    let variant: GPParagraphVariant
    @State private var edited: String?
    @State private var isShowingCopiedLabel = false
    @State private var isShowingCopiedConfirmation = false

    private var bundledText: String { GPParagraph.text(for: variant) }

    /// The text in the editor: the person's edit, or the bundled text.
    private var shownText: String { edited ?? bundledText }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // The editor grows with its text, so the whole paragraph shows at
            // every text size. A hidden copy of the text, with the editor's
            // own insets (8 points above and below, 5 at each side), sets the
            // height, and the editor fills it. With only a fixed height the
            // editor stayed 110 points high and showed the first lines at the
            // largest text size; with `fixedSize` it showed no text at all on
            // the iOS 27.0 simulator (AutomatedChecks
            // .testAuditExclusionPageAndCautionSheet).
            Text(verbatim: shownText)
                .padding(.vertical, 8)
                .padding(.horizontal, 5)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                .opacity(0)
                .accessibilityHidden(true)
                .overlay {
                    TextEditor(text: Binding(
                        get: { shownText },
                        set: { edited = $0 }
                    ))
                    .accessibilityLabel(CommonLabels.gpParagraphAccessibilityLabel.string)
                }
                .dynamicTypeSize(.large ... .accessibility5)

            Button { copy() } label: {
                Text(isShowingCopiedLabel ? GPParagraphCopy.copiedLabel : GPParagraphCopy.copyLabel).minimumHitArea()
            }
            // In a List row, only a tap on "Copy" itself copies.
            .buttonStyle(.borderless)

            if isShowingCopiedConfirmation {
                Text(GPParagraphCopy.copiedConfirmationLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        // "Edit not kept": a fresh `edited` state each time this view is
        // created (a new sheet, a new page) shows the bundled text again.
        .onDisappear { edited = nil }
    }

    private func copy() {
        let text = GPParagraphCopy.textToCopy(bundled: bundledText, edited: edited)
        UIPasteboard.general.setItems(
            [[UTType.plainText.identifier: text]],
            options: [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(GPParagraphCopy.pasteboardExpirySeconds),
            ]
        )
        isShowingCopiedLabel = true
        isShowingCopiedConfirmation = true
        UIAccessibility.post(notification: .announcement, argument: GPParagraphCopy.voiceOverAnnouncement)
        DispatchQueue.main.asyncAfter(deadline: .now() + GPParagraphCopy.copiedLabelDurationSeconds) {
            isShowingCopiedLabel = false
        }
    }
}
