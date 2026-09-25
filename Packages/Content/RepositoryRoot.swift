import Foundation

/// The repository's root directory, found from this file's own path at
/// compile time. The literal lint and the sign-off check both need a path
/// that works however the test runner sets its working directory.
public enum RepositoryRoot {
    /// `Packages/Content`, this file's own directory.
    public static let contentPackageDirectory: URL = {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    }()

    /// The repository root: up from this file through `Content` and
    /// `Packages` (`RepositoryRoot.swift` → `Content` → `Packages` → the
    /// root).
    public static let path: URL = {
        contentPackageDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }()

    /// `Packages/Content/Resources`, where the content bundle's data,
    /// `content-lock.json` and every sign-off file live.
    public static var contentResourcesDirectory: URL {
        contentPackageDirectory.appendingPathComponent("Resources", isDirectory: true)
    }

    /// The `App` directory the literal lint scans.
    public static var appDirectory: URL {
        path.appendingPathComponent("App", isDirectory: true)
    }
}
