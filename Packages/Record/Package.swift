// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Record",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "RecordCore", targets: ["RecordCore"]),
    ],
    targets: [
        .target(name: "RecordCore"),
        .testTarget(name: "RecordCoreTests", dependencies: ["RecordCore"]),
    ]
)
