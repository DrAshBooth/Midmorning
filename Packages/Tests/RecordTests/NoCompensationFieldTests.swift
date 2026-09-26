import Foundation
import XCTest
@testable import Record

/// Safeguarding spec, "No question about vomiting or laxatives": "The store
/// MUST have no field for compensation." (mm-t14.18, "The store" scenario).
final class NoCompensationFieldTests: XCTestCase {
    private let bannedFieldWords = ["vomit", "laxative", "purge", "compensat"]

    private func propertyNames(of instance: Any) -> [String] {
        Mirror(reflecting: instance).children.compactMap { $0.label }
    }

    func testNoRecordModelHasACompensationField() {
        let instances: [Any] = [
            Item(id: UUID()),
            ItemVersion(entryId: UUID(), changedAt: .now, dayKey: "2026-09-24", time: .now, utcOffsetSeconds: 0, what: "", feltLikeABinge: false, createdAt: .now),
            Day(dateKey: "2026-09-24", changedAt: .now),
            Answer(kind: "card", value: "", changedAt: .now),
        ]
        for instance in instances {
            for name in propertyNames(of: instance) {
                let lowered = name.lowercased()
                for banned in bannedFieldWords {
                    XCTAssertFalse(lowered.contains(banned), "\(type(of: instance)).\(name) should not name compensation")
                }
            }
        }
    }
}
