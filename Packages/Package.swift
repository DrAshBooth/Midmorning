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
        // literal, spec-named path that tooling reads directly.
        .target(name: "Content", path: "Content", exclude: ["SIGNOFF.md"], resources: [.copy("Resources")]),
        .testTarget(name: "ContentTests", dependencies: ["Content"], path: "Tests/ContentTests"),
        // scripts/content-lock runs this. It is not part of `swift test`.
        .executableTarget(name: "ContentLockTool", dependencies: ["Content"], path: "Tools/ContentLockTool"),
        // scripts/content-signoff-list runs this. It is not part of `swift test`.
        .executableTarget(name: "ContentSignOffListTool", dependencies: ["Content"], path: "Tools/ContentSignOffListTool"),
    ]
)
