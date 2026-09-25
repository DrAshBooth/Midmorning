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
    ],
    targets: [
        .target(name: "Constants"),
        .target(name: "Record", dependencies: ["Constants"], resources: [.copy("FrozenSchema.json")]),
        .testTarget(name: "ConstantsTests", dependencies: ["Constants"]),
        .testTarget(name: "RecordTests", dependencies: ["Record"]),
    ]
)
