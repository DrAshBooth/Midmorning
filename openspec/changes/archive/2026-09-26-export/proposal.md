# Proposal

## Why

Task 4.2 of `v1-programme`. The person needs a paper-like record to hand to a GP or a therapist. `settings`, `weigh-in` and `safeguarding` (`mm-t13`, `mm-t22`, `mm-t14`, `mm-t41`) already show a stub "Export" control and a stub "Export your record to take with you" button on three pages. No PDF exists yet. `record-full`, `weigh-in` and `local-delete-all` are merged, so this change can build the real export.

## What Changes

- `ExportDocument`, `Paginator` and `ExportFileName` in a new `Export` package target. `ExportDocument` holds the PDF's content as a value; `Paginator.paginate(document:pageHeight:measure:)` splits it into pages and repeats a day's heading on the page that continues it; the package imports no UIKit, so it stays testable under `swift test` on macOS. `ExportDocumentBuilder` and `ExportWeighInPageBuilder` map `RecordStore`'s rows into a document, reusing `weigh-in`'s own `WeighInWeight.display` for the weigh-in page's values.
- The export screen (`App/Midmorning/Export/ExportScreenView.swift`): "From" and "To" date controls, "Include weigh-ins" and "Include context", the share-disclosure line and "Make PDF". Reached from the settings screen's Record group in one tap, and from Today in two.
- `ExportPDFRenderer`: a tagged, A4 PDF drawn with Core Graphics (`CGPDFContextBeginTag`/`EndTag`). "Record" is an H1, each day heading an H2, each day's entries one tagged list with one list item per entry; every tag names the language en-GB. Fixed text sizes (11/14/18 pt), independent of Dynamic Type. Empty Creator, no Author, the system's own Producer, no password.
- `ShareSheetView` presents the PDF in the system share sheet; the app writes it to a protected temporary file and deletes it when the sheet closes, either way.
- Connects the three existing stub controls (the settings screen's Record group, the GP suggestion page, the not-right-now page) to the real screen, with the default range and no text about why it opened — the same control the deterioration rule's own offer uses.
- `AppLockRootView` gains a `safeMode` phase: on the third consecutive launch with an uncleared marker (`Record.LaunchSafety`, built by `local-delete-all` over fixture facts), the app now opens a minimal `SafeModeView` — Today with only Export and Get support — instead of the ordinary running phase, so the reminder scheduler is never called.
- Proves, over real components, four Delete-all scenarios earlier epics proved only by argument, and the two `local-delete-all` scenarios built over fixture facts (the three-launch restart, a real container failure).

Not in this change: a real `UNUserNotificationCenter`-driven proof of "Pending requests first" (confirmed to crash outside a real app bundle; stays a device check); the widget-snapshot half of "Side files" (`2.5`, not merged); the App Store submission gate (`mm-t43`).

## Capabilities

### New Capabilities
- `export`: the whole capability, every requirement this change builds.

### Modified Capabilities
- `weigh-in`: adds "The weigh-in page in an export", with the three scenarios this change builds.

## Impact

- `Packages/Sources/Export/`: `ExportContent.swift`, `ExportDayKey.swift`, `ExportDocument.swift`, `ExportDocumentBuilder.swift`, `ExportFileName.swift`, `ExportRange.swift`, `ExportWeighInPageBuilder.swift`, `Paginator.swift`. New target, depends on `Record` and `Programme`.
- `Packages/Sources/Record/RecordStore.swift`: `earliestEntryDayKey()`.
- `App/Midmorning/Export/`: `ExportComposer.swift`, `ExportPDFRenderer.swift`, `ExportScreenView.swift`, `ShareSheetView.swift`.
- `App/Midmorning/AppLock/`: `AppLockRootView.swift` (the `safeMode` phase), `SafeModeView.swift`.
- `App/Midmorning/Safeguarding/`: `ExportControlButton.swift` (renamed from the `ExportStubButton` placeholder), `GPSuggestionPageView.swift`, `NotRightNowPageView.swift` (each now takes `store: RecordStore`).
- `App/Midmorning/SettingsView.swift`: the Record group's "Export" control.
- `App/Midmorning.xcodeproj/project.pbxproj`: links the new `Export` package product.
- No third-party dependency. `Export` imports Foundation, CoreGraphics (the app target only) and the two packages named above; never UIKit inside `Packages/Sources/Export`.
