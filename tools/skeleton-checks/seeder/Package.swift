// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "Seeder",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "../../../Packages")],
    targets: [.executableTarget(name: "Seeder", dependencies: [.product(name: "RecordCore", package: "Packages")])]
)
