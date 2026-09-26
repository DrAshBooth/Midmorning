import SwiftUI
import Programme

/// The support sheet (safeguarding spec, "The support sheet"). Opened from
/// Get support, it has a "Close" control in the navigation bar.
struct SupportSheetView: View {
    var fromSelfHarmReason: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                SupportSheetSections(order: SupportSheet.order(fromSelfHarmReason: fromSelfHarmReason))
            }
            .navigationTitle(SupportSheet.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(CommonLabels.close) { dismiss() }
                }
            }
        }
    }
}

/// The support sheet's items as list sections, in the order given
/// (safeguarding spec, "The support sheet"). The sheet shows them in its own
/// List. A screen that asks the self-harm item shows them in its own Form,
/// under the support line, in `SupportSheet.inlineOrder` ("The self-harm
/// item": "Under the line the app MUST show the support sheet's items
/// inline, with Samaritans first."). The inline form has no navigation bar
/// and no "Close". Each number, the webchat link and the GP paragraph's
/// "Copy" sit in their own row, with their own tap target.
struct SupportSheetSections: View {
    let order: [SupportSheet.Item]
    @State private var copiedNumber: String?

    var body: some View {
        ForEach(order, id: \.self) { item in
            section(for: item)
        }
    }

    @ViewBuilder
    private func section(for item: SupportSheet.Item) -> some View {
        switch item {
        case .beatHelpline:
            Section("Beat helpline") {
                Text(SupportSheet.beatIntro)
                ForEach(SupportSheet.beatNumbers, id: \.number) { entry in
                    NumberRow(label: entry.label, number: entry.number, copiedNumber: $copiedNumber)
                }
                Text(SupportSheet.beatHoursLine).font(.footnote).foregroundStyle(.secondary)
            }
        case .beatWebchat:
            Section {
                BeatWebchatButton()
            }
        case .samaritans:
            Section(CommonLabels.samaritansName) {
                NumberRow(label: CommonLabels.samaritansName, number: SupportSheet.samaritansNumber, copiedNumber: $copiedNumber)
                Text(SupportSheet.samaritansLine).font(.footnote).foregroundStyle(.secondary)
                NumberRow(label: "Samaritans in Welsh", number: SupportSheet.samaritansWelshNumber, copiedNumber: $copiedNumber)
            }
        case .lifelineNI:
            Section("Lifeline, Northern Ireland") {
                NumberRow(label: "Lifeline, Northern Ireland", number: SupportSheet.lifelineNumber, copiedNumber: $copiedNumber)
                Text(SupportSheet.lifelineLine).font(.footnote).foregroundStyle(.secondary)
            }
        case .nhs111:
            Section("NHS 111") {
                NumberRow(label: "NHS 111", number: SupportSheet.nhs111Number, copiedNumber: $copiedNumber)
                Text(SupportSheet.nhs111Line).font(.footnote).foregroundStyle(.secondary)
                Text(SupportSheet.nhs111RegionLine).font(.footnote).foregroundStyle(.secondary)
            }
        case .emergency999:
            Section("999") {
                NumberRow(label: "999", number: SupportSheet.emergencyNumber, copiedNumber: $copiedNumber)
                Text(SupportSheet.emergencyLine).font(.footnote).foregroundStyle(.secondary)
            }
        case .talkToYourGP:
            Section(CommonLabels.talkToYourGP) {
                Text(SupportSheet.compensationLine)
                GPParagraphView(variant: .standard)
            }
        }
    }
}

/// The support sheet's items inline, with Samaritans first (safeguarding
/// spec, "The self-harm item"). After "Yes" and then "No", a screen that asks
/// the self-harm item shows the support line as the last row of the item's
/// own section and places this right after that section. Onboarding screen
/// 2, the weekly review and the restart re-screen use it.
struct SelfHarmInlineSupport: View {
    var body: some View {
        SupportSheetSections(order: SupportSheet.inlineOrder)
    }
}
