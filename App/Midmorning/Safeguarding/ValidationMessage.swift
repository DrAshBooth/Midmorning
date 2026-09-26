import SwiftUI
import UIKit

/// A validation message, such as "Please answer this one." or the weigh-in
/// range message, in the neutral text colour (r13-15, mm-t14.45). The app
/// never shows a validation message in red, also under the self-harm
/// question and on the weigh-in screen. The focus move and the VoiceOver
/// announcement (`ValidationAnnouncement`) tell the person about the
/// message, not a colour. `product-rules`: every screen uses the system
/// semantic colours.
struct ValidationMessageText: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Text(verbatim: message)
            .foregroundStyle(.primary)
    }
}

/// The VoiceOver announcement of a validation message (r13-15,
/// mm-t14.45). The announcement waits in the speech queue, so VoiceOver
/// first reads the question that the focus move goes to, and then the
/// message.
@MainActor
enum ValidationAnnouncement {
    static func post(_ message: String) {
        let queued = NSAttributedString(string: message, attributes: [.accessibilitySpeechQueueAnnouncement: true])
        UIAccessibility.post(notification: .announcement, argument: queued)
    }
}
