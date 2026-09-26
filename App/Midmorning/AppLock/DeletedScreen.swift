import SwiftUI

/// The one screen Delete-all and "Delete from this device" each show,
/// staying up until the next launch (data-and-privacy spec, "Delete-all":
/// "the app MUST then show one screen... The app MUST keep that screen
/// after 'Done' until the next launch"; "Delete from this device" states
/// the same rule with its own text). "Done" does nothing but acknowledge:
/// there is nothing left to show until the app relaunches into onboarding.
struct DeletedScreen: View {
    enum Kind {
        case everything
        case thisDeviceOnly

        var messageKey: LocalizedStringKey {
            switch self {
            case .everything: return "applock.deleteEverything.done.message"
            case .thisDeviceOnly: return "applock.deleteFromThisDevice.done.message"
            }
        }
    }

    let kind: Kind
    @State private var isAcknowledged = false
    @State private var isShowingSupportSheet = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Text(kind.messageKey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                if !isAcknowledged {
                    Button("applock.done") { isAcknowledged = true }
                        .buttonStyle(.borderedProminent)
                }
                // Safeguarding: "Get support on every screen" — this is a
                // full screen, so it carries the same control every other
                // full screen this change adds does.
                Button("settings.getSupport") { isShowingSupportSheet = true }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .dynamicTypeSize(...(.accessibility5))
            .padding()
        }
        .sheet(isPresented: $isShowingSupportSheet) {
            SupportSheetView()
        }
    }
}
