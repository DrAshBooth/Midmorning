import Foundation
import SwiftData

/// Height, the onboarding BMI, the caution flag and `askedAt`. One fixed id;
/// `Profile` carries no creation moment. Winner: later `changedAt`, whole row
/// (data-and-privacy spec, "The app reads iCloud before onboarding").
///
/// CloudKit rules: every property has an inline default, no property is
/// unique, and every property except `id` allows cloud encryption.
@Model
public final class Profile {
    public var id: UUID = Profile.fixedId
    @Attribute(.allowsCloudEncryption) public var heightCm: Double = 0
    @Attribute(.allowsCloudEncryption) public var onboardingBMI: Double = 0
    @Attribute(.allowsCloudEncryption) public var cautionFlag: Bool = false
    /// The moment of the last screening. The store keeps no other screening
    /// date or moment (data-and-privacy spec, "Retention").
    @Attribute(.allowsCloudEncryption) public var askedAt: Date?
    @Attribute(.allowsCloudEncryption) public var changedAt: Date = Date()

    public init(id: UUID = Profile.fixedId, heightCm: Double, onboardingBMI: Double, cautionFlag: Bool, askedAt: Date?, changedAt: Date) {
        self.id = id
        self.heightCm = heightCm
        self.onboardingBMI = onboardingBMI
        self.cautionFlag = cautionFlag
        self.askedAt = askedAt
        self.changedAt = changedAt
    }

    /// The one fixed id every `Profile` row shares.
    public static let fixedId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
}
