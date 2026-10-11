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
                        .buttonStyle(.filled)
                }
                // Safeguarding: "Get support on every screen" — this is a
                // full screen, so it carries the same control every other
                // full screen this change adds does.
                // Ruling r22-06 (mm-t45.17): button text contrasts at 4.5:1 or
                // more. The secondary text colour is about 3.4:1 on white, so the
                // text uses the accent colour, as product-rules "Appearance" gives
                // every control.
                Button { isShowingSupportSheet = true } label: {
                    Text("today.getSupport").minimumHitArea()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
            .dynamicTypeSize(...(.accessibility5))
            .padding()
        }
        .sheet(isPresented: $isShowingSupportSheet) {
            SupportSheetView()
        }
    }
}
