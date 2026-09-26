import Foundation

/// One content version's clinical sign-off. "Clinical sign-off per content
/// version" requires one such file per shipped content version, holding the
/// reviewer's tone-question answer for every reviewed id.
public struct SignOff: Sendable, Equatable, Codable {
    public let contentVersion: Int
    public let bundleHash: String
    public let date: String
    public let reviewerName: String
    public let reviewerRole: String
    public let reviewedIds: [String]
    public let toneAnswers: [String: String]

    public init(
        contentVersion: Int,
        bundleHash: String,
        date: String,
        reviewerName: String,
        reviewerRole: String,
        reviewedIds: [String],
        toneAnswers: [String: String]
    ) {
        self.contentVersion = contentVersion
        self.bundleHash = bundleHash
        self.date = date
        self.reviewerName = reviewerName
        self.reviewerRole = reviewerRole
        self.reviewedIds = reviewedIds
        self.toneAnswers = toneAnswers
    }

    /// `true` when this sign-off matches `bundle`: same content version,
    /// same hash.
    public func matches(_ bundle: ContentBundle) -> Bool {
        contentVersion == bundle.contentVersion && bundleHash == bundle.bundleHash
    }

    /// The sign-off file name for a content version, `content-signoff-
    /// v<n>.json`.
    public static func fileName(forContentVersion version: Int) -> String {
        "content-signoff-v\(version).json"
    }

    /// Reads the sign-off file for `bundle`'s content version from
    /// `directory`, if one exists, and returns it only when it matches the
    /// bundle's hash too.
    public static func matching(bundle: ContentBundle, in directory: URL) -> SignOff? {
        guard let signOff = read(contentVersion: bundle.contentVersion, from: directory) else { return nil }
        return signOff.matches(bundle) ? signOff : nil
    }

    /// Reads the sign-off file for `contentVersion` from `directory`, and
    /// returns it only when `content-lock.json` in the same directory holds
    /// the same content version and the sign-off's hash. The installed app
    /// uses this check, because it cannot compute the hash of the signed
    /// catalogue keys (ruling r13-01).
    public static func matching(contentVersion: Int, lockIn directory: URL) -> SignOff? {
        guard let lock = ContentLock.read(from: directory), lock.contentVersion == contentVersion else { return nil }
        guard let signOff = read(contentVersion: contentVersion, from: directory) else { return nil }
        return signOff.contentVersion == lock.contentVersion && signOff.bundleHash == lock.bundleHash ? signOff : nil
    }

    private static func read(contentVersion: Int, from directory: URL) -> SignOff? {
        let url = directory.appendingPathComponent(fileName(forContentVersion: contentVersion))
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SignOff.self, from: data)
    }
}

/// The release-lane rule: "Release without sign-off" and "A local test run
/// without sign-off". `MIDMORNING_RELEASE=1` requires a matching sign-off;
/// otherwise the bundle simply carries the Draft flag.
public enum ReleaseLane {
    public static let environmentKey = "MIDMORNING_RELEASE"

    public static func isRelease(_ environment: [String: String]) -> Bool {
        environment[environmentKey] == "1"
    }

    /// `true` when the release lane's sign-off requirement is met: not a
    /// release build, or a release build with a matching sign-off.
    public static func satisfiesReleaseGate(environment: [String: String], signOff: SignOff?) -> Bool {
        !isRelease(environment) || signOff != nil
    }
}
