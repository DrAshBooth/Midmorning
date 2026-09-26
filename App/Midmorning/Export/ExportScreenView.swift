import SwiftUI
import Record
import Export

/// The export screen (export spec, "Choose a date range"). Reached from the
/// settings screen's Record group (`mm-t42.12`... `mm-t42.1`'s own control),
/// from the safeguarding pages' export control (`mm-t42.13`) and from safe
/// mode's Today (`mm-t42.20`). The screen never says which of those opened
/// it (export spec, "The export offered by the deterioration rule": "The
/// export screen MUST NOT show any text about why it opened.").
struct ExportScreenView: View {
    let store: RecordStore
    var now: () -> Date = Date.init
    var calendar: Calendar = .current

    @State private var fromDayKey = ""
    @State private var toDayKey = ""
    @State private var currentDayKey = ""
    @State private var includeWeighIns = ExportContent.includeWeighInsDefault
    @State private var includeContext = ExportContent.includeContextDefault
    @State private var isLoaded = false
    @State private var isShowingShareSheet = false
    @State private var pendingFileURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                DatePicker(ExportContent.fromLabel, selection: fromDateBinding, in: ...toDateUpperBound, displayedComponents: .date)
                    .accessibilityLabel(ExportContent.fromLabel)
                DatePicker(ExportContent.toLabel, selection: toDateBinding, in: ...currentDateUpperBound, displayedComponents: .date)
                    .accessibilityLabel(ExportContent.toLabel)
            }

            Section {
                Toggle(ExportContent.includeWeighInsLabel, isOn: $includeWeighIns)
                Toggle(ExportContent.includeContextLabel, isOn: $includeContext)
            }

            Section {
                Text(ExportContent.shareDisclosureLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(ExportContent.makePDFLabel, action: makePDF)
                    .disabled(!isLoaded)
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
        }
        .navigationTitle(ExportContent.screenTitle)
        .getSupport()
        .onAppear(perform: loadDefaultsIfNeeded)
        .sheet(isPresented: $isShowingShareSheet, onDismiss: cleanUpTemporaryFile) {
            if let pendingFileURL {
                ShareSheetView(items: [pendingFileURL])
            }
        }
    }

    // MARK: Date bindings

    private var fromDateBinding: Binding<Date> {
        Binding(
            get: { ExportDayKey.date(fromDayKey) ?? now() },
            set: { fromDayKey = ExportDayKey.key(from: $0) }
        )
    }

    private var toDateBinding: Binding<Date> {
        Binding(
            get: { ExportDayKey.date(toDayKey) ?? now() },
            set: { toDayKey = ExportDayKey.key(from: $0) }
        )
    }

    /// export spec, "Choose a date range": "'From' MUST NOT be after 'To'."
    private var toDateUpperBound: Date { ExportDayKey.date(toDayKey) ?? now() }

    /// export spec: "'To' MUST NOT be after the current record day."
    private var currentDateUpperBound: Date { ExportDayKey.date(currentDayKey) ?? now() }

    // MARK: Loading

    private func loadDefaultsIfNeeded() {
        guard !isLoaded else { return }
        let today = RecordDay.key(containing: now(), calendar: calendar)
        let dayStart = (try? store.dayStartHour(effectiveOn: today)) ?? RecordDay.startHour
        currentDayKey = RecordDay.key(containing: now(), calendar: calendar, startHour: dayStart)
        let earliest = try? store.earliestEntryDayKey()
        let defaults = ExportRange.defaultRange(currentDayKey: currentDayKey, earliestEntryDayKey: earliest ?? nil)
        fromDayKey = defaults.from
        toDayKey = defaults.to
        isLoaded = true
    }

    // MARK: Make PDF

    private func makePDF() {
        errorMessage = nil
        let dayStart = (try? store.dayStartHour(effectiveOn: currentDayKey)) ?? RecordDay.startHour
        do {
            let built = try ExportComposer.buildPDF(
                store: store,
                fromDayKey: fromDayKey,
                toDayKey: toDayKey,
                includeContext: includeContext,
                includeWeighIns: includeWeighIns,
                dayStartHour: dayStart
            )
            let url = try ExportComposer.writeTemporaryFile(data: built.data, fileName: built.fileName)
            pendingFileURL = url
            isShowingShareSheet = true
        } catch {
            // export spec, "Offline and out of logs": the error carries no
            // entry field and no weight value; `ExportComposer.Failure` and
            // every file-system error here name no record content.
            errorMessage = ExportContent.buildErrorMessage
        }
    }

    private func cleanUpTemporaryFile() {
        guard let pendingFileURL else { return }
        ExportComposer.deleteTemporaryFile(at: pendingFileURL)
        self.pendingFileURL = nil
    }
}
