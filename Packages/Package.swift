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
        .library(name: "Content", targets: ["Content"]),
        .executable(name: "content-lock", targets: ["ContentLockTool"]),
        .executable(name: "content-signoff-list", targets: ["ContentSignOffListTool"]),
    ],
    targets: [
        .target(name: "Constants"),
        .target(name: "Record", dependencies: ["Constants"], resources: [.copy("FrozenSchema.json")]),
        .testTarget(name: "ConstantsTests", dependencies: ["Constants"]),
        .testTarget(name: "RecordTests", dependencies: ["Record"]),
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
        // scripts/content-lock runs this. It is not part of `swift test`.
        .executableTarget(name: "ContentLockTool", dependencies: ["Content"], path: "Tools/ContentLockTool"),
        // scripts/content-signoff-list runs this. It is not part of `swift test`.
        .executableTarget(name: "ContentSignOffListTool", dependencies: ["Content"], path: "Tools/ContentSignOffListTool"),
    ]
)
