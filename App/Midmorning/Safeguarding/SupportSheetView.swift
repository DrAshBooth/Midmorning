import SwiftUI
import Programme

/// The support sheet (safeguarding spec, "The support sheet"). When opened
/// from Get support it has a "Close" control; the inline form a review or a
/// check-in embeds (not built by this change) sets `showsCloseButton: false`.
struct SupportSheetView: View {
    var fromSelfHarmReason: Bool = false
    var showsCloseButton: Bool = true
    @Environment(\.dismiss) private var dismiss
    @State private var pendingCallNumber: String?
    @State private var isShowingWebchat = false
    @State private var copiedNumber: String?

    var body: some View {
        NavigationStack {
            List {
                ForEach(SupportSheet.order(fromSelfHarmReason: fromSelfHarmReason), id: \.self) { item in
                    section(for: item)
                }
            }
            .navigationTitle(SupportSheet.title)
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(CommonLabels.close) { dismiss() }
                    }
                }
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

    @ViewBuilder
    private func section(for item: SupportSheet.Item) -> some View {
        switch item {
        case .beatHelpline:
            Section("Beat helpline") {
                Text(SupportSheet.beatIntro)
                ForEach(SupportSheet.beatNumbers, id: \.number) { entry in
                    NumberRow(label: entry.label, number: entry.number, pendingCallNumber: $pendingCallNumber, copiedNumber: $copiedNumber)
                }
                Text(SupportSheet.beatHoursLine).font(.footnote).foregroundStyle(.secondary)
            }
        case .beatWebchat:
            Section {
                Button(CommonLabels.beatWebchat) { isShowingWebchat = true }
            }
        case .samaritans:
            Section("Samaritans") {
                NumberRow(label: "Samaritans", number: SupportSheet.samaritansNumber, pendingCallNumber: $pendingCallNumber, copiedNumber: $copiedNumber)
                Text(SupportSheet.samaritansLine).font(.footnote).foregroundStyle(.secondary)
                NumberRow(label: "Samaritans in Welsh", number: SupportSheet.samaritansWelshNumber, pendingCallNumber: $pendingCallNumber, copiedNumber: $copiedNumber)
            }
        case .lifelineNI:
            Section("Lifeline, Northern Ireland") {
                NumberRow(label: "Lifeline, Northern Ireland", number: SupportSheet.lifelineNumber, pendingCallNumber: $pendingCallNumber, copiedNumber: $copiedNumber)
                Text(SupportSheet.lifelineLine).font(.footnote).foregroundStyle(.secondary)
            }
        case .nhs111:
            Section("NHS 111") {
                NumberRow(label: "NHS 111", number: SupportSheet.nhs111Number, pendingCallNumber: $pendingCallNumber, copiedNumber: $copiedNumber)
                Text(SupportSheet.nhs111Line).font(.footnote).foregroundStyle(.secondary)
                Text(SupportSheet.nhs111RegionLine).font(.footnote).foregroundStyle(.secondary)
            }
        case .emergency999:
            Section("999") {
                NumberRow(label: "999", number: SupportSheet.emergencyNumber, pendingCallNumber: $pendingCallNumber, copiedNumber: $copiedNumber)
                Text(SupportSheet.emergencyLine).font(.footnote).foregroundStyle(.secondary)
            }
        case .talkToYourGP:
            Section("Talk to your GP") {
                Text(SupportSheet.compensationLine)
                GPParagraphView(variant: .standard)
            }
        }
    }
}
