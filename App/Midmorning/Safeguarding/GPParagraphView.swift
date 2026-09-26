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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: Binding(
                get: { edited ?? bundledText },
                set: { edited = $0 }
            ))
            .frame(minHeight: 110)
            .dynamicTypeSize(.large ... .accessibility5)
            .accessibilityLabel(CommonLabels.gpParagraphAccessibilityLabel)

            Button(isShowingCopiedLabel ? GPParagraphCopy.copiedLabel : GPParagraphCopy.copyLabel) {
                copy()
            }

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
