// swift-tools-version: 6.0
import PackageDescription

// One package, one build tree: every module compiles once under `swift test`.
// Ash chose this on 25 September 2026 so ./verify stays inside its budget as
// the Plan, Programme and Content modules join.
let package = Package(
    name: "Midmorning",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "Record", targets: ["Record"]),
        .library(name: "Constants", targets: ["Constants"]),
        .library(name: "Plan", targets: ["Plan"]),
        .library(name: "AppLock", targets: ["AppLock"]),
        .library(name: "Programme", targets: ["Programme"]),
        .library(name: "Content", targets: ["Content"]),
        .library(name: "Export", targets: ["Export"]),
        .executable(name: "content-lock", targets: ["ContentLockTool"]),
        .executable(name: "content-signoff-list", targets: ["ContentSignOffListTool"]),
    ],
    targets: [
        .target(name: "Constants"),
        // `Record` depends on `Plan` for the slot, planned-meal and
        // materialisation shapes that `Day.slotsJSON` and `Template.slotsJSON`
        // hold opaquely (regular-eating-plan, 2.3): one source of truth for
        // the payload shape, not a duplicate in each target. `Plan` never
        // imports `Record`, so there is no cycle.
        .target(name: "Record", dependencies: ["Constants", "Plan"], resources: [.copy("FrozenSchema.json")]),
        .testTarget(name: "ConstantsTests", dependencies: ["Constants"]),
        // Also depends on `Programme` (test-only; `Record` itself never
        // does) so a test can prove the composition of `Programme`'s
        // pending-card output with `Record`'s `TodayCardSlot` — the seam
        // `programme-engine` (2.1) wires in the App target
        // (`v1-programme/design.md`, "Programme takes value facts").
        .testTarget(name: "RecordTests", dependencies: ["Record", "Programme", "Export", "AppLock"]),
        // The plan, templates, planned days, the match of planned meals to
        // entries and the gap computation (design.md, "One umbrella package,
        // five targets"). Pure value types and functions only: it takes
        // value facts, never a `Record` model, so it compiles without
        // `Record` (regular-eating-plan, 2.3).
        .target(name: "Plan", dependencies: ["Constants"]),
        .testTarget(name: "PlanTests", dependencies: ["Plan"]),
        // The pure app-lock rules: the cover state machine, the label
        // function, the lock-grace policy and the seams the App target's
        // LocalAuthentication and lifecycle code call (app-lock spec).
        .target(name: "AppLock", dependencies: ["Constants"]),
        .testTarget(name: "AppLockTests", dependencies: ["AppLock"]),
        // The safeguarding rules and (from later changes) the stage engine,
        // week counting, the weekly review builder, pattern sentences, the
        // scheduler and the analytics summary builder (design.md, "One
        // umbrella package, five targets"). `Programme` takes value facts
        // and imports `Constants` only, never `Record` or `Plan`, so every
        // rule here is a pure function a test drives with fixed inputs.
        .target(name: "Programme", dependencies: ["Constants"], path: "Programme"),
        .testTarget(name: "ProgrammeTests", dependencies: ["Programme"], path: "Tests/ProgrammeTests"),
        // The content spec fixes this package's path, `Packages/Content`,
        // because the content-lock file and the sign-off files live at a
        // literal, spec-named path that tooling reads directly. Each
        // resource is named individually, not as a whole-folder `.copy
        // ("Resources")`: a resource-only bundle with a nested top-level
        // directory fails codesign ("bundle format unrecognized") once the
        // App target links it, which `swift test` alone never surfaces.
        // Whoever adds a file under `Resources` (for example the next
        // content version's sign-off file) adds its own `.copy` line here.
        .target(name: "Content", path: "Content", exclude: ["SIGNOFF.md"], resources: [
            .copy("Resources/manifest.json"),
            .copy("Resources/cards.json"),
            .copy("Resources/strings.json"),
            .copy("Resources/content-lock.json"),
        ]),
        .testTarget(name: "ContentTests", dependencies: ["Content"], path: "Tests/ContentTests"),
        // `ExportDocument`, `Paginator` and `ExportFileName` (export spec,
        // "The document and the paginator live in a package"): imports no
        // UIKit, so it stays testable under `swift test` on macOS, where
        // UIKit does not exist; the app target supplies the text measurer
        // and does the Core Graphics drawing (4.2, `mm-t42.10`). Depends on
        // `Record` only for its already-neutral read types (`RecordRow`,
        // `DayStateKind`), never a `@Model` class.
        .target(name: "Export", dependencies: ["Record", "Programme"]),
        .testTarget(name: "ExportTests", dependencies: ["Export", "Record", "Programme"]),
        // scripts/content-lock runs this. It is not part of `swift test`.
        .executableTarget(name: "ContentLockTool", dependencies: ["Content"], path: "Tools/ContentLockTool"),
        // scripts/content-signoff-list runs this. It is not part of `swift test`.
        .executableTarget(name: "ContentSignOffListTool", dependencies: ["Content"], path: "Tools/ContentSignOffListTool"),
    ]
)
