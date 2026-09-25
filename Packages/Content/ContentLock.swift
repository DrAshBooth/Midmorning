import Foundation

/// `Packages/Content/Resources/content-lock.json`. It holds the content
/// version and the bundle hash that shipped last. A commit that raises the
/// content version updates this file in the same commit; `scripts/content-
/// lock` writes it.
public struct ContentLock: Sendable, Equatable, Codable {
    public let contentVersion: Int
    public let bundleHash: String

    public init(contentVersion: Int, bundleHash: String) {
        self.contentVersion = contentVersion
        self.bundleHash = bundleHash
    }

    public static let fileName = "content-lock.json"

    public static func read(from directory: URL) -> ContentLock? {
        let url = directory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ContentLock.self, from: data)
    }

    public func write(to directory: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: directory.appendingPathComponent(Self.fileName))
    }

    /// `true` when `lock` and `bundle` disagree: the same content version
    /// but a different hash. "The content test MUST fail when the bundle's
    /// hash differs from the lock's and the bundle's version equals the
    /// lock's."
    public static func disagrees(_ lock: ContentLock, with bundle: ContentBundle) -> Bool {
        lock.contentVersion == bundle.contentVersion && lock.bundleHash != bundle.bundleHash
    }
}
